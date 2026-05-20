# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

健康小云是一个AI健康助手应用，包含Flutter移动端、Vue 3 Web落地页和Python FastAPI后端。

## 技术栈

### Flutter App (health_xiaohe/)
- **状态管理**: flutter_bloc (BLoC pattern)
- **网络**: dio (HTTP), web_socket_channel (WebSocket)
- **依赖注入**: get_it
- **路由**: go_router
- **本地存储**: shared_preferences
- **Markdown渲染**: flutter_markdown
- **摄像头**: camera (Android), 浏览器 getUserMedia (Web)
- **文件系统**: path_provider

### Python Backend (backend/)
- **框架**: FastAPI + uvicorn
- **数据库**: PostgreSQL + SQLAlchemy (测试用SQLite)
- **认证**: JWT (python-jose + bcrypt)
- **AI模型**: 阿里云百炼 qwen3-omni-flash (文本), qwen3.5-omni-plus-realtime (语音实时通话)
- **实时通信**: websockets (语音通话桥接)

## 目录结构

```
app/
├── health_xiaohe/          # Flutter应用
│   └── lib/
│       ├── core/           # 基础设施: constants, network, storage, theme, audio, camera
│       ├── data/           # 数据层: models, repositories impl
│       ├── domain/         # 领域层: repositories接口(抽象)
│       ├── presentation/   # 表现层: blocs, pages, widgets, router
│       ├── app.dart        # 应用入口 widget (MultiBlocProvider)
│       ├── injection.dart  # 依赖注入配置 (get_it)
│       └── main.dart       # main函数
├── backend/               # Python后端 (git submodule，独立commit)
│   ├── models/            # SQLAlchemy模型 (User, HealthRecord, Conversation, Message, UserProfile, Memory)
│   ├── routers/           # API路由 (auth, health, consult, voice, user_profile)
│   ├── schemas/           # Pydantic schemas
│   ├── services/          # 业务逻辑 (auth_service, health_service, ai_service)
│   ├── utils/             # 工具函数 (security, deps)
│   ├── tests/             # pytest测试 (SQLite隔离)
│   ├── main.py            # FastAPI入口
│   ├── database.py        # 数据库配置 (SessionLocal, engine, Base)
│   └── config.py          # pydantic-settings, 从.env读取
├── xiaohe-web/            # Vue 3 Web落地页 (Vite + Vue 3 + TS + Pinia)
└── docs/                  # 项目文档
    ├── README.md           # 快速上手和常用命令
    ├── 架构说明.md         # Clean Architecture 分层详解
    ├── 语音通话实现.md     # DashScope Realtime 集成细节
    ├── 部署打包.md         # 构建、部署、测试
    └── design/             # 设计规范和原型
```

## 常用命令

### 一键启动（Windows）

```powershell
# 启动全部（后端 + Flutter）
.\start_dev.ps1

# 仅启动后端
.\start_dev.ps1 -Backend

# 仅启动前端
.\start_dev.ps1 -Frontend

# 启动前先安装依赖
.\start_dev.ps1 -Build
```

### Flutter
```bash
cd health_xiaohe

# 运行 (Web平台)
flutter run -d chrome

# 构建Web
flutter build web

# 代码分析
flutter analyze

# 运行测试
flutter test

# 运行单测试文件
flutter test test/widget_test.dart
```

### Backend（独立 git 仓库）

backend 是独立 submodule，需在 backend/ 目录内单独管理 git 操作。

```bash
cd backend

# 安装依赖
pip install -r requirements.txt

# 开发环境启动
uvicorn main:app --reload --host 0.0.0.0 --port 8002

# 生产环境启动
uvicorn main:app --host 0.0.0.0 --port 8002 --workers 4

# 运行测试 (自动使用SQLite隔离环境)
pytest tests/ -v

# 运行单测试文件
pytest tests/test_auth.py -v

# 查看 git 历史
git log --oneline -3
```

## 环境配置

Backend通过 `backend/.env` 文件配置，由 `config.py` 的 `pydantic-settings` 读取。需要配置的环境变量：

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `DATABASE_URL` | PostgreSQL连接字符串 | `postgresql://user:password@localhost:5432/health_app` |
| `SECRET_KEY` | JWT签名密钥 | 生产环境必须更改 |
| `DASHSCOPE_API_KEY` | 阿里云百炼API密钥 | `sk-xxxxxxxxxxxx` |
| `AI_MODEL` | 文本对话模型 | `qwen3-omni-flash` |

测试自动使用SQLite (`sqlite:///./test_isolated.db`)，无需额外配置。`conftest.py` 在导入前设置 `DATABASE_URL` 环境变量并覆盖数据库引擎。

## API端点

