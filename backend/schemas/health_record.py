from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from typing import Optional, Dict, Any, Literal
from enum import Enum


class HealthRecordType(str, Enum):
    BLOOD_PRESSURE = "blood_pressure"
    BLOOD_SUGAR = "blood_sugar"
    WEIGHT = "weight"
    TEMPERATURE = "temperature"
    HEART_RATE = "heart_rate"


class HealthRecordCreate(BaseModel):
    type: HealthRecordType
    value: Dict[str, Any]  # 如 {"systolic": 120, "diastolic": 80}
    recorded_at: datetime
    note: Optional[str] = None


class HealthRecordResponse(BaseModel):
    id: UUID
    user_id: UUID
    type: str
    value: Dict[str, Any]
    recorded_at: datetime
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class LatestRecordsResponse(BaseModel):
    blood_pressure: Optional[Dict[str, Any]] = None
    blood_sugar: Optional[Dict[str, Any]] = None
    weight: Optional[Dict[str, Any]] = None
    temperature: Optional[Dict[str, Any]] = None
    heart_rate: Optional[Dict[str, Any]] = None