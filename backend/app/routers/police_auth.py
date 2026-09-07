from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.schemas.auth import SignupRequest, LoginRequest, SignupResponse, LoginResponse, ErrorResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth/police", tags=["Police Authentication"])

@router.post(
    "/signup",
    response_model=SignupResponse,
    responses={400: {"model": ErrorResponse}}
)
async def police_signup(
    request: SignupRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Register a new police/patrol officer.
    Enforces role='police' and Maharashtra district validation.
    """
    return await AuthService.signup(db=db, request=request, role="police")

@router.post(
    "/login",
    response_model=LoginResponse,
    responses={401: {"model": ErrorResponse}}
)
async def police_login(
    request: LoginRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Authenticate a police/patrol officer.
    Strictly accepts only credentials registered under the 'police' role.
    """
    return await AuthService.login(db=db, request=request, expected_role="police")
