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

    if not os.path.exists(cred_path):
        raise FileNotFoundError(
            f"Firebase credentials not found at '{cred_path}'.\n"
            "Download your service account key from:\n"
            "Firebase Console → Project Settings → Service Accounts → Generate new private key"
        )

    cred = credentials.Certificate(cred_path)
    _app = firebase_admin.initialize_app(cred)
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
