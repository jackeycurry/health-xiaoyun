<script setup lang="ts">
import { onMounted, onUnmounted, ref } from "vue";

interface Memory {
  text: string;
  category: string;
  /** angle in degrees from center, 0 = right */
  angle: number;
  /** distance from center, 0-1 (1 = edge of garden) */
  dist: number;
  importance: number;
}

const memories: Memory[] = [
  { text: "晚睡 · 平均 1:30 才入睡",        category: "sleep",    angle: -82, dist: 0.85, importance: 0.9 },
  { text: "对牛奶不耐受",                    category: "diet",     angle: -38, dist: 0.92, importance: 0.6 },
  { text: "下雨前膝盖会酸",                  category: "body",     angle: 12,  dist: 0.78, importance: 0.7 },
  { text: '压力大时你说"累"\n而不是"焦虑"',   category: "language", angle: 48,  dist: 0.95, importance: 0.85 },
  { text: "上次体检 118/76",                category: "vital",    angle: 100, dist: 0.7,  importance: 0.5 },
  { text: "不爱吃药 · 倾向食疗",             category: "habit",    angle: 145, dist: 0.88, importance: 0.65 },
  { text: "对花生过敏",                      category: "allergy",  angle: -170,dist: 0.82, importance: 0.95 },
  { text: "周末偶尔跑 5km",                  category: "habit",    angle: -130,dist: 0.78, importance: 0.55 },
  { text: "经期前情绪低 · 第 21-25 天",       category: "cycle",    angle: 175, dist: 0.62, importance: 0.7 },
];

function nodePosition(m: Memory) {
  // canvas 1000x680, center at 500,340
  const cx = 500, cy = 340;
  const rx = 420 * m.dist;
  const ry = 280 * m.dist;
  const rad = (m.angle * Math.PI) / 180;
  return {
    x: cx + Math.cos(rad) * rx,
    y: cy + Math.sin(rad) * ry,
  };
}

function curvePath(m: Memory) {
  const { x, y } = nodePosition(m);
  // curved branch from center (500, 340) to node, with a control point biased outward
  const mx = (500 + x) / 2 + Math.cos(((m.angle + 30) * Math.PI) / 180) * 60;
  const my = (340 + y) / 2 + Math.sin(((m.angle + 30) * Math.PI) / 180) * 60;
  return `M 500 340 Q ${mx.toFixed(1)} ${my.toFixed(1)}, ${x.toFixed(1)} ${y.toFixed(1)}`;
}

const sentinel = ref<HTMLElement | null>(null);
const isAlive = ref(false);
let io: IntersectionObserver | null = null;

onMounted(() => {
  io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          isAlive.value = true;
          io?.disconnect();
        }
      });
    },
    { threshold: 0.3 }
  );
  if (sentinel.value) io.observe(sentinel.value);
});
onUnmounted(() => io?.disconnect());
</script>

<template>
  <section ref="sentinel" class="garden section">
    <div class="aura ambient" aria-hidden="true"></div>

    <div class="section-inner">
      <header class="head reveal">
        <p class="eyebrow">No. 03 — Long-term memory</p>
        <h2 class="display display-l">
          她会慢慢长出<br />
          <em>对你的理解</em>
        </h2>
        <p class="muted lede">
          每次对话，她都在悄悄记下一些事实。<br />
          不是聊天记录 —— 是关于你这个人的、慢慢厚起来的笔记。
        </p>
      </header>

      <!-- the garden canvas -->
      <div class="canvas" :class="{ alive: isAlive }">
        <svg
          class="branches"
          viewBox="0 0 1000 680"
          preserveAspectRatio="xMidYMid meet"
          aria-hidden="true"
        >
          <defs>
            <radialGradient id="centerG" cx="50%" cy="50%" r="50%">
              <stop offset="0%"  stop-color="#F4C5B0" />
              <stop offset="55%" stop-color="#A8D8C5" />
              <stop offset="100%" stop-color="#6B8F7A" />
            </radialGradient>
            <filter id="grain" x="0" y="0" width="100%" height="100%">
              <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" />
              <feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.08 0" />
              <feComposite in2="SourceGraphic" operator="in" />
            </filter>
          </defs>

          <!-- branches: dashed paths that draw themselves -->
          <path
            v-for="(m, i) in memories"
            :key="`p-${i}`"
            class="branch"
            :d="curvePath(m)"
            :style="{ '--len': '600px', '--delay': `${0.3 + i * 0.12}s` }"
          />

          <!-- center bloom -->
          <circle cx="500" cy="340" r="46" fill="url(#centerG)" class="core-shadow" />
          <circle cx="500" cy="340" r="38" fill="url(#centerG)" class="core" />
          <text x="500" y="346" text-anchor="middle" class="core-text">你</text>
        </svg>

        <!-- memory nodes overlaid -->
        <div
          v-for="(m, i) in memories"
          :key="`n-${i}`"
          class="node"
          :class="`cat-${m.category}`"
          :style="{
            left:  `${(nodePosition(m).x / 1000) * 100}%`,
            top:   `${(nodePosition(m).y / 680)  * 100}%`,
            '--delay': `${0.65 + i * 0.12}s`,
            '--imp':   m.importance,
          }"
        >
          <span class="node-cat">{{ m.category }}</span>
          <span class="node-text">{{ m.text }}</span>
        </div>
      </div>

      <!-- caption + legend -->
      <div class="caption reveal">
        <div>
          <span class="cap-num">9</span>
          <span class="cap-label">条记忆 · 来自最近 12 次对话</span>
        </div>
        <div class="legend">
          <span><i class="dot sleep"></i>sleep</span>
          <span><i class="dot diet"></i>diet</span>
          <span><i class="dot body"></i>body</span>
          <span><i class="dot vital"></i>vital</span>
          <span><i class="dot language"></i>language</span>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.garden {
  position: relative;
  overflow: hidden;
}

