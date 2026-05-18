import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Float, ForeignKey, Integer
from sqlalchemy.types import Uuid, JSON
from database import Base


class UserProfile(Base):
    """用户健康画像 (1:1 User)"""
    __tablename__ = "user_profiles"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    gender = Column(String(10), nullable=True)       # male/female/other
    age = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)           # cm
    weight = Column(Integer, nullable=True)           # kg

    # AI 自动生成的内容
    health_summary = Column(Text, nullable=True)      # AI 生成的整体健康总结
    risk_tags = Column(JSON, nullable=True)           # ["高血压风险", "过敏体质"]

    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Memory(Base):
    """长期记忆 — 从对话中提取的用户事实"""
    __tablename__ = "memories"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid, ForeignKey("users.id"), nullable=False, index=True)
    category = Column(String(20), nullable=False, index=True)   # personal/health/habit/preference/note
    fact = Column(Text, nullable=False)                          # 记忆内容
    importance = Column(Float, default=0.5)                      # 0-1 重要性
    source_conversation_id = Column(Uuid, ForeignKey("conversations.id"), nullable=True)
    access_count = Column(Integer, default=0)                    # 被引用次数
    created_at = Column(DateTime, default=datetime.utcnow)
