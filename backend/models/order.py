from pydantic import BaseModel
from typing import Optional, List, Dict
from datetime import datetime
from enum import Enum


class OrderStatus(str, Enum):
    RECEIVED   = "received"
    IN_PROGRESS = "in_progress"
    READY      = "ready"
    PICKED_UP  = "picked_up"


class PaymentMethod(str, Enum):
    """Online payment methods (no cash — orders must be paid online)."""
    MADA      = "mada"
    CARD      = "card"        # Visa / Mastercard
    APPLE_PAY = "apple_pay"
    STC_PAY   = "stc_pay"


# ─── Order Item (snapshot of menu item at time of order) ─────
class OrderItemCreate(BaseModel):
    menu_item_id: str
    name_en: str                       # snapshot — name may change later
    name_ar: str
    quantity: int
    price: float                       # snapshot — price at time of order
    customizations: Dict[str, str] = {} # {"Size": "Large", "Milk": "Oat"}
    notes: str = ""


class OrderItemResponse(BaseModel):
    menu_item_id: str
    name_en: str
    name_ar: str
    quantity: int
    price: float
    customizations: Dict[str, str]
    notes: str


# ─── Order ───────────────────────────────────────────────────
class OrderCreate(BaseModel):
    customer_id: str
    customer_name: str
    items: List[OrderItemCreate]
    payment_method: PaymentMethod        # required — orders are paid online
    notes: str = ""


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


class OrderResponse(BaseModel):
    id: str
    order_number: int = 0              # sequential, 1-based; 0 = legacy order without one
    customer_id: str
    customer_name: str
    items: List[OrderItemResponse]
    status: OrderStatus
    payment_method: Optional[str] = None
    notes: str
    total_price: float
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
