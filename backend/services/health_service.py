from typing import List, Optional, Dict, Any
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import desc
from models.health_record import HealthRecord
from schemas.health_record import HealthRecordCreate, HealthRecordType


class HealthService:
    def __init__(self, db: Session):
        self.db = db

    def create_record(self, user_id: UUID, data: HealthRecordCreate) -> HealthRecord:
        record = HealthRecord(
            user_id=user_id,
            type=data.type.value,
            value=data.value,
            recorded_at=data.recorded_at,
            note=data.note
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record

    def get_records(
        self,
        user_id: UUID,
        record_type: Optional[HealthRecordType] = None,
        limit: int = 20,
        offset: int = 0
    ) -> List[HealthRecord]:
        query = self.db.query(HealthRecord).filter(HealthRecord.user_id == user_id)
        if record_type:
            query = query.filter(HealthRecord.type == record_type.value)
        return query.order_by(desc(HealthRecord.recorded_at)).offset(offset).limit(limit).all()

    def get_latest_records(self, user_id: UUID) -> Dict[str, Optional[Dict[str, Any]]]:
        result = {
            "blood_pressure": None,
            "blood_sugar": None,
            "weight": None,
            "temperature": None,
            "heart_rate": None,
        }

        for record_type in result.keys():
            record = (
                self.db.query(HealthRecord)
                .filter(HealthRecord.user_id == user_id, HealthRecord.type == record_type)
                .order_by(desc(HealthRecord.recorded_at))
                .first()
            )
            if record:
                result[record_type] = {
                    "value": record.value,
                    "recorded_at": record.recorded_at.isoformat(),
                    "id": str(record.id)
                }

        return result

    def delete_record(self, user_id: UUID, record_id: UUID) -> bool:
        record = (
            self.db.query(HealthRecord)
            .filter(HealthRecord.id == record_id, HealthRecord.user_id == user_id)
            .first()
        )
        if record:
            self.db.delete(record)
            self.db.commit()
            return True
        return False