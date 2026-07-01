"""
Shared FastAPI auth dependencies.

The backend uses the Firebase Admin SDK, which BYPASSES Firestore security
rules — so these checks are the backend's own access gate. Every protected
endpoint verifies the caller's Firebase ID token, and staff-only endpoints
additionally require a /staff/{uid} document.
"""
from fastapi import Depends, Header, HTTPException, status
from firebase_admin import auth as firebase_auth
from services import firestore as db


def require_user(authorization: str = Header(None)) -> dict:
    """
    Verify the Firebase ID token from the `Authorization: Bearer <token>`
    header. Returns the decoded token (a dict containing 'uid').
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token.",
        )
    token = authorization.split(" ", 1)[1]
    try:
        return firebase_auth.verify_id_token(token, clock_skew_seconds=60)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )


def require_staff(decoded: dict = Depends(require_user)) -> dict:
    """Require the caller to be a verified staff member (/staff/{uid} doc)."""
    if not db.is_staff(decoded["uid"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Staff access required.",
        )
    return decoded
