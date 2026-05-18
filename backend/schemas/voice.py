from pydantic import BaseModel
from typing import Optional


class VoiceChatRequest(BaseModel):
    audio: str  # base64 编码的音频数据


class VoiceChatResponse(BaseModel):
    text: str
    audio: Optional[str] = None
