"""
Saved cards (Moyasar tokenization).

A card is saved by the order flow: when the customer opts in, place_order
extracts the token from the verified payment and stores it here. These
endpoints let the customer list their cards, remove one, and pay with one.

Paying with a token happens entirely server-side (the secret key charges
the token) — the app never re-collects card details. The charge usually
completes synchronously because the card was 3DS-verified when saved; if
the issuer still demands 3DS, the response carries a transaction_url the
app opens in a webview, and Moyasar redirects to /cards/payment-callback
when the challenge is done.
"""

import os
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from models.card import SavedCardResponse, TokenChargeRequest, TokenChargeResponse
from services import firestore as db
from services.moyasar import charge_token, delete_token, TokenChargeError
from dependencies import require_user
from routes.orders import price_order_items
from typing import List

router = APIRouter(prefix="/cards", tags=["Saved Cards"])

# Where Moyasar redirects the customer after a 3DS challenge on a token
# charge. Must be an absolute URL on this backend — the app's webview
# watches for it to know the challenge finished.
BACKEND_BASE_URL = os.getenv(
    "BACKEND_BASE_URL",
    "https://hamsa-backend-269284588239.europe-west3.run.app",
)
PAYMENT_CALLBACK_PATH = "/cards/payment-callback"


def _to_response(card: dict) -> SavedCardResponse:
    return SavedCardResponse(
        id=card["id"],
        brand=card.get("brand", "") or "",
        last4=card.get("last4", "") or "",
        expiry_month=card.get("expiry_month"),
        expiry_year=card.get("expiry_year"),
        created_at=card.get("created_at"),
    )


# ─── List Saved Cards ─────────────────────────────────────────
@router.get("/", response_model=List[SavedCardResponse])
def list_cards(decoded: dict = Depends(require_user)):
    """The caller's own saved cards — display data only, tokens never leave
    the backend."""
    return [_to_response(c) for c in db.get_saved_cards(decoded["uid"])]


# ─── Delete a Saved Card ──────────────────────────────────────
@router.delete("/{card_id}", status_code=204)
def remove_card(card_id: str, decoded: dict = Depends(require_user)):
    """
    Remove a saved card. The token is invalidated on Moyasar's side too;
    if that call fails the local record is still removed — an orphaned
    token is unusable without the secret key.
    """
    card = db.get_saved_card(card_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found.")
    if card.get("customer_id") != decoded["uid"]:
        raise HTTPException(status_code=403, detail="Not allowed.")

    if card.get("token"):
        delete_token(card["token"])
    db.delete_saved_card(card_id)


# ─── Pay with a Saved Card ────────────────────────────────────
@router.post("/{card_id}/pay", response_model=TokenChargeResponse)
def pay_with_card(
    card_id: str,
    body: TokenChargeRequest,
    decoded: dict = Depends(require_user),
):
    """
    Charge the caller's saved card for the given cart. The amount is
    recomputed from the menu server-side. On success the app follows up
    with the normal POST /orders/ using the returned payment_id — which
    re-verifies the payment before the order is created.
    """
    uid = decoded["uid"]
    card = db.get_saved_card(card_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found.")
    if card.get("customer_id") != uid:
        raise HTTPException(status_code=403, detail="Not allowed.")
    if not card.get("token"):
        raise HTTPException(status_code=400, detail="Card has no usable token.")

    total = price_order_items(body.items)
    if total <= 0:
        raise HTTPException(status_code=400, detail="Cart is empty.")

    customer = db.get_user(uid) or {}
    try:
        payment = charge_token(
            token=card["token"],
            amount_halalas=round(total * 100),
            description=f"Hamsa To Go order — {customer.get('full_name', '')}".strip(" —"),
            callback_url=f"{BACKEND_BASE_URL}{PAYMENT_CALLBACK_PATH}",
            metadata={"customer_id": uid, "saved_card_id": card_id},
        )
    except TokenChargeError as e:
        raise HTTPException(status_code=402, detail=str(e))

    transaction_url = (payment.get("source") or {}).get("transaction_url")
    return TokenChargeResponse(
        payment_id=payment["id"],
        status=payment.get("status", ""),
        transaction_url=transaction_url,
    )


# ─── 3DS Callback Landing Page ────────────────────────────────
@router.get("/payment-callback", response_class=HTMLResponse, include_in_schema=False)
def payment_callback():
    """
    Where Moyasar redirects after a 3DS challenge on a token charge.
    The app's webview intercepts this URL and reads the query params
    (status/message) — this page only shows briefly, if at all.
    """
    return HTMLResponse(
        "<!doctype html><html><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width, initial-scale=1'>"
        "<title>Hamsa To Go</title></head>"
        "<body style='font-family:sans-serif;text-align:center;padding-top:40vh'>"
        "<p>تمت معالجة الدفع — جارٍ العودة للتطبيق…</p>"
        "<p>Payment processed — returning to the app…</p>"
        "</body></html>"
    )
