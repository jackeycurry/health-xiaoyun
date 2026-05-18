from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from database import get_db
from schemas.health_record import (
    HealthRecordCreate,
    HealthRecordResponse,
    HealthRecordType,
    LatestRecordsResponse
)
from services.health_service import HealthService
from utils.deps import get_current_user
from models.user import User

router = APIRouter()


@router.post("/records", response_model=HealthRecordResponse)
def create_record(
    data: HealthRecordCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = HealthService(db)
    return service.create_record(current_user.id, data)


@router.get("/records", response_model=list[HealthRecordResponse])
def get_records(
    record_type: Optional[HealthRecordType] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = HealthService(db)
    return service.get_records(current_user.id, record_type, limit, offset)


@router.get("/records/latest", response_model=LatestRecordsResponse)
def get_latest_records(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = HealthService(db)
    return service.get_latest_records(current_user.id)


@router.delete("/records/{record_id}")
def delete_record(
    record_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = HealthService(db)
    deleted = service.delete_record(current_user.id, record_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="记录不存在")
    return {"message": "删除成功"}