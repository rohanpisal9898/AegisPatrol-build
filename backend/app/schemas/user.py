from pydantic import BaseModel
from typing import Optional

class UserResponse(BaseModel):
    id: str
    name: str
    phone: Optional[str] = None
    role: str
    district: str

class UserProfileResponse(BaseModel):
    success: bool = True
    user: UserResponse
