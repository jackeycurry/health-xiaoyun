# 健康小云 - 后端 API 服务

## 技术栈

- Python 3.11 + FastAPI
- PostgreSQL + SQLAlchemy
- JWT 认证
- 阿里云百炼 qwen3-omni-flash 模型

## 快速开始

### 1. 安装依赖

```bash
cd backend
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入数据库和 API Key 信息
```

### 3. 启动服务

```bash
# 开发环境
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 生产环境
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 4. 访问 API 文档

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API 接口

### 认证模块
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/me` - 获取当前用户

### 健康记录模块
- `POST /api/health/records` - 创建记录
- `GET /api/health/records` - 获取记录列表
- `GET /api/health/records/latest` - 获取最新记录
- `DELETE /api/health/records/{id}` - 删除记录

### AI 咨询模块
- `POST /api/consult/chat` - AI 对话
- `POST /api/consult/chat/stream` - AI 对话（流式）
- `GET /api/consult/chat/history` - 获取历史

## 运行测试

```bash
pytest tests/ -v
```
