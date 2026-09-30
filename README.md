<div align="center">

# 🛡️ VIRA — Women Safety Application

### *Because every woman deserves to feel safe*

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Render](https://img.shields.io/badge/Deployed_on-Render-46E3B7?style=for-the-badge&logo=render&logoColor=black)](https://render.com/)
[![JWT](https://img.shields.io/badge/Auth-JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)](https://jwt.io/)

<br/>

**VIRA** is a full-stack women safety application that allows users to send instant SOS alerts with live GPS location to their emergency contacts — with a single tap.

<br/>

[🔗 Live API Docs](https://vira-backend.onrender.com/docs) • [💚 Health Check](https://vira-backend.onrender.com/health) • [📊 Admin Dashboard](https://vira-backend.onrender.com/static/admin/index.html)

</div>

---

## 🌟 The Problem We're Solving

Women in India face serious safety concerns every day — on public transport, while walking alone at night, or in emergency situations. When danger strikes, every second counts. Most safety apps are too slow — too many taps before help is called.

**VIRA solves this with:**
- A single tap SOS that instantly alerts all emergency contacts
- Real-time GPS location shared automatically
- Background location tracking during active emergencies
- An admin dashboard for monitoring active emergencies

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🆘 **One-Tap SOS** | Instantly triggers an emergency alert with live GPS coordinates |
| 📍 **Live Location Sharing** | Shares real-time location with all saved emergency contacts |
| 👥 **Emergency Contacts** | Add and manage trusted contacts (family, friends) |
| 📳 **Shake Detection** | Shake your phone to trigger SOS without unlocking |
| 📷 **Spy Camera** | Secretly record video during an emergency |
| 🗺️ **Nearby Police** | Shows nearest police stations on the map |
| 🔐 **JWT Authentication** | Secure token-based login and registration |
| 📊 **Admin Dashboard** | Web dashboard showing real-time stats and all SOS alerts |
| 📜 **Alert History** | Full history of all past SOS events with location and timestamp |
| 🔔 **Background Service** | Continues working even when app is minimized |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VIRA System                              │
├─────────────────┬───────────────────────┬───────────────────────┤
│  Flutter App    │    FastAPI Backend     │   Firebase Firestore  │
│  (Dart)         │    (Python)            │   (Database)          │
│                 │                       │                       │
│  • Login/Signup │  POST /register        │  • users collection   │
│  • SOS Button   │  POST /login           │  • contacts           │
│  • Shake Detect │  GET  /me              │  • sos_alerts         │
│  • Live Map     │  GET  /profile         │  • locations          │
│  • Contacts     │  PUT  /profile         │                       │
│  • Spy Cam      │  POST /contacts        │                       │
│  • Police Near  │  POST /sos/trigger     │                       │
│                 │  POST /sos/cancel      │                       │
│                 │  GET  /sos/history     │                       │
│                 │  PUT  /location        │                       │
│                 │  GET  /admin/stats     │                       │
│                 │  GET  /admin/users     │                       │
│                 │  GET  /admin/alerts    │                       │
└─────────────────┴───────────────────────┴───────────────────────┘
                              │
                         Deployed on
                      Render (Singapore)
                    for low latency from India
```

---

## 🛠️ Tech Stack

### Mobile App
| Technology | Purpose |
|---|---|
| Flutter (Dart) | Cross-platform mobile framework |
| SharedPreferences | Local JWT token storage |
| Geolocator | GPS & live location |
| Google Maps Flutter | Map view & nearby police stations |
| Firebase Messaging | Push notifications |
| Camera | Spy cam feature |
| Sensors Plus | Shake detection |

### Backend
| Technology | Purpose |
|---|---|
| FastAPI (Python) | High-performance REST API |
| Firebase Admin SDK | Firestore database connection |
| Python-JOSE | JWT token generation & validation |
| Passlib (bcrypt) | Secure password hashing |
| Uvicorn | ASGI production server |
| Pydantic | Request/response data validation |

### Infrastructure
| Technology | Purpose |
|---|---|
| Firebase Firestore | NoSQL cloud database |
| Render (Singapore) | Cloud deployment & hosting |
| GitHub | Version control & CI/CD |

---

## 📡 API Endpoints

### 🔐 Authentication
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/register` | Register a new user | ❌ |
| POST | `/login` | Login & receive JWT token | ❌ |
| GET | `/me` | Get current user info | ✅ |

### 👤 Profile
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/profile` | Get user profile | ✅ |
| PUT | `/profile` | Update profile info | ✅ |

### 📞 Emergency Contacts
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/contacts` | Add emergency contact | ✅ |
| GET | `/contacts` | Get all contacts | ✅ |
| DELETE | `/contacts/{id}` | Remove a contact | ✅ |

### 🆘 SOS & Location
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/sos/trigger` | Trigger SOS alert with location | ✅ |
| POST | `/sos/cancel` | Cancel active SOS | ✅ |
| GET | `/sos/history` | Get past SOS alerts | ✅ |
| PUT | `/location` | Update live location | ✅ |

### 🛡️ Admin
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/admin/stats` | Total users, alerts, active emergencies | ✅ Admin |
| GET | `/admin/users` | Paginated list of all users | ✅ Admin |
| GET | `/admin/alerts` | All SOS alerts with status filter | ✅ Admin |

---

## 📁 Project Structure

```
vira-women-safety-app/
│
├── 📱 Flutter App (root)
│   ├── lib/
│   │   ├── main.dart                     # App entry point
│   │   ├── firebase_options.dart         # Firebase config
│   │   ├── screens/
│   │   │   ├── home_screen.dart          # Main SOS screen
│   │   │   ├── login_screen.dart         # Login
│   │   │   ├── signup_screen.dart        # Registration
│   │   │   ├── contacts_screen.dart      # Emergency contacts
│   │   │   ├── map_screen.dart           # Live map
│   │   │   ├── nearby_police_screen.dart # Police stations map
│   │   │   ├── profile_screen.dart       # User profile
│   │   │   └── onboarding_screen.dart    # First launch screens
│   │   └── services/
│   │       ├── api_service.dart          # Central HTTP client (JWT)
│   │       ├── auth_services.dart        # Auth logic
│   │       ├── sos_service.dart          # SOS trigger logic
│   │       ├── location_service.dart     # GPS tracking
│   │       ├── shake_service.dart        # Shake detection
│   │       ├── sms_service.dart          # SMS alerts
│   │       └── spy_cam_service.dart      # Background camera
│   ├── android/                          # Android config
│   ├── ios/                              # iOS config
│   ├── assets/                           # Icons & splash images
│   └── pubspec.yaml                      # Flutter dependencies
│
└── 🐍 vira-backend/
    ├── main.py                           # FastAPI app entry point
    ├── auth.py                           # JWT authentication
    ├── models.py                         # Pydantic models
    ├── firebase_config.py                # Firestore connection
    ├── routes.py                         # Route registration
    ├── requirements.txt                  # Python dependencies
    ├── routers/
    │   ├── auth.py                       # /register /login /me
    │   ├── profile.py                    # /profile
    │   ├── contacts.py                   # /contacts
    │   ├── sos.py                        # /sos/*
    │   ├── location.py                   # /location
    │   └── admin.py                      # /admin/*
    └── static/
        └── admin/
            └── index.html                # Admin dashboard UI
```

---

## 🚀 Run Locally

### Prerequisites
- Python 3.11+
- Flutter SDK 3.x+
- Firebase project with Firestore enabled
- `serviceAccountKey.json` from Firebase Console

### Backend Setup

```bash
# 1. Clone the repo
git clone https://github.com/Kashif-14/vira-women-safety-app.git
cd vira-women-safety-app/vira-backend

# 2. Create virtual environment
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Place serviceAccountKey.json in this folder (do not commit it)

# 5. Start the server
uvicorn main:app --reload
```

Visit **http://localhost:8000/docs** to explore all endpoints in Swagger UI.

### Flutter App Setup

```bash
# From project root
flutter pub get
flutter run
```

---

## 🧪 Testing

### Postman
Import `vira-backend/VIRA_API.postman_collection.json` — 25 automated tests with tokens auto-saved between requests.

### pytest
```bash
cd vira-backend
pip install pytest httpx
pytest tests/ -v
```

---

## 🌐 Live Deployment

Deployed on **Render** (Singapore) — auto-deploys on every `git push` to `main`.

| Link | Purpose |
|------|---------|
| [API Docs](https://vira-backend-qeog.onrender.com/docs) | Swagger UI |
| [Health Check](https://vira-backend-qeog.onrender.com/health) | Server status |
| [Admin Dashboard](https://vira-backend-qeog.onrender.com/admin-dashboard/) | Admin panel |

> ⚠️ Free tier sleeps after 15 min of inactivity. First request may take ~30 seconds to wake up.

---

## 👨‍💻 Author

**Kashif Ahmed**
- 🐙 GitHub: [@Kashif-14](https://github.com/Kashif-14)
- 💼 LinkedIn: *www.linkedin.com/in/kashif-ahmed-1b1814294*
- 📧 Email: *kashifahmed.ka03@gmail.com*

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

Made with ❤️ for women's safety 🛡️

⭐ **Star this repo if you found it helpful!**

</div>
