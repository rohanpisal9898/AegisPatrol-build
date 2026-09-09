import pytest
from httpx import AsyncClient, ASGITransport
from mongomock_motor import AsyncMongoMockClient
from app.main import app
from app.db.mongodb import get_database, db_instance
from app.services.police_service import police_service

from copy import deepcopy
from app.services.police_service import VERIFIED_MUMBAI_POLICE_STATIONS

@pytest.fixture(autouse=True)
def mock_db():
    mock_client = AsyncMongoMockClient()
    db_instance.client = mock_client
    db_instance.db = mock_client["test_dhaal"]
    
    app.dependency_overrides[get_database] = lambda: db_instance.db
    yield db_instance.db
    app.dependency_overrides.clear()

async def get_civilian_token(ac: AsyncClient) -> tuple[str, str]:
    signup_payload = {
        "name": "Ananya Sharma",
        "phone": "9820098200",
        "password": "civilianPassword123",
        "district": "Mumbai Suburban"
    }
    res = await ac.post("/auth/civilian/signup", json=signup_payload)
    login_res = await ac.post("/auth/civilian/login", json={
        "phone": "9820098200",
        "password": "civilianPassword123"
    })
    data = login_res.json()
    return data["access_token"], data["user"]["id"]

async def get_police_token(ac: AsyncClient) -> str:
    signup_payload = {
        "name": "Officer Jadhav",
        "phone": "9820011111",
        "password": "policePassword123",
        "district": "Mumbai Suburban"
    }
    await ac.post("/auth/police/signup", json=signup_payload)
    login_res = await ac.post("/auth/police/login", json={
        "phone": "9820011111",
        "password": "policePassword123"
    })
    return login_res.json()["access_token"]

@pytest.mark.asyncio
async def test_journey_full_lifecycle():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        token, user_id = await get_civilian_token(ac)
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Start Journey
        start_payload = {
            "travel_mode": "walk",
            "current_location": {"lat": 19.0596, "lon": 72.8368},
            "destination": {"lat": 19.1197, "lon": 72.8467},
            "expected_duration_minutes": 30
        }
        start_res = await ac.post("/journeys/start", json=start_payload, headers=headers)
        assert start_res.status_code == 200
        start_data = start_res.json()
        assert start_data["status"] == "active"
        assert start_data["risk_level"] == "normal"
        assert start_data["risk_score"] == 3.2
        journey_id = start_data["journey_id"]
        assert journey_id is not None

        # 2. Update Location - Step 1 (Normal)
        loc_res_1 = await ac.post(
            f"/journeys/{journey_id}/location",
            json={"lat": 19.0650, "lon": 72.8380, "step_index": 1},
            headers=headers
        )
        assert loc_res_1.status_code == 200
        loc_data_1 = loc_res_1.json()
        assert loc_data_1["risk_score"] == 3.8
        assert loc_data_1["risk_level"] == "normal"
        assert loc_data_1["status"] == "active"

        # 3. Update Location - Step 2 (Safety Check-in / Alert)
        loc_res_2 = await ac.post(
            f"/journeys/{journey_id}/location",
            json={"lat": 19.0800, "lon": 72.8400, "step_index": 2},
            headers=headers
        )
        assert loc_res_2.status_code == 200
        loc_data_2 = loc_res_2.json()
        assert loc_data_2["risk_score"] == 7.5
        assert loc_data_2["risk_level"] == "high"
        assert loc_data_2["status"] == "safety_alert"

        # 4. Mark Safe ("I'm Safe")
        safe_res = await ac.post(f"/alerts/journey/{journey_id}/safe", headers=headers)
        assert safe_res.status_code == 200
        assert safe_res.json()["success"] is True

        # 6. End Journey
        end_res = await ac.post(f"/journeys/{journey_id}/end", headers=headers)
        assert end_res.status_code == 200
        end_data = end_res.json()
        assert end_data["status"] == "completed"
        assert "duration_minutes" in end_data
        assert "distance_km" in end_data

        # 7. Get Single Journey
        get_res = await ac.get(f"/journeys/{journey_id}", headers=headers)
        assert get_res.status_code == 200
        assert get_res.json()["status"] == "completed"

        # 8. List User Journeys
        list_res = await ac.get("/journeys", headers=headers)
        assert list_res.status_code == 200
        journeys_list = list_res.json()
        assert len(journeys_list) >= 1
        assert journeys_list[0]["journey_id"] == journey_id

