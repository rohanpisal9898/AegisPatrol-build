from datetime import datetime, timezone
import logging
import math
from typing import List, Dict, Any, Optional
import httpx
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.police_station import PoliceStationResponse
from app.schemas.user import UserResponse
from app.schemas.police import PoliceJourneyCardResponse
from app.models.journey import JourneyStatus, RiskLevel, TravelMode, GeoLocation, RouteData

logger = logging.getLogger("aegispatrol.police")

# Verified Police Station data for Mumbai / Mumbai Suburban demo area
VERIFIED_MUMBAI_POLICE_STATIONS = [
    {
        "name": "Bandra Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8368, 19.0596]},
        "phone": "+91 22 2642 2233",
        "address": "Hill Road, Bandra West, Mumbai, Maharashtra 400050",
        "source": "osm_verified"
    },
    {
        "name": "Andheri Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8467, 19.1197]},
        "phone": "+91 22 2683 1583",
        "address": "Old Nagardas Rd, Andheri East, Mumbai, Maharashtra 400069",
        "source": "osm_verified"
    },
    {
        "name": "Juhu Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8277, 19.1026]},
        "phone": "+91 22 2618 3496",
        "address": "VM Road, Juhu Scheme, Vile Parle West, Mumbai 400056",
        "source": "osm_verified"
    },
    {
        "name": "Santacruz Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8396, 19.0831]},
        "phone": "+91 22 2649 1466",
        "address": "SV Road, Santacruz West, Mumbai, Maharashtra 400054",
        "source": "osm_verified"
    },
    {
        "name": "Khar Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8344, 19.0700]},
        "phone": "+91 22 2648 8303",
        "address": "SV Road, Khar West, Mumbai, Maharashtra 400052",
        "source": "osm_verified"
    },
    {
        "name": "Oshiwara Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8306, 19.1482]},
        "phone": "+91 22 2632 2358",
        "address": "Link Road, Oshiwara, Jogeshwari West, Mumbai 400102",
        "source": "osm_verified"
    },
    {
        "name": "Powai Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.9051, 19.1176]},
        "phone": "+91 22 2570 2690",
        "address": "Saki Vihar Rd, Powai, Mumbai, Maharashtra 400076",
        "source": "osm_verified"
    },
    {
        "name": "Kurla Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8797, 19.0688]},
        "phone": "+91 22 2650 0100",
        "address": "S.G. Barve Marg, Kurla West, Mumbai, Maharashtra 400070",
        "source": "osm_verified"
    },
    {
        "name": "Ghatkopar Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.9080, 19.0860]},
        "phone": "+91 22 2511 4984",
        "address": "LBS Marg, Ghatkopar West, Mumbai, Maharashtra 400086",
        "source": "osm_verified"
    },
    {
        "name": "Chembur Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8988, 19.0558]},
        "phone": "+91 22 2522 3474",
        "address": "VN Purav Marg, Chembur, Mumbai, Maharashtra 400071",
        "source": "osm_verified"
    },
    {
        "name": "Malad Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8484, 19.1860]},
        "phone": "+91 22 2882 1475",
        "address": "SV Road, Malad West, Mumbai, Maharashtra 400064",
        "source": "osm_verified"
    },
    {
        "name": "Borivali Police Station",
        "district": "Mumbai Suburban",
        "location": {"type": "Point", "coordinates": [72.8567, 19.2307]},
        "phone": "+91 22 2890 3899",
        "address": "SV Road, Borivali West, Mumbai, Maharashtra 400092",
        "source": "osm_verified"
    },
    {
        "name": "Dadar Police Station",
        "district": "Mumbai City",
        "location": {"type": "Point", "coordinates": [72.8428, 19.0178]},
        "phone": "+91 22 2422 2644",
        "address": "Dadar West, Mumbai, Maharashtra 400028",
        "source": "osm_verified"
    },
    {
        "name": "Colaba Police Station",
        "district": "Mumbai City",
        "location": {"type": "Point", "coordinates": [72.8258, 18.9150]},
        "phone": "+91 22 2285 2885",
        "address": "Shahid Bhagat Singh Rd, Colaba, Mumbai, Maharashtra 400005",
        "source": "osm_verified"
    }
]

