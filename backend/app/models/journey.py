from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class JourneyStatus(str, Enum):
    NOT_STARTED = "not_started"
    PLANNING = "planning"
    ACTIVE = "active"
    UNUSUAL_ACTIVITY = "unusual_activity"
    SAFETY_ALERT = "safety_alert"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class RiskLevel(str, Enum):
    NORMAL = "normal"
    UNUSUAL = "unusual"
    HIGH = "high"

class TravelMode(str, Enum):
    WALK = "walk"
    AUTO = "auto"
    BUS = "bus"
    CAB = "cab"

class GeoLocation(BaseModel):
    lat: float
    lon: float

class RouteData(BaseModel):
    distance_km: float = 0.0
    duration_minutes: float = 0.0
    coordinates: List[List[float]] = []  # [[lon, lat], [lon, lat], ...]

class StartJourneyRequest(BaseModel):
    travel_mode: TravelMode = TravelMode.WALK
    destination: Optional[GeoLocation] = None
    destination_name: Optional[str] = None
    expected_duration_minutes: int = 30
    current_location: Optional[GeoLocation] = None
    start_location_name: Optional[str] = None

class LocationUpdateRequest(BaseModel):
    lat: float
    lon: float
    step_index: Optional[int] = None

class JourneyResponse(BaseModel):
    journey_id: str
    user_id: str
    status: JourneyStatus
    travel_mode: TravelMode
    start_location: Optional[GeoLocation] = None
    start_location_name: Optional[str] = None
    current_location: Optional[GeoLocation] = None
    destination: Optional[GeoLocation] = None
    destination_name: Optional[str] = None
    route: Optional[RouteData] = None
    distance_km: float = 0.0
    expected_duration_minutes: int = 30
    actual_duration_minutes: Optional[float] = None
    risk_score: float = 0.0
    risk_level: RiskLevel = RiskLevel.NORMAL
    message: Optional[str] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

class RiskEvaluationResponse(BaseModel):
    journey_id: str
    h3_cell: Optional[str] = None
    risk_score: float
    risk_level: RiskLevel
    status: JourneyStatus
    message: str

class EndJourneyResponse(BaseModel):
    status: JourneyStatus = JourneyStatus.COMPLETED
    duration_minutes: float
    distance_km: float
    safe_route: bool
    risk_score_max: float
