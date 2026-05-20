<script setup lang="ts">
import { computed } from "vue";

interface Bloom {
  label: string;
  caption: string;
  value: string;
  unit: string;
  status: string;
  statusTone: "calm" | "watch" | "good";
  series: number[];
  /** flower tint */
  hue: "sage" | "apricot" | "cream" | "rose";
  shape: number; // pick bubble-1..4
  rotate: number;
}

const blooms: Bloom[] = [
  {
    label: "血压",
    caption: "Blood pressure · 7d avg",
    value: "118/76",
    unit: "mmHg",
    status: "稳",
    statusTone: "good",
    series: [120, 118, 122, 116, 118, 119, 118],
    hue: "sage",
    shape: 1,
    rotate: -3,
  },
  {
    label: "心率",
    caption: "Resting heart rate",
    value: "67",
    unit: "bpm",
    status: "略偏低 · 你训练量上来了",
    statusTone: "calm",
    series: [72, 70, 69, 68, 67, 67, 67],
    hue: "apricot",
    shape: 2,
    rotate: 2,
  },
  {
    label: "睡眠",
    caption: "Sleep · last night",
    value: "6h 12m",
    unit: "深睡 1h28m",
    status: "想再多睡 40 分钟吗？",
    statusTone: "watch",
    series: [7.2, 6.8, 5.5, 6.0, 6.3, 5.8, 6.2],
    hue: "cream",
    shape: 3,
    rotate: -2,
  },
  {
    label: "情绪",
    caption: "Mood · this week",
    value: "平 · 略累",
    unit: "self-reported",
    status: "周三 / 周五 写到 \"累\"",
    statusTone: "watch",
    series: [3.5, 3.2, 2.8, 3.0, 2.5, 3.6, 3.1],
    hue: "rose",
    shape: 4,
    rotate: 4,
  },
];

function spark(series: number[]) {
  const w = 120;
  const h = 40;
  const min = Math.min(...series);
  const max = Math.max(...series);
  const range = max - min || 1;
  const step = w / (series.length - 1);
  return series
    .map((v, i) => {
      const x = (i * step).toFixed(1);
      const y = (h - ((v - min) / range) * h).toFixed(1);
      return `${i === 0 ? "M" : "L"} ${x} ${y}`;
    })
    .join(" ");
}

