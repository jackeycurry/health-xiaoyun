<script setup lang="ts">
import { computed, ref } from "vue";
import { useRouter, useRoute, RouterLink } from "vue-router";
import { useAuthStore } from "../stores/auth";

const router = useRouter();
const route = useRoute();
const store = useAuthStore();

type Mode = "login" | "register";
const mode = ref<Mode>("login");
const phone = ref("");
const password = ref("");

const isValid = computed(() => phone.value.length >= 11 && password.value.length >= 6);
const ctaLabel = computed(() => (mode.value === "login" ? "进入 →" : "认识一下 →"));

async function submit() {
  if (!isValid.value || store.busy) return;
  try {
    if (mode.value === "login") {
      await store.login(phone.value.trim(), password.value);
    } else {
      await store.register(phone.value.trim(), password.value);
    }
    const from = (route.query.from as string) || "/chat";
    router.push(from);
  } catch {
    // error already on store
  }
}

function toggleMode() {
  mode.value = mode.value === "login" ? "register" : "login";
  store.error = null;
}
</script>

<template>
  <div class="login-page">
    <!-- ambient atmosphere -->
    <div class="aura a1" aria-hidden="true"></div>
    <div class="aura a2" aria-hidden="true"></div>
    <div class="aura a3" aria-hidden="true"></div>

    <header class="nav">
      <RouterLink to="/" class="brand" data-hover>
        <span class="brand-mark" aria-hidden="true">
          <svg viewBox="0 0 36 36" width="26" height="26">
            <defs>
              <radialGradient id="login-mark" cx="40%" cy="35%" r="65%">
                <stop offset="0%"   stop-color="#F4C5B0" />
                <stop offset="55%"  stop-color="#A8D8C5" />
                <stop offset="100%" stop-color="#6B8F7A" />
              </radialGradient>
            </defs>
            <path d="M18 4c5 0 8 2.5 9.5 6.5C32 11 34 14.5 33.5 18 36 21 35.5 25 32 27c.5 4-3 7-7 6.5-2 3-7 3-9 0-4 .5-7-2-7-6-3.5-2-4-6.5-1.5-9.5-.5-3 1-6.5 5-7C13.5 6.5 16 4 18 4z" fill="url(#login-mark)" />
          </svg>
        </span>
        <span class="brand-name">健康小云</span>
      </RouterLink>
      <span class="quiet italic-en">a quiet beginning</span>
    </header>

    <main class="frame">
      <div class="card-wrap">
        <p class="eyebrow">{{ mode === "login" ? "回来啦" : "你好，先认识一下" }}</p>
        <h1 class="display display-m">
          <span v-if="mode === 'login'">很高兴<br /><em>你又来了</em></span>
          <span v-else>我们慢慢<br /><em>互相认识</em></span>
        </h1>
        <p class="muted lede italic-en">
          {{ mode === "login"
            ? "她还记得你上次说的那些事。"
            : "只需要一个手机号 — 暂时不必告诉她更多。"
          }}
        </p>

        <form class="card" @submit.prevent="submit" autocomplete="on">
          <label class="field">
            <span class="field-label">手机号</span>
            <input
              v-model="phone"
              type="tel"
              inputmode="numeric"
              autocomplete="username"
              placeholder="11 位手机号"
              :disabled="store.busy"
            />
          </label>

          <label class="field">
            <span class="field-label">
              {{ mode === "login" ? "密码" : "给自己设一个密码" }}
            </span>
            <input
              v-model="password"
              type="password"
              :autocomplete="mode === 'login' ? 'current-password' : 'new-password'"
              placeholder="至少 6 位"
              :disabled="store.busy"
              @keydown.enter="submit"
            />
          </label>

          <p v-if="store.error" class="err">{{ store.error }}</p>

          <button
            type="submit"
            class="pebble"
            :class="{ ready: isValid, busy: store.busy }"
            :disabled="!isValid || store.busy"
            data-hover
          >
            <span class="pebble-bg"></span>
            <span class="pebble-text">
              <span v-if="!store.busy">{{ ctaLabel }}</span>
              <span v-else class="dots"><i></i><i></i><i></i></span>
            </span>
          </button>

          <div class="switch">
            <span class="switch-q">{{ mode === "login" ? "还没有账号？" : "已经有账号了？" }}</span>
            <button type="button" class="switch-btn" @click="toggleMode" data-hover>
              {{ mode === "login" ? "注册一个新的 →" : "← 回去登录" }}
            </button>
          </div>
        </form>

        <p class="fineprint italic-en">
          隐私是一种安静的承诺 —— <br />
          你的数据只属于你，工程师也看不到。
        </p>
      </div>
    </main>
  </div>
</template>

<style scoped>
.login-page {
  position: relative;
  min-height: 100vh;
  overflow: hidden;
  isolation: isolate;
}

.aura {
  position: absolute;
  border-radius: var(--bubble-1);
  filter: blur(60px);
  pointer-events: none;
  animation: drift 22s ease-in-out infinite alternate;
  z-index: 0;
}
.a1 {
  width: 50vmax; height: 50vmax;
  top: -18vmax; right: -12vmax;
  background: radial-gradient(closest-side, var(--apricot) 0%, transparent 70%);
  opacity: 0.55;
}
.a2 {
  width: 44vmax; height: 44vmax;
  bottom: -22vmax; left: -10vmax;
  background: radial-gradient(closest-side, var(--sage) 0%, transparent 70%);
  opacity: 0.55;
  animation-delay: -10s;
}
.a3 {
  width: 22vmax; height: 22vmax;
  top: 35%; left: 25%;
  background: radial-gradient(closest-side, var(--cream) 0%, transparent 70%);
  opacity: 0.5;
  animation-delay: -14s;
}

