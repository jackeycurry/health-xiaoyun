import pytest
import sys
import os

# 在导入 main 之前，先用测试数据库配置替换
os.environ["DATABASE_URL"] = "sqlite:///./test_isolated.db"

# 重新加载 database 模块前先清除缓存
for mod in list(sys.modules.keys()):
    if mod in ['database', 'main', 'config', 'models', 'schemas', 'routers', 'services', 'utils']:
        del sys.modules[mod]

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# 创建测试数据库引擎
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_isolated.db"
test_engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}, poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

# 导入并覆盖 database 模块
import database
database.engine = test_engine
database.SessionLocal = TestingSessionLocal

# 导入 Base 并创建表
from database import Base

# 在测试开始前创建所有表
Base.metadata.create_all(bind=test_engine)

# 导入 app
from main import app
from database import get_db

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    """创建测试数据库表"""
    Base.metadata.create_all(bind=test_engine)
    yield


@pytest.fixture(autouse=True)
def clean_database():
    """每个测试前清空数据库"""
    with test_engine.connect() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            conn.execute(text(f"DELETE FROM {table.name}"))
        conn.commit()
    yield


@pytest.fixture
def client():
    """返回 TestClient"""
    from fastapi.testclient import TestClient
    return TestClient(app)


@pytest.fixture
def auth_token(client):
    """创建测试用户并返回 token"""
    client.post("/api/auth/register", json={"phone": "13900139000", "password": "123456"})
    resp = client.post("/api/auth/login", json={"phone": "13900139000", "password": "123456"})
    return resp.json()["access_token"]
