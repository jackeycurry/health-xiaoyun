import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.types import Uuid, JSON
from sqlalchemy.orm import relationship
from database import Base


class HealthRecord(Base):
    __tablename__ = "health_records"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String(20), nullable=False, index=True)  # blood_pressure, blood_sugar, weight, temperature, heart_rate
    value = Column(JSON, nullable=False)  # 存储数值，如 {"systolic": 120, "diastolic": 80}
    recorded_at = Column(DateTime, nullable=False)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)