from fastapi import APIRouter, HTTPException, Query
from models.order import OrderCreate, OrderStatusUpdate, OrderResponse, OrderStatus
from services import firestore as db
from services import postgres as pg
from services.fcm import notify_order_ready, notify_order_received
from typing import List, Optional

router = APIRouter(prefix="/orders", tags=["Orders"])


# ─── Place Order (Customer) ───────────────────────────────────
@router.post("/", response_model=OrderResponse, status_code=201)
def place_order(order: OrderCreate):
    """
    Customer places a new order.
    - Saves to Firestore with status = 'received'
    - Sends a confirmation notification to the customer
    """
    # Verify customer exists
    customer = db.get_user(order.customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found.")

    # Verify all menu items exist and are available
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

    # Create the order in Firestore
    data = db.create_order(order.model_dump())

    # Sync to PostgreSQL
    pg.insert_order(data)
    pg.insert_order_items(data["id"], data.get("items", []))

    # Notify customer that order was received
    notify_order_received(
        customer_id=order.customer_id,
        order_id=data["id"],
    )

    return OrderResponse(**data)


# ─── Get All Orders (Admin / Employee) ───────────────────────
@router.get("/", response_model=List[OrderResponse])
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
def get_customer_orders(customer_id: str):
    """Customer: Get all orders placed by a specific customer."""
    customer = db.get_user(customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found.")
    orders = db.get_customer_orders(customer_id)
    return [OrderResponse(**o) for o in orders]


# ─── Get Single Order ─────────────────────────────────────────
@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: str):
    """Get a single order by ID."""
    order = db.get_order(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found.")
    return OrderResponse(**order)


# ─── Update Order Status (Admin / Employee) ───────────────────
@router.patch("/{order_id}/status", response_model=OrderResponse)
def update_order_status(order_id: str, update: OrderStatusUpdate):
    """
    Admin: Update the status of an order.

    Flow:
      received → in_progress → ready → picked_up

    When status becomes 'ready':
      → Push notification is sent to the customer automatically.
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

    # Send push notification when order is ready
    if update.status == OrderStatus.READY:
        notify_order_ready(
            customer_id=order["customer_id"],
            order_id=order_id,
        )

    return OrderResponse(**updated)
