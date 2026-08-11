"""
Moyasar payment verification — confirms a payment was actually paid
before an order is created. Never trust the client's claim alone;
the app could be tampered with to skip payment entirely.

If MOYASAR_SECRET_KEY isn't set yet (merchant account still pending
activation), verification is skipped with a loud warning so the rest
of the app can keep being developed and tested. Remove this fallback
mentally once real keys are in place — setting the env var is enough,
no code change needed.
"""

import os
import httpx

MOYASAR_API_URL = "https://api.moyasar.com/v1/payments"
MOYASAR_TOKENS_URL = "https://api.moyasar.com/v1/tokens"


class PaymentVerificationError(Exception):
    pass


class RefundError(Exception):
    pass


class TokenChargeError(Exception):
    pass


def verify_payment(payment_id: str, expected_amount_sar: float) -> dict:
    """
    Fetches the payment from Moyasar and confirms it's paid and the
    amount matches the order total. Raises PaymentVerificationError
    if anything is off. Returns the raw Moyasar payment record.
    """
    secret_key = os.getenv("MOYASAR_SECRET_KEY")
    if not secret_key:
        print(f"[Moyasar] WARNING: MOYASAR_SECRET_KEY not set — "
              f"skipping verification for payment_id={payment_id}. "
              f"Do not ship to production like this.")
        return {"id": payment_id, "status": "skipped_no_key"}

    try:
        resp = httpx.get(
            f"{MOYASAR_API_URL}/{payment_id}",
            auth=(secret_key, ""),
            timeout=10.0,
        )
    except httpx.HTTPError as e:
        raise PaymentVerificationError(f"Could not reach Moyasar: {e}")

    if resp.status_code != 200:
        raise PaymentVerificationError(
            f"Moyasar returned {resp.status_code} for payment {payment_id}"
        )

    payment = resp.json()

    if payment.get("status") != "paid":
        raise PaymentVerificationError(
            f"Payment {payment_id} is not paid (status={payment.get('status')})"
        )

    expected_halalas = round(expected_amount_sar * 100)
    if payment.get("amount") != expected_halalas:
        raise PaymentVerificationError(
            f"Payment amount mismatch: expected {expected_halalas}, "
            f"got {payment.get('amount')}"
        )

    return payment


def charge_token(
    token: str,
    amount_halalas: int,
    description: str,
    callback_url: str,
    metadata: dict | None = None,
) -> dict:
    """
    Charges a saved card token. Returns the raw Moyasar payment record.

    The payment usually completes synchronously (status='paid') because the
    card was 3DS-verified when it was first saved. If the issuer still
    demands 3DS, the record comes back status='initiated' with a
    source.transaction_url the customer must visit — the app opens it in a
    webview and Moyasar redirects to callback_url when done.
    """
    secret_key = os.getenv("MOYASAR_SECRET_KEY")
    if not secret_key:
        raise TokenChargeError(
            "MOYASAR_SECRET_KEY not set — cannot charge saved cards."
        )

    try:
        resp = httpx.post(
            MOYASAR_API_URL,
            auth=(secret_key, ""),
            json={
                "amount": amount_halalas,
                "currency": "SAR",
                "description": description,
                "callback_url": callback_url,
                "metadata": metadata or {},
                "source": {"type": "token", "token": token},
            },
            timeout=15.0,
        )
    except httpx.HTTPError as e:
        raise TokenChargeError(f"Could not reach Moyasar: {e}")

    if resp.status_code not in (200, 201):
        raise TokenChargeError(
            f"Moyasar returned {resp.status_code} charging token: {resp.text}"
        )

    payment = resp.json()
    if payment.get("status") == "failed":
        message = (payment.get("source") or {}).get("message", "declined")
        raise TokenChargeError(f"Charge failed: {message}")

    return payment


def get_token(token_id: str) -> dict | None:
    """Fetches a saved-card token's details (brand, last4, expiry). Returns
    None on any failure — callers use this only to enrich display data."""
    secret_key = os.getenv("MOYASAR_SECRET_KEY")
    if not secret_key:
        return None
    try:
        resp = httpx.get(
            f"{MOYASAR_TOKENS_URL}/{token_id}",
            auth=(secret_key, ""),
            timeout=10.0,
        )
        if resp.status_code == 200:
            return resp.json()
    except httpx.HTTPError:
        pass
    return None


def delete_token(token_id: str) -> bool:
    """
    Invalidates a saved-card token on Moyasar's side. Returns True when the
    token is gone (deleted now, or already didn't exist). Failures are
    logged, not raised — the caller removes the local record regardless,
    since a token is unusable without the secret key anyway.
    """
    secret_key = os.getenv("MOYASAR_SECRET_KEY")
    if not secret_key:
        return False
    try:
        resp = httpx.delete(
            f"{MOYASAR_TOKENS_URL}/{token_id}",
            auth=(secret_key, ""),
            timeout=10.0,
        )
        if resp.status_code in (200, 204, 404):
            return True
        print(f"[Moyasar] delete_token {token_id} returned {resp.status_code}: {resp.text}")
    except httpx.HTTPError as e:
        print(f"[Moyasar] delete_token {token_id} failed: {e}")
    return False


def refund_payment(payment_id: str) -> dict:
    """
    Fully refunds a payment on Moyasar. Used when a customer cancels an
    order that hasn't started preparation yet. Raises RefundError on
    failure — the caller should NOT mark the order cancelled if this fails,
    since the customer would have paid with no order and no refund.
    """
    secret_key = os.getenv("MOYASAR_SECRET_KEY")
    if not secret_key:
        print(f"[Moyasar] WARNING: MOYASAR_SECRET_KEY not set — "
              f"skipping refund for payment_id={payment_id}. "
              f"Do not ship to production like this.")
        return {"id": payment_id, "status": "skipped_no_key"}

    try:
        resp = httpx.post(
            f"{MOYASAR_API_URL}/{payment_id}/refund",
            auth=(secret_key, ""),
            timeout=10.0,
        )
    except httpx.HTTPError as e:
        raise RefundError(f"Could not reach Moyasar: {e}")

    if resp.status_code != 200:
        raise RefundError(
            f"Moyasar returned {resp.status_code} refunding payment {payment_id}: {resp.text}"
        )

    return resp.json()
