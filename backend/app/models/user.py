from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field

class UserInDB(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    name: str
    phone: str
    password_hash: str
    role: str  # "civilian" or "police"
    district: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Config:
        populate_by_name = True
