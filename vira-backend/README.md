# VIRA Women Safety App — FastAPI Backend
## Chat 1: Project Setup + JWT Auth

---

### Project Structure

```
vira-backend/
├── main.py              # FastAPI app entry point + CORS
├── auth.py              # JWT creation, bcrypt hashing, current_user dependency
├── models.py            # Pydantic request/response models
├── firebase_config.py   # Firestore initialisation
├── routes.py            # /register  /login  /me  endpoints
├── requirements.txt
├── .env.example         # Copy → .env and fill secrets
└── .gitignore
```

---

### Quick Start

#### 1. Clone & create virtualenv
```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

#### 2. Firebase setup
1. Firebase Console → your project → **Project Settings → Service Accounts**
2. **Generate new private key** → save as `serviceAccountKey.json` in project root
3. Add `serviceAccountKey.json` to `.gitignore` ✅ (already done)

#### 3. Environment variables
```bash
cp .env.example .env
# Edit .env:
#   SECRET_KEY  →  openssl rand -hex 32
#   Leave ALGORITHM and ACCESS_TOKEN_EXPIRE_MINUTES as-is
#   GOOGLE_APPLICATION_CREDENTIALS=serviceAccountKey.json
```

#### 4. Load .env and run
```bash
# Install python-dotenv if not already:
pip install python-dotenv

# Run server
uvicorn main:app --reload --port 8000
```

#### 5. Explore interactive docs
Open **http://localhost:8000/docs** — Swagger UI is auto-generated.

---

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/auth/register` | ❌ | Create account → returns JWT |
| `POST` | `/auth/login` | ❌ | Login → returns JWT |
| `GET`  | `/auth/me` | ✅ Bearer | Get current user profile |
| `GET`  | `/` | ❌ | Health check |

#### Register
```json
POST /auth/register
{
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "password": "SecurePass123!",
  "phone": "+919876543210"
}
```

#### Login
```json
POST /auth/login
{
  "email": "priya@example.com",
  "password": "SecurePass123!"
}
```

#### Me
```
GET /auth/me
Authorization: Bearer <token>
```

---

### Firestore Data Model

**Collection:** `users`  
**Document ID:** auto-generated (used as `uid`)

```json
{
  "uid": "abc123",
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "phone": "+919876543210",
  "password_hash": "$2b$12$...",
  "created_at": "<server timestamp>"
}
```

---

### Security Notes
- Passwords are **never stored in plaintext** — bcrypt with 12 rounds
- JWTs expire after **7 days** by default (configurable in `.env`)
- `SECRET_KEY` must be rotated before production — generate with `openssl rand -hex 32`
- Tighten `allow_origins` in `main.py` to your Flutter app's domain before going live

---

### Next: Chat 2 — User Profile & Contacts API
Adds `GET/PUT /profile` and `POST/GET/DELETE /contacts` endpoints.