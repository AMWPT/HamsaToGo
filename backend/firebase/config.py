import firebase_admin
from firebase_admin import credentials, firestore, auth, messaging
from dotenv import load_dotenv
import os

load_dotenv()

_app = None


def init_firebase():
    """Initialize Firebase Admin SDK (called once on startup)."""
    global _app
    if _app is not None:
        return _app

    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase/serviceAccountKey.json")

    if os.path.exists(cred_path):
        # Local development — use the downloaded service account key file.
        cred = credentials.Certificate(cred_path)
        _app = firebase_admin.initialize_app(cred)
    else:
        # Production (e.g. Cloud Run) — use Application Default Credentials
        # from the runtime's service account. No key file is shipped or needed.
        print(
            f"[Firebase] No key file at '{cred_path}'; "
            "falling back to Application Default Credentials."
        )
        _app = firebase_admin.initialize_app()
    return _app


def get_firestore():
    """Return the Firestore client."""
    return firestore.client()


def get_auth():
    """Return the Firebase Auth client."""
    return auth


def get_messaging():
    """Return the Firebase Messaging client."""
    return messaging
