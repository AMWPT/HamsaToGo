from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from models.order import OrderItemCreate


class SavedCardResponse(BaseModel):
    """A customer's saved card — display data only, never the card number.
    The Moyasar token itself stays server-side."""
    id: str
    brand: str = ""                    # e.g. "visa", "mada", "master"
    last4: str = ""
    expiry_month: Optional[int] = None
    expiry_year: Optional[int] = None
    created_at: Optional[datetime] = None


class TokenChargeRequest(BaseModel):
    """Charge a saved card for the current cart. Items are re-priced from
    the menu server-side; the client's prices are never trusted."""
    items: List[OrderItemCreate]


class TokenChargeResponse(BaseModel):
    payment_id: str
    status: str                        # "paid" | "initiated"
    # Present when the issuer demands a 3DS challenge — the app opens this
    # URL in a webview and Moyasar redirects to our callback when done.
    transaction_url: Optional[str] = None
