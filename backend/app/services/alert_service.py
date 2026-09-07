import logging
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.alert import CreateAlertRequest, ResolveAlertRequest, AlertResponse, AlertStatus, AlertType

logger = logging.getLogger("aegispatrol.alerts")

class AlertService:

    @classmethod
    async def create_alert(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str,
        request: CreateAlertRequest
    ) -> AlertResponse:
        collection = db["alerts"]
        now = datetime.now(timezone.utc)
        
        target_district = request.district
        if not target_district and request.journey_id:
            try:
                journey = await db["journeys"].find_one({"_id": ObjectId(request.journey_id)})
                if journey:
                    target_district = journey.get("destination_name") or journey.get("start_location_name")
            except Exception:
                pass

        if not target_district:
            try:
                user = await db["users"].find_one({"_id": ObjectId(user_id)})
                if user:
                    target_district = user.get("district")
            except Exception:
                pass

        doc = {
            "user_id": user_id,
            "journey_id": request.journey_id,
            "district": target_district,
            "alert_type": request.alert_type.value,
            "status": AlertStatus.ACTIVE.value,
            "lat": request.lat,
            "lon": request.lon,
            "h3_cell": request.h3_cell,
            "risk_score": request.risk_score,
            "message": request.message or f"Alert triggered: {request.alert_type.value}",
            "created_at": now,
            "resolved_at": None
        }

        result = await collection.insert_one(doc)
        alert_id = str(result.inserted_id)
        logger.info("Alert %s created for user %s (type=%s, destination_district=%s). Dispatched notification to police.",
                    alert_id, user_id, request.alert_type.value, target_district)

        # If associated with a journey and it's NEED_HELP or SAFETY_ALERT, update journey status
        if request.journey_id:
            journeys = db["journeys"]
            try:
                await journeys.update_one(
                    {"_id": ObjectId(request.journey_id), "user_id": user_id},
                    {"$set": {"status": "safety_alert", "updated_at": now}}
                )
            except Exception as e:
                logger.warning("Could not update journey status for alert: %s", e)

        return AlertResponse(
            id=alert_id,
            user_id=user_id,
            journey_id=request.journey_id,
            alert_type=request.alert_type,
            status=AlertStatus.ACTIVE,
            lat=request.lat,
            lon=request.lon,
            h3_cell=request.h3_cell,
            risk_score=request.risk_score,
            message=doc["message"],
            created_at=now,
            resolved_at=None
        )

    @classmethod
    async def resolve_alert(
        cls,
        db: AsyncIOMotorDatabase,
        alert_id: str,
        user_id: str,
        request: Optional[ResolveAlertRequest] = None
    ) -> bool:
        collection = db["alerts"]
        now = datetime.now(timezone.utc)
        
        try:
            update_res = await collection.update_one(
                {"_id": ObjectId(alert_id), "user_id": user_id},
                {"$set": {"status": AlertStatus.RESOLVED.value, "resolved_at": now, "resolve_note": request.note if request else "Resolved"}}
            )
            return update_res.modified_count > 0
        except Exception as e:
            logger.error("Error resolving alert %s: %s", alert_id, e)
            return False

    @classmethod
    async def mark_user_safe_for_journey(
        cls,
        db: AsyncIOMotorDatabase,
        user_id: str,
        journey_id: str
    ) -> bool:
        """Resolves active alerts for a journey and resets journey status to active."""
        alerts_col = db["alerts"]
        journeys_col = db["journeys"]
        now = datetime.now(timezone.utc)

        try:
            # Resolve all active alerts for this journey
            await alerts_col.update_many(
                {"journey_id": journey_id, "user_id": user_id, "status": AlertStatus.ACTIVE.value},
                {"$set": {"status": AlertStatus.RESOLVED.value, "resolved_at": now, "resolve_note": "User marked safe"}}
            )
            # Reset journey to active
            await journeys_col.update_one(
                {"_id": ObjectId(journey_id), "user_id": user_id},
                {"$set": {"status": "active", "risk_level": "normal", "risk_score": 3.2, "updated_at": now}}
            )
            return True
        except Exception as e:
            logger.error("Error marking user safe for journey %s: %s", journey_id, e)
            return False

alert_service = AlertService()
