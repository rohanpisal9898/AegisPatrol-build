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
        civilian_name = "Civilian User"
        civilian_phone = None
        civilian_district = None

        try:
            user = await db["users"].find_one({"_id": ObjectId(user_id)})
            if user:
                civilian_name = user.get("name", "Civilian User")
                civilian_phone = user.get("phone")
                civilian_district = user.get("district")
                if not target_district:
                    target_district = civilian_district
        except Exception:
            pass

        if not target_district and request.journey_id:
            try:
                journey = await db["journeys"].find_one({"_id": ObjectId(request.journey_id)})
                if journey:
                    target_district = journey.get("destination_name") or journey.get("start_location_name")
            except Exception:
                pass

        location_name = target_district or f"Near {round(request.lat, 4)}, {round(request.lon, 4)}"

        doc = {
            "user_id": user_id,
            "civilian_name": civilian_name,
            "civilian_phone": civilian_phone,
            "civilian_district": civilian_district,
            "location_name": location_name,
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
        logger.info("Alert %s created for user %s (name=%s, phone=%s, type=%s, district=%s). Dispatched notification to police.",
                    alert_id, user_id, civilian_name, civilian_phone, request.alert_type.value, target_district)

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
            civilian_name=civilian_name,
            civilian_phone=civilian_phone,
            civilian_district=civilian_district,
            location_name=location_name,
            journey_id=request.journey_id,
            district=target_district,
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
            # Allow either user or police officer to resolve
            update_res = await collection.update_one(
                {"_id": ObjectId(alert_id)},
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

    @classmethod
    async def update_alert_location(
        cls,
        db: AsyncIOMotorDatabase,
        alert_id: str,
        user_id: str,
        lat: float,
        lon: float,
        h3_cell: Optional[str] = None
    ) -> Dict[str, Any]:
        """Updates continuous GPS coordinates for an alert. Returns tracking state."""
        collection = db["alerts"]
        now = datetime.now(timezone.utc)
        try:
            doc = await collection.find_one({"_id": ObjectId(alert_id)})
            if not doc:
                return {"success": False, "status": "not_found", "is_tracking_active": False}
            
            status = doc.get("status", AlertStatus.ACTIVE.value)
            if status == AlertStatus.RESOLVED.value:
                return {
                    "success": True,
                    "status": "resolved",
                    "is_tracking_active": False,
                    "resolved_at": doc.get("resolved_at")
                }
            
            await collection.update_one(
                {"_id": ObjectId(alert_id)},
                {"$set": {
                    "lat": lat,
                    "lon": lon,
                    "h3_cell": h3_cell,
                    "updated_at": now
                }}
            )
            return {
                "success": True,
                "status": "active",
                "is_tracking_active": True,
                "lat": lat,
                "lon": lon
            }
        except Exception as e:
            logger.error("Error updating location for alert %s: %s", alert_id, e)
            return {"success": False, "status": "error", "is_tracking_active": False}

    @classmethod
    async def get_alert(
        cls,
        db: AsyncIOMotorDatabase,
        alert_id: str
    ) -> Optional[AlertResponse]:
        """Fetch a single alert with enriched civilian user details."""
        collection = db["alerts"]
        users_col = db["users"]
        try:
            doc = await collection.find_one({"_id": ObjectId(alert_id)})
            if not doc:
                return None
            user_id = doc.get("user_id", "")
            civ_name = doc.get("civilian_name")
            civ_phone = doc.get("civilian_phone")
            civ_district = doc.get("civilian_district")

            if (not civ_name or not civ_phone) and user_id:
                try:
                    u = await users_col.find_one({"_id": ObjectId(user_id)})
                    if u:
                        civ_name = civ_name or u.get("name")
                        civ_phone = civ_phone or u.get("phone")
                        civ_district = civ_district or u.get("district")
                except Exception:
                    pass

            loc_name = doc.get("location_name") or doc.get("district") or f"Near {round(doc.get('lat', 0.0), 4)}, {round(doc.get('lon', 0.0), 4)}"

            return AlertResponse(
                id=str(doc["_id"]),
                user_id=user_id,
                civilian_name=civ_name or "Civilian User",
                civilian_phone=civ_phone,
                civilian_district=civ_district,
                location_name=loc_name,
                journey_id=doc.get("journey_id"),
                district=doc.get("district"),
                alert_type=doc.get("alert_type"),
                status=doc.get("status"),
                lat=doc.get("lat", 0.0),
                lon=doc.get("lon", 0.0),
                h3_cell=doc.get("h3_cell"),
                risk_score=doc.get("risk_score"),
                message=doc.get("message"),
                created_at=doc.get("created_at"),
                resolved_at=doc.get("resolved_at")
            )
        except Exception as e:
            logger.error("Error retrieving alert %s: %s", alert_id, e)
            return None

    @classmethod
    async def list_alerts(
        cls,
        db: AsyncIOMotorDatabase,
        limit: int = 50
    ) -> List[AlertResponse]:
        """Fetch latest alerts from the alerts collection with full civilian user details."""
        collection = db["alerts"]
        users_col = db["users"]
        cursor = collection.find({}).sort("created_at", -1).limit(limit)
        docs = await cursor.to_list(length=limit)
        results = []
        user_cache: Dict[str, Dict[str, Any]] = {}

        for doc in docs:
            user_id = doc.get("user_id", "")
            civ_name = doc.get("civilian_name")
            civ_phone = doc.get("civilian_phone")
            civ_district = doc.get("civilian_district")

            if (not civ_name or not civ_phone) and user_id:
                if user_id not in user_cache:
                    try:
                        u = await users_col.find_one({"_id": ObjectId(user_id)})
                        if u:
                            user_cache[user_id] = {
                                "name": u.get("name", "Civilian User"),
                                "phone": u.get("phone"),
                                "district": u.get("district")
                            }
                        else:
                            user_cache[user_id] = {}
                    except Exception:
                        user_cache[user_id] = {}
                cached = user_cache.get(user_id, {})
                civ_name = civ_name or cached.get("name", "Civilian User")
                civ_phone = civ_phone or cached.get("phone")
                civ_district = civ_district or cached.get("district")

            loc_name = doc.get("location_name") or doc.get("district") or f"Near {round(doc.get('lat', 0.0), 4)}, {round(doc.get('lon', 0.0), 4)}"

            results.append(
                AlertResponse(
                    id=str(doc["_id"]),
                    user_id=user_id,
                    civilian_name=civ_name or "Civilian User",
                    civilian_phone=civ_phone,
                    civilian_district=civ_district,
                    location_name=loc_name,
                    journey_id=doc.get("journey_id"),
                    district=doc.get("district"),
                    alert_type=doc.get("alert_type"),
                    status=doc.get("status"),
                    lat=doc.get("lat", 0.0),
                    lon=doc.get("lon", 0.0),
                    h3_cell=doc.get("h3_cell"),
                    risk_score=doc.get("risk_score"),
                    message=doc.get("message"),
                    created_at=doc.get("created_at"),
                    resolved_at=doc.get("resolved_at")
                )
            )
        return results

alert_service = AlertService()

