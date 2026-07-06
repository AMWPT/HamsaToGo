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


class PaymentVerificationError(Exception):
    pass


class RefundError(Exception):
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