.nav {
  position: relative;
  z-index: 10;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem clamp(1.5rem, 4vw, 5rem);
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.7rem;
}
.brand-name {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100;
  font-size: 1.1rem;
  color: var(--ink);
}
.brand-mark svg {
  animation: ring-breathe 6s ease-in-out infinite;
}

.quiet { color: var(--ink-quiet); font-size: var(--t-small); }

.frame {
  position: relative;
  z-index: 5;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem clamp(1.5rem, 4vw, 5rem) 4rem;
  min-height: calc(100vh - 7rem);
}

.card-wrap {
  width: 100%;
  max-width: 30rem;
  text-align: left;
}

.eyebrow { margin-bottom: 1.2rem; }

.card-wrap h1 {
  margin-bottom: 1rem;
}
.card-wrap h1 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--apricot));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.lede {
  font-size: 1.05rem;
  margin-bottom: 2.5rem;
  color: var(--ink-soft);
}

.card {
  position: relative;
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.75), rgba(168, 216, 197, 0.12)),
    var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.18);
  border-radius: var(--bubble-2);
  padding: 2rem;
  box-shadow: var(--shadow-soft);
  backdrop-filter: blur(8px);
  animation: card-breathe 12s ease-in-out infinite alternate;
}

@keyframes card-breathe {
  0%   { border-radius: var(--bubble-2); }
  50%  { border-radius: var(--bubble-3); }
  100% { border-radius: var(--bubble-4); }
}

.field {
  display: block;
  margin-bottom: 1.4rem;
}

.field-label {
  display: block;
  font-size: var(--t-micro);
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  margin-bottom: 0.45rem;
}

.field input {
  width: 100%;
  padding: 0.85rem 1rem;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100, 'wght' 400;
  font-size: 1.15rem;
  color: var(--ink);
  background: transparent;
  border: none;
  border-bottom: 1px solid var(--ink-whisper);
  outline: none;
  transition: border-color 0.4s, padding 0.4s;
  letter-spacing: 0.05em;
}
.field input::placeholder {
  color: var(--ink-quiet);
  opacity: 0.7;
  font-style: italic;
}
.field input:focus {
  border-color: var(--sage-deep);
}
.field input:disabled { opacity: 0.5; cursor: wait; }

.err {
  margin: -0.5rem 0 1rem;
  padding: 0.7rem 0.9rem;
  background: rgba(232, 184, 176, 0.25);
  color: #8B4530;
  border-radius: var(--bubble-3);
  font-size: 0.9rem;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 14, 'SOFT' 100;
  font-style: italic;
}

/* the submit pebble */
.pebble {
  position: relative;
  width: 100%;
  padding: 1rem 1.5rem;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100, 'wght' 500;
  font-size: 1.25rem;
  color: var(--ink);
  background: transparent;
  border-radius: var(--bubble-1);
  cursor: pointer;
  transition: border-radius 1.2s cubic-bezier(0.22, 1, 0.36, 1), transform 0.5s;
  isolation: isolate;
  margin-top: 0.5rem;
  letter-spacing: 0.04em;
  animation: pebble-breathe 8s ease-in-out infinite alternate;
  overflow: hidden;
}

.pebble:disabled { cursor: not-allowed; opacity: 0.55; animation: none; }

.pebble-bg {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(135deg, var(--sage) 0%, var(--apricot) 100%);
  opacity: 0.45;
  z-index: -1;
  transition: opacity 0.5s;
}

.pebble.ready .pebble-bg { opacity: 0.9; }
.pebble.ready:hover {
  border-radius: var(--bubble-3);
  transform: translateY(-2px);
}

@keyframes pebble-breathe {
  0%   { border-radius: var(--bubble-1); }
  50%  { border-radius: var(--bubble-2); }
  100% { border-radius: var(--bubble-4); }
}

.pebble-text {
  position: relative;
  z-index: 1;
}

.dots {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.dots i {
  width: 6px; height: 6px;
  background: var(--ink);
  border-radius: 50%;
  animation: pulse 1.2s ease-in-out infinite;
}
.dots i:nth-child(2) { animation-delay: 0.15s; }
.dots i:nth-child(3) { animation-delay: 0.30s; }
@keyframes pulse {
  0%, 100% { opacity: 0.3; transform: translateY(0); }
  50%      { opacity: 1;   transform: translateY(-2px); }
}

.switch {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  margin-top: 1.4rem;
  padding-top: 1.4rem;
  border-top: 1px dashed rgba(107, 143, 122, 0.3);
  font-size: 0.9rem;
}
.switch-q { color: var(--ink-quiet); }
.switch-btn {
  color: var(--sage-deep);
  font-weight: 500;
  position: relative;
  cursor: pointer;
}
.switch-btn::after {
  content: '';
  position: absolute;
  left: 0; bottom: -2px;
  width: 100%;
  height: 1px;
  background: var(--sage-deep);
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.5s cubic-bezier(0.22, 1, 0.36, 1);
}
.switch-btn:hover::after { transform: scaleX(1); transform-origin: left; }

.fineprint {
  margin-top: 2.5rem;
  font-size: 0.85rem;
  color: var(--ink-quiet);
  line-height: 1.55;
  font-style: italic;
}

@media (max-width: 700px) {
  .frame { padding-top: 1rem; }
  .card { padding: 1.6rem; }
}
</style>
