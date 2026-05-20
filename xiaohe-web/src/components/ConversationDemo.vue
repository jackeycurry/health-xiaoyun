<script setup lang="ts">
import { onMounted, onUnmounted, ref } from "vue";

const finalText = "听起来更像紧张性头痛 — 你昨晚 1:40 才睡，这周睡眠加起来不到 30 小时。先放下手机，闭眼五分钟，喝一杯温水。如果两小时后没缓解，我们再细看。";
const typed = ref("");
const isTyping = ref(false);
const sentinel = ref<HTMLElement | null>(null);

let io: IntersectionObserver | null = null;
let timer: number | null = null;

function startTyping() {
  if (isTyping.value) return;
  isTyping.value = true;
  let i = 0;
  const step = () => {
    if (i >= finalText.length) {
      isTyping.value = false;
      return;
    }
    typed.value = finalText.slice(0, ++i);
    // variable delay — feels like real streaming
    const delay = 32 + Math.random() * 38;
    timer = window.setTimeout(step, delay);
  };
  step();
}

onMounted(() => {
  io = new IntersectionObserver(
    (entries) => {
      for (const e of entries) {
        if (e.isIntersecting) {
          startTyping();
          io?.disconnect();
        }
      }
    },
    { threshold: 0.45 }
  );
  if (sentinel.value) io.observe(sentinel.value);
});

onUnmounted(() => {
  io?.disconnect();
  if (timer) clearTimeout(timer);
});
</script>

<template>
  <section class="convo section" ref="sentinel">
    <div class="aura ambient-1" aria-hidden="true"></div>

    <div class="section-inner">
      <header class="head reveal">
        <p class="eyebrow">No. 02 — Conversation, not chat</p>
        <h2 class="display display-l">
          她会记得<br />
          <em>你的小毛病</em>
        </h2>
        <p class="muted lede">
          流式回复，像一个真正在听你说话的人。<br />
          不是问答机器，是一只能续上昨天对话的云。
        </p>
      </header>

      <!-- floating conversation cluster -->
      <div class="cluster">
        <!-- decorative satellite blob -->
        <div class="satellite" aria-hidden="true"></div>

        <article class="bubble bubble-user b1 reveal" style="--d:0.05s">
          <div class="role">你 · 周二 14:21</div>
          <p>最近老是头疼，三天了，下午尤其严重</p>
        </article>

        <article class="bubble bubble-ai b2 reveal" style="--d:0.20s">
          <div class="role">小云</div>
          <p>嗯，可以详细告诉我吗？是闷痛还是胀痛？除了头疼还有别的感觉吗？</p>
        </article>

        <article class="bubble bubble-user b3 reveal" style="--d:0.35s">
          <div class="role">你</div>
          <p>胀胀的，眼睛也酸</p>
        </article>

        <article class="bubble bubble-ai b4 reveal" style="--d:0.50s">
          <div class="role">
            小云
            <span class="streaming" v-if="isTyping">
              <span class="bar"></span><span class="bar"></span><span class="bar"></span>
            </span>
          </div>
          <p class="typed">
            {{ typed }}<span class="caret" v-if="isTyping">▍</span>
          </p>
          <div class="suggest" v-if="!isTyping">
            <span class="suggest-label">↳ 你可能还想问</span>
            <button data-hover>头疼多久要去医院？</button>
            <button data-hover>枕头要怎么挑？</button>
            <button data-hover>试试拉伸？</button>
          </div>
        </article>
      </div>

      <!-- under-cluster diagnostics row, kept quiet & technical -->
      <div class="diag reveal">
        <div class="diag-cell">
          <span class="diag-k">Streaming</span>
          <span class="diag-v">SSE · chunk-by-chunk</span>
        </div>
        <div class="diag-cell">
          <span class="diag-k">Context</span>
          <span class="diag-v">conversation_id · 续聊</span>
        </div>
        <div class="diag-cell">
          <span class="diag-k">After</span>
          <span class="diag-v">AI 自动生成对话标题</span>
        </div>
        <div class="diag-cell">
          <span class="diag-k">Then</span>
          <span class="diag-v">事实抽入长期记忆</span>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.convo {
  position: relative;
  overflow: hidden;
  isolation: isolate;
}

.ambient-1 {
  width: 30vmax; height: 30vmax;
  top: 10%; right: -12vmax;
  background: radial-gradient(closest-side, var(--sage-soft), transparent 70%);
  opacity: 0.5;
}

.head {
  max-width: 38rem;
  margin-bottom: 6rem;
}

.head h2 {
  margin: 1.5rem 0 1.8rem;
}

.head em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--apricot));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.lede {
  font-size: var(--t-body-l);
  max-width: 30rem;
}

