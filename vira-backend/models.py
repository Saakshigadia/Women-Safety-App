"""
VIRA Women Safety App — Pydantic Models
Covers: Auth (Chat 1) + Profile & Contacts (Chat 2) + SOS/Location (Chat 3)
        + Admin Dashboard (Chat 5)
"""

from __future__ import annotations
import re
from typing import Optional, Any
from pydantic import BaseModel, EmailStr, Field, validator
from datetime import datetime, timezone


# ─────────────────────────────────────────────
#  AUTH MODELS  (Chat 1)
# ─────────────────────────────────────────────

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, description="Minimum 8 characters")
    full_name: str = Field(..., min_length=2, max_length=80)
    phone: Optional[str] = None

    @validator("phone")
    def validate_phone(cls, v):
        if v and not re.match(r"^\+?[1-9]\d{6,14}$", v):
            raise ValueError("Invalid phone number format. Use E.164 (e.g. +919876543210)")
        return v

    @validator("password")
    def password_strength(cls, v):
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain at least one digit")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    uid: str
    full_name: str


class TokenData(BaseModel):
    uid: Optional[str] = None


# ─────────────────────────────────────────────
#  PROFILE MODELS  (Chat 2)
# ─────────────────────────────────────────────

class UserProfile(BaseModel):
    uid: str
    email: str
    full_name: str
    phone: Optional[str] = None
    profile_picture_url: Optional[str] = None
    created_at: Optional[Any] = None   # Firestore Timestamp — serialised as str
    updated_at: Optional[Any] = None

    class Config:
        # Allow Firestore Timestamps to pass through as-is
        arbitrary_types_allowed = True
        json_encoders = {
            # Convert any non-serialisable object to its string representation
            object: str,
        }


class UserProfileUpdate(BaseModel):
    """
    All fields are optional — the router only writes non-None values to Firestore.
    email is intentionally excluded: changing email requires re-verification.
    """
    full_name: Optional[str] = Field(None, min_length=2, max_length=80)
    phone: Optional[str] = None
    profile_picture_url: Optional[str] = None

    @validator("phone")
    def validate_phone(cls, v):
        if v and not re.match(r"^\+?[1-9]\d{6,14}$", v):
            raise ValueError("Invalid phone number format. Use E.164 (e.g. +919876543210)")
        return v


# ─────────────────────────────────────────────
#  CONTACT MODELS  (Chat 2)
# ─────────────────────────────────────────────

class ContactCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=80, description="Contact's full name")
    phone: str = Field(..., description="E.164 phone number, e.g. +919876543210")
    email: Optional[EmailStr] = None
    relationship: Optional[str] = Field(
        None,
        max_length=50,
        description="E.g. Mother, Sister, Friend",
    )

    @validator("phone")
    def validate_phone(cls, v):
        if not re.match(r"^\+?[1-9]\d{6,14}$", v):
            raise ValueError("Invalid phone number. Use E.164 format e.g. +919876543210")
        return v


class ContactResponse(BaseModel):
    id: str
    name: str
    phone: str
    email: Optional[str] = None
    relationship: Optional[str] = None




# ══════════════════════════════════════════════
# CHAT 3  ·  SOS & Location models
# ══════════════════════════════════════════════
 
class SOSTriggerRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = None          # reverse-geocoded address from Flutter
    message: Optional[str] = None          # custom distress message
 
 
class SOSCancelRequest(BaseModel):
    alert_id: str = Field(..., description="Firestore document ID of the alert to cancel")
 
 
class SOSAlertResponse(BaseModel):
    alert_id: str
    uid: str
    status: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    message: Optional[str] = None
    triggered_at: datetime
    resolved_at: Optional[datetime] = None
    
 
 
class LocationUpdateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = Field(None, description="GPS accuracy in metres")
 
 
class LocationResponse(BaseModel):
    uid: str
    latitude: float
    longitude: float
    accuracy: Optional[float]
    updated_at: datetime
 
    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}


# ══════════════════════════════════════════════
# CHAT 5  ·  Admin Dashboard models
# ══════════════════════════════════════════════

class AdminStatsResponse(BaseModel):
    """Response for GET /admin/stats — aggregate counts for the dashboard cards."""
    total_users: int
    total_alerts: int
    active_emergencies: int
    resolved_emergencies: int


class AdminUserResponse(BaseModel):
    """A single row in the admin users table."""
    uid: str
    full_name: str
    email: str
    phone: Optional[str] = None
    is_admin: bool = False
    created_at: Optional[str] = None  # ISO 8601 string, formatted server-side


class AdminUsersPage(BaseModel):
    """Response for GET /admin/users — paginated list of users."""
    total: int
    page: int
    page_size: int
    users: list[AdminUserResponse]


class AdminAlertResponse(BaseModel):
    """A single row in the admin alerts table, enriched with user info."""
    alert_id: str
    uid: str
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    status: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    message: Optional[str] = None
    triggered_at: datetime
    resolved_at: Optional[datetime] = None

    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}


class AdminAlertsPage(BaseModel):
    """Response for GET /admin/alerts — paginated list of SOS alerts."""
    total: int
    page: int
    page_size: int
    alerts: list[AdminAlertResponse]
    