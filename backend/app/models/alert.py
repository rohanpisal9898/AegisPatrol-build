from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum

class AlertType(str, Enum):
    SOS = "sos"
    SAFETY_ALERT = "safety_alert"
    UNUSUAL_ACTIVITY = "unusual_activity"
    NEED_HELP = "need_help"

class AlertStatus(str, Enum):
    ACTIVE = "active"
    RESOLVED = "resolved"

class CreateAlertRequest(BaseModel):
    journey_id: Optional[str] = None
    district: Optional[str] = None
    lat: float
    lon: float
    h3_cell: Optional[str] = None
    risk_score: Optional[float] = None
    alert_type: AlertType = AlertType.SAFETY_ALERT
    message: Optional[str] = None

class ResolveAlertRequest(BaseModel):
    journey_id: Optional[str] = None
    note: Optional[str] = "User reported safe"

class AlertResponse(BaseModel):
    id: str
    user_id: str
    journey_id: Optional[str] = None
    district: Optional[str] = None
    alert_type: AlertType
    status: AlertStatus
    lat: float
    lon: float
    h3_cell: Optional[str] = None
    risk_score: Optional[float] = None
    message: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None
