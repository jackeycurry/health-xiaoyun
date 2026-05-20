# 健康小云 (health-xiaoyun)

AI 健康助手 — Flutter 移动端 + Python FastAPI 后端 + Vue 3 落地页

---

## 项目组成

| 模块 | 路径 | 技术栈 | 说明 |
|------|------|--------|------|
| Flutter App | `health_xiaohe/` | Flutter / BLoC / GoRouter | 文字对话 + 实时语音/视频通话 |
| Python Backend | `backend/` | FastAPI / SQLAlchemy / JWT | REST API + WebSocket 语音桥接 |
| Web Landing | `xiaohe-web/` | Vue 3 / Vite / Pinia | 温柔生物形态美学落地页 |

> **重要**: `backend/` 是 git submodule，修改后端代码时需在 `backend/` 目录内单独 commit/push，再回根仓库更新 submodule 指针。

---

## 技术栈

### Flutter App
- **状态管理**: flutter_bloc (BLoC Pattern)
- **网络**: dio (HTTP), web_socket_channel (WebSocket)
- **依赖注入**: get_it
- **路由**: go_router (ShellRoute 底部导航)
- **本地存储**: shared_preferences
- **AI**: 阿里云百炼 DashScope — `qwen3-omni-flash` (文本) / `qwen3.5-omni-plus-realtime` (实时语音)

### Python Backend
- **框架**: FastAPI + uvicorn
- **数据库**: PostgreSQL (生产) / SQLite (测试)
- **认证**: JWT (python-jose + bcrypt)
- **实时通信**: WebSocket (语音通话桥接)

### Vue 3 Web
- **框架**: Vue 3 + Vite + TypeScript + Pinia + vue-router
- **UI**: 自定义生物形态设计系统（不套用常见组件库）

---

## 快速启动

### 一键启动（推荐）

```powershell
# 同时启动后端 + Flutter Web (Chrome)
.\start_dev.ps1

# 仅后端 / 仅前端
.\start_dev.ps1 -Backend
.\start_dev.ps1 -Frontend

# 启动前先装依赖
.\start_dev.ps1 -Build
```

> 脚本依赖 `backend/.env`。后端跑在 `:8002`，端口冲突时自动跳过。

### 手动启动

**后端：**
```bash
cd backend
pip install -r requirements.txt
# 配置 .env (参考 backend/.env.example)
uvicorn main:app --reload --host 0.0.0.0 --port 8002
```

**Flutter Web：**
```bash
cd health_xiaohe
flutter pub get
flutter run -d chrome
```

**Vue 3 Web：**
```bash
cd xiaohe-web
npm install
npm run dev      # http://localhost:5180
```

---

## 环境配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `DATABASE_URL` | PostgreSQL 连接字符串 | `postgresql://user:password@localhost:5432/health_app` |
| `SECRET_KEY` | JWT 签名密钥 | **生产环境必须更改** |
| `DASHSCOPE_API_KEY` | 阿里云百炼 API 密钥 | `sk-xxxxxxxxxxxx` |
| `AI_MODEL` | 文本对话模型 | `qwen3-omni-flash` |

测试自动使用 SQLite (`sqlite:///./test_isolated.db`)，无需额外配置。

---

## API 文档

启动后访问：
- Swagger UI: `http://localhost:8002/docs`
- ReDoc: `http://localhost:8002/redoc`

### 认证 `/api/auth`
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 用户注册 (phone + password) |
| POST | `/api/auth/login` | 登录，返回 JWT token |
| GET | `/api/auth/me` | 获取当前用户信息 |

### 健康记录 `/api/health`
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/health/records` | 创建健康记录 |
| GET | `/api/health/records` | 获取记录列表 (支持 record_type / limit / offset) |
| GET | `/api/health/records/latest` | 获取各类型最新记录 |
| DELETE | `/api/health/records/{id}` | 删除记录 |

### AI 咨询 `/api/consult`
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/consult/chat` | AI 对话（非流式） |
| POST | `/api/consult/chat/stream` | AI 对话（SSE 流式） |
| GET | `/api/consult/conversations` | 获取对话列表 |
| GET | `/api/consult/conversations/{id}` | 获取对话详情（含消息列表） |

### 语音通话 `/api/consult/voice`
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/consult/voice/chat` | 单轮语音对话 (base64 音频 → 文本回复) |
| POST | `/api/consult/voice/chat/stream` | 语音对话流式 |
| WS | `/api/consult/voice/ws` | 实时语音通话 WebSocket（需 `?token=xxx`） |

### 用户画像 & 长期记忆 `/api/user`
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/user/profile` | 获取 UserProfile + Top 20 长期记忆 |
| PUT | `/api/user/profile` | 更新画像基本信息 |
| DELETE | `/api/user/memories/{memory_id}` | 删除单条长期记忆 |

---

