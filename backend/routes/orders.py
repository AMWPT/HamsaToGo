from fastapi import APIRouter, Depends, HTTPException, Query
from models.order import OrderCreate, OrderStatusUpdate, OrderResponse, OrderStatus
from services import firestore as db
from services import postgres as pg
from services.fcm import notify_order_status
from dependencies import require_user, require_staff
from services.moyasar import verify_payment, refund_payment, PaymentVerificationError, RefundError
from typing import List, Optional

router = APIRouter(prefix="/orders", tags=["Orders"])


def _authoritative_unit_price(menu_item: dict, customizations: dict) -> float:
    """
    Compute an item's unit price from the menu (never trust the client).
    Base price + any selected option's price modifier.
    """
    price = float(menu_item.get("price", 0.0))
    for opt in menu_item.get("options", []):
        mods = opt.get("price_modifiers") or {}
        chosen = (customizations or {}).get(opt.get("name"))
        if chosen and chosen in mods:
            price += float(mods[chosen])
    return price


# ─── Place Order (Customer) ───────────────────────────────────
@router.post("/", response_model=OrderResponse, status_code=201)
def place_order(order: OrderCreate, decoded: dict = Depends(require_user)):
    """
    Customer places a new order.
    - Identity (customer_id/name) comes from the verified token, not the client.
    - Item prices are recomputed from the menu, never trusted from the client.
    - Saves to Firestore with status = 'received' (no push notification —
      status-change pushes start once staff begins preparing).
    """
    # Identity from the token — a caller can only order as themselves.
    uid = decoded["uid"]
    customer = db.get_user(uid)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found.")
    order.customer_id = uid
    order.customer_name = customer.get("full_name", "") or order.customer_name

    # Verify items exist + are available, and set the authoritative price.
    for item in order.items:
        menu_item = db.get_menu_item(item.menu_item_id)
        if not menu_item:
            raise HTTPException(
                status_code=404,
                detail=f"Menu item '{item.name_en}' not found."
            )
        if not menu_item.get("available", False):
            raise HTTPException(
                status_code=400,
                detail=f"'{item.name_en}' is currently unavailable."
            )
        item.price = _authoritative_unit_price(menu_item, item.customizations)

    # Verify the payment actually went through before creating the order —
    # never trust the client's claim alone.
    expected_total = sum(item.price * item.quantity for item in order.items)
    try:
        verify_payment(order.payment_id, expected_total)
    except PaymentVerificationError as e:
        raise HTTPException(status_code=402, detail=f"Payment verification failed: {e}")

    # Create the order in Firestore (store the method as a plain string)
    payload = order.model_dump()
    payload["payment_method"] = order.payment_method.value
    data = db.create_order(payload)

    # Sync to PostgreSQL
    pg.insert_order(data)
    pg.insert_order_items(data["id"], data.get("items", []))

    # No notification here — the customer just placed the order themselves;
    # pushes start when staff moves it to in_progress.

    return OrderResponse(**data)


# ─── Get All Orders (Admin / Employee) ───────────────────────
@router.get("/", response_model=List[OrderResponse],
            dependencies=[Depends(require_staff)])
def get_orders(
    status: Optional[str] = Query(None, description="Filter by status"),
    active_only: bool = Query(False, description="Show only received + in_progress + ready"),
):
    """
    Admin: Get all orders.
    - active_only=true → only 'received', 'in_progress' and 'ready' (the live queue)
    - status=received  → filter by specific status
    """
    if active_only:
        orders = db.get_active_orders()
    else:
        orders = db.get_all_orders(status=status)
    return [OrderResponse(**o) for o in orders]


# ─── Get Customer Orders ──────────────────────────────────────
@router.get("/customer/{customer_id}", response_model=List[OrderResponse])
def get_customer_orders(customer_id: str, decoded: dict = Depends(require_user)):
    """A customer may fetch only their own orders; staff may fetch anyone's."""
    if decoded["uid"] != customer_id and not db.is_staff(decoded["uid"]):
        raise HTTPException(status_code=403, detail="Not allowed.")
    orders = db.get_customer_orders(customer_id)
    return [OrderResponse(**o) for o in orders]


# ─── Get Single Order ─────────────────────────────────────────
@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: str, decoded: dict = Depends(require_user)):
    """Readable by the order's owner or by staff."""
    order = db.get_order(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found.")
    if order.get("customer_id") != decoded["uid"] and not db.is_staff(decoded["uid"]):
        raise HTTPException(status_code=403, detail="Not allowed.")
    return OrderResponse(**order)


# ─── Cancel Order (Customer) ──────────────────────────────────
@router.post("/{order_id}/cancel", response_model=OrderResponse)
def cancel_order(order_id: str, decoded: dict = Depends(require_user)):
    """
    Customer: Cancel an order and receive a full refund.
    Only the order's owner (or staff) may cancel it, and only while the
    order is still 'received' — once staff has started preparing it, it
    can no longer be cancelled.
    """
    order = db.get_order(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found.")

    if order.get("customer_id") != decoded["uid"] and not db.is_staff(decoded["uid"]):
        raise HTTPException(status_code=403, detail="Not allowed.")

    if order["status"] != OrderStatus.RECEIVED.value:
        raise HTTPException(
            status_code=400,
            detail="Only orders that haven't started preparation can be cancelled.",
        )

    payment_id = order.get("payment_id")
    if payment_id:
        try:
            refund_payment(payment_id)
        except RefundError as e:
            raise HTTPException(status_code=502, detail=f"Refund failed: {e}")

    updated = db.update_order_status(order_id, OrderStatus.CANCELLED.value)
    pg.update_order_status(order_id, OrderStatus.CANCELLED.value)

    notify_order_status(
        customer_id=order["customer_id"],
        order_id=order_id,
        status=OrderStatus.CANCELLED.value,
    )

    return OrderResponse(**updated)


# ─── Update Order Status (Admin / Employee) ───────────────────
@router.patch("/{order_id}/status", response_model=OrderResponse,
              dependencies=[Depends(require_staff)])
def update_order_status(order_id: str, update: OrderStatusUpdate):
    """
    Admin: Update the status of an order.

    Flow:
      received → in_progress → ready → picked_up

    A push notification is sent to the customer on every status change.
    """
    order = db.get_order(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found.")

    # Enforce valid status transitions
    transitions = {
        OrderStatus.RECEIVED:    [OrderStatus.IN_PROGRESS],
        OrderStatus.IN_PROGRESS: [OrderStatus.READY],
        OrderStatus.READY:       [OrderStatus.PICKED_UP],
        OrderStatus.PICKED_UP:   [],
    }

    current = OrderStatus(order["status"])
    allowed = transitions.get(current, [])

    if update.status not in allowed:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot transition from '{current}' to '{update.status}'. "
                   f"Allowed: {[s.value for s in allowed]}",
        )

    # Update in Firestore
    updated = db.update_order_status(order_id, update.status.value)

    # Sync status to PostgreSQL
    pg.update_order_status(order_id, update.status.value)

    # Notify the customer of the new status (in_progress / ready / picked_up)
    notify_order_status(
        customer_id=order["customer_id"],
        order_id=order_id,
        status=update.status.value,
    )

    return OrderResponse(**updated)
