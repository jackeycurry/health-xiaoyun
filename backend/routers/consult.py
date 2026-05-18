from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from uuid import UUID
from database import get_db
from schemas.chat import (
    ChatRequest, ChatResponse, ChatMessage,
    ConversationItem, ConversationListResponse, MessageItem, ConversationDetailResponse,
)
from services.ai_service import ai_service
from utils.deps import get_current_user, get_current_user_from_request
from models.user import User
from models.conversation import Conversation, Message

router = APIRouter()


def _save_chat_messages(
    db: Session,
    user_id: UUID,
    messages: list[dict],
    ai_response: str,
    conversation_id: str = None,
) -> UUID:
    """保存对话和消息，返回 conversation_id。
    若提供 conversation_id 则追加到已有对话（仅保存新增消息），否则创建新对话。
    """
    if conversation_id:
        try:
            conv_uuid = UUID(conversation_id)
        except (ValueError, AttributeError):
            conv_uuid = None
        conv = db.query(Conversation).filter(
            Conversation.id == conv_uuid,
            Conversation.user_id == user_id,
        ).first() if conv_uuid else None
        if not conv:
            # 无效的 conversation_id，降级为创建新对话
            conv = Conversation(user_id=user_id, title="新对话")
            db.add(conv)
            db.flush()
            for m in messages:
                db.add(Message(conversation_id=conv.id, role=m["role"], content=m["content"]))
        else:
            # 只追加 DB 中尚不存在的新消息
            existing_count = db.query(Message).filter(Message.conversation_id == conv.id).count()
            for m in messages[existing_count:]:
                db.add(Message(conversation_id=conv.id, role=m["role"], content=m["content"]))
    else:
        # 用占位标题，等 _generate_title 异步生成 AI 摘要后替换
        conv = Conversation(user_id=user_id, title="新对话")
        db.add(conv)
        db.flush()
        for m in messages:
            db.add(Message(conversation_id=conv.id, role=m["role"], content=m["content"]))

    db.add(Message(conversation_id=conv.id, role="assistant", content=ai_response))
    db.commit()
    return conv.id


@router.post("/chat")
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 健康咨询"""
    try:
        messages = [{"role": m.role, "content": m.content, "image": m.image} for m in request.messages]
        response = await ai_service.chat(messages, user_id=str(current_user.id))

        ai_content = response.get("choices", [{}])[0].get("message", {}).get("content", "")

        conv_id = _save_chat_messages(
            db, current_user.id, [{"role": m.role, "content": m.content} for m in request.messages],
            ai_content, request.conversation_id,
        )

        # 异步提取记忆 + 生成标题
        from services.memory_service import memory_service
        memory_service.extract_memories_sync(current_user.id, conv_id)
        all_text = " ".join([m.content for m in request.messages]) + " " + ai_content
        _generate_title(conv_id, all_text)
        response["conversation_id"] = str(conv_id)
        return response
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.post("/chat/stream")
async def chat_stream(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user_from_request)
):
    """AI 健康咨询（流式）"""
    try:
        messages = [{"role": m.role, "content": m.content, "image": m.image} for m in body.messages]

        async def generate():
            import json as json_lib
            from database import SessionLocal

            full_response = ""

            async for content in ai_service.chat_stream(messages, user_id=str(current_user.id)):
                full_response += content
                yield f"data: {json_lib.dumps({'content': content})}\n\n"

            # 持久化（在 [DONE] 之前，以便把 conversation_id 通知客户端）
            db = SessionLocal()
            try:
                conv_id = _save_chat_messages(
                    db, current_user.id,
                    [{"role": m.role, "content": m.content} for m in body.messages],
                    full_response, body.conversation_id,
                )
            finally:
                db.close()

            # 异步提取记忆 + 生成标题
            from services.memory_service import memory_service
            memory_service.extract_memories_sync(current_user.id, conv_id)
            all_text = " ".join([m.content for m in body.messages]) + " " + full_response
            _generate_title(conv_id, all_text)

            yield f"data: {json_lib.dumps({'conversation_id': str(conv_id)})}\n\n"

            # 生成智能追问建议
            try:
                suggest_msgs = messages + [{"role": "assistant", "content": full_response}]
                suggestion_prompt = suggest_msgs + [{"role": "user", "content": "基于以上对话，生成3个用户可能想继续追问的问题。要求：简短（10字以内）、自然口语化、覆盖不同方向。返回纯JSON数组，不要其他文字。格式：[\"问题1\",\"问题2\",\"问题3\"]"}]
                suggest_result = await ai_service.chat(suggestion_prompt, user_id=str(current_user.id))
                suggest_text = suggest_result.get("choices", [{}])[0].get("message", {}).get("content", "[]")
                suggestions = json_lib.loads(suggest_text) if suggest_text.startswith("[") else []
                if suggestions:
                    yield f"data: {json_lib.dumps({'suggestions': suggestions})}\n\n"
            except Exception:
                pass

            yield "data: [DONE]\n\n"

        return StreamingResponse(
            generate(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Allow-Methods": "*",
            }
        )
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/conversations", response_model=ConversationListResponse)
def list_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取用户对话列表"""
    convs = (
        db.query(Conversation)
        .filter(Conversation.user_id == current_user.id)
        .order_by(Conversation.updated_at.desc())
        .all()
    )
    return ConversationListResponse(
        conversations=[
            ConversationItem(
                id=c.id,
                title=c.title,
                created_at=c.created_at,
                updated_at=c.updated_at,
            )
            for c in convs
        ]
    )


