"""
VIRA Women Safety App — Auth Router  (Chat 1 endpoints, router version)
POST /register  — create a new user in Firestore + return JWT
POST /login     — verify credentials + return JWT
GET  /me        — return current user info from token
"""

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

from auth import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
)
from models import UserRegister, UserLogin, Token, UserProfile
from firebase_config import db

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(payload: UserRegister):
    """
    Register a new user.
    - Checks for duplicate email in Firestore
    - Hashes password with bcrypt
    - Stores user document in `users` collection
    - Returns a JWT access token
    """
    users_ref = db.collection("users")

    # Check duplicate email
    try:
        existing = users_ref.where("email", "==", payload.email).stream()
        if any(True for _ in existing):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists.",
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore query failed: {str(e)}",
        )

    hashed_pw = hash_password(payload.password)

    # Create new user document — Firestore auto-generates the UID
    new_doc_ref = users_ref.document()
    uid = new_doc_ref.id

    user_data = {
        "uid": uid,
        "email": payload.email,
        "full_name": payload.full_name,
        "phone": payload.phone,
        "password_hash": hashed_pw,
        "created_at": firestore.SERVER_TIMESTAMP,
        "updated_at": firestore.SERVER_TIMESTAMP,
    }

    try:
        new_doc_ref.set(user_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore write failed: {str(e)}",
        )

    access_token = create_access_token(data={"sub": uid})
    return Token(access_token=access_token, uid=uid, full_name=payload.full_name)


@router.post("/login", response_model=Token)
async def login(payload: UserLogin):
    """
    Authenticate an existing user.
    - Looks up user by email
    - Verifies bcrypt password hash
    - Returns a JWT access token
    """
    try:
        docs = db.collection("users").where("email", "==", payload.email).stream()
        user_doc = next((d for d in docs), None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore query failed: {str(e)}",
        )

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    user_data = user_doc.to_dict()

    if not verify_password(payload.password, user_data["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    uid = user_data["uid"]
    access_token = create_access_token(data={"sub": uid})
    return Token(
        access_token=access_token,
        uid=uid,
        full_name=user_data.get("full_name", ""),
    )


@router.get("/me", response_model=UserProfile)
async def me(current_user: dict = Depends(get_current_user)):
    """
    Return the authenticated user's profile.
    Requires a valid Bearer token in the Authorization header.
    """
    uid = current_user["uid"]

    try:
        doc = db.collection("users").document(uid).get()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Firestore read failed: {str(e)}",
        )

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    d = doc.to_dict()
    return UserProfile(
        uid=uid,
        email=d.get("email", ""),
        full_name=d.get("full_name", ""),
        phone=d.get("phone"),
        profile_picture_url=d.get("profile_picture_url"),
        created_at=d.get("created_at"),
        updated_at=d.get("updated_at"),
    )