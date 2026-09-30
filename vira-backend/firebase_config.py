"""
VIRA Women Safety App — Firebase / Firestore Initialisation

Reads credentials from the GOOGLE_APPLICATION_CREDENTIALS env var
(path to your serviceAccountKey.json) OR from FIREBASE_CREDENTIALS_JSON
(the raw JSON string, useful for Railway / Render secrets).
"""

import os
import json
import firebase_admin
from firebase_admin import credentials, firestore

def _init_firebase():
    # Avoid double-initialisation (FastAPI hot-reload)
    if firebase_admin._apps:
        return

    raw_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if raw_json:
        # Deployment path: secret stored as JSON string in env var
        cred_dict = json.loads(raw_json)
        cred = credentials.Certificate(cred_dict)
    else:
        # Local dev path: point to your downloaded serviceAccountKey.json
        key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "serviceAccountKey.json")
        cred = credentials.Certificate(key_path)

    firebase_admin.initialize_app(cred)

_init_firebase()
db: firestore.Client = firestore.client()