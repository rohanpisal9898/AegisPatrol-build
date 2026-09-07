# 🛡️ AegisPatrol - Mobile Safety Application Skeleton

A clean, modular foundation for the **AegisPatrol** mobile safety application featuring **strict role-based separation** between **Civilian** and **Police** workflows.

---

## 🏗️ Architecture Overview

```
APP START
    ↓
┌─────────────────────┐
│   Choose Your Role  │
│                     │
│   [ CIVILIAN ]      │
│   [ POLICE ]        │
└─────────────────────┘
       ↓
   ┌───────────────┐
   │               │
   ↓               ↓
CIVILIAN         POLICE
AUTH             AUTH
   ↓               ↓
Login/Signup     Login/Signup
   ↓               ↓
CIVILIAN APP     POLICE APP
   ↓               ↓
┌──────────────┐  ┌─────────────────┐
│ Home         │  │ Home            │
│ Journeys     │  │ Assignments     │
│ Profile      │  │ Journeys        │
└──────────────┘  │ Profile         │
                  └─────────────────┘
```

- **Frontend**: Flutter (Cross-platform iOS, Android, Web)
- **Backend**: FastAPI (Python 3.9+)
- **Database**: MongoDB (Motor async driver)
- **Authentication**: Phone Number + Password (JWT HS256 + bcrypt)
- **District Scope**: Restricted to 36 Maharashtra Districts
- **AI Integration**: Gemini API configuration placeholder ready for downstream AI features

---

## 📁 Repository Structure

```
D.H.A.A.L/
├── backend/
│   ├── app/
│   │   ├── core/
│   │   │   ├── config.py             # Settings (MONGO_URI, JWT_SECRET, GEMINI_API_KEY)
│   │   │   ├── constants.py          # 36 Maharashtra districts
│   │   │   └── security.py           # Bcrypt password hashing & JWT handling
│   │   ├── db/
│   │   │   └── mongodb.py            # MongoDB Motor client & compound unique index
│   │   ├── models/
│   │   │   └── user.py               # Database User document model
│   │   ├── schemas/
│   │   │   ├── auth.py               # Signup / Login request & response schemas
│   │   │   └── user.py               # User response schemas
│   │   ├── routers/
│   │   │   ├── civilian_auth.py      # POST /auth/civilian/signup, /login
│   │   │   ├── police_auth.py        # POST /auth/police/signup, /login
│   │   │   └── users.py              # GET /auth/me, POST /auth/logout
│   │   ├── services/
│   │   │   ├── auth_service.py       # Authentication business logic & role checks
│   │   │   └── gemini_service.py     # Gemini AI client placeholder
│   │   └── main.py                   # FastAPI lifespan, CORS, and routers
│   ├── tests/
│   │   └── test_auth.py              # Pytest suite verifying auth & role separation
│   ├── .env.example                  # Environment configuration template
│   ├── requirements.txt              # Python dependencies
│   └── README.md
│
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── api_endpoints.dart# API route definitions
│   │   │   │   ├── app_colors.dart   # Safety green brand theme & police accents
│   │   │   │   └── districts.dart    # 36 Maharashtra districts list
│   │   │   ├── storage/
│   │   │   │   └── secure_storage_service.dart # flutter_secure_storage wrapper
│   │   │   └── theme/
│   │   │       └── app_theme.dart    # Modern typography & card styling
│   │   ├── models/
│   │   │   └── user_model.dart       # User data model
│   │   ├── services/
│   │   │   └── api_service.dart      # HTTP API communication
│   │   ├── providers/
│   │   │   └── auth_provider.dart    # Auth state management
│   │   ├── features/
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart # Auto session check & routing
│   │   │   ├── role_selection/
│   │   │   │   └── role_selection_screen.dart # 2-role landing page
│   │   │   ├── auth/
│   │   │   │   ├── civilian_auth/    # Civilian Login & Signup
│   │   │   │   └── police_auth/      # Police Login & Signup
│   │   │   ├── civilian/             # Civilian 3-tab Dashboard (IndexedStack)
│   │   │   │   ├── home/
│   │   │   │   ├── journeys/
│   │   │   │   ├── profile/
│   │   │   │   └── civilian_main_screen.dart
│   │   │   └── police/               # Police 4-tab Dashboard (IndexedStack)
│   │   │       ├── home/
│   │   │       ├── assignments/
│   │   │       ├── journeys/
│   │   │       ├── profile/
│   │   │       └── police_main_screen.dart
│   │   └── main.dart
│   └── pubspec.yaml
│
└── README.md
```

