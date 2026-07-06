from firebase_admin import messaging
from firebase.config import get_firestore

USERS = "users"


# ─── Per-status notification copy (EN + AR) ───────────────────
STATUS_MESSAGES = {
    "received": {
        "title_en": "Order received",
        "title_ar": "تم استلام الطلب",
        "body_en": "Your order has been received.",
        "body_ar": "تم استلام طلبك.",
    },
    "in_progress": {
        "title_en": "Order being prepared ☕",
        "title_ar": "جاري تحضير الطلب ☕",
        "body_en": "Your order is being prepared.",
        "body_ar": "يتم تحضير طلبك الآن.",
    },
    "ready": {
        "title_en": "Order ready",
        "title_ar": "الطلب جاهز",
        "body_en": "Your order is ready for pick up.",
        "body_ar": "طلبك جاهز للاستلام.",
    },
    "picked_up": {
        "title_en": "Thank you!",
        "title_ar": "شكراً لك!",
        "body_en": "Thank you for your visit.",
        "body_ar": "شكراً لزيارتك.",
    },
    "cancelled": {
        "title_en": "Order cancelled",
        "title_ar": "تم إلغاء الطلب",
        "body_en": "Your order was cancelled and refunded.",
        "body_ar": "تم إلغاء طلبك واسترجاع المبلغ.",
    },
}


def get_customer_doc(customer_id: str) -> dict | None:
    """Fetch the customer's profile document from Firestore."""
    db = get_firestore()
    doc = db.collection(USERS).document(customer_id).get()
    if not doc.exists:
        return None
    return doc.to_dict()


def get_customer_fcm_token(customer_id: str) -> str | None:
    """Fetch the customer's FCM token from Firestore."""
    doc = get_customer_doc(customer_id)
    return doc.get("fcm_token") if doc else None


def send_push_notification(
    fcm_token: str,
    title_en: str,
    title_ar: str,
    body_en: str,
    body_ar: str,
    data: dict = None,
    lang: str = "en",
) -> bool:
    """
    Send a push notification via FCM.
    The customer's preferred language determines which title/body is sent.
    """
    if not fcm_token:
        return False

    title = title_ar if lang == "ar" else title_en
    body  = body_ar  if lang == "ar" else body_en

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={k: str(v) for k, v in (data or {}).items()},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    sound="default",
                    channel_id="orders",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default"),
                ),
            ),
        )
        messaging.send(message)
        return True
    except Exception as e:
        print(f"[FCM Error] Failed to send notification: {e}")
        return False


def notify_order_status(customer_id: str, order_id: str, status: str) -> bool:
    """
    Notify a customer that their order moved to a new status.
    Sends in the customer's preferred language (stored on their profile).
    Fires for every status: received → in_progress → ready → picked_up.
    """
    msg = STATUS_MESSAGES.get(status)
    if not msg:
        return False

    doc = get_customer_doc(customer_id)
    if not doc:
        return False

    token = doc.get("fcm_token")
    if not token:
        print(f"[FCM] No token for customer {customer_id}, skipping notification.")
        return False

    lang = doc.get("lang", "en")

    return send_push_notification(
        fcm_token=token,
        title_en=msg["title_en"],
        title_ar=msg["title_ar"],
        body_en=msg["body_en"],
        body_ar=msg["body_ar"],
        data={"order_id": order_id, "type": f"order_{status}", "status": status},
        lang=lang,
    )
