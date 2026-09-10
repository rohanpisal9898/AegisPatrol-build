import logging
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.routers.users import get_current_user_dependency
from app.schemas.user import UserResponse
from app.models.alert import CreateAlertRequest, ResolveAlertRequest, AlertResponse
from app.services.alert_service import alert_service

logger = logging.getLogger("aegispatrol.routers.alerts")

router = APIRouter(prefix="/alerts", tags=["Safety & SOS Alerts"])

@router.post("", response_model=AlertResponse)
async def create_alert(
    request: CreateAlertRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Create a new safety or SOS emergency alert for the authenticated user.
    """
    return await alert_service.create_alert(
        db=db,
        user_id=current_user.id,
        request=request
    )

@router.post("/{alert_id}/resolve")
async def resolve_alert(
    alert_id: str,
    request: ResolveAlertRequest = None,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Resolve an active alert (e.g. user reports 'I am safe').
    """
    resolved = await alert_service.resolve_alert(
        db=db,
        alert_id=alert_id,
        user_id=current_user.id,
        request=request
    )
    if not resolved:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found or does not belong to authenticated user"
        )
    return {"success": True, "message": "Alert resolved successfully"}

@router.post("/journey/{journey_id}/safe")
async def mark_journey_safe(
    journey_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Mark user safe for an active journey: resolves alerts and resets journey risk status.
    """
    success = await alert_service.mark_user_safe_for_journey(
        db=db,
        user_id=current_user.id,
        journey_id=journey_id
    )
    return {"success": success, "message": "Journey marked safe and returned to active monitoring"}
 
@router.get("", response_model=List[AlertResponse])
async def list_alerts(
    limit: int = 50,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: UserResponse = Depends(get_current_user_dependency)
):
    """
    Get latest safety and SOS emergency alerts from MongoDB.
    """
    return await alert_service.list_alerts(db=db, limit=limit)

