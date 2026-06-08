import os
from fastapi import APIRouter, HTTPException, status
from firebase_admin import auth as firebase_auth
from models.user import PhoneVerifyRequest, UserUpdate, UserResponse, AdminLogin
from services import firestore as db

router = APIRouter(prefix="/auth", tags=["Auth"])


# ─── Phone OTP Verify (Sign In + Register) ───────────────────
@router.post("/phone-verify")
def phone_verify(data: PhoneVerifyRequest):
    """
    Called after Firebase phone OTP is verified on the client.
    - Verifies the Firebase ID token server-side.
    - If the user exists in Firestore → signs them in (returns user + token).
    - If not and full_name is provided → creates new account.
    - If not and full_name is missing → returns 404 so the app redirects to register.
    """
    # Verify the Firebase ID token
    try:
        decoded = firebase_auth.verify_id_token(data.id_token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )

    uid = decoded["uid"]
    phone = decoded.get("phone_number", "")

    # Check Firestore
    user_data = db.get_user(uid)

    if not user_data:
        # New user — full_name required
        if not data.full_name or not data.full_name.strip():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="NO_ACCOUNT",
            )
        user_data = db.create_user(uid, {
            "phone": phone,
            "full_name": data.full_name.strip(),
            "fcm_token": None,
        })

    return {"user": user_data, "token": data.id_token}


# ─── Get User Profile ─────────────────────────────────────────
@router.get("/users/{user_id}")
def get_user(user_id: str):
    user = db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return {
        "id": user["id"],
        "phone": user.get("phone", ""),
        "full_name": user.get("full_name", ""),
        "fcm_token": user.get("fcm_token"),
        "created_at": str(user["created_at"]) if user.get("created_at") else None,
    }


# ─── Update User (FCM token / full name) ─────────────────────
@router.patch("/users/{user_id}")
def update_user(user_id: str, update: UserUpdate):
    user = db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    updated = db.update_user(user_id, update.model_dump(exclude_none=True))
    return {
        "id": updated["id"],
        "phone": updated.get("phone", ""),
        "full_name": updated.get("full_name", ""),
        "fcm_token": updated.get("fcm_token"),
    }


# ─── Admin Login ──────────────────────────────────────────────
@router.post("/admin/verify")
def verify_admin(credentials: AdminLogin):
    """Fixed admin credentials check (single shared device)."""
    admin_email    = os.getenv("ADMIN_EMAIL", "admin@hamsa.com")
    admin_password = os.getenv("ADMIN_PASSWORD", "")

    if credentials.email != admin_email or credentials.password != admin_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin credentials.",
        )
    return {"success": True}
