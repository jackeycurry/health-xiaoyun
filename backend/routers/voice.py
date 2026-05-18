import json as json_lib
import base64
import asyncio
import websockets
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException, status, Depends
from sqlalchemy.orm import Session
from database import get_db, SessionLocal
from schemas.voice import VoiceChatRequest
from services.ai_service import ai_service
from services.memory_service import memory_service
from config import get_settings
from utils.security import decode_token
from models.user import User
from models.conversation import Conversation, Message
from uuid import UUID
import traceback

router = APIRouter()
settings = get_settings()


def _save_voice_message(conv_id: str, role: str, content: str) -> None:
    """持久化语音通话的转录消息"""
    try:
        db = SessionLocal()
        msg = Message(conversation_id=UUID(conv_id), role=role, content=content)
        db.add(msg)
        db.commit()
        db.close()
    except Exception as e:
        print(f"[VOICE_WS] 保存消息失败: {e}")


@router.post("/chat")
async def voice_chat(
    request: VoiceChatRequest,
    db: Session = Depends(get_db),
):
    """单轮语音对话 — 发送 base64 音频，获取文本回复"""
    try:
        response = await ai_service.voice_chat(request.audio)
        ai_content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
        return {"text": ai_content}
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.websocket("/ws")
async def voice_ws(websocket: WebSocket):
    """实时语音通话 WebSocket — 桥接到 DashScope realtime API"""
    await websocket.accept()

    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4003, reason="缺少认证 token")
        return

    user_id = decode_token(token)
    if user_id is None:
        await websocket.close(code=4001, reason="无效的认证凭证")
        return

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == UUID(user_id)).first()
        if not user:
            await websocket.close(code=4001, reason="用户不存在")
            return
    finally:
        db.close()

    print(f"[VOICE_WS] 用户 {user_id} 已连接")

    # 复用已有的文字对话，或创建新对话
    conversation_id = websocket.query_params.get("conversation_id")
    try:
        db_conv = SessionLocal()
        if conversation_id:
            # 续接之前的文字/语音对话
            existing = db_conv.query(Conversation).filter(
                Conversation.id == UUID(conversation_id),
                Conversation.user_id == UUID(user_id),
            ).first()
            if existing:
                print(f"[VOICE_WS] 续接已有对话: {conversation_id}")
            else:
                conversation_id = None
        if not conversation_id:
            conv = Conversation(user_id=UUID(user_id), title="语音通话")
            db_conv.add(conv)
            db_conv.commit()
            conversation_id = str(conv.id)
            print(f"[VOICE_WS] 新建对话: {conversation_id}")
        db_conv.close()
    except Exception as e:
        print(f"[VOICE_WS] Conversation 处理失败: {e}")
        conversation_id = None

    # 加载对话历史上下文（文字聊天记录）
    chat_context = ""
    if conversation_id:
        try:
            db_ctx = SessionLocal()
            msgs = db_ctx.query(Message).filter(
                Message.conversation_id == UUID(conversation_id)
            ).order_by(Message.created_at).limit(20).all()
            if msgs:
                lines = ["## 本对话之前的聊天记录"]
                for m in msgs:
                    role_label = "用户" if m.role == "user" else "AI"
                    lines.append(f"{role_label}: {m.content[:100]}")
                chat_context = "\n".join(lines)
            db_ctx.close()
        except Exception as e:
            print(f"[VOICE_WS] 加载对话历史失败: {e}")

    health_instructions = """你是一位专业的AI健康助手，名叫"健康小云"。请根据用户的语音问题提供健康建议。

重要提示：用户可能开启或关闭摄像头。你只有在实际收到图像数据 (input_image_buffer.append) 时才能看到画面。如果此轮对话中没有收到任何图像数据，说明用户未开摄像头，你绝不能编造或提及任何视觉观察。如果确实收到了图像，可以结合画面给出建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂，控制在50字以内
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文
6. 只在实际收到图像时才提及视觉观察，否则只基于语音回答"""

    # 注入本对话的文字聊天记录（让AI知道之前聊了什么）
    if chat_context:
        health_instructions += f"\n\n{chat_context}"

    # 注入用户画像和长期记忆（与文字对话共用同一份记忆）
    enriched = memory_service.build_enriched_prompt(UUID(user_id))
    if enriched:
        health_instructions += f"\n\n{enriched}"

    realtime_url = f"wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3.5-omni-plus-realtime"

    try:
        async with websockets.connect(
            realtime_url,
            extra_headers={"Authorization": f"Bearer {settings.DASHSCOPE_API_KEY}"},
            open_timeout=30,
        ) as ds_ws:
            print(f"[VOICE_WS] DashScope 连接成功")

            # 1. 先接收 DashScope 自动发送的 session.created
            first_msg = await ds_ws.recv()
            print(f"[VOICE_WS] DashScope 首条消息: {first_msg[:200]}")

            # 2. 发送 session.update 配置
            session_config = {
                "event_id": f"event_{user_id}_session",
                "type": "session.update",
                "session": {
                    "modalities": ["text", "audio"],
                    "voice": "Tina",
                    "input_audio_format": "pcm",
                    "output_audio_format": "pcm",
                    "instructions": health_instructions,
                    "turn_detection": {
                        "type": "semantic_vad",
                        "threshold": 0.5,
                        "silence_duration_ms": 1000
                    }
                }
            }
            await ds_ws.send(json_lib.dumps(session_config))
            print(f"[VOICE_WS] session.update 已发送 (VAD threshold=0.5)")

            # 3. 等待 session.updated 确认
            second_msg = await ds_ws.recv()
            print(f"[VOICE_WS] DashScope 第二条消息: {second_msg[:200]}")

            # 通知 Flutter 连接就绪（含 conversation_id）
            await websocket.send_text(json_lib.dumps({
                "type": "connected",
                "conversation_id": conversation_id,
            }))
            print(f"[VOICE_WS] 已通知 Flutter 连接就绪, conv_id={conversation_id}")

            # 4. 双向桥接
            audio_seq = 0
            image_seq = 0
            event_seq = 0
            response_in_progress = False

            def _next_event_id():
                nonlocal event_seq
                event_seq += 1
                return f"event_{user_id}_{event_seq}"

            async def _cancel_and_clear():
                """取消当前AI回复并清除音频缓冲区（防止回声触发新一轮回复）"""
                nonlocal response_in_progress, audio_seq
                if response_in_progress:
                    cancel_id = _next_event_id()
                    await ds_ws.send(json_lib.dumps({
                        "event_id": cancel_id,
                        "type": "response.cancel"
                    }))
                    print(f"[VOICE_WS] response.cancel 已发送 (id={cancel_id})")
                    response_in_progress = False
                # 清除缓冲区中的残留回声，防止VAD自动提交触发新一轮回复
                clear_id = _next_event_id()
                await ds_ws.send(json_lib.dumps({
                    "event_id": clear_id,
                    "type": "input_audio_buffer.clear"
                }))
                print(f"[VOICE_WS] input_audio_buffer.clear 已发送 (id={clear_id})")
                # 重置音频计数器，防止图像在新音频到达前发送（DashScope要求先有音频）
                audio_seq = 0

            async def forward_audio():
                """Flutter → DashScope: 转发音频和图像"""
                nonlocal audio_seq, image_seq
                print(f"[VOICE_WS] forward_audio 任务启动")
                try:
                    while True:
                        try:
                            msg = await websocket.receive_text()
                            data = json_lib.loads(msg)
                            msg_type = data.get("type", "")

                            if msg_type == "audio":
                                audio_b64 = data.get("data", "")
                                if audio_b64:
                                    audio_seq += 1
                                    if audio_seq <= 2 or audio_seq % 20 == 0:
                                        print(f"[VOICE_WS] 收到 Flutter 消息: type=audio seq={audio_seq}")
                                    audio_packet = {
                                        "event_id": _next_event_id(),
                                        "type": "input_audio_buffer.append",
                                        "audio": audio_b64,
                                    }
                                    await ds_ws.send(json_lib.dumps(audio_packet))
                            elif msg_type == "image":
                                if audio_seq == 0:
                                    if image_seq == 0:
                                        print(f"[VOICE_WS] 图像在音频之前到达，跳过")
                                    continue
                                image_b64 = data.get("data", "")
                                if image_b64:
                                    image_seq += 1
                                    if image_seq <= 2 or image_seq % 10 == 0:
                                        print(f"[VOICE_WS] 收到 Flutter 消息: type=image seq={image_seq} len={len(image_b64)}")
                                    image_packet = {
                                        "event_id": _next_event_id(),
                                        "type": "input_image_buffer.append",
                                        "image": image_b64,
                                    }
                                    await ds_ws.send(json_lib.dumps(image_packet))
                            elif msg_type == "commit":
                                commit_msg = {
                                    "event_id": _next_event_id(),
                                    "type": "input_audio_buffer.commit",
                                }
                                await ds_ws.send(json_lib.dumps(commit_msg))
                            elif msg_type == "ping":
                                pass  # 心跳保活
                            elif msg_type == "stop":
                                print(f"[VOICE_WS] Flutter 请求停止")
                                break
                        except WebSocketDisconnect:
                            print(f"[VOICE_WS] Flutter WebSocket 断开 (WebSocketDisconnect)")
                            break
                        except Exception as e:
                            print(f"[VOICE_WS] forward_audio 内部错误: {e}")
                            traceback.print_exc()
                            break
                except Exception as e:
                    print(f"[VOICE_WS] forward_audio 外部错误: {e}")
                    traceback.print_exc()
                print(f"[VOICE_WS] forward_audio 任务结束")

            async def forward_response():
                """DashScope → Flutter: 转发回复"""
                nonlocal response_in_progress
                print(f"[VOICE_WS] forward_response 任务启动")
                try:
                    while True:
                        try:
                            message = await asyncio.wait_for(ds_ws.recv(), timeout=30.0)
                            if isinstance(message, str):
                                data = json_lib.loads(message)
                                msg_type = data.get("type", "")
                                print(f"[VOICE_WS] DashScope → Flutter: type={msg_type}")

                                if msg_type == "response.audio_transcript.delta":
                                    text = data.get("delta", "")
                                    if text:
                                        await websocket.send_text(
                                            json_lib.dumps({"type": "text", "data": text})
                                        )
                                elif msg_type == "response.text.delta":
                                    text = data.get("delta", {}).get("content", "") or data.get("text", "")
                                    if text:
                                        await websocket.send_text(
                                            json_lib.dumps({"type": "text", "data": text})
                                        )
                                elif msg_type == "response.audio.delta":
                                    audio = data.get("delta", "")
                                    if audio:
                                        await websocket.send_text(
                                            json_lib.dumps({"type": "audio", "data": audio})
                                        )
                                elif msg_type == "response.created":
                                    response_in_progress = True
                                elif msg_type == "response.done":
                                    response_in_progress = False
                                    await websocket.send_text(json_lib.dumps({"type": "done"}))
                                elif msg_type.startswith("error"):
                                    print(f"[VOICE_WS] DashScope 错误: {data}")
                                    response_in_progress = False
                                    await websocket.send_text(
                                        json_lib.dumps({"type": "error", "data": str(data)})
                                    )
                                elif msg_type == "session.done":
                                    print(f"[VOICE_WS] DashScope session.done, 结束桥接")
                                    break
                                elif msg_type in ("session.updated", "session.created",
                                                   "response.output_item.added",
                                                   "response.content_part.added",
                                                   "response.output_item.done",
                                                   "response.content_part.done",
                                                   "response.audio.done",
                                                   "input_audio_buffer.committed",
                                                   "input_audio_buffer.cleared",
                                                   "conversation.item.created",
                                                   "conversation.item.input_audio_transcription.delta"):
                                    pass
                                elif msg_type == "response.audio_transcript.done":
                                    ai_text = data.get("transcript", "")
                                    if ai_text and conversation_id:
                                        _save_voice_message(conversation_id, "assistant", ai_text)
                                    await websocket.send_text(
                                        json_lib.dumps({"type": "ai_text", "data": ai_text})
                                    )
                                elif msg_type == "conversation.item.input_audio_transcription.completed":
                                    user_text = data.get("transcript", "")
                                    if user_text and conversation_id:
                                        _save_voice_message(conversation_id, "user", user_text)
                                    await websocket.send_text(
                                        json_lib.dumps({"type": "user_text", "data": user_text})
                                    )
                                elif msg_type == "input_audio_buffer.speech_started":
                                    print(f"[VOICE_WS] DashScope: 检测到语音开始 (response_in_progress={response_in_progress})")
                                    if response_in_progress:
                                        # 回声或用户打断 → 取消AI回复并清除缓冲区
                                        print(f"[VOICE_WS] 取消当前响应+清除缓冲区")
                                        await _cancel_and_clear()
                                    else:
                                        print(f"[VOICE_WS] 首次语音，跳过cancel")
                                    await websocket.send_text(
                                        json_lib.dumps({"type": "speech_started"})
                                    )
                                elif msg_type == "input_audio_buffer.speech_stopped":
                                    print(f"[VOICE_WS] DashScope: 检测到语音结束")
                                    await websocket.send_text(
                                        json_lib.dumps({"type": "speech_stopped"})
                                    )
                                else:
                                    print(f"[VOICE_WS] 未知 DashScope 消息类型: {msg_type}")
                            else:
                                await websocket.send_bytes(message)
                        except asyncio.TimeoutError:
                            print(f"[VOICE_WS] forward_response 超时，继续等待...")
                            continue
                        except Exception as e:
                            print(f"[VOICE_WS] forward_response 内部错误: {e}")
                            traceback.print_exc()
                            break
                except Exception as e:
                    print(f"[VOICE_WS] forward_response 外部错误: {e}")
                    traceback.print_exc()
                print(f"[VOICE_WS] forward_response 任务结束")

            # 并行运行两个桥接任务
            audio_task = asyncio.create_task(forward_audio())
            response_task = asyncio.create_task(forward_response())

            print(f"[VOICE_WS] 桥接任务已创建，等待中...")

            done, pending = await asyncio.wait(
                [audio_task, response_task],
                return_when=asyncio.FIRST_COMPLETED,
            )
            print(f"[VOICE_WS] 桥接任务结束: done={len(done)}, pending={len(pending)}")
            for task in pending:
                task.cancel()

            # 异步提取记忆（与文字对话共用同一份记忆库）
            if conversation_id:
                try:
                    memory_service.extract_memories_sync(UUID(user_id), UUID(conversation_id))
                    print(f"[VOICE_WS] 记忆提取已触发, conv_id={conversation_id}")
                    # 生成AI总结标题
                    from routers.consult import _generate_title
                    all_text = "语音通话对话"
                    try:
                        db_t = SessionLocal()
                        ms = db_t.query(Message).filter(Message.conversation_id == UUID(conversation_id)).limit(5).all()
                        all_text = " ".join([m.content[:80] for m in ms])
                        db_t.close()
                    except Exception:
                        pass
                    _generate_title(UUID(conversation_id), all_text)
                except Exception as e:
                    print(f"[VOICE_WS] 记忆提取失败: {e}")

    except websockets.exceptions.ConnectionClosed as e:
        print(f"[VOICE_WS] DashScope 连接关闭: {e}")
    except WebSocketDisconnect:
        print(f"[VOICE_WS] 用户 {user_id} 断开连接")
    except Exception as e:
        print(f"[VOICE_WS] 错误: {e}")
        traceback.print_exc()
        try:
            await websocket.send_text(json_lib.dumps({"type": "error", "data": str(e)}))
        except Exception:
            pass

    print(f"[VOICE_WS] 通话结束")