### 认证 (prefix: /api/auth)
- `POST /api/auth/register` - 用户注册 (phone + password)
- `POST /api/auth/login` - 用户登录，返回JWT token
- `GET /api/auth/me` - 获取当前用户信息

### 健康记录 (prefix: /api/health)
- `POST /api/health/records` - 创建健康记录
- `GET /api/health/records` - 获取记录列表 (支持record_type, limit, offset)
- `GET /api/health/records/latest` - 获取各类型最新记录
- `DELETE /api/health/records/{id}` - 删除记录

### AI咨询 (prefix: /api/consult)
- `POST /api/consult/chat` - AI对话 (非流式)
- `POST /api/consult/chat/stream` - AI对话 (SSE流式)
- `GET /api/consult/chat/history` - 获取对话历史 (已废弃，用conversations替代)
- `GET /api/consult/conversations` - 获取对话列表
- `GET /api/consult/conversations/{id}` - 获取对话详情(含消息列表)

### 语音通话 (prefix: /api/consult/voice)
- `POST /api/consult/voice/chat` - 单轮语音对话 (base64音频 → 文本回复)
- `POST /api/consult/voice/chat/stream` - 语音对话流式
- `WS /api/consult/voice/ws` - 实时语音通话WebSocket (需token参数认证)

## 架构说明

