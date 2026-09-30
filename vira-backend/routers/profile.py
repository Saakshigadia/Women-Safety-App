"""
VIRA Women Safety App — Profile Router
GET /profile  — fetch current user's profile
PUT /profile  — update profile fields
"""

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

from auth import get_current_user
from models import UserProfile, UserProfileUpdate
from firebase_config import db

router = APIRouter(prefix="/profile", tags=["Profile"])


@router.get("", response_model=UserProfile)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """
    Return the authenticated user's full profile from Firestore.
    The token's uid is used to look up the document.
    """
    uid = current_user["uid"]

    try:
        doc_ref = db.collection("users").document(uid)
        doc = doc_ref.get()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore read failed: {str(e)}",
        )

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found. Please register first.",
        )

    data = doc.to_dict()
    return UserProfile(
        uid=uid,
        email=data.get("email", ""),
        full_name=data.get("full_name", ""),
        phone=data.get("phone"),
        profile_picture_url=data.get("profile_picture_url"),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


@router.put("", response_model=UserProfile)
async def update_profile(
    payload: UserProfileUpdate,
    current_user: dict = Depends(get_current_user),
):
    """
    Partially update the authenticated user's profile.
    Only non-None fields in the payload are written to Firestore.
    """
    uid = current_user["uid"]
    doc_ref = db.collection("users").document(uid)

    try:
        doc = doc_ref.get()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore read failed: {str(e)}",
        )

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found.",
        )

    # Build update dict — skip fields the caller left as None
    updates = {k: v for k, v in payload.dict().items() if v is not None}
    if not updates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update.",
        )

    updates["updated_at"] = firestore.SERVER_TIMESTAMP

    try:
        doc_ref.update(updates)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore write failed: {str(e)}",
        )

    # Return the freshly-updated document
    fresh = doc_ref.get().to_dict()
    return UserProfile(
        uid=uid,
        email=fresh.get("email", ""),
        full_name=fresh.get("full_name", ""),
        phone=fresh.get("phone"),
        profile_picture_url=fresh.get("profile_picture_url"),
        created_at=fresh.get("created_at"),
        updated_at=fresh.get("updated_at"),
    )