@pytest.mark.asyncio
async def test_police_role_cannot_start_civilian_journey():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        police_token = await get_police_token(ac)
        headers = {"Authorization": f"Bearer {police_token}"}

        start_res = await ac.post("/journeys/start", json={"travel_mode": "walk"}, headers=headers)
        assert start_res.status_code == 403

@pytest.mark.asyncio
async def test_nearby_police_and_sos_alerts():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        token, user_id = await get_civilian_token(ac)
        headers = {"Authorization": f"Bearer {token}"}

        # Seed police stations in mock db
        await police_service.seed_police_stations_if_empty(db_instance.db)

        # Test Nearby Police
        police_res = await ac.get("/police/nearby?lat=19.0596&lon=72.8368&radius_km=10", headers=headers)
        assert police_res.status_code == 200
        stations = police_res.json()
        assert len(stations) > 0
        assert any("Bandra" in st["name"] for st in stations)

        # Test SOS Alert Creation
        alert_res = await ac.post("/alerts", json={
            "lat": 19.0596,
            "lon": 72.8368,
            "alert_type": "sos",
            "message": "SOS triggered by user"
        }, headers=headers)
        assert alert_res.status_code == 200
        alert_data = alert_res.json()
        assert alert_data["alert_type"] == "sos"
        assert alert_data["status"] == "active"
        alert_id = alert_data["id"]

        # Resolve Alert
        resolve_res = await ac.post(f"/alerts/{alert_id}/resolve", json={"note": "False alarm"}, headers=headers)
        assert resolve_res.status_code == 200

@pytest.mark.asyncio
async def test_police_jurisdiction_active_journeys():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Signup & Login Thane Civilian
        await ac.post("/auth/civilian/signup", json={
            "name": "Pooja Patil",
            "phone": "9898989898",
            "password": "password123",
            "district": "Thane"
        })
        civ_login = await ac.post("/auth/civilian/login", json={"phone": "9898989898", "password": "password123"})
        civ_token = civ_login.json()["access_token"]

        # 2. Civilian Starts Journey
        start_res = await ac.post(
            "/journeys/start",
            json={
                "travel_mode": "walk",
                "start_location_name": "Thane West",
                "destination_name": "Mumbai Fort",
                "expected_duration_minutes": 60
            },
            headers={"Authorization": f"Bearer {civ_token}"}
        )
        assert start_res.status_code == 200
        journey_data = start_res.json()
        assert journey_data["status"] == "active"

        # 3. Thane Police Officer Login
        await ac.post("/auth/police/signup", json={
            "name": "Inspector Shinde",
            "phone": "9797979797",
            "password": "password123",
            "district": "Thane"
        })
        thane_police_login = await ac.post("/auth/police/login", json={"phone": "9797979797", "password": "password123"})
        thane_token = thane_police_login.json()["access_token"]

        # 4. Thane Police Fetches Journeys -> Should see Pooia Patil's journey
        thane_res = await ac.get("/police/journeys", headers={"Authorization": f"Bearer {thane_token}"})
        assert thane_res.status_code == 200
        thane_journeys = thane_res.json()
        assert len(thane_journeys) == 1
        assert thane_journeys[0]["civilian_name"] == "Pooja Patil"
        assert thane_journeys[0]["start_location_name"] == "Thane West"

        # 5. Pune Police Officer Login
        await ac.post("/auth/police/signup", json={
            "name": "Inspector Kulkarni",
            "phone": "9696969696",
            "password": "password123",
            "district": "Pune"
        })
        pune_police_login = await ac.post("/auth/police/login", json={"phone": "9696969696", "password": "password123"})
        pune_token = pune_police_login.json()["access_token"]

        # 6. Pune Police Fetches Journeys -> Should see ZERO journeys ([])
        pune_res = await ac.get("/police/journeys", headers={"Authorization": f"Bearer {pune_token}"})
        assert pune_res.status_code == 200
        pune_journeys = pune_res.json()
        assert len(pune_journeys) == 0

