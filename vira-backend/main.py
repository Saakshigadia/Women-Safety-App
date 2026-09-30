"""
main.py  —  VIRA Women Safety App · FastAPI entry point
Chat 3 update: SOS & Location routers added.
Chat 5 update: Admin Dashboard API + static admin dashboard added.
"""
from dotenv import load_dotenv
load_dotenv()


from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Routers
from routers.auth import router as auth_router          # Chat 1
from routers.profile import router as profile_router    # Chat 2
from routers.contacts import router as contacts_router  # Chat 2
from routers.sos import router as sos_router            # Chat 3
from routers.location import router as location_router  # Chat 3
from routers.admin import router as admin_router        # Chat 5  ← NEW

app = FastAPI(
    title="VIRA Women Safety API",
    description="Backend for the VIRA women safety Flutter app.",
    version="0.4.0",
)

# ── CORS (adjust origins for production) ──────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten this before going to production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Register routers ──────────────────────────────────────────────────────────
app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(contacts_router)
app.include_router(sos_router)       # /sos/trigger, /sos/cancel, /sos/history
app.include_router(location_router)  # /location
app.include_router(admin_router)     # /admin/stats, /admin/users, /admin/alerts


# ── Admin dashboard (static HTML/CSS/JS) ────────────────────────────────────────
import os
static_admin_dir = os.path.join(os.path.dirname(__file__), "static", "admin")
if os.path.exists(static_admin_dir):
    app.mount(
        "/admin-dashboard",
        StaticFiles(directory=static_admin_dir, html=True),
        name="admin-dashboard",
    )

@app.get("/", tags=["Health"])
async def root():
    return {"status": "ok", "app": "VIRA API", "version": "0.4.0"}


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy"}
