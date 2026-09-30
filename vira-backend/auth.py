"""
auth.py
───────
JWT token helpers + bcrypt password utilities.

Environment variables required:
  SECRET_KEY   — long random string (generate with: openssl rand -hex 32)
  ALGORITHM    — default HS256
  ACCESS_TOKEN_EXPIRE_MINUTES — default 60 * 24 * 7  (1 week)
"""

import os
import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

from firebase_config import db

# ── Config ─────────────────────────────────────────────────────────────────────

SECRET_KEY: str = os.getenv("SECRET_KEY", "CHANGE_ME_IN_PRODUCTION_USE_OPENSSL_RAND")
ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
    os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", str(60 * 24 * 7))
)

# ── OAuth2 scheme (reads Bearer token from Authorization header) ───────────────

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")


# ── Password helpers ───────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


# ── JWT helpers ────────────────────────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    payload = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload.update({"exp": expire})
    # print("=== SECRET_KEY USED FOR ENCODE ===", repr(SECRET_KEY))
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Raises HTTPException 401 if the token is invalid or expired."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        uid: str = payload.get("sub")
        if uid is None:
            raise credentials_exception
        return payload
    except JWTError as e:
        print("=== JWT DECODE FAILED ===", str(e))
        print("=== SECRET_KEY USED FOR DECODE ===", repr(SECRET_KEY))
        raise credentials_exception
    

# ── Current-user dependency ────────────────────────────────────────────────────

async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """
    FastAPI dependency — inject into any protected endpoint:
        current_user: dict = Depends(get_current_user)
    Returns the Firestore user document as a plain dict.
    """
    payload = decode_access_token(token)
    uid: str = payload["sub"]

    user_ref = db.collection("users").document(uid).get()
    if not user_ref.exists:
        raise HTTPException(status_code=404, detail="User not found")

    user_data = user_ref.to_dict()
    user_data["uid"] = uid
    return user_data


# ── Current-admin dependency (Chat 5) ───────────────────────────────────────────

async def get_current_admin(current_user: dict = Depends(get_current_user)) -> dict:
    """
    FastAPI dependency — inject into any admin-only endpoint:
        current_admin: dict = Depends(get_current_admin)

    Builds on get_current_user: first validates the JWT and loads the
    Firestore user document, then checks the `is_admin` flag on that
    document. Returns 403 if the flag is missing or False.

    NOTE: there is intentionally no endpoint to set `is_admin`. To create
    your first admin, open the Firebase console → Firestore → `users`
    collection → your user document → add a boolean field:
        is_admin: true
    """
    if not current_user.get("is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required",
        )
    return current_user