.ambient {
  width: 50vmax; height: 50vmax;
  bottom: -20vmax; left: -10vmax;
  background: radial-gradient(closest-side, var(--cream), transparent 70%);
  opacity: 0.5;
}

.head {
  max-width: 38rem;
  margin-bottom: 4rem;
}
.head h2 { margin: 1.5rem 0 1.8rem; }
.head em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--apricot), var(--sage-deep));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede {
  font-size: var(--t-body-l);
  max-width: 32rem;
}

.canvas {
  position: relative;
  width: 100%;
  aspect-ratio: 1000 / 680;
  max-width: 1100px;
  margin: 2rem auto 4rem;
}

.branches {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

/* dashed branch animation — pen-draws on reveal */
.branch {
  fill: none;
  stroke: var(--sage-deep);
  stroke-width: 1.4;
  stroke-linecap: round;
  stroke-dasharray: 800;
  stroke-dashoffset: 800;
  opacity: 0.6;
  transition: stroke-dashoffset 1.8s cubic-bezier(0.22, 1, 0.36, 1);
  transition-delay: var(--delay);
}

.canvas.alive .branch {
  stroke-dashoffset: 0;
}

.core, .core-shadow {
  transform-box: fill-box;
  transform-origin: center;
}
.core-shadow {
  opacity: 0.35;
  filter: blur(14px);
  animation: bloom 6s ease-in-out infinite alternate;
}
.core {
  animation: bloom 4.5s ease-in-out infinite alternate-reverse;
}

@keyframes bloom {
  0%   { transform: scale(0.94); }
  100% { transform: scale(1.08); }
}

.core-text {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100;
  font-size: 24px;
  font-weight: 400;
  fill: var(--bone);
  letter-spacing: 0.02em;
}

/* memory nodes — small bubbles tagged with category */
.node {
  position: absolute;
  transform: translate(-50%, -50%) scale(0.6);
  padding: 0.7rem 0.95rem;
  background: var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.25);
  border-radius: var(--bubble-3);
  box-shadow: 0 16px 40px -20px rgba(42, 61, 53, 0.15);
  font-size: 0.85rem;
  line-height: 1.4;
  color: var(--ink);
  max-width: 14rem;
  text-align: left;
  opacity: 0;
  white-space: pre-line;
  transition:
    transform 1.2s cubic-bezier(0.22, 1, 0.36, 1),
    opacity 0.8s ease;
  transition-delay: var(--delay);
  animation: float-node 9s ease-in-out infinite alternate;
  animation-delay: var(--delay);
}

.canvas.alive .node {
  transform: translate(-50%, -50%) scale(1);
  opacity: calc(0.7 + var(--imp, 0.5) * 0.3);
}

@keyframes float-node {
  0%   { translate: 0    0;   }
  50%  { translate: 0  -6px;  }
  100% { translate: 2px 4px;  }
}

.node-cat {
  display: block;
  font-size: var(--t-micro);
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  margin-bottom: 0.2rem;
}
.node-text {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 18, 'SOFT' 80;
  font-size: 0.96rem;
  color: var(--ink);
}

/* category color hints (small inner glow on top edge) */
.node.cat-sleep    { box-shadow: inset 0 1px 0 var(--sage-deep),    0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-diet     { box-shadow: inset 0 1px 0 var(--apricot),      0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-body     { box-shadow: inset 0 1px 0 var(--rose),         0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-vital    { box-shadow: inset 0 1px 0 var(--cream),        0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-language { box-shadow: inset 0 1px 0 #B8A8E0,             0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-allergy  { box-shadow: inset 0 1px 0 var(--rose),         0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-habit    { box-shadow: inset 0 1px 0 var(--sage),         0 16px 40px -20px rgba(42, 61, 53, 0.15); }
.node.cat-cycle    { box-shadow: inset 0 1px 0 #E8B8B0,             0 16px 40px -20px rgba(42, 61, 53, 0.15); }

/* caption */
.caption {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 1.5rem;
  padding-top: 2rem;
  border-top: 1px solid var(--ink-whisper);
}

.cap-num {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 144, 'SOFT' 100;
  font-size: 3rem;
  line-height: 1;
  color: var(--sage-deep);
  margin-right: 1rem;
}
.cap-label {
  font-size: var(--t-small);
  color: var(--ink-soft);
}

.legend {
  display: flex;
  gap: 1.2rem;
  flex-wrap: wrap;
  font-size: var(--t-small);
  color: var(--ink-quiet);
}
.legend span { display: inline-flex; align-items: center; gap: 0.4rem; }
.legend .dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  display: inline-block;
}
.dot.sleep    { background: var(--sage-deep); }
.dot.diet     { background: var(--apricot); }
.dot.body     { background: var(--rose); }
.dot.vital    { background: var(--cream); border: 1px solid var(--ink-whisper); }
.dot.language { background: #B8A8E0; }

@media (max-width: 800px) {
  .canvas { aspect-ratio: 1; }
  .node {
    font-size: 0.72rem;
    padding: 0.45rem 0.6rem;
    max-width: 9rem;
  }
  .node-text { font-size: 0.78rem; }
}
</style>
