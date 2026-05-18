import json as json_lib
from datetime import datetime, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID

from database import SessionLocal
from models.memory import UserProfile, Memory
from models.conversation import Conversation, Message
from models.health_record import HealthRecord
from services.ai_service import ai_service


_RECORD_LABELS = {
    "blood_pressure": "血压",
    "blood_sugar": "血糖",
    "weight": "体重",
    "temperature": "体温",
    "heart_rate": "心率",
}

_RECORD_UNITS = {
    "blood_pressure": "mmHg",
    "blood_sugar": "mmol/L",
    "weight": "kg",
    "temperature": "°C",
    "heart_rate": "bpm",
}


def _format_record_value(record_type: str, value: dict) -> str:
    """把 JSON value 格式化成易读的字符串。"""
    if not isinstance(value, dict):
        return str(value)
    if record_type == "blood_pressure":
        s = value.get("systolic")
        d = value.get("diastolic")
        if s is not None and d is not None:
            return f"{s}/{d}"
    v = value.get("value")
    if v is not None:
        return str(v)
    return json_lib.dumps(value, ensure_ascii=False)


class MemoryService:

    # ---- 短期记忆：最近对话 ----

    def get_recent_context(self, user_id: UUID, n: int = 3) -> str:
        """获取最近 n 轮对话摘要作为短期记忆"""
        db = SessionLocal()
        try:
            conversations = (
                db.query(Conversation)
                .filter(Conversation.user_id == user_id)
                .order_by(desc(Conversation.updated_at))
                .limit(n)
                .all()
            )
            if not conversations:
                return ""
            lines = ["## 近期对话记录"]
            for conv in conversations:
                # 取前两条用户消息作为摘要
                user_msgs = (
                    db.query(Message)
                    .filter(Message.conversation_id == conv.id, Message.role == "user")
                    .order_by(Message.created_at)
                    .limit(2)
                    .all()
                )
                summary = "、".join([m.content[:40] for m in user_msgs])
                lines.append(f"- {conv.title}: {summary}")
            return "\n".join(lines)
        finally:
            db.close()

    # ---- 长期记忆 ----

    def get_top_memories(self, user_id: UUID, limit: int = 10) -> str:
        """获取最相关的长期记忆，注入 system prompt"""
        db = SessionLocal()
        try:
            memories = (
                db.query(Memory)
                .filter(Memory.user_id == user_id)
                .order_by(desc(Memory.importance), desc(Memory.access_count))
                .limit(limit)
                .all()
            )
            if not memories:
                return ""
            by_cat: dict = {}
            for m in memories:
                by_cat.setdefault(m.category, []).append(m.fact)
            lines = ["## 关于用户的长期记忆"]
            cat_names = {"personal": "个人信息", "health": "健康相关", "habit": "生活习惯", "preference": "偏好", "note": "备注"}
            for cat, facts in by_cat.items():
                lines.append(f"### {cat_names.get(cat, cat)}")
                for f in facts:
                    lines.append(f"- {f}")
                # 提升被引用计数
            return "\n".join(lines)
        finally:
            db.close()

    # ---- 画像 ----

    def get_profile_summary(self, user_id: UUID) -> str:
        """获取用户画像的文字摘要（含姓名）"""
        db = SessionLocal()
        try:
            from models.user import User as UserModel
            profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            user = db.query(UserModel).filter(UserModel.id == user_id).first()
            name = (user.nickname if user and user.nickname and user.nickname != "健康用户" else "")
            parts = []
            if name:
                parts.append(f"姓名：{name}")
            if profile:
                if profile.gender:
                    gender_map = {"male": "男", "female": "女"}
                    parts.append(gender_map.get(profile.gender, profile.gender))
                if profile.age:
                    parts.append(f"{profile.age}岁")
                if profile.height:
                    parts.append(f"身高{profile.height}cm")
                if profile.weight:
                    parts.append(f"体重{profile.weight}kg")
            summary = "## 用户画像\n" + "，".join(parts) if parts else ""
            if profile:
                if profile.health_summary:
                    summary += f"\n健康概况：{profile.health_summary}"
                if profile.risk_tags:
                    tags_str = "、".join(profile.risk_tags)
                    summary += f"\n风险标签：{tags_str}"
            return summary
        finally:
            db.close()

    # ---- 健康记录数据 ----

    def get_recent_health_records(self, user_id: UUID, days: int = 7, per_type: int = 3) -> str:
        """
        获取最近 N 天的健康记录，按类型分组，每类型最多 per_type 条最新数据。
        让 AI 看到用户的实际生理数据，避免重复询问。
        """
        db = SessionLocal()
        try:
            since = datetime.utcnow() - timedelta(days=days)
            records = (
                db.query(HealthRecord)
                .filter(
                    HealthRecord.user_id == user_id,
                    HealthRecord.recorded_at >= since,
                )
                .order_by(desc(HealthRecord.recorded_at))
                .all()
            )
            if not records:
                return ""
            by_type: dict = {}
            for r in records:
                by_type.setdefault(r.type, []).append(r)
            lines = [f"## 最近{days}天健康记录"]
            for rt, items in by_type.items():
                label = _RECORD_LABELS.get(rt, rt)
                unit = _RECORD_UNITS.get(rt, "")
                top = items[:per_type]
                if len(top) == 1:
                    r = top[0]
                    val = _format_record_value(rt, r.value)
                    date_str = r.recorded_at.strftime("%m-%d %H:%M")
                    lines.append(f"- {label}: {val}{unit}（{date_str}）")
                else:
                    series = []
                    for r in top:
                        val = _format_record_value(rt, r.value)
                        date_str = r.recorded_at.strftime("%m-%d")
                        series.append(f"{val}{unit}({date_str})")
                    lines.append(f"- {label}: " + " → ".join(reversed(series)))
            return "\n".join(lines)
        finally:
            db.close()

    # ---- 构建完整提示词 ----

    def build_enriched_prompt(self, user_id: Optional[UUID]) -> str:
        """构建包含记忆的增强系统提示词"""
        extra = ""
        if user_id:
            profile = self.get_profile_summary(user_id)
            if profile:
                extra += profile + "\n\n"
            health_data = self.get_recent_health_records(user_id)
            if health_data:
                extra += health_data + "\n\n"
            memories = self.get_top_memories(user_id)
            if memories:
                extra += memories + "\n\n"
            recent = self.get_recent_context(user_id, n=3)
            if recent:
                extra += recent + "\n"
        return extra.strip()

    # ---- 记忆提取 ----

    async def extract_memories_async(self, user_id: UUID, conversation_id: UUID) -> List[dict]:
        """
        对话完成后，异步调用 AI 提取用户事实。
        带已有记忆作为上下文，AI 输出 op（add/update/skip）实现智能去重和冲突合并。
        返回本次产生变更的记忆列表。
        """
        db = SessionLocal()
        try:
            # 验证对话属于该用户
            conv = db.query(Conversation).filter(
                Conversation.id == conversation_id,
                Conversation.user_id == user_id,
            ).first()
            if not conv:
                return []
            messages = (
                db.query(Message)
                .filter(Message.conversation_id == conversation_id)
                .order_by(Message.created_at)
                .all()
            )
            if not messages:
                return []
            # 拼接对话文本
            text_parts = []
            for m in messages:
                text_parts.append(f"{'用户' if m.role == 'user' else 'AI'}: {m.content}")
            full_text = "\n".join(text_parts)

            # 取已有记忆作为去重/合并上下文（按重要性 + 引用次数排序）
            existing_memories = (
                db.query(Memory)
                .filter(Memory.user_id == user_id)
                .order_by(desc(Memory.importance), desc(Memory.access_count))
                .limit(40)
                .all()
            )
            existing_lines = []
            for em in existing_memories:
                existing_lines.append(f"[{em.id}] ({em.category}) {em.fact}")
            existing_block = "\n".join(existing_lines) if existing_lines else "（暂无已有记忆）"

            # 当前画像作为冲突检测的参考
            profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            profile_lines = []
            if profile:
                if profile.gender:
                    profile_lines.append(f"性别: {profile.gender}")
                if profile.age is not None:
                    profile_lines.append(f"年龄: {profile.age}")
                if profile.height is not None:
                    profile_lines.append(f"身高: {profile.height}cm")
                if profile.weight is not None:
                    profile_lines.append(f"体重: {profile.weight}kg")
            profile_block = "\n".join(profile_lines) if profile_lines else "（暂无）"

            extraction_prompt = [
                {
                    "role": "system",
                    "content": """你是一个信息提取助手。从对话中提取关于用户的长期持久事实，并对照已有记忆做去重和冲突合并。

类别：
- personal: 姓名、年龄、性别、职业、所在地、家庭成员等基本身份信息
- health: 慢性病史、过敏史、确诊疾病、长期服药情况
- habit: 长期生活习惯（运动、饮食、作息、烟酒等）
- preference: 用户的偏好（沟通方式、对某些事物的态度等）
- note: 其他值得长期记住的信息

每条新事实，必须判断 op（操作）：
- "add"   全新事实，与已有记忆都不同
- "update" 与某条已有记忆是同一信息但更精确、或与之冲突（如"30岁"已有，现在说"31岁"应 update），必须提供 target_id
- "skip"  已有记忆里完全等价的信息（同义即可），跳过避免重复

判定相似度宁可严不可宽：含义相同就算重复，不要因为措辞不同就重复添加。

提取规则：
1. 优先提取 personal：姓名、年龄、职业等
2. 稳定的事实 importance 给高分（>0.7）
3. 不要提取：视觉观察、临时症状、AI 回复建议
4. 如对话明确给出 gender/age/height/weight，在 profile 中返回数值

返回纯 JSON：
{
  "facts": [
    {"op": "add", "fact": "...", "category": "...", "importance": 0.8},
    {"op": "update", "target_id": "<UUID>", "fact": "...", "category": "...", "importance": 0.9},
    {"op": "skip", "reason": "已有记忆 <id> 包含此事实"}
  ],
  "profile": {"gender": "male", "age": 30, "height": 175, "weight": 70}
}

profile: gender ∈ {male, female}，其它整数。无新数据时 profile 设 {}。"""
                },
                {
                    "role": "user",
                    "content": f"""## 已有长期记忆
{existing_block}

## 当前画像数值
{profile_block}

## 本次对话
{full_text}"""
                }
            ]

            result = await ai_service.chat(extraction_prompt)
            content = result.get("choices", [{}])[0].get("message", {}).get("content", "{}")

            # 解析 JSON
            try:
                data = json_lib.loads(content)
                if isinstance(data, list):
                    data = {"facts": data, "profile": {}}
                facts = data.get("facts", [])
                profile_updates = data.get("profile", {})
            except Exception:
                facts = []
                profile_updates = {}

            # 更新画像：新值优先（用户最新陈述覆盖旧值）
            if profile_updates:
                if not profile:
                    profile = UserProfile(user_id=user_id)
                    db.add(profile)
                for field in ['gender', 'age', 'height', 'weight']:
                    val = profile_updates.get(field)
                    if val is not None:
                        setattr(profile, field, val)
                db.commit()
                print(f"[MEMORY] 更新画像: {profile_updates}")

            # 按 op 处理 facts
            saved = []
            for item in facts:
                op = (item.get("op") or "add").lower()
                fact_text = (item.get("fact") or "").strip()
                category = item.get("category", "note")
                importance = float(item.get("importance", 0.5))

                if op == "skip":
                    continue

                if op == "update":
                    target_id = item.get("target_id")
                    target = None
                    if target_id:
                        try:
                            target = db.query(Memory).filter(
                                Memory.id == UUID(str(target_id)),
                                Memory.user_id == user_id,
                            ).first()
                        except (ValueError, TypeError):
                            target = None
                    if target and fact_text:
                        target.fact = fact_text
                        target.category = category
                        target.importance = max(target.importance, importance)
                        target.access_count += 1
                        db.commit()
                        saved.append({"op": "update", "id": str(target.id), "fact": fact_text})
                        continue
                    # 找不到目标 → 退回到 add 路径
                    op = "add"

                if op == "add" and fact_text:
                    # 同 category+fact 完全匹配兜底去重
                    existing = db.query(Memory).filter(
                        Memory.user_id == user_id,
                        Memory.category == category,
                        Memory.fact == fact_text,
                    ).first()
                    if existing:
                        existing.importance = max(existing.importance, importance)
                        existing.access_count += 1
                        db.commit()
                        continue
                    mem = Memory(
                        user_id=user_id,
                        category=category,
                        fact=fact_text,
                        importance=importance,
                        source_conversation_id=conversation_id,
                    )
                    db.add(mem)
                    saved.append({"op": "add", "fact": fact_text, "category": category})
            db.commit()
            return saved
        finally:
            db.close()

    def extract_memories_sync(self, user_id: UUID, conversation_id: UUID):
        """同步包装，用于异步触发"""
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                asyncio.create_task(self.extract_memories_async(user_id, conversation_id))
            else:
                loop.run_until_complete(self.extract_memories_async(user_id, conversation_id))
        except Exception:
            pass


memory_service = MemoryService()