/* the floating cluster — overlapping bubbles in a loose composition */
.cluster {
  position: relative;
  min-height: 36rem;
  margin-bottom: 5rem;
}

.satellite {
  position: absolute;
  right: 6%;
  top: -2rem;
  width: 14rem;
  height: 14rem;
  border-radius: var(--bubble-2);
  background: radial-gradient(closest-side, var(--apricot) 0%, var(--apricot-soft) 60%, transparent 78%);
  opacity: 0.7;
  filter: blur(8px);
  animation: morph 18s ease-in-out infinite alternate, drift 22s ease-in-out infinite alternate-reverse;
  z-index: 0;
}

@keyframes morph {
  0%   { border-radius: var(--bubble-1); }
  33%  { border-radius: var(--bubble-2); }
  66%  { border-radius: var(--bubble-3); }
  100% { border-radius: var(--bubble-1); }
}

.bubble {
  position: absolute;
  padding: 1.4rem 1.6rem 1.5rem;
  max-width: 22rem;
  box-shadow: var(--shadow-soft);
  z-index: 1;
  transition-delay: var(--d);
  transform-origin: center;
}

.bubble .role {
  font-size: var(--t-micro);
  letter-spacing: 0.24em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  margin-bottom: 0.6rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.bubble p {
  font-size: 1.05rem;
  line-height: 1.65;
  color: var(--ink);
}

/* user bubbles — warmer, smaller */
.bubble-user {
  background: var(--bone-deep);
  color: var(--ink);
  border-radius: var(--bubble-2);
  border: 1px solid rgba(42, 61, 53, 0.06);
}

/* AI bubbles — sage-tinted, slightly larger */
.bubble-ai {
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.7), rgba(168, 216, 197, 0.18)),
    var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.18);
  border-radius: var(--bubble-3);
  backdrop-filter: blur(6px);
}

/* loose positioning — break the grid */
.b1 { top: 0;    left: 4%;  transform: rotate(-1.5deg); }
.b2 { top: 7rem; left: 28%; max-width: 26rem; transform: rotate(0.8deg); }
.b3 { top: 18rem; left: 6%; max-width: 16rem; transform: rotate(-2deg); }
.b4 {
  top: 14rem;
  right: 4%;
  max-width: 30rem;
  transform: rotate(1.2deg);
  z-index: 2;
}

/* streaming indicator bars */
.streaming {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  margin-left: 0.7rem;
}
.streaming .bar {
  width: 3px;
  height: 9px;
  background: var(--sage-deep);
  border-radius: 2px;
  animation: pulse 1.2s ease-in-out infinite;
}
.streaming .bar:nth-child(2) { animation-delay: 0.15s; }
.streaming .bar:nth-child(3) { animation-delay: 0.30s; }

@keyframes pulse {
  0%, 100% { transform: scaleY(0.5); opacity: 0.5; }
  50%      { transform: scaleY(1);   opacity: 1; }
}

.typed {
  min-height: 6.5rem;
}

.caret {
  display: inline-block;
  margin-left: 1px;
  color: var(--sage-deep);
  animation: blink 1s steps(2) infinite;
}
@keyframes blink {
  50% { opacity: 0; }
}

.suggest {
  margin-top: 1.2rem;
  padding-top: 1.2rem;
  border-top: 1px dashed rgba(107, 143, 122, 0.3);
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  align-items: center;
}

.suggest-label {
  width: 100%;
  font-size: var(--t-micro);
  letter-spacing: 0.2em;
  color: var(--ink-quiet);
  text-transform: uppercase;
  margin-bottom: 0.4rem;
}

.suggest button {
  font-family: var(--font-body);
  font-size: 0.88rem;
  padding: 0.45rem 0.95rem;
  background: rgba(168, 216, 197, 0.2);
  color: var(--sage-deep);
  border-radius: 999px;
  border: 1px solid rgba(107, 143, 122, 0.3);
  transition: all 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}
.suggest button:hover {
  background: var(--sage-deep);
  color: var(--bone);
  transform: translateY(-2px) rotate(-1deg);
  border-radius: var(--bubble-4);
}

/* diagnostics row */
.diag {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
  padding-top: 3rem;
  border-top: 1px solid var(--ink-whisper);
}

.diag-cell {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.diag-k {
  font-size: var(--t-micro);
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--ink-quiet);
}
.diag-v {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 60;
  font-size: 1.05rem;
  color: var(--ink);
}

@media (max-width: 900px) {
  .cluster { min-height: 0; display: flex; flex-direction: column; gap: 1.5rem; }
  .bubble { position: relative; top: auto !important; left: auto !important; right: auto !important; transform: rotate(0) !important; max-width: 100% !important; }
  .satellite { display: none; }
  .diag { grid-template-columns: 1fr 1fr; }
}
</style>
