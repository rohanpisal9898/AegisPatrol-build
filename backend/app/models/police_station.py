from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class GeoPoint(BaseModel):
    type: str = "Point"
    coordinates: List[float]  # [longitude, latitude]

class PoliceStationResponse(BaseModel):
    id: str
    name: str
    district: str
    lat: float
    lon: float
    phone: Optional[str] = None
    address: Optional[str] = None
    distance_km: Optional[float] = None