const today = computed(() => {
  const d = new Date();
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, "0")}.${String(d.getDate()).padStart(2, "0")}`;
});
</script>

<template>
  <section class="blooms section">
    <div class="aura ambient" aria-hidden="true"></div>

    <div class="section-inner">
      <header class="head reveal">
        <p class="eyebrow">No. 04 — Data, as language</p>
        <h2 class="display display-l">
          数据不只是数字 ——<br />
          <em>是身体的语言</em>
        </h2>
        <p class="muted lede">
          硬邦邦的图表不会让人想多看一眼。<br />
          我们把你的指标长成花的样子。
        </p>
      </header>

      <div class="garden">
        <article
          v-for="(b, i) in blooms"
          :key="b.label"
          class="bloom reveal"
          :class="[`hue-${b.hue}`, `shape-${b.shape}`]"
          :style="{ '--rot': `${b.rotate}deg`, '--d': `${0.1 + i * 0.12}s` }"
        >
          <div class="petal-bg" aria-hidden="true"></div>

          <header class="bloom-head">
            <div>
              <span class="bloom-label">{{ b.label }}</span>
              <span class="bloom-caption">{{ b.caption }}</span>
            </div>
            <span class="bloom-status" :class="`tone-${b.statusTone}`">
              {{ b.status }}
            </span>
          </header>

          <div class="bloom-figure">
            <span class="figure">{{ b.value }}</span>
            <span class="unit">{{ b.unit }}</span>
          </div>

          <div class="spark">
            <svg viewBox="0 0 120 40" preserveAspectRatio="none">
              <path :d="spark(b.series)" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" />
              <circle
                :cx="120" :cy="40 - ((b.series[b.series.length-1] - Math.min(...b.series)) / (Math.max(...b.series) - Math.min(...b.series) || 1)) * 40"
                r="2.5" fill="currentColor"
              />
            </svg>
            <span class="spark-days">7 天</span>
          </div>
        </article>
      </div>

      <!-- timestamp + note -->
      <div class="signature reveal">
        <span class="vrl">小云于 {{ today }} · 为你记</span>
        <p class="muted note">
          所有数据都属于你 ——<br />
          除非你主动同步给医生，否则连小云的工程师也看不到。
        </p>
      </div>
    </div>
  </section>
</template>

<style scoped>
.blooms {
  position: relative;
  overflow: hidden;
}

.ambient {
  width: 50vmax; height: 50vmax;
  top: -20vmax; right: -20vmax;
  background: radial-gradient(closest-side, var(--apricot-soft), transparent 70%);
  opacity: 0.45;
}

.head { max-width: 38rem; margin-bottom: 5rem; }
.head h2 { margin: 1.5rem 0 1.8rem; }
.head em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--rose));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede { font-size: var(--t-body-l); max-width: 30rem; }

/* the garden — 4 blooms in a loose grid */
.garden {
  display: grid;
  grid-template-columns: 1.05fr 0.95fr;
  gap: clamp(1.5rem, 3vw, 3rem);
  margin-bottom: 6rem;
}

.bloom {
  position: relative;
  padding: 2rem 2rem 1.8rem;
  background: var(--bone);
  border-radius: var(--bubble-1);
  transition: transform 1.2s cubic-bezier(0.22, 1, 0.36, 1), border-radius 8s ease-in-out infinite alternate;
  transition-delay: var(--d);
  transform: rotate(var(--rot));
  isolation: isolate;
  min-height: 16rem;
  box-shadow: var(--shadow-soft);
  overflow: hidden;
}

.bloom:hover {
  transform: rotate(0) translateY(-6px) scale(1.015);
}

.shape-1 { border-radius: var(--bubble-1); }
.shape-2 { border-radius: var(--bubble-2); }
.shape-3 { border-radius: var(--bubble-3); }
.shape-4 { border-radius: var(--bubble-4); }

/* color hues */
.hue-sage    { color: var(--sage-deep); }
.hue-apricot { color: #B86F4E; }
.hue-cream   { color: #9D7B2E; }
.hue-rose    { color: #B5645B; }

.petal-bg {
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: inherit;
  opacity: 0.45;
  animation: petal-shift 14s ease-in-out infinite alternate;
}

.hue-sage    .petal-bg { background: radial-gradient(ellipse at 30% 70%, var(--sage-soft) 0%, var(--bone) 70%); }
.hue-apricot .petal-bg { background: radial-gradient(ellipse at 70% 40%, var(--apricot-soft) 0%, var(--bone) 70%); }
.hue-cream   .petal-bg { background: radial-gradient(ellipse at 60% 30%, var(--cream) 0%, var(--bone) 70%); }
.hue-rose    .petal-bg { background: radial-gradient(ellipse at 30% 80%, var(--rose) -10%, var(--bone) 70%); }

@keyframes petal-shift {
  0%   { transform: scale(1)    rotate(0deg); }
  100% { transform: scale(1.15) rotate(8deg); }
}

.bloom-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 1.8rem;
}

.bloom-label {
  display: block;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100;
  font-size: 1.5rem;
  font-weight: 450;
  color: var(--ink);
  margin-bottom: 0.15rem;
}

.bloom-caption {
  font-size: var(--t-micro);
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--ink-quiet);
}

.bloom-status {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 14, 'SOFT' 100;
  font-style: italic;
  font-size: 0.85rem;
  color: currentColor;
  text-align: right;
  max-width: 14rem;
  line-height: 1.4;
}

.bloom-figure {
  display: flex;
  align-items: baseline;
  gap: 0.8rem;
  margin-bottom: 2rem;
}

.figure {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 144, 'SOFT' 80, 'wght' 350;
  font-size: clamp(2.6rem, 5vw, 4rem);
  line-height: 1;
  letter-spacing: -0.03em;
  color: var(--ink);
}

.unit {
  font-size: 0.85rem;
  color: var(--ink-soft);
}

.spark {
  display: flex;
  align-items: center;
  gap: 1rem;
  color: currentColor;
}

.spark svg {
  width: 120px;
  height: 40px;
  flex-shrink: 0;
}

.spark-days {
  font-size: var(--t-micro);
  letter-spacing: 0.3em;
  text-transform: uppercase;
  color: var(--ink-quiet);
}

/* status tones */
.tone-good  { color: var(--sage-deep); }
.tone-calm  { color: var(--ink-soft); }
.tone-watch { color: #B86F4E; }

/* signature row */
.signature {
  display: flex;
  align-items: center;
  gap: 3rem;
  padding-top: 3rem;
  border-top: 1px solid var(--ink-whisper);
}

.signature .vrl {
  flex-shrink: 0;
  height: 8rem;
}

.note {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 18, 'SOFT' 100;
  font-style: italic;
  font-size: 1.05rem;
  color: var(--ink-soft);
  line-height: 1.6;
}

@media (max-width: 800px) {
  .garden { grid-template-columns: 1fr; }
  .bloom { transform: none; min-height: 0; }
  .bloom:hover { transform: translateY(-4px); }
  .signature { flex-direction: column; align-items: flex-start; gap: 1.5rem; }
  .signature .vrl { height: auto; writing-mode: horizontal-tb; }
}
</style>
