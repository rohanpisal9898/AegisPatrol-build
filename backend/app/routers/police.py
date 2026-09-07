import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.routers.users import get_current_user_dependency
from app.schemas.user import UserResponse
from app.models.police_station import PoliceStationResponse
from app.services.police_service import police_service

logger = logging.getLogger("aegispatrol.routers.police")

router = APIRouter(prefix="/police", tags=["Police Stations"])

@router.get("/nearby", response_model=List[PoliceStationResponse])
async def get_nearby_police_stations(
    lat: float = Query(..., description="Latitude of user"),
    lon: float = Query(..., description="Longitude of user"),
    radius_km: float = Query(10.0, description="Search radius in kilometers"),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Find police stations near current GPS coordinates using MongoDB 2dsphere index.
    """
    return await police_service.get_nearby_stations(
        db=db,
        lat=lat,
        lon=lon,
        radius_km=radius_km
    )

@router.post("/seed")
async def seed_police_stations(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Development/Setup endpoint to ensure verified police stations are seeded.
    """
    await police_service.seed_police_stations_if_empty(db)
    return {"success": True, "message": "Verified police stations seeded successfully"}
