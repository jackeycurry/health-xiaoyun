from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # 应用配置
    APP_NAME: str = "健康小云 API"
    DEBUG: bool = True

    # 数据库配置
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/health_app"

    # JWT 配置
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7天

    # 阿里云百炼配置
    DASHSCOPE_API_KEY: str = "sk-xxxxxxxxxxxx"
    DASHSCOPE_BASE_URL: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    AI_MODEL: str = "qwen3-omni-flash"

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()
