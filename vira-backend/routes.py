"""
routes.py
─────────
Auth endpoints:
  POST  /auth/register  — create a new user account
  POST  /auth/login     — exchange credentials (JSON) for a JWT
  POST  /auth/token     — exchange credentials (Form) for a JWT  ← Swagger UI uses this
  GET   /auth/me        — return the authenticated user's profile
"""

from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordRequestForm
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from auth import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
)
from firebase_config import db
from models import UserRegister, UserLogin, Token, UserOut

auth_router = APIRouter()


# ── POST /auth/register ────────────────────────────────────────────────────────

@auth_router.post(
    "/register",
    response_model=Token,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new VIRA user",
)
async def register(payload: UserRegister):
    # 1. Check if email already exists
    existing = db.collection("users").where("email", "==", payload.email).get()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    # 2. Hash password and write user document
    hashed = hash_password(payload.password)
    user_ref = db.collection("users").document()   # auto-generated UID
    uid = user_ref.id

    user_ref.set(
        {
            "uid": uid,
            "name": payload.name,
            "email": payload.email,
            "phone": payload.phone,
            "password_hash": hashed,
            "created_at": SERVER_TIMESTAMP,
        }
    )

    # 3. Issue JWT
    token = create_access_token({"sub": uid})
    return Token(access_token=token)


# ── POST /auth/login (JSON) ────────────────────────────────────────────────────

@auth_router.post(
    "/login",
    response_model=Token,
    summary="Login with JSON and receive a JWT",
)
async def login(payload: UserLogin):
    results = db.collection("users").where("email", "==", payload.email).get()
    if not results:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    user_data = results[0].to_dict()

    if not verify_password(payload.password, user_data["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    token = create_access_token({"sub": user_data["uid"]})
    return Token(access_token=token)


# ── POST /auth/token (Form) — used by Swagger UI Authorize button ──────────────

@auth_router.post(
    "/token",
    response_model=Token,
    summary="Login with form data (used by Swagger UI)",
    include_in_schema=False,   # hides it from docs to keep things clean
)
async def token_form(form: OAuth2PasswordRequestForm = Depends()):
    results = db.collection("users").where("email", "==", form.username).get()
    if not results:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    user_data = results[0].to_dict()

    if not verify_password(form.password, user_data["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    token = create_access_token({"sub": user_data["uid"]})
    return Token(access_token=token)


# ── GET /auth/me ───────────────────────────────────────────────────────────────

@auth_router.get(
    "/me",
    response_model=UserOut,
    summary="Get the currently authenticated user",
)
async def me(current_user: dict = Depends(get_current_user)):
    return UserOut(
        uid=current_user["uid"],
        name=current_user["name"],
        email=current_user["email"],
        phone=current_user.get("phone"),
    )