---

## 🔒 Strict Role Separation Mechanism

1. **Database Level**:
   - Compound unique index: `{ "phone": 1, "role": 1 }`
   - MongoDB documents strictly store `"role": "civilian"` or `"role": "police"`.
2. **Backend Query Level**:
   - `POST /auth/civilian/login` queries MongoDB exclusively for `{ "phone": phone, "role": "civilian" }`.
   - `POST /auth/police/login` queries MongoDB exclusively for `{ "phone": phone, "role": "police" }`.
   - If a civilian account attempts to log in on the police endpoint, MongoDB returns `null` and the endpoint returns a generic 401 `Invalid phone number or password` (no account enumeration).
3. **JWT Token Claims**:
   - JWT tokens include the verified `role` claim along with `sub` (User ID) and `district`.
4. **Frontend Navigation Guard**:
   - Civilian session can only access Civilian tabs (`Home`, `Journeys`, `Profile`).
   - Police session can only access Police tabs (`Home`, `Assignments`, `Journeys`, `Profile`).
   - Log out destroys the local JWT from `flutter_secure_storage` and resets to the Role Selection screen.

---

## ⚙️ Quickstart Guide

### 1. Backend Setup

```bash
cd backend

# 1. Install dependencies
pip install -r requirements.txt

# 2. Configure environment
cp .env.example .env

# 3. Start FastAPI server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# (Or double-click backend/run.bat)
```
API Documentation will be available at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

### 2. Frontend Setup (Flutter)

```bash
cd frontend

# 1. Get dependencies
flutter pub get

# 2. Run in Browser (Chrome - Instant, no extra permissions needed):
flutter run -d chrome
# (Or double-click frontend/run_web.bat)

# 3. Alternatively, to run as Windows Desktop app:
# First enable Windows Developer Mode: Run 'start ms-settings:developers' and turn ON Developer Mode.
flutter run -d windows
```

---

## 🧪 Testing Role Isolation

Run automated pytest backend tests:

```bash
cd backend
python -m pytest tests/ -v
```

All 6 core tests verify:
- Civilian signup and login
- Police signup and login
- Cross-role rejection (Civilian -> Police portal fails; Police -> Civilian portal fails)
- Duplicate phone prevention within role
- Maharashtra district restriction validation
- Authenticated `/auth/me` and `/auth/logout` flows

---

## 👥 Instructions for Teammates

This repository provides the modular skeleton. To build out future feature screens:
1. **Civilian Features**:
   - Edit [civilian_home_screen.dart](file:///c:/Users/Rohan/OneDrive/Desktop/D.H.A.A.L/frontend/lib/features/civilian/home/civilian_home_screen.dart) for SOS / Quick Status widgets.
   - Edit [civilian_journeys_screen.dart](file:///c:/Users/Rohan/OneDrive/Desktop/D.H.A.A.L/frontend/lib/features/civilian/journeys/civilian_journeys_screen.dart) for Safe Journeys / GPS Tracking.
2. **Police Features**:
   - Edit [police_home_screen.dart](file:///c:/Users/Rohan/OneDrive/Desktop/D.H.A.A.L/frontend/lib/features/police/home/police_home_screen.dart) for Risk Hotspots / Live Dispatches.
   - Edit [police_assignments_screen.dart](file:///c:/Users/Rohan/OneDrive/Desktop/D.H.A.A.L/frontend/lib/features/police/assignments/police_assignments_screen.dart) for Shift Incident queue.
   - Edit [police_journeys_screen.dart](file:///c:/Users/Rohan/OneDrive/Desktop/D.H.A.A.L/frontend/lib/features/police/journeys/police_journeys_screen.dart) for Escort & Patrol routes.
3. **Gemini AI**:
   - Use `gemini_service.py` in `backend/app/services/gemini_service.py` with your `GEMINI_API_KEY`.
