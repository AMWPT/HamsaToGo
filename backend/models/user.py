from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class PhoneVerifyRequest(BaseModel):
    """Sent after Firebase phone OTP verification."""
    id_token: str           # Firebase ID token from client
    full_name: Optional[str] = None   # Required only for new users (register)
    lang: Optional[str] = None        # Preferred language ('en' | 'ar')


class UserUpdate(BaseModel):
    """Update a customer's profile or FCM token."""
    fcm_token: Optional[str] = None
    full_name: Optional[str] = None
    lang: Optional[str] = None        # Preferred language ('en' | 'ar')


class UserResponse(BaseModel):
    """Returned to the client."""
    id: str
    phone: Optional[str] = None
    full_name: str
    fcm_token: Optional[str] = None
    lang: Optional[str] = None
    created_at: Optional[datetime] = None


class AdminPhoneVerify(BaseModel):
    """Staff login via Firebase phone OTP (single whitelisted number)."""
    id_token: str           # Firebase ID token from client
