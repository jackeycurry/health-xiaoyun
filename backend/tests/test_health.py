import pytest
from datetime import datetime


class TestHealthRecords:
    def test_create_record(self, client, auth_token):
        response = client.post(
            "/api/health/records",
            json={
                "type": "blood_pressure",
                "value": {"systolic": 120, "diastolic": 80},
                "recorded_at": datetime.now().isoformat()
            },
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["type"] == "blood_pressure"
        assert data["value"] == {"systolic": 120, "diastolic": 80}

    def test_get_records(self, client, auth_token):
        # 先创建记录
        client.post(
            "/api/health/records",
            json={
                "type": "weight",
                "value": {"value": 65.5},
                "recorded_at": datetime.now().isoformat()
            },
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        # 获取记录
        response = client.get(
            "/api/health/records",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        assert len(response.json()) >= 1

    def test_get_latest_records(self, client, auth_token):
        # 创建血压记录
        client.post(
            "/api/health/records",
            json={
                "type": "blood_pressure",
                "value": {"systolic": 120, "diastolic": 80},
                "recorded_at": datetime.now().isoformat()
            },
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        response = client.get(
            "/api/health/records/latest",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["blood_pressure"] is not None
        assert data["blood_pressure"]["value"] == {"systolic": 120, "diastolic": 80}
