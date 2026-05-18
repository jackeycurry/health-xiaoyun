from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from uuid import UUID

from database import get_db, SessionLocal
from models.user import User
from models.memory import UserProfile as UserProfileModel, Memory
from utils.deps import get_current_user

router = APIRouter()


class ProfileResponse(BaseModel):
    gender: Optional[str] = None
    age: Optional[int] = None
    height: Optional[int] = None
    weight: Optional[int] = None
    health_summary: Optional[str] = None
    risk_tags: Optional[List[str]] = None


class ProfileUpdateRequest(BaseModel):
    gender: Optional[str] = None
    age: Optional[int] = None
    height: Optional[int] = None
    weight: Optional[int] = None


class MemoryItem(BaseModel):
    id: str
    category: str
    fact: str
    importance: float
    created_at: str


class ProfileFullResponse(BaseModel):
    profile: Optional[ProfileResponse]
    memories: List[MemoryItem]


@router.get("/profile", response_model=ProfileFullResponse)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取用户画像和长期记忆"""
    profile = db.query(UserProfileModel).filter(UserProfileModel.user_id == current_user.id).first()
    memories = (
        db.query(Memory)
        .filter(Memory.user_id == current_user.id)
        .order_by(Memory.importance.desc(), Memory.created_at.desc())
        .limit(20)
        .all()
    )

    profile_data = None
    if profile:
        profile_data = ProfileResponse(
            gender=profile.gender,
            age=profile.age,
            height=profile.height,
            weight=profile.weight,
            health_summary=profile.health_summary,
            risk_tags=profile.risk_tags,
        )

    memory_data = [
        MemoryItem(
            id=str(m.id),
            category=m.category,
            fact=m.fact,
            importance=m.importance,
            created_at=m.created_at.isoformat(),
        )
        for m in memories
    ]

    return ProfileFullResponse(profile=profile_data, memories=memory_data)


@router.put("/profile", response_model=ProfileResponse)
def update_profile(
    request: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """更新用户画像基本信息"""
    profile = db.query(UserProfileModel).filter(UserProfileModel.user_id == current_user.id).first()
    if not profile:
        profile = UserProfileModel(user_id=current_user.id)
        db.add(profile)

    if request.gender is not None:
        profile.gender = request.gender
    if request.age is not None:
        profile.age = request.age
    if request.height is not None:
        profile.height = request.height
    if request.weight is not None:
        profile.weight = request.weight

    db.commit()
    db.refresh(profile)

    return ProfileResponse(
        gender=profile.gender,
        age=profile.age,
        height=profile.height,
        weight=profile.weight,
        health_summary=profile.health_summary,
        risk_tags=profile.risk_tags,
    )


@router.delete("/memories/{memory_id}")
def delete_memory(
    memory_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """删除单条长期记忆"""
    mem = db.query(Memory).filter(
        Memory.id == memory_id,
        Memory.user_id == current_user.id,
    ).first()
    if not mem:
        raise HTTPException(status_code=404, detail="记忆不存在")
    db.delete(mem)
    db.commit()
    return {"ok": True}
