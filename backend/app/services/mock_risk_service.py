from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
from app.models.journey import RiskLevel, JourneyStatus

# Configurable prototype risk thresholds
UNUSUAL_THRESHOLD = 6.0
SAFETY_ALERT_THRESHOLD = 8.0

class RiskEvaluation:
    def __init__(
        self,
        risk_score: float,
        risk_level: RiskLevel,
        status: JourneyStatus,
        message: str,
        h3_cell: Optional[str] = None
    ):
        self.risk_score = risk_score
        self.risk_level = risk_level
        self.status = status
        self.message = message
        self.h3_cell = h3_cell

    def to_dict(self) -> Dict[str, Any]:
        return {
            "risk_score": self.risk_score,
            "risk_level": self.risk_level.value,
            "status": self.status.value,
            "message": self.message,
            "h3_cell": self.h3_cell
        }

class RiskServiceInterface(ABC):
    """
    Formal interface for the AegisPatrol Risk Engine.
    
    CURRENT PHASE:
    - Implemented by MockRiskService for the civilian safety prototype.
    
    FUTURE INTEGRATION:
    - Will be implemented by AegisPatrolRiskService using XGBoost, historical
      crime context, lighting telemetry, crowd anomalies, and future YOLO/CCTV signals.
    - Civilian frontend and APIs will remain unchanged.
    """

    @abstractmethod
    async def evaluate_risk(
        self,
        journey_id: str,
        lat: float,
        lon: float,
        step_index: Optional[int] = None,
        h3_cell: Optional[str] = None
    ) -> RiskEvaluation:
        pass


class MockRiskService(RiskServiceInterface):
    """
    Mock risk service used to demonstrate and validate the complete civilian journey flow.
    
    IMPORTANT:
    This service returns simulated risk scores and threshold evaluations for hackathon demos.
    It does NOT run YOLO, CCTV vision, or XGBoost inference.
    """

    def __init__(self):
        # Demo simulation steps for prototype walkthrough
        self._demo_steps = [
            {"score": 3.2, "msg": "You're on a safe route."},
            {"score": 3.8, "msg": "You're on a safe route."},
            {"score": 7.5, "msg": "Safety check: Unexpected pause detected near route."},
            {"score": 3.5, "msg": "You're on a safe route."},
            {"score": 2.8, "msg": "Arrived safely at your destination."},
        ]

    def _determine_level_and_status(self, score: float) -> tuple[RiskLevel, JourneyStatus]:
        if score >= SAFETY_ALERT_THRESHOLD or score >= 7.0:
            return RiskLevel.HIGH, JourneyStatus.SAFETY_ALERT
        else:
            return RiskLevel.NORMAL, JourneyStatus.ACTIVE

    async def evaluate_risk(
        self,
        journey_id: str,
        lat: float,
        lon: float,
        step_index: Optional[int] = None,
        h3_cell: Optional[str] = None
    ) -> RiskEvaluation:
        # If an explicit demo step is passed, use the scenario progression
        if step_index is not None and 0 <= step_index < len(self._demo_steps):
            step_data = self._demo_steps[step_index]
            score = step_data["score"]
            message = step_data["msg"]
        else:
            # Default baseline safe score
            score = 3.2
            message = "You're on a safe route."

        risk_level, status = self._determine_level_and_status(score)

        return RiskEvaluation(
            risk_score=score,
            risk_level=risk_level,
            status=status,
            message=message,
            h3_cell=h3_cell
        )

# Global active risk service instance (injectable for future swapping)
mock_risk_service = MockRiskService()
