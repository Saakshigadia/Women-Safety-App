"""
VIRA Women Safety App — Contacts Router
POST   /contacts           — add a trusted contact
GET    /contacts           — list all trusted contacts
DELETE /contacts/{id}      — remove a trusted contact
"""

import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

from auth import get_current_user
from models import ContactCreate, ContactResponse
from firebase_config import db

router = APIRouter(prefix="/contacts", tags=["Contacts"])

# Firestore sub-collection path helper
def _contacts_ref(uid: str):
    """Returns the 'trusted_contacts' sub-collection for a given user."""
    return db.collection("users").document(uid).collection("trusted_contacts")


@router.post("", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
async def add_contact(
    payload: ContactCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Add a new trusted contact under the authenticated user's profile.

    Each contact gets a UUID as its Firestore document ID.
    Limits the user to 10 trusted contacts to prevent abuse.
    """
    uid = current_user["uid"]
    ref = _contacts_ref(uid)

    # Enforce maximum contacts limit
    try:
        existing = ref.stream()
        count = sum(1 for _ in existing)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore read failed: {str(e)}",
        )

    if count >= 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum of 10 trusted contacts allowed.",
        )

    # Prevent duplicate phone numbers
    try:
        duplicates = ref.where("phone", "==", payload.phone).stream()
        if any(True for _ in duplicates):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A contact with this phone number already exists.",
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore query failed: {str(e)}",
        )

    contact_id = str(uuid.uuid4())
    contact_data = {
        "id": contact_id,
        "name": payload.name,
        "phone": payload.phone,
        "email": payload.email,
        "relationship": payload.relationship,
        "created_at": firestore.SERVER_TIMESTAMP,
    }

    try:
        ref.document(contact_id).set(contact_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore write failed: {str(e)}",
        )

    return ContactResponse(
        id=contact_id,
        name=payload.name,
        phone=payload.phone,
        email=payload.email,
        relationship=payload.relationship,
    )


@router.get("", response_model=list[ContactResponse])
async def list_contacts(current_user: dict = Depends(get_current_user)):
    """
    Return all trusted contacts for the authenticated user,
    ordered by creation time (oldest first).
    """
    uid = current_user["uid"]

    try:
        docs = _contacts_ref(uid).order_by("created_at").stream()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore read failed: {str(e)}",
        )

    contacts = []
    for doc in docs:
        d = doc.to_dict()
        contacts.append(
            ContactResponse(
                id=d.get("id", doc.id),
                name=d.get("name", ""),
                phone=d.get("phone", ""),
                email=d.get("email"),
                relationship=d.get("relationship"),
            )
        )

    return contacts


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contact(
    contact_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Remove a trusted contact by its ID.
    Returns 404 if the contact doesn't belong to the user.
    """
    uid = current_user["uid"]
    doc_ref = _contacts_ref(uid).document(contact_id)

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
            detail=f"Contact '{contact_id}' not found.",
        )

    try:
        doc_ref.delete()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore delete failed: {str(e)}",
        )

    # 204 No Content — return nothing