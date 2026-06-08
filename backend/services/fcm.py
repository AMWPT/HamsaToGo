from firebase_admin import messaging
from firebase.config import get_firestore

USERS = "users"


def get_customer_fcm_token(customer_id: str) -> str | None:
    """Fetch the customer's FCM token from Firestore."""
    db = get_firestore()
    doc = db.collection(USERS).document(customer_id).get()
    if not doc.exists:
        return None
    return doc.to_dict().get("fcm_token")


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


def notify_order_ready(customer_id: str, order_id: str, lang: str = "en") -> bool:
    """
    Notify a customer that their order is ready for pickup.
    Called when an employee marks an order as 'ready'.
    """
    token = get_customer_fcm_token(customer_id)
    if not token:
        print(f"[FCM] No token for customer {customer_id}, skipping notification.")
        return False

    return send_push_notification(
        fcm_token=token,
        title_en="Your order is ready! ☕",
        title_ar="طلبك جاهز! ☕",
        body_en="Come pick it up at the counter.",
        body_ar="تفضل باستلامه من الكاونتر.",
        data={"order_id": order_id, "type": "order_ready"},
        lang=lang,
    )


def notify_order_received(customer_id: str, order_id: str, lang: str = "en") -> bool:
    """
    Notify a customer that their order was received by the cafe.
    """
    token = get_customer_fcm_token(customer_id)
    if not token:
        return False

    return send_push_notification(
        fcm_token=token,
        title_en="Order received!",
        title_ar="تم استلام طلبك!",
        body_en="We're working on your order.",
        body_ar="نحن نعمل على تحضير طلبك.",
        data={"order_id": order_id, "type": "order_received"},
        lang=lang,
    )
