<script setup lang="ts">
import { ref } from "vue";

const hovering = ref(false);
</script>

<template>
  <section id="enter" class="enter section">
    <div class="aura ambient-1" aria-hidden="true"></div>
    <div class="aura ambient-2" aria-hidden="true"></div>

    <div class="section-inner">
      <div class="letter reveal">
        <div class="letter-head">
          <span class="eyebrow">No. 05 — Begin</span>
          <span class="vrl small">致 想被听见的你</span>
        </div>

        <h2 class="display display-xl">
          和小云<br />
          <em>开始一次</em><br />
          安静的对话
        </h2>

        <p class="muted lede">
          不用注册一长串信息。<br />
          一个手机号，一个昵称，就够她认得你。<br />
          后面的事，慢慢说。
        </p>

        <!-- the big CTA pebble -->
        <div class="cta-wrap">
          <button
            class="pebble"
            :class="{ hot: hovering }"
            @mouseenter="hovering = true"
            @mouseleave="hovering = false"
            data-hover
          >
            <span class="pebble-bg" aria-hidden="true"></span>
            <span class="pebble-bg pebble-bg-2" aria-hidden="true"></span>
            <span class="pebble-text">
              <span class="cta-zh">进入对话</span>
              <span class="cta-en italic-en">enter, softly →</span>
            </span>
          </button>

          <div class="promises">
            <div class="promise">
              <span class="promise-num">01</span>
              <span class="promise-text">手机号注册<br /><em>无需身份证 / 无需邀请码</em></span>
            </div>
            <div class="promise">
              <span class="promise-num">02</span>
              <span class="promise-text">数据只属于你<br /><em>本地存储 / 工程师看不到</em></span>
            </div>
            <div class="promise">
              <span class="promise-num">03</span>
              <span class="promise-text">不推送广告<br /><em>不卖你的健康数据</em></span>
            </div>
          </div>
        </div>

        <div class="alt">
          <span class="alt-or">或</span>
          <a class="alt-link" href="/docs" data-hover>先翻翻 API · 给开发者</a>
          <span class="alt-or">·</span>
          <a class="alt-link" href="/voice-test" data-hover>试听一段语音 demo</a>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.enter {
  position: relative;
  overflow: hidden;
  padding-bottom: 8rem;
}

.ambient-1 {
  width: 50vmax; height: 50vmax;
  bottom: -25vmax; right: -15vmax;
  background: radial-gradient(closest-side, var(--sage), transparent 70%);
  opacity: 0.55;
}
.ambient-2 {
  width: 28vmax; height: 28vmax;
  top: 10%; left: -8vmax;
  background: radial-gradient(closest-side, var(--apricot), transparent 70%);
  opacity: 0.45;
  animation-delay: -10s;
}

.letter {
  position: relative;
  max-width: 64rem;
  margin-inline: auto;
  text-align: left;
}

.letter-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 3rem;
}

.vrl.small {
  height: 5rem;
  font-size: var(--t-micro);
}

.letter h2 {
  margin-bottom: 2.5rem;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 300;
}

.letter h2 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--apricot), var(--sage-deep));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.lede {
  font-size: clamp(1.1rem, 1.6vw, 1.4rem);
  max-width: 30rem;
  margin-bottom: 5rem;
}

/* big pebble cta */
.cta-wrap {
  display: grid;
  grid-template-columns: minmax(20rem, 28rem) 1fr;
  gap: clamp(2rem, 5vw, 5rem);
  align-items: center;
  margin-bottom: 5rem;
}

.pebble {
  position: relative;
  width: 22rem;
  height: 22rem;
  max-width: 100%;
  aspect-ratio: 1;
  isolation: isolate;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--bubble-1);
  transition: border-radius 1.2s cubic-bezier(0.22, 1, 0.36, 1), transform 1.2s cubic-bezier(0.22, 1, 0.36, 1);
  animation: pebble-breathe 8s ease-in-out infinite alternate;
}

.pebble.hot {
  border-radius: var(--bubble-3);
  transform: scale(1.04) rotate(-1.5deg);
}

@keyframes pebble-breathe {
  0%   { transform: scale(1)    rotate(0deg);   border-radius: var(--bubble-1); }
  50%  { transform: scale(1.03) rotate(1.5deg); border-radius: var(--bubble-2); }
  100% { transform: scale(1)    rotate(-1deg);  border-radius: var(--bubble-4); }
}

.pebble-bg {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(135deg, var(--sage) 0%, var(--apricot) 100%);
  box-shadow: var(--shadow-bloom);
  z-index: -2;
}

.pebble-bg-2 {
  inset: 8%;
  background: radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.5) 0%, transparent 55%);
  z-index: -1;
  mix-blend-mode: screen;
}

.pebble-text {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.4rem;
  z-index: 1;
}

.cta-zh {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100, 'wght' 500;
  font-size: 2.6rem;
  color: var(--ink);
  letter-spacing: 0.04em;
}

.cta-en {
  font-size: 1rem;
  color: rgba(42, 61, 53, 0.65);
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
}

.pebble.hot .cta-en {
  transform: translateX(8px);
}

/* promises column */
.promises {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.promise {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 1.2rem;
  align-items: baseline;
}

.promise-num {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100;
  font-size: 1.6rem;
  color: var(--sage-deep);
  font-feature-settings: 'tnum';
}

.promise-text {
  font-size: 1rem;
  line-height: 1.55;
  color: var(--ink);
}

.promise-text em {
  display: block;
  font-family: var(--font-display);
  font-style: italic;
  font-variation-settings: 'opsz' 14, 'SOFT' 100;
  font-size: 0.85rem;
  color: var(--ink-quiet);
  margin-top: 0.15rem;
}

/* alt links row */
.alt {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
  padding-top: 2rem;
  border-top: 1px dashed var(--ink-whisper);
  font-size: var(--t-small);
  color: var(--ink-soft);
}

.alt-or {
  color: var(--ink-quiet);
  letter-spacing: 0.2em;
}

.alt-link {
  position: relative;
  transition: color 0.4s;
}

.alt-link::after {
  content: '';
  position: absolute;
  left: 0; bottom: -2px;
  width: 100%;
  height: 1px;
  background: var(--ink);
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.5s cubic-bezier(0.22, 1, 0.36, 1);
}
.alt-link:hover { color: var(--ink); }
.alt-link:hover::after { transform: scaleX(1); transform-origin: left; }

@media (max-width: 800px) {
  .cta-wrap { grid-template-columns: 1fr; }
  .pebble { width: 100%; max-width: 18rem; height: 18rem; margin-inline: auto; }
  .letter-head { flex-direction: column; gap: 1rem; }
  .vrl.small { writing-mode: horizontal-tb; height: auto; }
}
</style>
