# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

健康小荷是一个AI健康助手应用，包含Flutter移动端和Python FastAPI后端。

## 技术栈

### Flutter App (health_xiaohe/)
- **状态管理**: flutter_bloc (BLoC pattern)
- **网络**: dio (HTTP), web_socket_channel (WebSocket)
- **依赖注入**: get_it
- **路由**: go_router
- **本地存储**: shared_preferences

### Python Backend (backend/)
- **框架**: FastAPI + uvicorn
- **数据库**: PostgreSQL + SQLAlchemy
- **认证**: JWT (python-jose)
- **AI模型**: 阿里云百炼 qwen3-omni-flash

## 目录结构

```
app/
├── health_xiaohe/          # Flutter应用
│   └── lib/
│       ├── core/           # 核心模块 (constants, network, storage, theme)
│       ├── data/          # 数据层 (models, repositories impl)
│       ├── domain/        # 领域层 (repositories接口)
│       ├── presentation/  # 表现层 (blocs, pages, widgets)
│       ├── app.dart       # 应用入口 widget
│       ├── injection.dart # 依赖注入配置
│       └── main.dart      # main函数
├── backend/               # Python后端
│   ├── models/            # SQLAlchemy模型
│   ├── routers/           # API路由
│   ├── schemas/           # Pydantic schemas
│   ├── services/          # 业务逻辑
│   ├── utils/             # 工具函数
│   ├── main.py            # FastAPI入口
│   └── database.py        # 数据库配置
└── docs/                  # 设计文档
```

## 常用命令

### Flutter
```bash
cd health_xiaohe

# 运行
flutter run

# 构建Web
flutter build web

# 运行测试
flutter test

# 运行单测试文件
flutter test test/widget_test.dart
```

### Backend
```bash
cd backend

# 安装依赖
pip install -r requirements.txt

# 开发环境启动
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 生产环境启动
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4

# 运行测试
pytest tests/ -v
```

## API端点

### 认证 (prefix: /api/auth)
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/me` - 获取当前用户

### 健康记录 (prefix: /api/health)
- `POST /api/health/records` - 创建记录
- `GET /api/health/records` - 获取记录列表
- `GET /api/health/records/latest` - 获取最新记录
- `DELETE /api/health/records/{id}` - 删除记录

### AI咨询 (prefix: /api/consult)
- `POST /api/consult/chat` - AI对话
- `POST /api/consult/chat/stream` - AI对话(流式)
- `GET /api/consult/chat/history` - 获取历史

## 架构说明

### Flutter Clean Architecture
- **core/**: 基础设施常量、网络客户端、存储
- **data/**: 数据模型和仓库实现
- **domain/**: 仓库接口定义(抽象)
- **presentation/**: BLoC状态管理 + UI (pages/widgets)

### BLoC结构
每个功能模块包含:
- `*_bloc.dart` - 业务逻辑
- `*_event.dart` - 事件定义
- `*_state.dart` - 状态定义

## 设计规范

参考 `docs/design/健康小荷App原型.html` (手机模拟器原型):
- 品牌色: `#4ECDC4` (蓝绿)
- 辅助色: `#2D9CDB` (深蓝)
- 背景渐变: `#E8F8F7` → `#FFFFFF`
- 间距系统: 8pt网格

### 原型页面结构

```
启动页 → 登录页 → 聊天首页
                   ├── 侧边菜单 → 健康记录/历史记录/个人中心
                   ├── 语音通话页
                   └── 健康记录页(浮动添加按钮)
```

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
- 开发环境: `http://localhost:8002`