### Flutter Clean Architecture
- **core/**: 基础设施 — 常量(app_colors, app_spacing, app_strings)、网络客户端(api_client, websocket_client, sse_client)、本地存储、主题、音频录制/播放、摄像头采集
- **core/audio/**: 平台条件导入 — `*_stub.dart`(接口存根) / `*_web.dart`(浏览器) / `*_android.dart`(Android原生)
- **core/camera/**: 同上模式 — `camera_capture_base.dart`(抽象接口) + 平台实现
- **data/**: 数据模型(models)和仓库实现(repositories impl)
- **domain/**: 仓库接口定义(抽象)
- **presentation/**: BLoC状态管理 + UI页面 + 路由 + widgets

### BLoC 模块

| BLoC | 职责 |
|------|------|
| AuthBloc | 登录/注册/认证状态检查 |
| ChatBloc | AI对话，SSE流式接收 |
| ChatHistoryBloc | 对话列表加载和管理 |
| HealthBloc | 健康记录CRUD |
| VoiceBloc | 语音/视频通话状态、WebSocket连接管理、打断处理 |

每个BLoC模块包含 `*_bloc.dart` (逻辑)、`*_event.dart` (事件)、`*_state.dart` (状态)。

**VoiceBloc 关键状态流转**:
`VoiceInitial` → `VoiceConnecting` → `VoiceConnected`(就绪) → `VoiceListening`(用户说话) → `VoiceProcessingInput`(AI处理) → `VoiceReceivingText`/`VoiceReceivingAudio`(AI回复) → `VoiceDone` → `VoiceConnected`(循环)

**VoiceBloc 关键事件**: `VoiceConnect`, `VoiceDisconnect`, `VoiceSendAudioChunk`, `VoiceSendImageChunk`, `VoiceReceiveMessage`, `VoiceError`

### 流式输出架构 (SSE)

AI对话流式输出通过Flutter端的 `sse_client_web.dart` (web平台EventSource) 和 `sse_client_stub.dart` (非web平台存根) 实现。后端 `/api/consult/chat/stream` 使用FastAPI `StreamingResponse` 以SSE格式推送 `data: {json}\n\n` 块，最后发送 `data: [DONE]\n\n`。

### 语音通话架构

```
Flutter → WebSocket → /consult/voice/ws?token=xxx
       ↕ JSON消息 (type: audio / image / commit / ping / stop)
FastAPI voice.py → WebSocket桥接 → DashScope Realtime API (qwen3.5-omni-plus-realtime)
       ↕
DashScope → session.update → response.audio.delta / response.audio_transcript.delta / response.done
```

Flutter端 `VoiceBloc` 通过 `WebSocketClient` 管理连接。`AudioRecorder`/`AudioPlayer`/`CameraCapture` 均通过 Dart 条件导入实现平台适配:
- Web: `audio_recorder_web.dart` (AudioContext+PCM编码), `camera_capture_web.dart` (getUserMedia+Canvas JPEG)
- Android: `audio_recorder_android.dart`, `camera_capture_android.dart` (camera插件)
- Stub: 非支持平台的空实现

WebSocket消息类型:
- **Flutter→Backend**: `audio` (base64 PCM), `image` (base64 JPEG), `commit` (提交音频缓冲区), `ping` (15s心跳), `stop`
- **Backend→Flutter**: `connected` (含conversation_id), `text` (AI文本流), `audio` (AI音频delta), `speech_started` (用户打断), `speech_stopped` (用户说完), `user_text` (用户转录), `ai_text` (AI完整回复), `done`, `error`

**噪声门**: `AudioRecorderBase.gateOn()` 压低麦克风过滤环境噪音，`gateOff()` 恢复全量收音。AI说话时开启噪声门防止回声，用户说话时关闭。

**打断机制**: DashScope检测到用户语音 (`input_audio_buffer.speech_started`) → 后端发送 `response.cancel` 取消AI回复 → 通知Flutter `speech_started` → VoiceBloc进入 `VoiceListening` 状态 → 用户说完后 `speech_stopped` → 清除打断标志，处理新输入。

**视频通话**: 摄像头采集JPEG帧，通过 `VoiceSendImageChunk` 事件经WebSocket发送 `image` 类型消息到后端，后端转为 DashScope `input_image_buffer.append` 协议。DashScope要求先有音频数据才能接收图像。

**语音转录持久化**: `voice.py` 的 `_save_voice_message()` 在收到 `response.audio_transcript.done` (AI) 和 `conversation.item.input_audio_transcription.completed` (用户) 时自动保存转录文本到 Message 表。

### 对话持久化

`consult.py` 的 `_save_chat_messages()` 在每次AI回复后自动持久化。支持两种模式:
- **新对话**: 不传 `conversation_id`，自动创建Conversation
- **继续对话**: 传 `conversation_id`，追加新消息到已有对话

流式接口在生成完所有内容后，通过SSE返回 `conversation_id` 供前端后续使用。

## 路由与导航

Flutter使用 `go_router` 和 `ShellRoute` 实现底部导航栏:

```
/ (启动页) → /login (登录) → /chat (聊天首页)
                             ├── /ai-impression (AI画像+长期记忆，原/health-records)
                             ├── /chat-history (对话历史列表)
                             ├── /profile (个人中心)
                             ├── /call (语音通话)
                             └── /chat-history/:conversationId (对话详情)
```

底部导航栏4个tab: 咨询、画像、历史、我的。

## 设计规范

参考 `docs/design/健康小云App原型.html`:
- 品牌色: `#4ECDC4` (蓝绿)
- 辅助色: `#2D9CDB` (深蓝)
- 背景渐变: `#E8F8F7` → `#FFFFFF`
- 间距系统: 8pt网格

### 关键UI组件

| 组件 | 样式 |
|------|------|
| 顶部导航栏 | 72px, 品牌logo+标题+菜单按钮 |
| 消息气泡-AI | 左对齐, `#F0FAFB`背景, 圆角20px(左上4px) |
| 消息气泡-用户 | 右对齐, `#4ECDC4`背景, 白色文字 |
| 输入框 | 48px高, 圆角24px, `#F5F5F5`背景 |
| 快捷问题标签 | 圆角20px, `#E8F8F7`背景 |
| 记录卡片 | 圆角16px, 阴影, 状态标签(正常/偏高/危险) |

### API 端口
- 开发环境: `http://localhost:8002` (Flutter `ApiEndpoints.baseUrl` 和 uvicorn 默认端口一致)
- 模拟器环境: `http://192.168.1.84:8002` (Mumu模拟器通过WiFi连接宿主机局域网IP)

### xiaohe-web (Vue 3 Web落地页)

```bash
cd xiaohe-web
npm install
npm run dev        # http://localhost:5180
```

**已知 bug（修过的，不要再踩）：**

1. **reactive plain-object 闭包失效**：流式逐字更新时用 `const aiMsg = { content: "" }` push 后再闭包修改 `aiMsg.content += d` 不会触发 DOM 更新。必须用 `const aiMsg = reactive({...})` 包装后再 push。参考 `ChatPage.vue` 的 send()。

2. **Pinia computed 短路求值导致依赖追踪丢失**：`const isAuthed = computed(() => !!getToken() && !!user.value)` 中 `&&` 短路会导致 user 不进入 deps。修法：`user.value !== null && !!getToken()` 或先独立访问一次 user.value。

3. **Google Fonts variable axes 顺序**：必须是 `Fraunces:SOFT,ital,opsz,wght@...`，对，`ital,opsz,wght,SOFT@...` 返回 200 但 variable 轴静默失效。

**SSE 流式后端协议**：`POST /api/consult/chat/stream` 需要 `Authorization` header，不能用 EventSource（无法带 header），xiaohe-web 用 `fetch + ReadableStream`。

SSE 帧格式：`data: {json}\n\n`
- `{ content: "delta" }` — chunk
- `{ conversation_id: "..." }` — 持久化ID
- `{ suggestions: [...] }` — 建议问题
- 终止符：`data: [DONE]\n\n`
