# xiaohe-web

健康小云的 web 落地页 — 温柔生物形态，5 屏滚动叙事。

## 设计意图

不做 SaaS 蓝绿，不做 ChatGPT 终端，不用 Inter / Space Grotesk。整个页面是一只"会呼吸的云"，从巨大的有机 blob 一路走到一颗鹅卵石 CTA。

**美学锚点**

- 调色：温热米白 `#F8F4ED` + 鼠尾草薄荷 `#A8D8C5` + 杏粉 `#F4C5B0` + 墨绿文字 `#2A3D35`
- 字体：**Fraunces** (variable, `SOFT=100`) 配 **Noto Serif SC** 做标题；**Sora** 圆润无衬线配 **Noto Sans SC** 做正文
- 形态：所有圆都不是正圆 — 用 `border-radius: 63% 37% 54% 46% / 55% 48% 52% 45%` 这种非对称值，在 4 个形态间慢慢呼吸
- 全局：SVG turbulence 纸张噪点 + 自定义双层光标（精准点 + 慢追环）+ 右侧滚动茎 stem

## 5 屏叙事

| # | Section | 灵魂 |
|---|---|---|
| 01 | `HeroBreath` | 三层重叠 blob + 字符级 staggered 入场 + 鼠标 distortion |
| 02 | `ConversationDemo` | 漂浮对话气泡（旋转角度各异）+ 真打字机 + AI 续问 |
| 03 | `MemoryGarden` | SVG 记忆根系，9 条来自真实业务的事实节点（晚睡 / 不耐受 / 下雨膝盖酸 …） |
| 04 | `HealthBlooms` | 4 个不同形态的有机花瓣卡片承载健康指标 + sparkline |
| 05 | `CallToBloom` | 巨型鹅卵石 CTA，hover 时变形 |

## 跑起来

```bash
cd xiaohe-web
npm install
npm run dev      # http://localhost:5180
```

需要 Node ≥ 20。字体走 Google Fonts CDN，首次加载约 200ms 内可见。

## 文件地图

```
xiaohe-web/
├── index.html              # Google Fonts preconnect + Fraunces / Sora / Noto
├── vite.config.ts          # 端口 5180，启动自动打开 Chrome
├── src/
│   ├── main.ts
│   ├── App.vue             # 5 段 + cursor + scroll stem 编排
│   ├── styles/
│   │   ├── reset.css       # box-sizing, ::selection
│   │   ├── tokens.css      # 所有颜色 / 字号 / 不对称 border-radius
│   │   └── global.css      # cursor / stem / aura / reveal-on-scroll
│   └── components/
│       ├── HeroBreath.vue
│       ├── ConversationDemo.vue
│       ├── MemoryGarden.vue
│       ├── HealthBlooms.vue
│       └── CallToBloom.vue
```

## 不接真后端

这一版只画 landing。后端字段（`/api/consult/chat/stream` 流式、`/api/user/profile` 画像 / 长期记忆、`/api/health/records/latest` 健康记录）都已经在视觉上呈现，但走的是 **静态 mock**：

- 打字机字符串硬编码在 `ConversationDemo.vue`
- 9 条记忆节点是 `MemoryGarden.vue` 里的常量数组
- 4 个健康花瓣的数据在 `HealthBlooms.vue`

若要对接 8002 后端，从 `HeroBreath` 之外的 4 个组件入手 — 每个组件里 mock 数组的形状已经和后端 schema 对齐，替换成 `fetch('/api/...')` 即可。

## 性能 / 兼容性注记

- 自定义光标在 ≤768px 自动禁用（mobile 用原生触摸）
- 滚动揭示用 `IntersectionObserver`，不堆 JS 监听
- 所有 blob 动效是 CSS `border-radius` 关键帧 + `transform` —— 没引入 GSAP / Motion，bundle 极小
- Fraunces variable axis 走 CSS `font-variation-settings: 'opsz', 'SOFT'`，单文件搞定多重量级
