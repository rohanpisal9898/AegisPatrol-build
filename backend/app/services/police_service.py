import logging
import math
from typing import List, Dict, Any, Optional
import httpx
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.police_station import PoliceStationResponse

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

police_service = PoliceService()
