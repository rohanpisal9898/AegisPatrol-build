import pytest
from httpx import AsyncClient, ASGITransport
from mongomock_motor import AsyncMongoMockClient
from app.main import app
from app.db.mongodb import get_database, db_instance
from app.core.security import create_access_token

# Fixture to mock MongoDB for tests
@pytest.fixture(autouse=True)
def mock_db():
    mock_client = AsyncMongoMockClient()
    db_instance.client = mock_client
    db_instance.db = mock_client["test_dhaal"]
    
    app.dependency_overrides[get_database] = lambda: db_instance.db
    yield db_instance.db
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_civilian_signup_and_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Signup Civilian
        signup_payload = {
            "name": "Jane Citizen",
            "phone": "9876543210",
            "password": "strongPassword123",
            "district": "Mumbai City"
        }
        res = await ac.post("/auth/civilian/signup", json=signup_payload)
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert data["user"]["role"] == "civilian"
        assert data["user"]["district"] == "Mumbai City"
        assert data["user"]["name"] == "Jane Citizen"

        # 2. Login Civilian
        login_payload = {
            "phone": "9876543210",
            "password": "strongPassword123"
        }
        login_res = await ac.post("/auth/civilian/login", json=login_payload)
        assert login_res.status_code == 200
        login_data = login_res.json()
        assert login_data["success"] is True
        assert "access_token" in login_data
        assert login_data["user"]["role"] == "civilian"

@pytest.mark.asyncio
async def test_police_signup_and_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Signup Police
        signup_payload = {
            "name": "Officer Vikram",
            "phone": "9123456780",
            "password": "officerPassword456",
            "district": "Pune"
        }
        res = await ac.post("/auth/police/signup", json=signup_payload)
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert data["user"]["role"] == "police"
        assert data["user"]["district"] == "Pune"

        # 2. Login Police
        login_payload = {
            "phone": "9123456780",
            "password": "officerPassword456"
        }
        login_res = await ac.post("/auth/police/login", json=login_payload)
        assert login_res.status_code == 200
        login_data = login_res.json()
        assert login_data["success"] is True
        assert login_data["user"]["role"] == "police"

@pytest.mark.asyncio
async def test_strict_role_separation_cross_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Create Civilian
        await ac.post("/auth/civilian/signup", json={
            "name": "Civilian User",
            "phone": "9000000001",
            "password": "password123",
            "district": "Nagpur"
        })

        # Create Police
        await ac.post("/auth/police/signup", json={
            "name": "Police Officer",
            "phone": "9000000002",
            "password": "password123",
            "district": "Thane"
        })

        # TEST 5: Civilian credentials attempted on Police login -> MUST FAIL
        cross_res_1 = await ac.post("/auth/police/login", json={
            "phone": "9000000001",
            "password": "password123"
        })
        assert cross_res_1.status_code == 401
        assert cross_res_1.json()["success"] is False

        # TEST 6: Police credentials attempted on Civilian login -> MUST FAIL
        cross_res_2 = await ac.post("/auth/civilian/login", json={
            "phone": "9000000002",
            "password": "password123"
        })
        assert cross_res_2.status_code == 401
        assert cross_res_2.json()["success"] is False

@pytest.mark.asyncio
async def test_duplicate_signup_prevention():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        payload = {
            "name": "First Register",
            "phone": "9555555555",
            "password": "mypassword123",
            "district": "Nashik"
        }
        res1 = await ac.post("/auth/civilian/signup", json=payload)
        assert res1.status_code == 200

        # Duplicate signup for civilian role
        res2 = await ac.post("/auth/civilian/signup", json=payload)
        assert res2.status_code == 400
        assert res2.json()["success"] is False

@pytest.mark.asyncio
async def test_invalid_district_validation():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post("/auth/civilian/signup", json={
            "name": "Invalid District User",
            "phone": "9444444444",
            "password": "validPassword123",
            "district": "New York"  # Not a Maharashtra district
        })
        assert res.status_code == 422
        assert res.json()["success"] is False

@pytest.mark.asyncio
async def test_me_and_logout_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        signup_res = await ac.post("/auth/civilian/signup", json={
            "name": "Auth Me Test",
            "phone": "9333333333",
            "password": "passme12345",
            "district": "Kolhapur"
        })
        user_id = signup_res.json()["user"]["id"]
        
        login_res = await ac.post("/auth/civilian/login", json={
            "phone": "9333333333",
            "password": "passme12345"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # GET /auth/me
        me_res = await ac.get("/auth/me", headers=headers)
        assert me_res.status_code == 200
        assert me_res.json()["user"]["name"] == "Auth Me Test"
        assert me_res.json()["user"]["role"] == "civilian"

        # POST /auth/logout
        logout_res = await ac.post("/auth/logout", headers=headers)
        assert logout_res.status_code == 200
        assert logout_res.json()["success"] is True
