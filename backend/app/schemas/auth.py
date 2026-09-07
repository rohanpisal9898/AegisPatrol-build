from pydantic import BaseModel, Field, field_validator
from typing import Optional
from app.schemas.user import UserResponse
from app.core.constants import MAHARASHTRA_DISTRICTS

class SignupRequest(BaseModel):
    name: str = Field(..., min_length=1, description="Full name of the user")
    phone: str = Field(..., description="10-digit Phone number")
    password: str = Field(..., min_length=6, description="Password (at least 6 characters)")
    district: str = Field(..., description="Selected Maharashtra district")

    @field_validator("name")
    def validate_name(cls, v: str) -> str:
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("Name cannot be empty")
        return trimmed

    @field_validator("phone")
    def validate_phone(cls, v: str) -> str:
        cleaned = v.strip().replace(" ", "").replace("-", "")
        if cleaned.startswith("+91"):
            cleaned = cleaned[3:]
        elif len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = cleaned[2:]
        if not cleaned.isdigit() or len(cleaned) != 10:
            raise ValueError("Phone number must be exactly 10 digits")
        return cleaned

    @field_validator("district")
    def validate_district(cls, v: str) -> str:
        trimmed = v.strip()
        if trimmed not in MAHARASHTRA_DISTRICTS:
            raise ValueError("District must be one of the recognized Maharashtra districts.")
        return trimmed

class LoginRequest(BaseModel):
    phone: str = Field(..., description="10-digit Phone number")
    password: str = Field(..., min_length=1, description="Password")

    @field_validator("phone")
    def validate_phone(cls, v: str) -> str:
        cleaned = v.strip().replace(" ", "").replace("-", "")
        if cleaned.startswith("+91"):
            cleaned = cleaned[3:]
        elif len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = cleaned[2:]
        if not cleaned.isdigit() or len(cleaned) != 10:
            raise ValueError("Phone number must be exactly 10 digits")
        return cleaned

class SignupResponse(BaseModel):
    success: bool = True
    message: str = "Account created successfully"
    user: UserResponse

class LoginResponse(BaseModel):
    success: bool = True
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class ErrorResponse(BaseModel):
    success: bool = False
    message: str
