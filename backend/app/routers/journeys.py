import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.routers.users import get_current_user_dependency
from app.schemas.user import UserResponse
from app.models.journey import (
    StartJourneyRequest,
    LocationUpdateRequest,
    JourneyResponse,
    RiskEvaluationResponse,
    EndJourneyResponse
)
from app.services.journey_service import journey_service

logger = logging.getLogger("aegispatrol.routers.journeys")

from app.services.routing_service import routing_service

router = APIRouter(prefix="/journeys", tags=["Civilian Journeys"])

async def require_civilian(
    current_user: UserResponse = Depends(get_current_user_dependency)
) -> UserResponse:
    # Allow any authenticated user (civilian or police) to use journey safety features
    return current_user


@router.get("/active", response_model=Optional[JourneyResponse])
async def get_active_journey(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(require_civilian)
):
    """
    Get the current active/ongoing safe journey for the authenticated civilian.
    Automatically checks for and processes journey duration expiration.
    Returns null if no active journey exists.
    """
    return await journey_service.get_active_user_journey(
        db=db,
        user_id=current_user.id
    )

@router.get("/places/search")
async def search_places(
    q: str,
    lat: Optional[float] = None,
    lon: Optional[float] = None,
):
    """
    Search places and destinations with proximity biasing.
    """
    return await routing_service.search_places(query=q, lat=lat, lon=lon)

@router.post("/start", response_model=JourneyResponse)
async def start_journey(
    request: StartJourneyRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(require_civilian)
):
    """
    Start a new safe civilian journey.
    """
    return await journey_service.start_journey(
        db=db,
        user_id=current_user.id,
        request=request
    )

@router.post("/{journey_id}/location", response_model=RiskEvaluationResponse)
async def update_journey_location(
    journey_id: str,
    request: LocationUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(require_civilian)
):
    """
    Update civilian GPS location during an active journey and evaluate mock risk.
    """
    eval_res = await journey_service.update_location(
        db=db,
        user_id=current_user.id,
        journey_id=journey_id,
        request=request
    )
    if not eval_res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journey not found or does not belong to the authenticated civilian"
        )
    return eval_res

@router.post("/{journey_id}/end", response_model=EndJourneyResponse)
async def end_journey(
    journey_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(require_civilian)
):
    """
    Complete an active safe journey and record summary in MongoDB.
    """
    end_res = await journey_service.end_journey(
        db=db,
        user_id=current_user.id,
        journey_id=journey_id
    )
    if not end_res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journey not found or does not belong to the authenticated civilian"
        )
    return end_res

@router.get("/{journey_id}", response_model=JourneyResponse)
async def get_journey(
    journey_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(require_civilian)
):
    """
    Get a single journey by ID for the authenticated civilian.
    """
    journey = await journey_service.get_journey(
        db=db,
        user_id=current_user.id,
        journey_id=journey_id
    )
    if not journey:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journey not found or does not belong to the authenticated civilian"
        )
    return journey

@router.get("", response_model=List[JourneyResponse])
async def list_journeys(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(require_civilian)
):
    """
    Get journey history for the authenticated civilian (isolated per user).
    """
    return await journey_service.list_user_journeys(
        db=db,
        user_id=current_user.id
    )
