import os
import requests as http_requests
from fastapi import APIRouter, HTTPException, status
from firebase_admin import auth as firebase_auth
from models.user import UserCreate, UserLogin, UserUpdate, UserResponse, AdminLogin
from services import firestore as db

router = APIRouter(prefix="/auth", tags=["Auth"])

FIREBASE_SIGN_IN_URL = (
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
)


def _firebase_sign_in(email: str, password: str) -> dict:
    """Call Firebase REST API to verify credentials and get an ID token."""
    api_key = os.getenv("FIREBASE_WEB_API_KEY", "")
    resp = http_requests.post(
        FIREBASE_SIGN_IN_URL,
        params={"key": api_key},
        json={"email": email, "password": password, "returnSecureToken": True},
        timeout=10,
    )
    if resp.status_code != 200:
        error_msg = resp.json().get("error", {}).get("message", "LOGIN_FAILED")
        if "EMAIL_NOT_FOUND" in error_msg or "INVALID_LOGIN_CREDENTIALS" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password.",
            )
        if "INVALID_PASSWORD" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect password.",
            )
        if "TOO_MANY_ATTEMPTS" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed attempts. Try again later.",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg,
        )
    return resp.json()   # contains idToken, localId, email, ...


# ─── Customer Register ────────────────────────────────────────
@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user: UserCreate):
    """
    Register a new customer account.
    Creates a Firebase Auth user + Firestore document.
    Returns {user, token}.
    """
    try:
        firebase_user = firebase_auth.create_user(
            email=user.email,
            password=user.password,
            display_name=user.full_name,
        )
    except firebase_auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )

    # Save to Firestore
    user_data = db.create_user(firebase_user.uid, {
        "email":     user.email,
        "full_name": user.full_name,
        "fcm_token": None,
    })

    # Sign in immediately to get an ID token
    try:
        sign_in = _firebase_sign_in(user.email, user.password)
        token = sign_in.get("idToken")
    except Exception:
        token = None

    return {"user": user_data, "token": token}


# ─── Customer Login ───────────────────────────────────────────
@router.post("/login")
def login(credentials: UserLogin):
    """
    Log in a customer with email + password.
    Verifies with Firebase Auth and returns {user, token}.
    """
    sign_in = _firebase_sign_in(credentials.email, credentials.password)
    uid   = sign_in["localId"]
    token = sign_in["idToken"]

    # Fetch or lazily create Firestore profile
    user_data = db.get_user(uid)
    if not user_data:
        # Account exists in Firebase Auth but not in Firestore (edge case)
        user_data = db.create_user(uid, {
            "email":     credentials.email,
            "full_name": credentials.email.split("@")[0],
            "fcm_token": None,
        })

    return {"user": user_data, "token": token}


# ─── Update FCM Token / Profile ───────────────────────────────
@router.patch("/users/{user_id}", response_model=UserResponse)
def update_user(user_id: str, update: UserUpdate):
    user = db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    updated = db.update_user(user_id, update.model_dump(exclude_none=True))
    return UserResponse(**updated)


# ─── Get Customer Profile ─────────────────────────────────────
@router.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: str):
    user = db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return UserResponse(**user)


# ─── Admin Login Check ────────────────────────────────────────
@router.post("/admin/verify")
def verify_admin(credentials: AdminLogin):
    """
    Verify fixed admin credentials (single shared device).
    Returns {success: true} on match.
    """
    admin_email    = os.getenv("ADMIN_EMAIL", "admin@hamsa.com")
    admin_password = os.getenv("ADMIN_PASSWORD", "")

    if credentials.email != admin_email or credentials.password != admin_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin credentials.",
        )

    return {"success": True, "message": "Admin verified."}
