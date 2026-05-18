import pytest
from unittest.mock import patch, AsyncMock


class TestAIChat:
    @patch("services.ai_service.ai_service.chat", new_callable=AsyncMock)
    def test_chat(self, mock_chat, client, auth_token):
        mock_chat.return_value = {
            "id": "chatcmpl-test",
            "model": "qwen3-omni-flash",
            "choices": [{
                "message": {"role": "assistant", "content": "你好，我是健康小云"},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30}
        }

        response = client.post(
            "/api/consult/chat",
            json={
                "messages": [{"role": "user", "content": "你好"}],
                "stream": False
            },
            headers={"Authorization": f"Bearer {auth_token}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "choices" in data
        assert data["choices"][0]["message"]["content"] == "你好，我是健康小云"

    def test_chat_without_auth(self, client):
        response = client.post(
            "/api/consult/chat",
            json={"messages": [{"role": "user", "content": "你好"}]}
        )
        assert response.status_code == 403  # HTTPBearer returns 403 when no token
