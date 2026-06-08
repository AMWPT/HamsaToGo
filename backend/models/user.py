from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    """Used when a customer registers."""
    email: EmailStr
    password: str
    full_name: str


class UserUpdate(BaseModel):
    """Used to update a customer's FCM token."""
    fcm_token: Optional[str] = None
    full_name: Optional[str] = None


class UserResponse(BaseModel):
    """Returned to the client after register/login."""
    id: str
    email: str
    full_name: str
    fcm_token: Optional[str] = None
    created_at: Optional[datetime] = None


class UserLogin(BaseModel):
    """Used when a customer logs in."""
    email: EmailStr
    password: str


class AdminLogin(BaseModel):
    """Fixed admin login (single device)."""
    email: str
    password: str
