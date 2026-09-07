from datetime import datetime, timezone
from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.core.security import verify_password, get_password_hash, create_access_token, decode_access_token
from app.schemas.auth import SignupRequest, LoginRequest, SignupResponse, LoginResponse
from app.schemas.user import UserResponse

class AuthService:
    @staticmethod
    async def signup(db: AsyncIOMotorDatabase, request: SignupRequest, role: str) -> SignupResponse:
        """
        Creates a new user account strictly tied to the designated role.
        """
        users_col = db["users"]
        
        # Check if an account already exists with the same phone AND role
        existing_user = await users_col.find_one({
            "phone": request.phone,
            "role": role
        })
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"An account with this phone number already exists for {role} role."
            )
        
        # Hash password
        hashed_password = get_password_hash(request.password)
        now = datetime.now(timezone.utc)
        
        user_doc = {
            "name": request.name,
            "phone": request.phone,
            "password_hash": hashed_password,
            "role": role,
            "district": request.district,
            "created_at": now,
            "updated_at": now
        }
        
        insert_result = await users_col.insert_one(user_doc)
        user_id = str(insert_result.inserted_id)
        
        return SignupResponse(
            success=True,
            message="Account created successfully",
            user=UserResponse(
                id=user_id,
                name=request.name,
                phone=request.phone,
                role=role,
                district=request.district
            )
        )

    @staticmethod
    async def login(db: AsyncIOMotorDatabase, request: LoginRequest, expected_role: str) -> LoginResponse:
        """
        Authenticates a user verifying phone, password, and expected role.
        Rejects cross-role attempts with a uniform invalid credentials message.
        """
        users_col = db["users"]
        
        # Query MongoDB explicitly filtering by phone AND expected role
        user = await users_col.find_one({
            "phone": request.phone,
            "role": expected_role
        })
        
        # Generic error message to prevent account enumeration / role leakage
        if not user or not verify_password(request.password, user["password_hash"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid phone number or password"
            )
        
        user_id = str(user["_id"])
        token = create_access_token(
            user_id=user_id,
            role=user["role"],
            district=user["district"]
        )
        
        return LoginResponse(
            success=True,
            access_token=token,
            token_type="bearer",
            user=UserResponse(
                id=user_id,
                name=user["name"],
                phone=user.get("phone"),
                role=user["role"],
                district=user["district"]
            )
        )

    @staticmethod
    async def get_current_user(db: AsyncIOMotorDatabase, token: str) -> UserResponse:
        """
        Validates JWT token and fetches user data.
        """
        payload = decode_access_token(token)
        if not payload or "sub" not in payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired authentication token"
            )
        
        user_id = payload["sub"]
        try:
            obj_id = ObjectId(user_id)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user token format"
            )
        
        users_col = db["users"]
        user = await users_col.find_one({"_id": obj_id})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
            
        return UserResponse(
            id=str(user["_id"]),
            name=user["name"],
            phone=user.get("phone"),
            role=user["role"],
            district=user["district"]
        )
