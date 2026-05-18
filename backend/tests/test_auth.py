import pytest


class TestAuth:
    def test_register(self, client):
        response = client.post(
            "/api/auth/register",
            json={"phone": "13800138000", "password": "123456"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["phone"] == "13800138000"
        assert "id" in data

    def test_register_duplicate_phone(self, client):
        client.post("/api/auth/register", json={"phone": "13800138001", "password": "123456"})
        response = client.post(
            "/api/auth/register",
            json={"phone": "13800138001", "password": "123456"}
        )
        assert response.status_code == 400

    def test_login(self, client):
        client.post("/api/auth/register", json={"phone": "13800138002", "password": "123456"})
        response = client.post(
            "/api/auth/login",
            json={"phone": "13800138002", "password": "123456"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    def test_login_wrong_password(self, client):
        client.post("/api/auth/register", json={"phone": "13800138003", "password": "123456"})
        response = client.post(
            "/api/auth/login",
            json={"phone": "13800138003", "password": "wrongpassword"}
        )
        assert response.status_code == 401

    def test_get_me(self, client, auth_token):
        response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {auth_token}"})
        assert response.status_code == 200
        assert response.json()["phone"] == "13900139000"
