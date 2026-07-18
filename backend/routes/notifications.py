from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from services import firestore as db
from services.fcm import send_push_notification, get_customer_fcm_token
from dependencies import require_user, require_staff

router = APIRouter(prefix="/notifications", tags=["Notifications"])


class TokenUpdate(BaseModel):
    customer_id: str
    fcm_token: str


class StaffTokenUpdate(BaseModel):
    fcm_token: str


class ManualNotification(BaseModel):
    customer_id: str
    title_en: str
    title_ar: str
    body_en: str
    body_ar: str
    lang: str = "en"


# ─── Save FCM Token ───────────────────────────────────────────
@router.post("/token")
def save_token(payload: TokenUpdate, decoded: dict = Depends(require_user)):
    """
    Save or update the caller's own FCM device token.
    Called by the Flutter app every time it starts.
    """
    if decoded["uid"] != payload.customer_id:
        raise HTTPException(status_code=403, detail="You can only set your own token.")

    customer = db.get_user(payload.customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found.")

    db.update_user(payload.customer_id, {"fcm_token": payload.fcm_token})
    return {"success": True, "message": "FCM token saved."}


# ─── Save Staff FCM Token ─────────────────────────────────────
@router.post("/staff-token")
def save_staff_token(payload: StaffTokenUpdate,
                     decoded: dict = Depends(require_staff)):
    """
    Save the calling staff member's device token so their phone gets a
    push notification whenever a new order is placed.
    """
    db.set_staff_fcm_token(decoded["uid"], payload.fcm_token)
    return {"success": True, "message": "Staff FCM token saved."}


# ─── Send Manual Notification (Admin) ────────────────────────
@router.post("/send", dependencies=[Depends(require_staff)])
def send_manual_notification(payload: ManualNotification):
    """
    Admin: Manually send a custom push notification to a customer.
    Useful for special announcements or offers.
    """
    token = get_customer_fcm_token(payload.customer_id)
    if not token:
        raise HTTPException(
            status_code=404,
            detail="Customer has no FCM token registered. They must open the app first.",
        )

    success = send_push_notification(
        fcm_token=token,
        title_en=payload.title_en,
        title_ar=payload.title_ar,
        body_en=payload.body_en,
        body_ar=payload.body_ar,
        lang=payload.lang,
    )

    if not success:
        raise HTTPException(status_code=500, detail="Failed to send notification.")

    return {"success": True, "message": "Notification sent."}
