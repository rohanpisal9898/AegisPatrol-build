from fastapi import APIRouter, Depends, Header, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from typing import Optional
from app.db.mongodb import get_database
from app.schemas.user import UserProfileResponse, UserResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["User Profile & Session"])

async def get_current_user_dependency(
    authorization: Optional[str] = Header(None),
    db: AsyncIOMotorDatabase = Depends(get_database)
) -> UserResponse:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header"
        )
    token = authorization.split(" ")[1]
    return await AuthService.get_current_user(db=db, token=token)

@router.get("/me", response_model=UserProfileResponse)
async def get_me(current_user: UserResponse = Depends(get_current_user_dependency)):
    """
    Get profile information for the currently authenticated user.
    """
    return UserProfileResponse(success=True, user=current_user)

@router.post("/logout")
async def logout(current_user: UserResponse = Depends(get_current_user_dependency)):
    """
    Logout endpoint placeholder. Frontend discards the local JWT.
    """
    return {
        "success": True,
        "message": f"User {current_user.name} logged out successfully"
    }
