# 健康小荷 — 项目文档

## 项目概述

健康小荷是一个 AI 健康助手应用，支持文字对话和实时语音/视频通话。包含 Flutter 移动端（Android/Web）和 Python FastAPI 后端，AI 能力由阿里云百炼 DashScope 提供。

**快速链接：**

| 文档 | 内容 |
|------|------|
| [架构说明](./架构说明.md) | 项目架构、分层设计、核心模块 |
| [语音通话实现](./语音通话实现.md) | DashScope Realtime API 集成、回声处理、打断机制 |
| [部署打包](./部署打包.md) | 环境配置、构建打包、部署流程 |

---

## 环境要求

| 工具 | 版本要求 |
|------|----------|
| Flutter SDK | ≥3.11.5 |
| Python | ≥3.10 |
| PostgreSQL | 14+ |
| Android Studio | 最新稳定版（模拟器用） |
| Chrome | 最新稳定版（Web 调试用） |

---

## 5 分钟快速启动

### 1. 克隆并安装依赖

```bash
cd app

# 后端依赖
cd backend
pip install -r requirements.txt

# Flutter 依赖
cd ../health_xiaohe
flutter pub get
```

### 2. 配置后端环境

在 `backend/` 目录创建 `.env` 文件：

```env
DATABASE_URL=postgresql://user:password@localhost:5432/health_app
SECRET_KEY=your-secret-key-change-me
DASHSCOPE_API_KEY=sk-你的阿里云百炼API密钥
AI_MODEL=qwen3-omni-flash
```

> 如果没有 PostgreSQL，测试时可用 SQLite：`DATABASE_URL=sqlite:///./test.db`

### 3. 启动后端

```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8002
```

验证：浏览器打开 `http://localhost:8002/health` 应返回 `{"status":"healthy"}`

### 4. 启动 Flutter

```bash
# Web 端（推荐调试）
cd health_xiaohe
flutter run -d chrome

# Android 模拟器
flutter run
```

首次启动会自动注册/登录。调用 `/api/auth/register` 注册账号即可使用。

---

## 项目结构一览

```
app/
├── health_xiaohe/              # Flutter 应用
│   └── lib/
│       ├── main.dart           # 入口
│       ├── app.dart            # MultiBlocProvider 根组件
│       ├── injection.dart      # get_it 依赖注入
│       ├── core/               # 基础设施层
│       │   ├── constants/      # 颜色、间距、字符串常量
│       │   ├── network/        # HTTP、WebSocket、SSE 客户端
│       │   ├── storage/        # SharedPreferences 封装
│       │   ├── theme/          # Material3 主题
│       │   ├── audio/          # 平台音频录制/播放
│       │   └── camera/         # 平台摄像头采集
│       ├── data/               # 数据层
│       │   ├── models/         # 数据模型
│       │   └── repositories/   # 仓库实现
│       ├── domain/             # 领域层
│       │   └── repositories/   # 仓库接口（抽象）
│       └── presentation/       # 表现层
│           ├── blocs/          # BLoC 状态管理
│           ├── pages/          # 页面
│           ├── widgets/        # 可复用组件
│           └── router/         # GoRouter 路由
├── backend/                    # Python 后端
│   ├── main.py                 # FastAPI 入口
│   ├── config.py               # pydantic-settings 配置
│   ├── database.py             # SQLAlchemy 数据库
│   ├── models/                 # ORM 模型
│   ├── routers/                # API 路由
│   ├── schemas/                # Pydantic 请求/响应模型
│   ├── services/               # 业务逻辑
│   ├── utils/                  # 工具函数
│   └── tests/                  # pytest 测试
└── docs/                       # 文档
    └── design/                 # 设计规范和原型
```

---

## 技术栈速览

### Flutter App
- **状态管理**: flutter_bloc (BLoC Pattern)
- **网络**: dio (HTTP), web_socket_channel (WebSocket), EventSource (SSE)
- **依赖注入**: get_it
- **路由**: go_router (ShellRoute 底部导航)
- **本地存储**: shared_preferences
- **摄像头**: camera (Android), getUserMedia (Web)
- **平台适配**: Dart 条件导入 (`dart.library.html` / `dart.library.io`)

### Python Backend
- **框架**: FastAPI + uvicorn
- **数据库**: PostgreSQL (生产) / SQLite (测试)
- **ORM**: SQLAlchemy 2.0
- **认证**: JWT (python-jose + bcrypt)
- **AI 模型**: 阿里云百炼 DashScope
  - 文本对话: `qwen3-omni-flash`
  - 语音实时通话: `qwen3.5-omni-plus-realtime`
- **实时通信**: websockets (Python), web_socket_channel (Flutter)

---

## 常用命令

```bash
# === 后端 ===
cd backend

# 安装依赖
pip install -r requirements.txt

# 开发启动
uvicorn main:app --reload --host 0.0.0.0 --port 8002

# 运行测试
pytest tests/ -v

# 运行单个测试
pytest tests/test_auth.py -v


# === Flutter ===
cd health_xiaohe

# 依赖
flutter pub get

# Web 运行
flutter run -d chrome

# Web 构建
flutter build web

# 运行测试
flutter test

# 代码分析
flutter analyze


# === Git ===
# 查看提交历史
git log --oneline -10
```
