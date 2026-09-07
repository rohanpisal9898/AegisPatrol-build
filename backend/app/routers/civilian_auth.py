from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.schemas.auth import SignupRequest, LoginRequest, SignupResponse, LoginResponse, ErrorResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth/civilian", tags=["Civilian Authentication"])

@router.post(
    "/signup",
    response_model=SignupResponse,
    responses={400: {"model": ErrorResponse}}
)
async def civilian_signup(
    request: SignupRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Register a new civilian user.
    Enforces role='civilian' and Maharashtra district validation.
    """
    return await AuthService.signup(db=db, request=request, role="civilian")

@router.post(
    "/login",
    response_model=LoginResponse,
    responses={401: {"model": ErrorResponse}}
)
async def civilian_login(
    request: LoginRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Authenticate a civilian user.
    Strictly accepts only credentials registered under the 'civilian' role.
    """
    return await AuthService.login(db=db, request=request, expected_role="civilian")
