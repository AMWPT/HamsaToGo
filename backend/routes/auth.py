import os
from fastapi import APIRouter, Header, HTTPException, status
from firebase_admin import auth as firebase_auth
from models.user import PhoneVerifyRequest, UserUpdate, UserResponse, AdminPhoneVerify
from services import firestore as db
from services import postgres as pg

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
        decoded = firebase_auth.verify_id_token(data.id_token, clock_skew_seconds=60)
    except Exception as e:
        print(f"[AUTH ERROR] Token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )

    uid = decoded["uid"]
    phone = decoded.get("phone_number", "")

    # Check Firestore
    user_data = db.get_user(uid)

    lang = data.lang if data.lang in ("en", "ar") else "en"

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
            "lang": lang,
        })
    elif data.lang and user_data.get("lang") != lang:
        # Existing user — keep their language preference current
        user_data = db.update_user(uid, {"lang": lang})

    # Sync to PostgreSQL (upsert — safe to call on every login too)
    pg.upsert_customer(uid, user_data.get("phone", ""), user_data.get("full_name", ""))

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
        "lang": user.get("lang", "en"),
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
        "lang": updated.get("lang", "en"),
    }


# ─── Delete Account ───────────────────────────────────────────
@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: str, authorization: str = Header(None)):
    """
    Permanently delete a customer account.
    - Requires a valid Firebase ID token whose UID matches user_id, so a
      user can only delete their own account.
    - Removes the Firestore profile document.
    - Removes/anonymizes the PostgreSQL analytics record.
    - Deletes the Firebase Auth user so they can no longer sign in.
    """
    # Authenticate the caller and confirm they own this account
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token.",
        )
    token = authorization.split(" ", 1)[1]
    try:
        decoded = firebase_auth.verify_id_token(token, clock_skew_seconds=60)
    except Exception as e:
        print(f"[AUTH ERROR] Delete-account token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )
    if decoded["uid"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own account.",
        )

    user = db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    # Remove the profile + analytics record
    db.delete_user(user_id)
    pg.delete_customer(user_id)

    # Delete the Firebase Auth account (best-effort — may already be gone)
    try:
        firebase_auth.delete_user(user_id)
    except Exception as e:
        print(f"[AUTH] Firebase delete_user failed for {user_id}: {e}")

    return None


# ─── Admin Login via Phone OTP ────────────────────────────────
def _normalize_phone(p: str) -> str:
    """Strip spaces/dashes so '+966 5..' and '+9665..' compare equal."""
    return "".join(p.split()).replace("-", "")


def _allowed_staff_phones() -> set:
    """
    Whitelisted staff numbers (normalized).
    Reads STAFF_PHONES (comma-separated list) and falls back to the
    legacy single STAFF_PHONE, so both env var names work.
    """
    raw = os.getenv("STAFF_PHONES") or os.getenv("STAFF_PHONE", "")
    return {_normalize_phone(p) for p in raw.split(",") if p.strip()}


@router.post("/admin/phone-verify")
def verify_admin_phone(data: AdminPhoneVerify):
    """
    Staff login via Firebase phone OTP.
    Verifies the Firebase ID token server-side, then checks the phone
    number against the whitelisted staff numbers (STAFF_PHONES).
    """
    allowed = _allowed_staff_phones()
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Staff phones not configured.",
        )

    try:
        decoded = firebase_auth.verify_id_token(data.id_token, clock_skew_seconds=60)
    except Exception as e:
        print(f"[AUTH ERROR] Admin token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )

    phone = _normalize_phone(decoded.get("phone_number", ""))
    if phone not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This number is not authorized for staff access.",
        )

    # Record this user as staff (a /staff/{uid} document). Firestore rules
    # check for that document to grant order-queue access — this takes effect
    # immediately, with no client ID-token refresh required.
    try:
        db.mark_staff(decoded["uid"], phone)
    except Exception as e:
        print(f"[AUTH] Failed to mark staff {decoded['uid']}: {e}")

    return {"success": True}
