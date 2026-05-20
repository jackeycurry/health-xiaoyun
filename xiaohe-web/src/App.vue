<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useRoute } from "vue-router";

const route = useRoute();
const showStem = computed(() => route.path === "/");

const dot = ref<HTMLElement | null>(null);
const ring = ref<HTMLElement | null>(null);
const stem = ref<HTMLElement | null>(null);

let raf = 0;
let dx = 0, dy = 0;
let rx = 0, ry = 0;
let tx = 0, ty = 0;

function onMove(e: MouseEvent) {
  tx = e.clientX;
  ty = e.clientY;
  const t = e.target as HTMLElement | null;
  if (t && t.closest("button, a, [data-hover], input, textarea")) {
    ring.value?.classList.add("hover");
  } else {
    ring.value?.classList.remove("hover");
  }
}

function tick() {
  dx += (tx - dx) * 0.45;
  dy += (ty - dy) * 0.45;
  rx += (tx - rx) * 0.10;
  ry += (ty - ry) * 0.10;
  if (dot.value)  dot.value.style.transform  = `translate(${dx}px, ${dy}px) translate(-50%, -50%)`;
  if (ring.value) ring.value.style.transform = `translate(${rx}px, ${ry}px) translate(-50%, -50%)`;
  raf = requestAnimationFrame(tick);
}

function onScroll() {
  const max = document.documentElement.scrollHeight - window.innerHeight;
  const p = Math.min(1, Math.max(0, window.scrollY / Math.max(1, max)));
  if (stem.value) stem.value.style.setProperty("--p", `${p * 100}%`);
}

onMounted(() => {
  window.addEventListener("mousemove", onMove, { passive: true });
  window.addEventListener("scroll", onScroll, { passive: true });
  raf = requestAnimationFrame(tick);
  onScroll();
});

onUnmounted(() => {
  cancelAnimationFrame(raf);
  window.removeEventListener("mousemove", onMove);
  window.removeEventListener("scroll", onScroll);
});
</script>

<template>
  <RouterView />

  <div v-if="showStem" ref="stem" class="stem" aria-hidden="true"></div>
  <div ref="ring" class="cursor-ring" aria-hidden="true"></div>
  <div ref="dot"  class="cursor-dot"  aria-hidden="true"></div>
</template>