def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate Great Circle distance in km between two coordinate points."""
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)

import time

# Cache structure: key -> (timestamp, list of PoliceStationResponse)
_POLICE_CACHE: Dict[str, tuple] = {}
CACHE_TTL_SECONDS = 900  # 15 minutes

OVERPASS_ENDPOINTS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter"
]

def safe_parse_geolocation(raw: Any) -> Optional[GeoLocation]:
    if not isinstance(raw, dict):
        return None
    try:
        lat = float(raw.get("lat", 0.0))
        lon = float(raw.get("lon", 0.0))
        return GeoLocation(lat=lat, lon=lon)
    except Exception:
        return None

def safe_parse_route_data(raw: Any) -> Optional[RouteData]:
    if not isinstance(raw, dict):
        return None
    try:
        dist = float(raw.get("distance_km", 0.0))
        dur = float(raw.get("duration_minutes", 0.0))
        coords = raw.get("coordinates", [])
        clean_coords = []
        if isinstance(coords, list):
            for c in coords:
                if isinstance(c, list) and len(c) >= 2:
                    clean_coords.append([float(c[0]), float(c[1])])
        return RouteData(distance_km=dist, duration_minutes=dur, coordinates=clean_coords)
    except Exception:
        return None

def safe_parse_status(val: Any) -> JourneyStatus:
    if isinstance(val, JourneyStatus):
        return val
    s = str(val).lower() if val else "active"
    for item in JourneyStatus:
        if item.value == s:
            return item
    return JourneyStatus.ACTIVE

def safe_parse_risk_level(val: Any) -> RiskLevel:
    if isinstance(val, RiskLevel):
        return val
    s = str(val).lower() if val else "normal"
    for item in RiskLevel:
        if item.value == s:
            return item
    return RiskLevel.NORMAL

def safe_parse_travel_mode(val: Any) -> TravelMode:
    if isinstance(val, TravelMode):
        return val
    s = str(val).lower() if val else "walk"
    for item in TravelMode:
        if item.value == s:
            return item
    return TravelMode.WALK

class PoliceService:

    @classmethod
    async def seed_police_stations_if_empty(cls, db: AsyncIOMotorDatabase):
        """Preloads verified police station data if the collection is empty."""
        try:
            collection = db["police_stations"]
            count = await collection.count_documents({})
            if count == 0:
                logger.info("Seeding %s verified Mumbai police stations into MongoDB...", len(VERIFIED_MUMBAI_POLICE_STATIONS))
                await collection.insert_many(VERIFIED_MUMBAI_POLICE_STATIONS)
                logger.info("Police stations seeded successfully.")
        except Exception as e:
            logger.error("Error seeding police stations: %s", e)

    @classmethod
    async def get_nearby_stations(
        cls,
        db: AsyncIOMotorDatabase,
        lat: float,
        lon: float,
        radius_km: float = 12.0
    ) -> List[PoliceStationResponse]:
        """
        Dynamically finds genuine nearby police stations using OpenStreetMap Overpass API & Nominatim,
        with in-memory caching, MongoDB auto-persistence, and database fallback.
        """
        cache_key = f"{round(lat, 2)}_{round(lon, 2)}_{radius_km}"
        now = time.time()
        if cache_key in _POLICE_CACHE:
            ts, cached_stations = _POLICE_CACHE[cache_key]
            if now - ts < CACHE_TTL_SECONDS:
                return cached_stations

        live_results: List[PoliceStationResponse] = []
        new_stations_to_persist = []

        # 1. Primary: Dynamic real-time OpenStreetMap Overpass API with multi-endpoint failover
        radius_meters = int(radius_km * 1000.0)
        overpass_query = f"""[out:json][timeout:8];
