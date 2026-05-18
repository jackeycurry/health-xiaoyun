import httpx
import json as json_lib
import base64
import asyncio
import websockets
from typing import List, Dict, Any, AsyncGenerator, Optional
from uuid import UUID
from config import get_settings

settings = get_settings()


class AIService:
    def __init__(self):
        self.api_key = settings.DASHSCOPE_API_KEY
        self.base_url = settings.DASHSCOPE_BASE_URL
        self.model = settings.AI_MODEL
        self.realtime_model = "qwen3.5-omni-plus-realtime"
        self.realtime_url = f"wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model={self.realtime_model}"

    def _build_health_prompt(self, messages: List[Dict[str, Any]], user_id: str = None) -> List[Dict[str, Any]]:
        """构建健康助手提示词，支持多模态图片消息，注入用户画像和长期记忆"""
        instructions = """你是一位专业的AI健康助手，名叫"健康小云"。请根据用户的问题提供健康建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文
6. 如果用户发送了图片，请仔细分析图片内容并结合用户文字描述给出建议
7. 如果系统提供了用户的画像和长期记忆，请结合这些信息给出个性化建议"""

        # 注入用户画像和记忆
        if user_id:
            from services.memory_service import memory_service
            try:
                enriched = memory_service.build_enriched_prompt(UUID(user_id))
                if enriched:
                    instructions += f"\n\n{enriched}"
            except (ValueError, AttributeError):
                pass

        system_prompt = {
            "role": "system",
            "content": instructions
        }
        # 转换消息格式：有图片的转为 multimodal content
        converted = []
        for m in messages:
            role = m.get("role", "user")
            image = m.get("image")
            text = m.get("content", "")
            if image:
                # 多模态格式：content 为数组
                content = [
                    {"type": "text", "text": text or "请看这张图片"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image}"}}
                ]
            else:
                content = text
            converted.append({"role": role, "content": content})
        return [system_prompt] + converted

    async def chat(self, messages: List[Dict[str, str]], user_id: str = None) -> Dict[str, Any]:
        """发送对话请求"""
        prompt_messages = self._build_health_prompt(messages, user_id=user_id)

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": prompt_messages,
                    "max_tokens": 1000,
                    "temperature": 0.7
                }
            )
            response.raise_for_status()
            return response.json()

    async def chat_stream(self, messages: List[Dict[str, str]], user_id: str = None) -> AsyncGenerator[str, None]:
        """流式对话请求"""
        prompt_messages = self._build_health_prompt(messages, user_id=user_id)

        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": prompt_messages,
                    "max_tokens": 1000,
                    "temperature": 0.7,
                    "stream": True
                }
            ) as response:
                line_count = 0
                buffer = ""
                async for raw_chunk in response.aiter_bytes():
                    buffer += raw_chunk.decode("utf-8")
                    while "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                        line = line.strip()
                        if not line.startswith("data: "):
                            continue
                        data = line[6:]
                        if data == "[DONE]":
                            return
                        try:
                            parsed = json_lib.loads(data)
                            content = parsed.get("choices", [{}])[0].get("delta", {}).get("content", "")
                            if content:
                                line_count += 1
                                print(f"[AI_SERVICE] line #{line_count} delta: {content[:50] if len(content) > 50 else content}...")
                                yield content
                        except Exception:
                            pass

    async def voice_chat(self, audio_base64: str) -> Dict[str, Any]:
        """语音对话请求 - 使用 qwen3-omni 处理音频"""
        # 构建语音对话消息
        system_prompt = {
            "role": "system",
            "content": """你是一位专业的AI健康助手，名叫"健康小云"。请根据用户的语音问题提供健康建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂，控制在50字以内
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文"""
        }

        user_message = {
            "role": "user",
            "content": [
                {
                    "type": "audio",
                    "audio_url": f"data:audio/wav;base64,{audio_base64}"
                }
            ]
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": [system_prompt, user_message],
                    "modalities": ["text", "audio"],
                    "audio_format": "wav",
                    "max_tokens": 200,
                    "temperature": 0.7
                }
            )
            response.raise_for_status()
            return response.json()

    async def voice_chat_stream(self, audio_base64: str) -> AsyncGenerator[Dict[str, Any], None]:
        """语音对话流式请求 - 使用 qwen3-omni 处理音频"""
        system_prompt = {
            "role": "system",
            "content": """你是一位专业的AI健康助手，名叫"健康小云"。请根据用户的语音问题提供健康建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂，控制在50字以内
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文"""
        }

        user_message = {
            "role": "user",
            "content": [
                {
                    "type": "audio",
                    "audio_url": f"data:audio/wav;base64,{audio_base64}"
                }
            ]
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": [system_prompt, user_message],
                    "modalities": ["text", "audio"],
                    "audio_format": "wav",
                    "max_tokens": 200,
                    "temperature": 0.7,
                    "stream": True
                }
            ) as response:
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        data = line[6:]
                        if data == "[DONE]":
                            break
                        try:
                            parsed = json_lib.loads(data)
                            # 流式返回包含 delta
                            delta = parsed.get("choices", [{}])[0].get("delta", {})
                            content = delta.get("content", "")
                            audio_data = delta.get("audio", {})
                            yield {
                                "content": content,
                                "audio": audio_data
                            }
                        except Exception as e:
                            print(f"Parse error: {e}")

    async def voice_realtime_chat(self, audio_data: bytes) -> AsyncGenerator[Dict[str, Any], None]:
        """
        语音实时对话 - 使用 WebSocket 和 qwen3.5-omni-plus-realtime 模型
        处理 PCM 音频流输入，返回文本和音频流
        """
        health_instructions = """你是一位专业的AI健康助手，名叫"健康小云"。请根据用户的语音问题提供健康建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂，控制在50字以内
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文"""

        try:
            async with websockets.connect(
                self.realtime_url,
                extra_headers={"Authorization": f"Bearer {self.api_key}"}
            ) as ws:
                # 1. 发送 session.update 配置
                session_config = {
                    "event_id": f"event_{id(ws)}",
                    "type": "session.update",
                    "session": {
                        "modalities": ["text", "audio"],
                        "voice": "akura",  # 使用akura音色
                        "input_audio_format": "pcm",
                        "output_audio_format": "pcm",
                        "instructions": health_instructions,
                        "turn_detection": {
                            "type": "semantic_vad",
                            "threshold": 0.5,
                            "silence_duration_ms": 800
                        }
                    }
                }
                await ws.send(json_lib.dumps(session_config))

                # 2. 接收 session.updated 确认
                resp = await ws.recv()
                print(f"[VOICE] Session config sent, response: {resp[:200] if isinstance(resp, str) else 'binary'}")

                # 3. 发送音频数据
                # 将 PCM 数据转换为 base64 并发送
                audio_base64 = base64.b64encode(audio_data).decode('utf-8')
                audio_message = {
                    "event_id": f"event_{id(ws)}_audio",
                    "type": "input_audio_buffer.append",
                    "audio": audio_base64
                }
                await ws.send(json_lib.dumps(audio_message))

                # 4. 触发模型响应
                commit_message = {
                    "event_id": f"event_{id(ws)}_commit",
                    "type": "input_audio_buffer.commit"
                }
                await ws.send(json_lib.dumps(commit_message))

                # 5. 接收响应流
                while True:
                    try:
                        message = await asyncio.wait_for(ws.recv(), timeout=30.0)
                        if isinstance(message, str):
                            data = json_lib.loads(message)
                            # 处理不同的消息类型
                            msg_type = data.get("type", "")
                            if msg_type == "session.done":
                                break
                            elif msg_type == "response.audio.delta":
                                yield {
                                    "type": "audio",
                                    "data": data.get("audio", ""),
                                    "text": data.get("transcript", "")
                                }
                            elif msg_type == "response.text.delta":
                                yield {
                                    "type": "text",
                                    "data": data.get("text", "")
                                }
                            elif msg_type == "response.done":
                                break
                            elif msg_type.startswith("error"):
                                yield {
                                    "type": "error",
                                    "data": str(data)
                                }
                                break
                        else:
                            # 二进制音频数据
                            yield {
                                "type": "binary",
                                "data": message
                            }
                    except asyncio.TimeoutError:
                        break

        except Exception as e:
            print(f"[VOICE] WebSocket error: {e}")
            yield {"type": "error", "data": str(e)}

    async def voice_realtime_chat_stream(self, websocket) -> AsyncGenerator[Dict[str, Any], None]:
        """
        语音实时对话 - 从 WebSocket 接收音频并返回响应
        """
        import websockets
        health_instructions = """你是一位专业的AI健康助手，名叫"健康小云"。请根据用户的语音问题提供健康建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂，控制在50字以内
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文"""

        try:
            async with websockets.connect(
                self.realtime_url,
                extra_headers={"Authorization": f"Bearer {self.api_key}"}
            ) as ws:
                # 1. 发送 session.update 配置
                session_config = {
                    "event_id": f"event_{id(websocket)}",
                    "type": "session.update",
                    "session": {
                        "modalities": ["text", "audio"],
                        "voice": "akura",
                        "input_audio_format": "pcm",
                        "output_audio_format": "pcm",
                        "instructions": health_instructions,
                        "turn_detection": {
                            "type": "semantic_vad",
                            "threshold": 0.5,
                            "silence_duration_ms": 800
                        }
                    }
                }
                await ws.send(json_lib.dumps(session_config))

                # 2. 接收 session.updated 确认
                resp = await ws.recv()
                print(f"[VOICE] Session config sent, response: {resp[:200] if isinstance(resp, str) else 'binary'}")

                # 3. 主循环：转发音频并返回响应
                while True:
                    try:
                        # 从 WebSocket 接收消息（前端发送的音频或控制消息）
                        message = await websocket.receive_bytes()

                        # 转发音频数据到 qwen-omni
                        audio_base64 = base64.b64encode(message).decode('utf-8')
                        audio_packet = {
                            "event_id": f"event_{id(websocket)}_audio",
                            "type": "input_audio_buffer.append",
                            "audio": audio_base64
                        }
                        await ws.send(json_lib.dumps(audio_packet))

                        # 接收来自 qwen-omni 的响应并转发给前端
                        omni_resp = await asyncio.wait_for(ws.recv(), timeout=10.0)
                        if isinstance(omni_resp, str):
                            data = json_lib.loads(omni_resp)
                            msg_type = data.get("type", "")
                            if msg_type == "response.audio.delta":
                                yield {
                                    "type": "audio",
                                    "data": data.get("audio", ""),
                                    "text": data.get("transcript", "")
                                }
                            elif msg_type == "response.text.delta":
                                yield {
                                    "type": "text",
                                    "data": data.get("text", "")
                                }
                            elif msg_type == "response.done":
                                yield {"type": "done"}
                            elif msg_type.startswith("error"):
                                yield {
                                    "type": "error",
                                    "data": str(data)
                                }
                        else:
                            # 二进制音频数据直接转发
                            yield {
                                "type": "binary",
                                "data": omni_resp.hex() if omni_resp else ""
                            }
                    except asyncio.TimeoutError:
                        continue

        except Exception as e:
            print(f"[VOICE] WebSocket error: {e}")
            yield {"type": "error", "data": str(e)}


# 全局单例
ai_service = AIService()
