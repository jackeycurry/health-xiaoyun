<script setup lang="ts">
import { computed, onMounted, onUnmounted } from "vue";
import { useRouter, RouterLink } from "vue-router";
import { useAuthStore } from "../stores/auth";
import HeroBreath from "../components/HeroBreath.vue";
import ConversationDemo from "../components/ConversationDemo.vue";
import MemoryGarden from "../components/MemoryGarden.vue";
import HealthBlooms from "../components/HealthBlooms.vue";
import CallToBloom from "../components/CallToBloom.vue";

const router = useRouter();
const authStore = useAuthStore();
const ctaLabel = computed(() => (authStore.isAuthed ? "继续对话 →" : "进入对话 →"));
const enterPath = computed(() => (authStore.isAuthed ? "/chat" : "/login"));

function enterChat(e: Event) {
  e.preventDefault();
  router.push(enterPath.value);
}

let io: IntersectionObserver | null = null;

onMounted(() => {
  io = new IntersectionObserver(
    (entries) => {
      for (const e of entries) {
        if (e.isIntersecting) e.target.classList.add("in");
      }
    },
    { threshold: 0.18 }
  );
  document.querySelectorAll(".reveal").forEach((el) => io!.observe(el));
});

onUnmounted(() => {
  io?.disconnect();
});
</script>

<template>
  <header class="nav">
    <div class="brand">
      <span class="brand-mark" aria-hidden="true">
        <svg viewBox="0 0 36 36" width="28" height="28">
          <defs>
            <radialGradient id="mark-g" cx="40%" cy="35%" r="65%">
              <stop offset="0%"   stop-color="#F4C5B0" />
              <stop offset="55%"  stop-color="#A8D8C5" />
              <stop offset="100%" stop-color="#6B8F7A" />
            </radialGradient>
          </defs>
          <path d="M18 4c5 0 8 2.5 9.5 6.5C32 11 34 14.5 33.5 18 36 21 35.5 25 32 27c.5 4-3 7-7 6.5-2 3-7 3-9 0-4 .5-7-2-7-6-3.5-2-4-6.5-1.5-9.5-.5-3 1-6.5 5-7C13.5 6.5 16 4 18 4z" fill="url(#mark-g)" />
        </svg>
      </span>
      <span class="brand-name">健康小云</span>
    </div>
    <nav class="nav-links">
      <span class="italic-en" v-if="!authStore.isAuthed">v.0.1 · in residence</span>
      <span class="italic-en" v-else>· {{ authStore.user?.nickname || authStore.user?.phone }}</span>
      <RouterLink :to="enterPath" data-hover>{{ ctaLabel }}</RouterLink>
    </nav>
  </header>

  <main @click.capture="(e) => {
    const t = (e.target as HTMLElement).closest('.pebble, #enter button');
    if (t) enterChat(e);
  }">
    <HeroBreath />
    <ConversationDemo />
    <MemoryGarden />
    <HealthBlooms />
    <CallToBloom />
  </main>

  <footer class="foot">
    <div class="foot-row">
      <span>© 健康小云 · 一只懂你身体的安静的云</span>
      <span class="italic-en">made with care, not algorithms</span>
    </div>
  </footer>
</template>

<style scoped>
.nav {
  position: fixed;
  top: 0; left: 0; right: 0;
  z-index: 100;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem clamp(1.5rem, 4vw, 5rem);
  backdrop-filter: blur(8px) saturate(1.1);
  -webkit-backdrop-filter: blur(8px) saturate(1.1);
  background: linear-gradient(to bottom, rgba(248, 244, 237, 0.7), transparent);
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.7rem;
}

.brand-mark svg {
  animation: ring-breathe 6s ease-in-out infinite;
  transform-origin: center;
}

.brand-name {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100;
  font-weight: 400;
  font-size: 1.15rem;
  letter-spacing: 0.02em;
  color: var(--ink);
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 2rem;
  font-size: var(--t-small);
  color: var(--ink-soft);
}

.nav-links a {
  position: relative;
  transition: color 0.3s;
}
.nav-links a::after {
  content: '';
  position: absolute;
  left: 0; bottom: -3px;
  width: 100%;
  height: 1px;
  background: var(--ink);
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
}
.nav-links a:hover {
  color: var(--ink);
}
.nav-links a:hover::after {
  transform: scaleX(1);
  transform-origin: left;
}

.foot {
  padding: 3rem clamp(1.5rem, 4vw, 5rem) 2.5rem;
  border-top: 1px solid var(--ink-whisper);
  margin-top: 6rem;
}

.foot-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 2rem;
  font-size: var(--t-small);
  color: var(--ink-quiet);
  max-width: 1320px;
  margin-inline: auto;
  flex-wrap: wrap;
}

@media (max-width: 700px) {
  .nav-links .italic-en { display: none; }
}
</style>
