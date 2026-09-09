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

from app.schemas.police import PoliceJourneyCardResponse
from fastapi import HTTPException, status

@router.get("/journeys", response_model=List[PoliceJourneyCardResponse])
async def get_authorized_active_journeys(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Get real active civilian journeys authorized for the logged-in police officer's jurisdiction/district.
    Jurisdiction is strictly derived from the authenticated officer's JWT token context.
    Returns [] (empty list) if no active journeys exist for that jurisdiction.
    """
    if current_user.role != "police":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to police accounts only"
        )
    return await police_service.get_authorized_active_journeys(db=db, police_user=current_user)

@router.get("/journeys/{journey_id}", response_model=PoliceJourneyCardResponse)
async def get_authorized_journey_detail(
    journey_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Get detailed tracking information for a single active journey if authorized by district.
    Enforces server-side jurisdiction check.
    """
    if current_user.role != "police":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to police accounts only"
        )
    journeys = await police_service.get_authorized_active_journeys(db=db, police_user=current_user)
    matching = [j for j in journeys if j.journey_id == journey_id]
    if not matching:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journey not found or not authorized for officer jurisdiction"
        )
    return matching[0]

@router.post("/seed")
async def seed_police_stations(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Development/Setup endpoint to ensure verified police stations are seeded.
    """
    await police_service.seed_police_stations_if_empty(db)
    return {"success": True, "message": "Verified police stations seeded successfully"}
