import httpx
import logging
from typing import Optional, Dict, Any, List
from app.models.journey import RouteData, TravelMode

logger = logging.getLogger("aegispatrol.routing")

class PlaceResult:
    def __init__(self, name: str, display_name: str, lat: float, lon: float, city: Optional[str] = None):
        self.name = name
        self.display_name = display_name
        self.lat = lat
        self.lon = lon
        self.city = city

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "display_name": self.display_name,
            "lat": self.lat,
            "lon": self.lon,
            "city": self.city
        }

class RoutingService:
    """
    High-quality Multi-Provider Routing and Geocoding Service.
    Uses OSRM and OSM routing mirrors with automatic failover, and Photon/Nominatim for search.
    """

    ROUTING_ENDPOINTS = [
        "https://router.project-osrm.org/route/v1/driving",
        "https://routing.openstreetmap.de/routed-car/route/v1/driving",
        "https://routing.openstreetmap.de/routed-foot/route/v1/driving",
    ]

    USER_AGENT = "AegisPatrolSafety/1.0 (contact@aegispatrol.safety)"

    @classmethod
    async def get_route(
        cls,
        start_lat: float,
        start_lon: float,
        dest_lat: float,
        dest_lon: float,
        travel_mode: TravelMode = TravelMode.WALK
    ) -> Optional[RouteData]:
        """
        Fetches true road/path routing geometry across multiple OSRM providers.
        """
        headers = {"User-Agent": cls.USER_AGENT, "Accept": "application/json"}
        coord_str = f"{start_lon:.6f},{start_lat:.6f};{dest_lon:.6f},{dest_lat:.6f}"

        for base_url in cls.ROUTING_ENDPOINTS:
            url = f"{base_url}/{coord_str}?overview=full&geometries=geojson&steps=true"
            try:
                async with httpx.AsyncClient(headers=headers, timeout=6.0) as client:
                    response = await client.get(url)
                    if response.status_code == 200:
                        data = response.json()
                        if data.get("code") == "Ok" and data.get("routes"):
                            route_info = data["routes"][0]
                            distance_meters = float(route_info.get("distance", 0.0))
                            duration_seconds = float(route_info.get("duration", 0.0))
                            geometry = route_info.get("geometry", {})
                            coordinates = geometry.get("coordinates", [])

                            distance_km = round(distance_meters / 1000.0, 2)
                            
                            # If walking mode, estimate walking duration (~4.5 km/h = 75 m/min)
                            if travel_mode == TravelMode.WALK:
                                duration_minutes = round(distance_meters / 75.0, 1)
                            else:
                                duration_minutes = round(duration_seconds / 60.0, 1)

                            # Ensure at least 1 min
                            if duration_minutes < 1.0:
                                duration_minutes = 1.0

                            logger.info("Successfully fetched route from %s: %s km, %s min, %s points",
                                        base_url, distance_km, duration_minutes, len(coordinates))

                            return RouteData(
                                distance_km=distance_km,
                                duration_minutes=duration_minutes,
                                coordinates=coordinates
                            )
            except Exception as e:
                logger.warning("Routing request failed on %s: %s", base_url, e)
                continue

        logger.error("All routing endpoints failed for coords (%s, %s) -> (%s, %s)",
                     start_lat, start_lon, dest_lat, dest_lon)
        return None

    @classmethod
    async def search_places(
        cls,
        query: str,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Searches places and addresses with proximity biasing using Photon & Nominatim.
        """
        clean_query = query.strip()
        if not clean_query or len(clean_query) < 2:
            return []

        headers = {"User-Agent": cls.USER_AGENT, "Accept": "application/json"}
        results: List[Dict[str, Any]] = []

        # 1. Primary: Photon (Komoot)
        try:
            params: Dict[str, Any] = {"q": clean_query, "limit": limit}
            if lat is not None and lon is not None:
                params["lat"] = f"{lat:.4f}"
                params["lon"] = f"{lon:.4f}"

            async with httpx.AsyncClient(headers=headers, timeout=5.0) as client:
                res = await client.get("https://photon.komoot.io/api/", params=params)
                if res.status_code == 200:
                    data = res.json()
                    for feat in data.get("features", []):
                        props = feat.get("properties", {})
                        coords = feat.get("geometry", {}).get("coordinates", [])
                        if len(coords) >= 2:
                            name = props.get("name", clean_query)
                            city = props.get("city") or props.get("district") or props.get("state")
                            street = props.get("street")
                            
                            display_parts = [p for p in [name, street, city] if p]
                            display_name = ", ".join(display_parts) if display_parts else name

                            results.append({
                                "name": name,
                                "display_name": display_name,
                                "lat": coords[1],
                                "lon": coords[0],
                                "city": city
                            })
                    if results:
                        return results
        except Exception as e:
            logger.warning("Photon place search failed: %s", e)

        # 2. Fallback: Nominatim OpenStreetMap
        try:
            nom_params: Dict[str, Any] = {
                "q": clean_query,
                "format": "json",
                "limit": limit,
                "addressdetails": 1
            }
            async with httpx.AsyncClient(headers=headers, timeout=5.0) as client:
                res = await client.get("https://nominatim.openstreetmap.org/search", params=nom_params)
                if res.status_code == 200:
                    items = res.json()
                    for item in items:
                        results.append({
                            "name": item.get("name") or item.get("display_name", "").split(",")[0],
                            "display_name": item.get("display_name", clean_query),
                            "lat": float(item.get("lat", 0.0)),
                            "lon": float(item.get("lon", 0.0)),
                            "city": item.get("address", {}).get("city") or item.get("address", {}).get("state")
                        })
        except Exception as e:
            logger.warning("Nominatim fallback search failed: %s", e)

        return results

routing_service = RoutingService()
