from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from typing import Optional


class UserCreate(BaseModel):
    phone: str = Field(..., min_length=11, max_length=20)
    password: str = Field(..., min_length=6)


class UserLogin(BaseModel):
    phone: str
    password: str


class UserResponse(BaseModel):
    id: UUID
    phone: str
    nickname: str
    avatar_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: Optional[str] = None
