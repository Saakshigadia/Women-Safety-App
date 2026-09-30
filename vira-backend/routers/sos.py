from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore
from datetime import datetime, timezone
from typing import List

from auth import get_current_user
from models import (
    SOSTriggerRequest,
    SOSCancelRequest,
    LocationUpdateRequest,
    SOSAlertResponse,
    LocationResponse,
)
from firebase_config import db

router = APIRouter(prefix="/sos", tags=["SOS & Location"])


# ─────────────────────────────────────────────
# POST /sos/trigger
# ─────────────────────────────────────────────
@router.post("/trigger", response_model=SOSAlertResponse, status_code=status.HTTP_201_CREATED)
async def trigger_sos(
    payload: SOSTriggerRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new SOS alert in Firestore.
    Marks the alert as 'active' and stores location + timestamp.
    """
    uid = current_user["uid"]
    now = datetime.now(timezone.utc)

    alert_data = {
        "uid": uid,
        "status": "active",
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "address": payload.address,
        "message": payload.message or "SOS triggered",
        "triggered_at": now,
        "resolved_at": None,
        "notified_contacts": [],   # filled by a background task / FCM in a later chat
    }

    # Add to Firestore – auto-generated document ID
    alert_ref = db.collection("sos_alerts").document()
    alert_ref.set(alert_data)

    # Also update the user's live location & active_sos flag
    db.collection("users").document(uid).update({
        "active_sos_id": alert_ref.id,
        "last_location": {
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "updated_at": now,
        },
    })

    return SOSAlertResponse(
        alert_id=alert_ref.id,
        uid=uid,
        status="active",
        latitude=payload.latitude,
        longitude=payload.longitude,
        address=payload.address,
        message=alert_data["message"],
        triggered_at=now,
        resolved_at=None,
    )


# ─────────────────────────────────────────────
# POST /sos/cancel
# ─────────────────────────────────────────────
@router.post("/cancel", response_model=SOSAlertResponse)
async def cancel_sos(
    payload: SOSCancelRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Resolve / cancel an active SOS alert.
    Only the owner of the alert can cancel it.
    """
    uid = current_user["uid"]
    alert_ref = db.collection("sos_alerts").document(payload.alert_id)
    alert_doc = alert_ref.get()

    if not alert_doc.exists:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    alert = alert_doc.to_dict()

    if alert["uid"] != uid:
        raise HTTPException(status_code=403, detail="Not authorised to cancel this alert")

    if alert["status"] == "resolved":
        raise HTTPException(status_code=400, detail="Alert is already resolved")

    now = datetime.now(timezone.utc)
    alert_ref.update({"status": "resolved", "resolved_at": now})

    # Clear active_sos_id on the user document
    db.collection("users").document(uid).update({"active_sos_id": firestore.DELETE_FIELD})

    return SOSAlertResponse(
        alert_id=payload.alert_id,
        uid=uid,
        status="resolved",
        latitude=alert.get("latitude"),
        longitude=alert.get("longitude"),
        address=alert.get("address"),
        message=alert.get("message"),
        triggered_at=alert["triggered_at"],
        resolved_at=now,
    )


# ─────────────────────────────────────────────
# GET /sos/history
# ─────────────────────────────────────────────
@router.get("/history", response_model=List[SOSAlertResponse])
async def sos_history(
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
):
    """
    Return the authenticated user's past SOS alerts, newest first.
    """
    uid = current_user["uid"]

    docs = (
        db.collection("sos_alerts")
        .where("uid", "==", uid)
        .order_by("triggered_at", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )

    history: List[SOSAlertResponse] = []
    for doc in docs:
        data = doc.to_dict()
        history.append(
            SOSAlertResponse(
                alert_id=doc.id,
                uid=data["uid"],
                status=data["status"],
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                address=data.get("address"),
                message=data.get("message"),
                triggered_at=data["triggered_at"],
                resolved_at=data.get("resolved_at"),
            )
        )

    return history