@router.get("/conversations/{conv_id}", response_model=ConversationDetailResponse)
def get_conversation(
    conv_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取单个对话详情（含消息列表）"""
    conv = db.query(Conversation).filter(
        Conversation.id == conv_id,
        Conversation.user_id == current_user.id,
    ).first()

    if not conv:
        raise HTTPException(status_code=404, detail="对话不存在")

    return ConversationDetailResponse(
        id=conv.id,
        title=conv.title,
        messages=[
            MessageItem(
                id=m.id,
                role=m.role,
                content=m.content,
                created_at=m.created_at,
            )
            for m in conv.messages
        ],
        created_at=conv.created_at,
    )


@router.delete("/conversations/{conv_id}")
def delete_conversation(
    conv_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """删除对话"""
    conv = db.query(Conversation).filter(
        Conversation.id == conv_id,
        Conversation.user_id == current_user.id,
    ).first()
    if not conv:
        raise HTTPException(status_code=404, detail="对话不存在")
    # 先删消息再删对话
    db.query(Message).filter(Message.conversation_id == conv_id).delete()
    db.delete(conv)
    db.commit()
    return {"ok": True}


@router.post("/conversations/{conv_id}/regenerate-title")
async def regenerate_title(
    conv_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """基于对话内容重新生成 AI 摘要标题（强制覆盖现有标题）"""
    conv = db.query(Conversation).filter(
        Conversation.id == conv_id,
        Conversation.user_id == current_user.id,
    ).first()
    if not conv:
        raise HTTPException(status_code=404, detail="对话不存在")
    msgs = db.query(Message).filter(Message.conversation_id == conv_id).order_by(Message.created_at).limit(10).all()
    if not msgs:
        raise HTTPException(status_code=400, detail="对话还没有消息")
    text_parts = []
    for m in msgs:
        role_label = "用户" if m.role == "user" else "AI"
        text_parts.append(f"{role_label}: {m.content[:120]}")
    all_text = "\n".join(text_parts)
    try:
        title = await _regenerate_title_sync(conv_id, all_text)
        if not title:
            raise HTTPException(status_code=500, detail="生成标题失败")
        conv.title = title
        db.commit()
        return {"id": str(conv.id), "title": title}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"生成失败: {e}")


def _generate_title(conv_id: UUID, messages_text: str, force: bool = False):
    """异步生成 AI 总结标题。
    force=True 时无视当前标题强制覆盖（用于"重新生成"接口）；
    force=False 仅在标题为占位（"新对话"/"语音通话"）时替换。
    """
    import asyncio
    async def _do():
        try:
            prompt = [{
                "role": "system",
                "content": "你是对话标题生成助手。根据对话内容生成一个简洁的中文标题，要求：6-12字、口语化、能准确概括话题（健康问题、症状、生活习惯等），不要标点符号，不要书名号，不要前后缀。直接返回标题文本本身。",
            }, {
                "role": "user",
                "content": messages_text[:800],
            }]
            result = await ai_service.chat(prompt)
            title = result.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
            # 清洗：去掉常见的标点和包装
            for ch in ['"', '"', '"', '《', '》', '「', '」', '\n']:
                title = title.replace(ch, '')
            title = title.strip()[:20]
            if title:
                db = SessionLocal()
                conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
                if conv and (force or conv.title in ("新对话", "语音通话")):
                    conv.title = title
                    db.commit()
                db.close()
        except Exception:
            pass
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.create_task(_do())
        else:
            loop.run_until_complete(_do())
    except Exception:
        pass


async def _regenerate_title_sync(conv_id: UUID, messages_text: str) -> str:
    """同步版本：等待 AI 返回后再 commit。用于手动触发的"重新生成"接口。"""
    prompt = [{
        "role": "system",
        "content": "你是对话标题生成助手。根据对话内容生成一个简洁的中文标题，要求：6-12字、口语化、能准确概括话题（健康问题、症状、生活习惯等），不要标点符号，不要书名号，不要前后缀。直接返回标题文本本身。",
    }, {
        "role": "user",
        "content": messages_text[:800],
    }]
    result = await ai_service.chat(prompt)
    title = result.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
    for ch in ['"', '"', '"', '《', '》', '「', '」', '\n']:
        title = title.replace(ch, '')
    title = title.strip()[:20]
    return title


@router.get("/welcome-suggestions")
async def get_welcome_suggestions(
    current_user: User = Depends(get_current_user),
):
    """欢迎页快捷问题：基于用户画像/记忆/近期健康记录，AI 生成 3 条相关追问。"""
    import json as json_lib
    from services.memory_service import memory_service
    enriched = memory_service.build_enriched_prompt(current_user.id)
    if not enriched.strip():
        return {"suggestions": []}
    prompt = [
        {
            "role": "system",
            "content": "你是健康助手。根据用户画像/记忆/最近健康数据，为他生成3个最值得在此刻问 AI 健康助手的简短问题。要求：单条≤12字，口语化，覆盖不同维度（症状、健康指标、生活方式等）。返回纯JSON数组，不要其他文字。",
        },
        {"role": "user", "content": enriched},
    ]
    try:
        result = await ai_service.chat(prompt)
        content = result.get("choices", [{}])[0].get("message", {}).get("content", "[]").strip()
        # 兼容 ```json ... ``` 包裹
        if content.startswith("```"):
            content = content.strip("`").split("\n", 1)[-1].rsplit("```", 1)[0]
        suggestions = json_lib.loads(content) if content.startswith("[") else []
        if isinstance(suggestions, list):
            return {"suggestions": [str(s)[:20] for s in suggestions[:3]]}
    except Exception:
        pass
    return {"suggestions": []}


@router.get("/chat/history")
def get_chat_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取咨询历史（已废弃，请使用 /api/consult/conversations）"""
    convs = (
        db.query(Conversation)
        .filter(Conversation.user_id == current_user.id)
        .order_by(Conversation.updated_at.desc())
        .limit(20)
        .all()
    )
    return {
        "records": [
            {
                "id": str(c.id),
                "title": c.title,
                "created_at": c.created_at.isoformat(),
                "updated_at": c.updated_at.isoformat(),
            }
            for c in convs
        ]
    }
