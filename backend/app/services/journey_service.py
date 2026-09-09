import logging
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.journey import (
    JourneyStatus,
    RiskLevel,
    TravelMode,
    GeoLocation,
    RouteData,
    StartJourneyRequest,
    LocationUpdateRequest,
    JourneyResponse,
    RiskEvaluationResponse,
    EndJourneyResponse
)
from app.services.mock_risk_service import mock_risk_service
from app.services.routing_service import routing_service

logger = logging.getLogger("aegispatrol.journeys")

class JourneyService:

    @classmethod
    async def auto_expire_journeys(cls, db: AsyncIOMotorDatabase):
        """
        Auto-expires active journeys whose duration has elapsed based on started_at + expected_duration_minutes.
        Transitions status from active/unusual_activity/safety_alert to completed.
        """
        collection = db["journeys"]
        now = datetime.now(timezone.utc)
        active_statuses = [JourneyStatus.ACTIVE.value, JourneyStatus.UNUSUAL_ACTIVITY.value, JourneyStatus.SAFETY_ALERT.value]

        cursor = collection.find({"status": {"$in": active_statuses}})
        docs = await cursor.to_list(length=200)

        for doc in docs:
            started_at = doc.get("started_at")
            if not isinstance(started_at, datetime):
                continue
            if started_at.tzinfo is None:
                started_at = started_at.replace(tzinfo=timezone.utc)

            expected_mins = doc.get("expected_duration_minutes", 60)
            expire_at = started_at + timedelta(minutes=expected_mins)

            if now >= expire_at:
                actual_mins = float(expected_mins)
                await collection.update_one(
                    {"_id": doc["_id"]},
                    {
                        "$set": {
                            "status": JourneyStatus.COMPLETED.value,
                            "actual_duration_minutes": actual_mins,
                            "ended_at": expire_at,
                            "updated_at": now
                        }
                    }
                )
                logger.info("Journey %s auto-expired after %s mins", str(doc["_id"]), expected_mins)

    @classmethod
    async def start_journey(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str,
        request: StartJourneyRequest
    ) -> JourneyResponse:
        collection = db["journeys"]
        now = datetime.now(timezone.utc)

        start_loc = request.current_location
        dest_loc = request.destination
        route_data: Optional[RouteData] = None
        distance_km = 0.0

        # If destination is provided and start location is provided, query OSRM route
        if start_loc and dest_loc:
            route_data = await routing_service.get_route(
                start_lat=start_loc.lat,
                start_lon=start_loc.lon,
                dest_lat=dest_loc.lat,
                dest_lon=dest_loc.lon,
                travel_mode=request.travel_mode
            )
            if route_data:
                distance_km = route_data.distance_km

        if not route_data and start_loc:
            route_data = RouteData(
                distance_km=0.0,
                duration_minutes=float(request.expected_duration_minutes),
                coordinates=[[start_loc.lon, start_loc.lat]]
            )
        elif route_data and start_loc and not route_data.coordinates:
            route_data.coordinates = [[start_loc.lon, start_loc.lat]]

        journey_doc = {
            "user_id": user_id,
            "status": JourneyStatus.ACTIVE.value,
            "travel_mode": request.travel_mode.value,
            "start_location": start_loc.model_dump() if start_loc else None,
            "start_location_name": request.start_location_name,
            "current_location": start_loc.model_dump() if start_loc else None,
            "destination": dest_loc.model_dump() if dest_loc else None,
            "destination_name": request.destination_name,
            "route": route_data.model_dump() if route_data else None,
            "distance_km": distance_km,
            "expected_duration_minutes": request.expected_duration_minutes,
            "actual_duration_minutes": None,
            "risk_score": 3.2,
            "risk_level": RiskLevel.NORMAL.value,
            "risk_score_max": 3.2,
            "started_at": now,
            "ended_at": None,
            "created_at": now,
            "updated_at": now
        }

        result = await collection.insert_one(journey_doc)
        journey_id = str(result.inserted_id)
        logger.info("Journey %s created for user %s with status active", journey_id, user_id)

        return JourneyResponse(
            journey_id=journey_id,
            user_id=user_id,
            status=JourneyStatus.ACTIVE,
            travel_mode=request.travel_mode,
            start_location=start_loc,
            start_location_name=request.start_location_name,
            current_location=start_loc,
            destination=dest_loc,
            destination_name=request.destination_name,
            route=route_data,
            distance_km=distance_km,
            expected_duration_minutes=request.expected_duration_minutes,
            risk_score=3.2,
            risk_level=RiskLevel.NORMAL,
            message="You're on a safe route.",
            started_at=now,
            created_at=now
        )

    @classmethod
    async def update_location(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str,
        journey_id: str,
        request: LocationUpdateRequest
    ) -> Optional[RiskEvaluationResponse]:
        collection = db["journeys"]
        now = datetime.now(timezone.utc)

        # 1. Run auto-expiration check
        await cls.auto_expire_journeys(db)

        # 2. Verify journey belongs to user
        try:
            journey = await collection.find_one({"_id": ObjectId(journey_id), "user_id": user_id})
        except Exception:
            return None

        if not journey or journey.get("status") == JourneyStatus.COMPLETED.value:
            return None

        # 3. Evaluate risk via MockRiskService
        eval_result = await mock_risk_service.evaluate_risk(
            journey_id=journey_id,
            lat=request.lat,
            lon=request.lon,
            step_index=request.step_index
        )

        current_max = journey.get("risk_score_max", 0.0)
        new_max = max(current_max, eval_result.risk_score)

        # 4. Update MongoDB including pushing current location to route.coordinates
        await collection.update_one(
            {"_id": ObjectId(journey_id)},
            {
                "$set": {
                    "current_location": {"lat": request.lat, "lon": request.lon},
                    "risk_score": eval_result.risk_score,
                    "risk_level": eval_result.risk_level.value,
                    "status": eval_result.status.value,
                    "risk_score_max": new_max,
                    "updated_at": now
                },
                "$push": {
                    "route.coordinates": [request.lon, request.lat]
                }
            }
        )

        return RiskEvaluationResponse(
            journey_id=journey_id,
            h3_cell=eval_result.h3_cell,
            risk_score=eval_result.risk_score,
            risk_level=eval_result.risk_level,
            status=eval_result.status,
            message=eval_result.message
        )

    @classmethod
    async def end_journey(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str,
        journey_id: str
    ) -> Optional[EndJourneyResponse]:
        collection = db["journeys"]
        now = datetime.now(timezone.utc)

        try:
            journey = await collection.find_one({"_id": ObjectId(journey_id), "user_id": user_id})
        except Exception:
            return None

        if not journey:
            return None

        started_at = journey.get("started_at", now)
        if isinstance(started_at, datetime):
            if started_at.tzinfo is None:
                started_at = started_at.replace(tzinfo=timezone.utc)
            duration_minutes = round((now - started_at).total_seconds() / 60.0, 1)
        else:
            duration_minutes = float(journey.get("expected_duration_minutes", 30))

        # Ensure duration is at least 1 min for realism
        if duration_minutes < 1.0:
            duration_minutes = 1.0

        distance_km = journey.get("distance_km", 0.0)
        risk_score_max = journey.get("risk_score_max", 3.2)
        safe_route = risk_score_max < 8.0

        await collection.update_one(
            {"_id": ObjectId(journey_id)},
            {
                "$set": {
                    "status": JourneyStatus.COMPLETED.value,
                    "actual_duration_minutes": duration_minutes,
                    "ended_at": now,
                    "updated_at": now
                }
            }
        )

        return EndJourneyResponse(
            status=JourneyStatus.COMPLETED,
            duration_minutes=duration_minutes,
            distance_km=distance_km,
            safe_route=safe_route,
            risk_score_max=risk_score_max
        )

    @classmethod
    async def get_active_user_journey(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str
    ) -> Optional[JourneyResponse]:
        await cls.auto_expire_journeys(db)
        collection = db["journeys"]
        active_statuses = [JourneyStatus.ACTIVE.value, JourneyStatus.UNUSUAL_ACTIVITY.value, JourneyStatus.SAFETY_ALERT.value]
        doc = await collection.find_one({
            "user_id": user_id,
            "status": {"$in": active_statuses}
        })
        if not doc:
            return None
        return cls._doc_to_response(doc)

    @classmethod
    async def get_journey(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str,
        journey_id: str
    ) -> Optional[JourneyResponse]:
        collection = db["journeys"]
        try:
            doc = await collection.find_one({"_id": ObjectId(journey_id), "user_id": user_id})
        except Exception:
            return None

        if not doc:
            return None

        return cls._doc_to_response(doc)

    @classmethod
    async def list_user_journeys(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str
    ) -> List[JourneyResponse]:
        await cls.auto_expire_journeys(db)
        collection = db["journeys"]
        cursor = collection.find({
            "user_id": user_id,
            "status": JourneyStatus.COMPLETED.value
        }).sort([("ended_at", -1), ("created_at", -1)])
        docs = await cursor.to_list(length=100)
        return [cls._doc_to_response(doc) for doc in docs]

    @classmethod
    def _doc_to_response(cls, doc: Dict[str, Any]) -> JourneyResponse:
        route_dict = doc.get("route")
        route_obj = RouteData(**route_dict) if route_dict else None
        
        start_loc = doc.get("start_location")
        start_obj = GeoLocation(**start_loc) if start_loc else None

        current_loc = doc.get("current_location")
        current_obj = GeoLocation(**current_loc) if current_loc else None

        dest_loc = doc.get("destination")
        dest_obj = GeoLocation(**dest_loc) if dest_loc else None

        return JourneyResponse(
            journey_id=str(doc["_id"]),
            user_id=doc["user_id"],
            status=JourneyStatus(doc.get("status", JourneyStatus.COMPLETED.value)),
            travel_mode=TravelMode(doc.get("travel_mode", TravelMode.WALK.value)),
            start_location=start_obj,
            start_location_name=doc.get("start_location_name"),
            current_location=current_obj,
            destination=dest_obj,
            destination_name=doc.get("destination_name"),
            route=route_obj,
            distance_km=doc.get("distance_km", 0.0),
            expected_duration_minutes=doc.get("expected_duration_minutes", 30),
            actual_duration_minutes=doc.get("actual_duration_minutes"),
            risk_score=doc.get("risk_score", 0.0),
            risk_level=RiskLevel(doc.get("risk_level", RiskLevel.NORMAL.value)),
            message=doc.get("message"),
            started_at=doc.get("started_at"),
            ended_at=doc.get("ended_at"),
            created_at=doc.get("created_at")
        )

journey_service = JourneyService()