## 项目结构

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
│       │   ├── audio/          # 平台音频录制/播放（条件导入）
│       │   └── camera/         # 平台摄像头采集（条件导入）
│       ├── data/               # 数据层：models + repositories 实现
│       ├── domain/             # 领域层：repositories 接口（抽象）
│       └── presentation/       # 表现层：BLoC / pages / widgets / router
│
├── backend/                    # Python 后端 (git submodule)
│   ├── models/                 # SQLAlchemy 模型
│   ├── routers/                # API 路由
│   ├── schemas/                # Pydantic schemas
│   ├── services/               # 业务逻辑
│   ├── utils/                  # 工具函数 (security / deps)
│   ├── tests/                  # pytest 测试 (SQLite 隔离)
│   ├── main.py                 # FastAPI 入口
│   ├── database.py             # SQLAlchemy 配置
│   └── config.py               # pydantic-settings 配置
│
├── xiaohe-web/                 # Vue 3 落地页
│   └── src/
│       ├── components/         # 5 屏叙事组件
│       ├── styles/             # tokens / reset / global CSS
│       └── App.vue             # 入口
│
├── docs/                       # 项目文档
│   ├── README.md               # 快速上手
│   ├── 架构说明.md             # Clean Architecture 分层详解
│   ├── 语音通话实现.md         # DashScope Realtime 集成细节
│   ├── 部署打包.md             # 构建、部署、测试
│   └── design/                 # 设计规范和原型
│
└── start_dev.ps1               # 一键启动脚本 (PowerShell)
```

---

## 架构说明

### Flutter Clean Architecture

- **core/**: 基础设施 — 网络客户端、存储、主题、音频、摄像头
- **core/audio/** & **core/camera/**: 平台条件导入模式
  - `*_stub.dart` — 接口存根
  - `*_web.dart` — 浏览器实现 (AudioContext / getUserMedia)
  - `*_android.dart` — Android 原生实现 (camera 插件)
- **data/**: 数据模型 + 仓库实现
- **domain/**: 仓库接口（抽象）
- **presentation/**: BLoC 状态管理 + UI

### BLoC 模块

| BLoC | 职责 |
|------|------|
| AuthBloc | 登录/注册/认证状态 |
| ChatBloc | AI 对话，SSE 流式接收 |
| ChatHistoryBloc | 对话列表加载管理 |
| HealthBloc | 健康记录 CRUD |
| VoiceBloc | 语音/视频通话状态、WebSocket 连接、打断处理 |

### 语音通话架构

```
Flutter → WebSocket → /consult/voice/ws?token=xxx
       ↕ JSON 消息 (type: audio / image / commit / ping / stop)
FastAPI voice.py → WebSocket 桥接 → DashScope Realtime API
       ↕
DashScope → session.update → response.audio.delta / transcript.done
```

**噪声门**: AI 说话时开启 `gateOn()` 压低麦克风防止回声，用户说话时 `gateOff()` 恢复。

**打断机制**: DashScope 检测到用户语音 → 后端 `response.cancel` 取消 AI 回复 → 通知 Flutter `speech_started` → 用户说完 `speech_stopped` → 清除打断标志处理新输入。

### 流式输出 (SSE)

后端 SSE 帧格式：`data: {json}\n\n`
- `{ content: "delta" }` — chunk
- `{ conversation_id: "..." }` — 持久化后告诉前端
- `{ suggestions: [...] }` — 跟问建议
- 终止符：`data: [DONE]\n\n`

---

## 设计规范

参考 `docs/design/健康小云App原型.html`：

| 元素 | 规范 |
|------|------|
| 品牌色 | `#4ECDC4` (蓝绿) |
| 辅助色 | `#2D9CDB` (深蓝) |
| 背景渐变 | `#E8F8F7` → `#FFFFFF` |
| 间距系统 | 8pt 网格 |
| 顶部导航栏 | 72px，品牌 logo + 标题 + 菜单按钮 |
| 消息气泡-AI | 左对齐，`#F0FAFB` 背景，圆角 20px（左上 4px）|
| 消息气泡-用户 | 右对齐，`#4ECDC4` 背景，白色文字 |
| 输入框 | 48px 高，圆角 24px，`#F5F5F5` 背景 |
| 记录卡片 | 圆角 16px，阴影，状态标签（正常/偏高/危险）|

---

## 常用命令

```bash
# === 后端 ===
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8002   # 开发
uvicorn main:app --host 0.0.0.0 --port 8002 --workers 4 # 生产
pytest tests/ -v                                          # 测试
pytest tests/test_auth.py -v                              # 单测试

# === Flutter ===
cd health_xiaohe
flutter pub get
flutter run -d chrome    # Web 调试
flutter build web       # Web 构建
flutter test            # 测试

# === Vue Web ===
cd xiaohe-web
npm install
npm run dev             # http://localhost:5180

# === 一键启动 ===
.\start_dev.ps1         # 后端 + Flutter
.\start_dev.ps1 -Backend  # 仅后端
.\start_dev.ps1 -Frontend # 仅前端
```

---

## 开发注意事项

### xiaohe-web Vue 3 踩坑

1. **流式消息响应式失效**: `const aiMsg = { content: "" }` 闭包持有原始对象，改属性不触发 DOM 更新。修法：`const aiMsg = reactive({...})` 显式包装后再 push。

2. **Pinia computed 短路求值**: `computed(() => !!getToken() && !!user.value)` — token 为 null 时 `&&` 短路，`user.value` 未被读取，deps 里没有 user，之后赋值也不触发重算。修法：reactive ref 放 `&&` 左边。

3. **Google Fonts variable axes 顺序**: `Fraunces:SOFT,ital,opsz,wght@...` 对，`ital,opsz,wght,SOFT@...` 返回 200 但 variable 轴失效，静默回退 fallback 字体。

4. **scoped style 不作用于 v-html**: 用 `:deep()` 或把样式放 `global.css`。

### Backend submodule

```bash
# 修改后端代码后
cd backend
git add . && git commit -m "fix: ..."
git push

# 回到根仓库更新 submodule 指针
cd ..
git add backend
git commit -m "chore: sync backend submodule"
git push
```