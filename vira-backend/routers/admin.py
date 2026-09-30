"""
routers/admin.py
─────────────────
Chat 5 — Admin Dashboard API

Endpoints:
  GET /admin/stats   — aggregate counts (total users, total alerts,
                       active emergencies, resolved emergencies)
  GET /admin/users   — paginated list of all users
  GET /admin/alerts  — paginated list of all SOS alerts, optional status filter

All endpoints require an authenticated user whose Firestore document has
`is_admin: true` (enforced by auth.get_current_admin).

Firestore notes:
  • /admin/stats uses Firestore's count() aggregation queries, which are
    counted server-side and do NOT read full documents (cheap, fast).
    Requires firebase-admin >= 6.2 (google-cloud-firestore >= 2.11).
  • /admin/users and /admin/alerts use offset/limit pagination, which is
    simple and fine at admin-dashboard scale. If the `users` or
    `sos_alerts` collections grow very large (tens of thousands+ docs),
    consider switching to cursor-based pagination (start_after) instead.
  • /admin/alerts filtered by status AND ordered by triggered_at requires
    a composite index. The first time you call this with a status filter,
    Firestore will return an error containing a direct link to create that
    index automatically — click it once and the query will work from then on.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from firebase_admin import firestore

from auth import get_current_admin
from firebase_config import db
from models import (
    AdminStatsResponse,
    AdminUserResponse,
    AdminUsersPage,
    AdminAlertResponse,
    AdminAlertsPage,
)

router = APIRouter(prefix="/admin", tags=["Admin Dashboard"])


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def _count(query) -> int:
    """Run a Firestore count() aggregation query and return the integer result."""
    result = query.count().get()
    return result[0][0].value


def _format_timestamp(value) -> Optional[str]:
    """
    Convert a Firestore Timestamp (or Python datetime) to an ISO 8601 string.
    Returns None if the value is missing.
    """
    if value is None:
        return None
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value)


# ─────────────────────────────────────────────
# GET /admin/stats
# ─────────────────────────────────────────────
@router.get("/stats", response_model=AdminStatsResponse)
async def get_admin_stats(current_admin: dict = Depends(get_current_admin)):
    """
    Aggregate counts for the dashboard's stat cards.

    - total_users           → count of all documents in `users`
    - total_alerts          → count of all documents in `sos_alerts`
    - active_emergencies    → count of `sos_alerts` where status == "active"
    - resolved_emergencies  → count of `sos_alerts` where status == "resolved"
    """
    total_users = _count(db.collection("users"))
    total_alerts = _count(db.collection("sos_alerts"))
    active_emergencies = _count(
        db.collection("sos_alerts").where("status", "==", "active")
    )
    resolved_emergencies = _count(
        db.collection("sos_alerts").where("status", "==", "resolved")
    )

    return AdminStatsResponse(
        total_users=total_users,
        total_alerts=total_alerts,
        active_emergencies=active_emergencies,
        resolved_emergencies=resolved_emergencies,
    )


# ─────────────────────────────────────────────
# GET /admin/users
# ─────────────────────────────────────────────
@router.get("/users", response_model=AdminUsersPage)
async def list_users(
    page: int = Query(1, ge=1, description="1-indexed page number"),
    page_size: int = Query(20, ge=1, le=100, description="Rows per page (max 100)"),
    current_admin: dict = Depends(get_current_admin),
):
    """
    Paginated list of all users for the admin dashboard's users table.

    Ordered newest-first by `created_at`. Note: any user document that does
    not have a `created_at` field will be excluded from this ordered query
    (Firestore drops docs missing the order_by field). This should only
    affect documents created before Chat 1's registration flow set
    `created_at`, if any.
    """
    total = _count(db.collection("users"))

    offset = (page - 1) * page_size
    docs = (
        db.collection("users")
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .offset(offset)
        .limit(page_size)
        .stream()
    )

    users = []
    for doc in docs:
        data = doc.to_dict()
        users.append(
            AdminUserResponse(
                uid=doc.id,
                full_name=data.get("full_name", ""),
                email=data.get("email", ""),
                phone=data.get("phone"),
                is_admin=data.get("is_admin", False),
                created_at=_format_timestamp(data.get("created_at")),
            )
        )

    return AdminUsersPage(total=total, page=page, page_size=page_size, users=users)


# ─────────────────────────────────────────────
# GET /admin/alerts
# ─────────────────────────────────────────────
@router.get("/alerts", response_model=AdminAlertsPage)
async def list_alerts(
    page: int = Query(1, ge=1, description="1-indexed page number"),
    page_size: int = Query(20, ge=1, le=100, description="Rows per page (max 100)"),
    status: Optional[str] = Query(
        None,
        description="Filter by alert status: 'active' or 'resolved'. Omit for all.",
    ),
    current_admin: dict = Depends(get_current_admin),
):
    """
    Paginated list of all SOS alerts for the admin dashboard's alerts table,
    enriched with the triggering user's name/email. Ordered newest-first by
    `triggered_at`.
    """
    if status is not None and status not in ("active", "resolved"):
        raise HTTPException(
            status_code=400, detail="status must be 'active' or 'resolved'"
        )

    base_query = db.collection("sos_alerts")
    if status:
        base_query = base_query.where("status", "==", status)
        total = _count(db.collection("sos_alerts").where("status", "==", status))
    else:
        total = _count(db.collection("sos_alerts"))

    offset = (page - 1) * page_size
    alert_docs = list(
        base_query.order_by("triggered_at", direction=firestore.Query.DESCENDING)
        .offset(offset)
        .limit(page_size)
        .stream()
    )

    # Fetch the triggering users' name/email for this page so the table can
    # show "Jane Doe" instead of a raw uid. One read per distinct uid on the
    # current page (page_size is capped at 100, so this stays cheap).
    uids = list({d.to_dict().get("uid") for d in alert_docs if d.to_dict().get("uid")})
    user_lookup: dict[str, tuple[Optional[str], Optional[str]]] = {}
    for uid in uids:
        user_doc = db.collection("users").document(uid).get()
        if user_doc.exists:
            udata = user_doc.to_dict()
            user_lookup[uid] = (udata.get("full_name"), udata.get("email"))

    alerts = []
    for doc in alert_docs:
        data = doc.to_dict()
        uid = data.get("uid")
        user_name, user_email = user_lookup.get(uid, (None, None))

        alerts.append(
            AdminAlertResponse(
                alert_id=doc.id,
                uid=uid,
                user_name=user_name,
                user_email=user_email,
                status=data.get("status"),
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                address=data.get("address"),
                message=data.get("message"),
                triggered_at=data["triggered_at"],
                resolved_at=data.get("resolved_at"),
            )
        )

    return AdminAlertsPage(total=total, page=page, page_size=page_size, alerts=alerts)
