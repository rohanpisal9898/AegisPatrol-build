# AegisPatrol - Backend API (FastAPI + MongoDB)

A secure, role-isolated backend for the **AegisPatrol** mobile safety platform.

---

## 🌟 Key Architecture & Features

- **Framework**: FastAPI (Python 3.9+) with Uvicorn ASGI server.
- **Database**: MongoDB with Motor asynchronous driver.
- **Strict Role Isolation**:
  - Compound unique index on `{ phone: 1, role: 1 }`.
  - Civilian login `/auth/civilian/login` strictly validates against MongoDB documents with `role="civilian"`.
  - Police login `/auth/police/login` strictly validates against MongoDB documents with `role="police"`.
  - Cross-role login attempts fail with generic 401 unauthorized errors (no account or role leakage).
- **JWT Authentication**: HS256 algorithm containing user ID (`sub`), `role`, `district`, and expiration.
- **Password Hashing**: Secure `bcrypt` algorithm.
- **Maharashtra District Validation**: Enforces one of 36 official Maharashtra districts on registration.
- **AI Integration Placeholder**: `GeminiService` class configured with `GEMINI_API_KEY` for future safety intelligence features.

---

## 🚀 Setup Instructions

### 1. Prerequisites
- Python 3.9 or higher
- MongoDB instance (Local or MongoDB Atlas)

### 2. Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 3. Configure Environment Variables
Create a `.env` file in the `backend/` directory by copying `.env.example`:

```bash
cp .env.example .env
```

Set the configuration values:
```env
MONGO_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/
DATABASE_NAME=dhaal
JWT_SECRET=your_super_secret_jwt_key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
GEMINI_API_KEY=PASTE_YOUR_GEMINI_API_KEY_HERE
```

---

## 🏃 Running the Server

Start the FastAPI development server with auto-reload:

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# Or simply run:
run.bat
```

- **Interactive API Documentation (Swagger)**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **Alternative Redoc Documentation**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## 🧪 Running Automated Tests

Run the full pytest suite:

```bash
python -m pytest tests/ -v
```

### Test Coverage:
1. `test_civilian_signup_and_login` - Verifies civilian registration, district validation, and JWT token issuance.
2. `test_police_signup_and_login` - Verifies police registration and role assignment.
3. `test_strict_role_separation_cross_login` - Tests cross-role isolation (Civilian credentials rejected on police login; Police credentials rejected on civilian login).
4. `test_duplicate_signup_prevention` - Ensures same phone cannot register multiple times under the same role.
5. `test_invalid_district_validation` - Tests rejection of non-Maharashtra districts.
6. `test_me_and_logout_endpoints` - Validates `/auth/me` and `/auth/logout` with Bearer tokens.

---

## 📡 API Endpoints

### Civilian Authentication
- `POST /auth/civilian/signup` - Register a civilian account
- `POST /auth/civilian/login` - Login to civilian account

### Police Authentication
- `POST /auth/police/signup` - Register a police officer account
- `POST /auth/police/login` - Login to police dashboard

### User Session & Profile
- `GET /auth/me` - Get profile for authenticated session (Requires `Authorization: Bearer <token>`)
- `POST /auth/logout` - Invalidate session / server hook
