import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from database import engine, Base
from models import memory  # 确保 UserProfile, Memory 表被注册
from routers import auth, health, consult, voice, user_profile

# 创建数据库表
Base.metadata.create_all(bind=engine)

app = FastAPI(title="健康小云 API", version="1.0.0")

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth.router, prefix="/api/auth", tags=["认证"])
app.include_router(health.router, prefix="/api/health", tags=["健康记录"])
app.include_router(consult.router, prefix="/api/consult", tags=["AI 咨询"])
app.include_router(voice.router, prefix="/api/consult/voice", tags=["语音通话"])
app.include_router(user_profile.router, prefix="/api/user", tags=["用户画像"])


@app.get("/")
def root():
    return {"message": "健康小云 API 服务运行中"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/voice-test", response_class=HTMLResponse)
def voice_test_page():
    html_path = os.path.join(os.path.dirname(__file__), "..", "voice_test.html")
    with open(html_path, "r", encoding="utf-8") as f:
        return f.read()
