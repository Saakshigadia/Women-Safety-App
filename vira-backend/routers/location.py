from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timezone

from auth import get_current_user
from models import LocationUpdateRequest, LocationResponse
from firebase_config import db

router = APIRouter(tags=["Location"])


# ─────────────────────────────────────────────
# PUT /location
# ─────────────────────────────────────────────
@router.put("/location", response_model=LocationResponse)
async def update_location(
    payload: LocationUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the authenticated user's live location in Firestore.
    Called periodically by the Flutter app while an SOS is active
    (or for passive background tracking).
    """
    uid = current_user["uid"]
    now = datetime.now(timezone.utc)

    location_data = {
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "accuracy": payload.accuracy,
        "updated_at": now,
    }

    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User profile not found")

    user_ref.update({"last_location": location_data})

    # If there's an active SOS, mirror location there too so contacts can query it
    user_data = user_doc.to_dict()
    active_sos_id = user_data.get("active_sos_id")
    if active_sos_id:
        db.collection("sos_alerts").document(active_sos_id).update({
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "location_updated_at": now,
        })

    return LocationResponse(
        uid=uid,
        latitude=payload.latitude,
        longitude=payload.longitude,
        accuracy=payload.accuracy,
        updated_at=now,
    )