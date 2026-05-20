<script setup lang="ts">
import { computed } from "vue";
import { useRouter, RouterLink } from "vue-router";
import { useAuthStore } from "../stores/auth";

const router = useRouter();
const store = useAuthStore();

const userName = computed(() => store.user?.nickname || store.user?.phone?.slice(-4) || "");

function logout() {
  store.logout();
  router.push("/");
}
</script>

<template>
  <header class="appnav">
    <RouterLink to="/" class="brand" data-hover>
      <span class="brand-mark" aria-hidden="true">
        <svg viewBox="0 0 36 36" width="24" height="24">
          <defs>
            <radialGradient id="appnav-mark" cx="40%" cy="35%" r="65%">
              <stop offset="0%"   stop-color="#F4C5B0" />
              <stop offset="55%"  stop-color="#A8D8C5" />
              <stop offset="100%" stop-color="#6B8F7A" />
            </radialGradient>
          </defs>
          <path d="M18 4c5 0 8 2.5 9.5 6.5C32 11 34 14.5 33.5 18 36 21 35.5 25 32 27c.5 4-3 7-7 6.5-2 3-7 3-9 0-4 .5-7-2-7-6-3.5-2-4-6.5-1.5-9.5-.5-3 1-6.5 5-7C13.5 6.5 16 4 18 4z" fill="url(#appnav-mark)" />
        </svg>
      </span>
      <span class="brand-name">健康小云</span>
    </RouterLink>

    <nav class="links" aria-label="主导航">
      <RouterLink to="/chat"    active-class="active" data-hover>对话</RouterLink>
      <RouterLink to="/call"    active-class="active" data-hover>通话</RouterLink>
      <RouterLink to="/history" active-class="active" data-hover>历史</RouterLink>
      <RouterLink to="/profile" active-class="active" data-hover>画像</RouterLink>
      <RouterLink to="/records" active-class="active" data-hover>记录</RouterLink>
    </nav>

    <div class="right">
      <slot name="extra" />
      <span class="hello">{{ userName }}</span>
      <button class="quiet-btn" @click="logout" data-hover>退出</button>
    </div>
  </header>
</template>

<style scoped>
.appnav {
  position: relative;
  z-index: 30;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 2rem;
  padding: 1.2rem clamp(1rem, 3vw, 3rem);
  border-bottom: 1px solid rgba(184, 197, 190, 0.3);
  backdrop-filter: blur(8px);
  background: linear-gradient(to bottom, rgba(248, 244, 237, 0.7), transparent);
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  color: var(--ink);
}
.brand-name {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100;
  font-size: 1.05rem;
  color: var(--ink);
}
.brand-mark svg { animation: ring-breathe 6s ease-in-out infinite; }

.links {
  display: flex;
  justify-content: center;
  gap: clamp(1.2rem, 3vw, 2.5rem);
}

.links a {
  position: relative;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 80;
  font-size: 1rem;
  color: var(--ink-soft);
  letter-spacing: 0.04em;
  padding: 0.4rem 0;
  transition: color 0.35s;
}
.links a::after {
  content: '';
  position: absolute;
  left: 50%;
  bottom: -2px;
  width: 0;
  height: 1px;
  background: var(--sage-deep);
  transform: translateX(-50%);
  transition: width 0.55s cubic-bezier(0.22, 1, 0.36, 1);
}
.links a:hover {
  color: var(--ink);
}
.links a:hover::after {
  width: 80%;
}
.links a.active {
  color: var(--ink);
  font-variation-settings: 'opsz' 24, 'SOFT' 80, 'wght' 500;
}
.links a.active::after {
  width: 100%;
  background: linear-gradient(90deg, var(--sage-deep), var(--apricot));
}

.right {
  display: flex;
  align-items: center;
  gap: 1.2rem;
  font-size: var(--t-small);
  color: var(--ink-soft);
}
.hello {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 18, 'SOFT' 100;
  font-size: 0.95rem;
  color: var(--ink);
}
.quiet-btn {
  font-size: var(--t-small);
  color: var(--ink-quiet);
  position: relative;
  cursor: pointer;
}
.quiet-btn::after {
  content: '';
  position: absolute;
  left: 0; bottom: -2px; width: 100%; height: 1px;
  background: currentColor;
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.5s cubic-bezier(0.22, 1, 0.36, 1);
}
.quiet-btn:hover { color: var(--ink); }
.quiet-btn:hover::after { transform: scaleX(1); transform-origin: left; }

@media (max-width: 800px) {
  .appnav { grid-template-columns: auto 1fr auto; gap: 0.8rem; }
  .links { gap: 1rem; font-size: 0.9rem; }
  .right { gap: 0.7rem; font-size: 0.78rem; }
  .hello { display: none; }
}
@media (max-width: 540px) {
  .brand-name { display: none; }
}
</style>
