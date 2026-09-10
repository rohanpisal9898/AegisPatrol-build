from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.journey import JourneyStatus, RiskLevel, TravelMode, GeoLocation, RouteData

class PoliceJourneyCardResponse(BaseModel):
    journey_id: str
    civilian_id: str  # Short ID formatted like "#2481"
    civilian_name: str
    travel_mode: TravelMode = TravelMode.WALK
    start_location_name: Optional[str] = "Current Location"
    destination_name: Optional[str] = "Destination"
    start_location: Optional[GeoLocation] = None
    current_location: Optional[GeoLocation] = None
    destination: Optional[GeoLocation] = None
    route: Optional[RouteData] = None
    status: JourneyStatus = JourneyStatus.ACTIVE
    risk_level: RiskLevel = RiskLevel.NORMAL
    risk_score: float = 3.2
    started_at: Optional[datetime] = None
    elapsed_minutes: int = 0
    expected_duration_minutes: int = 60
    message: Optional[str] = None
    district: Optional[str] = None