(
  node["amenity"="police"](around:{radius_meters},{lat},{lon});
  way["amenity"="police"](around:{radius_meters},{lat},{lon});
);
out center 25;"""

        async with httpx.AsyncClient(headers={"User-Agent": "AegisPatrolSafetyApp/1.0"}, timeout=6.0) as client:
            # Try Overpass endpoints
            for endpoint in OVERPASS_ENDPOINTS:
                try:
                    res = await client.post(endpoint, data={"data": overpass_query})
                    if res.status_code == 200:
                        data = res.json()
                        elements = data.get("elements", [])
                        for el in elements:
                            tags = el.get("tags", {})
                            name = tags.get("name") or tags.get("operator") or tags.get("description") or "Police Station"
                            st_lat = el.get("lat") or el.get("center", {}).get("lat")
                            st_lon = el.get("lon") or el.get("center", {}).get("lon")
                            if st_lat and st_lon:
                                dist = haversine_distance_km(lat, lon, st_lat, st_lon)
                                if dist <= radius_km:
                                    phone = tags.get("phone") or tags.get("contact:phone") or tags.get("emergency:phone") or "+91 112"
                                    street = tags.get("addr:street")
                                    city = tags.get("addr:city") or tags.get("addr:district") or tags.get("addr:suburb") or tags.get("addr:state")
                                    addr_parts = [p for p in [tags.get("addr:housename"), street, city] if p]
                                    addr = ", ".join(addr_parts) if addr_parts else tags.get("address") or f"Near {st_lat:.3f}, {st_lon:.3f}"

                                    station_obj = PoliceStationResponse(
                                        id=str(el.get("id")),
                                        name=name,
                                        district=city or "Local District",
                                        lat=st_lat,
                                        lon=st_lon,
                                        phone=phone,
                                        address=addr,
                                        distance_km=dist
                                    )
                                    live_results.append(station_obj)
                                    new_stations_to_persist.append({
                                        "name": name,
                                        "district": city or "Local District",
                                        "location": {"type": "Point", "coordinates": [st_lon, st_lat]},
                                        "phone": phone,
                                        "address": addr,
                                        "source": "osm_dynamic"
                                    })
                        if live_results:
                            break  # Successfully fetched from Overpass
                except Exception as e:
                    logger.debug("Overpass search via %s failed or timed out: %s", endpoint, e)

            # 2. Secondary: Fast Nominatim search fallback if Overpass returned 0 results
            if not live_results:
                try:
                    delta = max(0.12, (radius_km / 111.0) * 1.1)
                    nom_params = {
                        "q": "police station",
                        "format": "jsonv2",
                        "viewbox": f"{lon-delta},{lat+delta},{lon+delta},{lat-delta}",
                        "bounded": 1,
                        "limit": 15,
                        "addressdetails": 1
                    }
                    nom_res = await client.get("https://nominatim.openstreetmap.org/search", params=nom_params, timeout=5.0)
                    if nom_res.status_code == 200:
                        nom_items = nom_res.json()
                        for item in nom_items:
                            try:
                                st_lat = float(item.get("lat", 0))
                                st_lon = float(item.get("lon", 0))
                                if st_lat and st_lon:
                                    dist = haversine_distance_km(lat, lon, st_lat, st_lon)
                                    if dist <= radius_km:
                                        raw_name = item.get("name") or item.get("display_name", "").split(",")[0]
                                        name = raw_name if "police" in raw_name.lower() else f"{raw_name} Police Station"
                                        addr_info = item.get("address", {})
                                        city = addr_info.get("city") or addr_info.get("town") or addr_info.get("county") or addr_info.get("state_district") or "Local District"
                                        disp_addr = item.get("display_name", "")
                                        short_addr = ", ".join(disp_addr.split(",")[:3]) if disp_addr else f"Near {st_lat:.3f}, {st_lon:.3f}"

                                        station_obj = PoliceStationResponse(
                                            id=str(item.get("place_id", f"{st_lat}_{st_lon}")),
                                            name=name,
                                            district=city,
                                            lat=st_lat,
                                            lon=st_lon,
                                            phone="+91 112",
                                            address=short_addr,
                                            distance_km=dist
                                        )
                                        live_results.append(station_obj)
                                        new_stations_to_persist.append({
                                            "name": name,
                                            "district": city,
                                            "location": {"type": "Point", "coordinates": [st_lon, st_lat]},
                                            "phone": "+91 112",
                                            "address": short_addr,
                                            "source": "nominatim_dynamic"
                                        })
                            except Exception as parse_err:
                                logger.debug("Error parsing Nominatim station: %s", parse_err)
                except Exception as nom_err:
                    logger.debug("Nominatim police lookup failed: %s", nom_err)

        # 3. Merge with MongoDB stations that are strictly within radius_km
        collection = db["police_stations"]
        try:
            # Auto-persist newly discovered OSM stations asynchronously in MongoDB
            if new_stations_to_persist:
                for st_doc in new_stations_to_persist[:10]:
                    await collection.update_one(
                        {"name": st_doc["name"]},
                        {"$setOnInsert": st_doc},
                        upsert=True
                    )

            cursor = collection.find({})
            db_stations = await cursor.to_list(length=100)
            seen_names = {s.name.lower() for s in live_results}
            for st in db_stations:
                coords = st.get("location", {}).get("coordinates", [0.0, 0.0])
                st_lon, st_lat = coords[0], coords[1]
                dist = haversine_distance_km(lat, lon, st_lat, st_lon)
                st_name = st.get("name", "Police Station")
                # Strictly check dist <= radius_km so distant stations (e.g. Mumbai when in Kolhapur) are never added
                if dist <= radius_km and st_name.lower() not in seen_names:
                    seen_names.add(st_name.lower())
                    live_results.append(
                        PoliceStationResponse(
                            id=str(st.get("_id")),
                            name=st_name,
                            district=st.get("district", "Police District"),
                            lat=st_lat,
                            lon=st_lon,
                            phone=st.get("phone", "+91 112"),
                            address=st.get("address"),
                            distance_km=dist
                        )
                    )
        except Exception as e:
            logger.warning("Database stations merge failed: %s", e)

        live_results.sort(key=lambda x: x.distance_km if x.distance_km is not None else 9999)
        final_list = live_results[:25]

        # Cache valid results
        if final_list:
            _POLICE_CACHE[cache_key] = (now, final_list)

        return final_list

    @classmethod
    async def get_authorized_active_journeys(
        cls,
        db: AsyncIOMotorDatabase,
        police_user: UserResponse,
        district_filter: Optional[str] = None
    ) -> List[PoliceJourneyCardResponse]:
        """
        Fetches active civilian journeys authorized for police monitoring.
        If district_filter is specified (and not 'all'), filters by that district.
        Populates real civilian name, route coordinates, and district.
        """
        police_district = (police_user.district or "").strip()
        primary_district = police_district.split(",")[0].strip() if police_district else ""

        users_col = db["users"]
        journeys_col = db["journeys"]

        # Auto-expire any journeys whose Share Until duration has passed
        from app.services.journey_service import JourneyService
        await JourneyService.auto_expire_journeys(db)

        # Query MongoDB journeys for all active/monitoring journeys
        active_statuses = ["active", "unusual_activity", "safety_alert"]
        query = {"status": {"$in": active_statuses}}

        cursor = journeys_col.find(query).sort("started_at", -1)
        journey_docs = await cursor.to_list(length=100)

        now = datetime.now(timezone.utc)
        results: List[PoliceJourneyCardResponse] = []
        civilian_user_map: Dict[str, str] = {}
        civilian_district_map: Dict[str, str] = {}

        for doc in journey_docs:
            user_id = doc.get("user_id", "")
            civilian_name = civilian_user_map.get(user_id)
            civilian_district = civilian_district_map.get(user_id)

            # If user_id wasn't in our initial map, query user record directly
            if not civilian_name and user_id:
                try:
                    u_doc = await users_col.find_one({"_id": ObjectId(user_id)})
                    if u_doc:
                        civilian_name = u_doc.get("name", "Civilian User")
                        civilian_district = u_doc.get("district", "")
                        civilian_user_map[user_id] = civilian_name
                        if civilian_district:
                            civilian_district_map[user_id] = civilian_district
                except Exception:
                    pass

            if not civilian_name:
                civilian_name = "Civilian User"

            start_name = doc.get("start_location_name") or "Start Location"
            dest_name = doc.get("destination_name") or "Destination"

            if not civilian_district:
                if "kolhapur" in start_name.lower() or "kolhapur" in dest_name.lower():
                    civilian_district = "Kolhapur"
                elif "thane" in start_name.lower() or "thane" in dest_name.lower():
                    civilian_district = "Thane"
                elif "mumbai city" in start_name.lower() or "dadar" in start_name.lower() or "colaba" in start_name.lower():
                    civilian_district = "Mumbai City"
                else:
                    civilian_district = "Mumbai Suburban"

            # District filter check (explicit filter, or officer's jurisdiction district if None)
            target_filter = district_filter if district_filter is not None else primary_district
            if target_filter and target_filter.lower() != "all":
                d_filter = target_filter.lower().strip()
                if (d_filter not in civilian_district.lower() and
                    d_filter not in start_name.lower() and
                    d_filter not in dest_name.lower()):
                    continue

            started_at = doc.get("started_at")
            if isinstance(started_at, datetime):
                if started_at.tzinfo is None:
                    started_at = started_at.replace(tzinfo=timezone.utc)
                elapsed_minutes = max(0, int((now - started_at).total_seconds() / 60.0))
            else:
                elapsed_minutes = 0

            jid_str = str(doc["_id"])
            short_id = f"#{jid_str[-4:].upper()}"

            start_loc = safe_parse_geolocation(doc.get("start_location"))
            current_loc = safe_parse_geolocation(doc.get("current_location"))
            dest_loc = safe_parse_geolocation(doc.get("destination"))
            route_obj = safe_parse_route_data(doc.get("route"))

            status_val = safe_parse_status(doc.get("status"))
            risk_level_val = safe_parse_risk_level(doc.get("risk_level"))
            travel_mode_val = safe_parse_travel_mode(doc.get("travel_mode"))

            results.append(
                PoliceJourneyCardResponse(
                    journey_id=jid_str,
                    civilian_id=short_id,
                    civilian_name=civilian_name,
                    travel_mode=travel_mode_val,
                    start_location_name=start_name,
                    destination_name=dest_name,
                    start_location=start_loc,
                    current_location=current_loc,
                    destination=dest_loc,
                    route=route_obj,
                    status=status_val,
                    risk_level=risk_level_val,
                    risk_score=float(doc.get("risk_score", 3.2)),
                    started_at=started_at,
                    elapsed_minutes=elapsed_minutes,
                    expected_duration_minutes=int(doc.get("expected_duration_minutes", 60)),
                    message=doc.get("message"),
                    district=civilian_district
                )
            )

        return results

police_service = PoliceService()
