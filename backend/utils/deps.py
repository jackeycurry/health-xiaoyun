from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from uuid import UUID
from database import get_db
from models.user import User
from utils.security import decode_token

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    token = credentials.credentials
    user_id = decode_token(token)

    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的认证凭证",
        )

    user = db.query(User).filter(User.id == UUID(user_id)).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户不存在",
        )

    return user


async def get_current_user_from_request(
    request: Request,
    db: Session = Depends(get_db)
) -> User:
    """从 `Authorization` header 或 `token` query 参数中获取并验证用户（供 SSE/EventSource 使用）。
    注意：将 token 放在 query 中存在风险，仅在无法通过自定义 header 的流式场景使用。
    """
    # 优先读取 Authorization header
    auth: str | None = None
    if "authorization" in request.headers:
        auth = request.headers.get("authorization")

    token = None
    if auth:
        parts = auth.split()
        if len(parts) == 2 and parts[0].lower() == "bearer":
            token = parts[1]

    # fallback to query param `token`
    if not token:
        token = request.query_params.get("token")

    if not token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="未提供认证凭证",
        )

    user_id = decode_token(token)
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的认证凭证",
        )

    user = db.query(User).filter(User.id == UUID(user_id)).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户不存在",
        )

    return user
