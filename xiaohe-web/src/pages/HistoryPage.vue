<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import AppNav from "../components/AppNav.vue";
import { conv, type ConversationItem } from "../services/api";

const router = useRouter();

const items = ref<ConversationItem[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);
const busyId = ref<string | null>(null);

interface Bucket {
  label: string;
  hint: string;
  items: ConversationItem[];
}

function dayStart(d: Date) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}

const buckets = computed<Bucket[]>(() => {
  const now = new Date();
  const today = dayStart(now);
  const yesterday = today - 86400000;
  const weekAgo = today - 6 * 86400000;
  const monthAgo = today - 30 * 86400000;

  const groups: Record<string, ConversationItem[]> = {
    today: [],
    yesterday: [],
    week: [],
    month: [],
    older: [],
  };

  for (const c of items.value) {
    const t = new Date(c.updated_at).getTime();
    if (t >= today) groups.today.push(c);
    else if (t >= yesterday) groups.yesterday.push(c);
    else if (t >= weekAgo) groups.week.push(c);
    else if (t >= monthAgo) groups.month.push(c);
    else groups.older.push(c);
  }

  return [
    { label: "今天",     hint: "刚刚说过的事", items: groups.today },
    { label: "昨天",     hint: "睡前那一段",   items: groups.yesterday },
    { label: "这一周",   hint: "最近发生的",   items: groups.week },
    { label: "这一月",   hint: "还热乎着",     items: groups.month },
    { label: "更早以前", hint: "陈年的小事",   items: groups.older },
  ].filter((b) => b.items.length > 0);
});

const total = computed(() => items.value.length);

function timeLabel(iso: string): string {
  const d = new Date(iso);
  const now = new Date();
  const today = dayStart(now);
  const t = d.getTime();
  const hm = `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  if (t >= today) return `今天 ${hm}`;
  if (t >= today - 86400000) return `昨天 ${hm}`;
  return `${d.getMonth() + 1}月${d.getDate()}日 ${hm}`;
}

async function load() {
  loading.value = true;
  error.value = null;
  try {
    items.value = await conv.list();
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "加载失败";
  } finally {
    loading.value = false;
  }
}

function open(c: ConversationItem) {
  router.push({ path: "/chat", query: { conversationId: c.id } });
}

async function regen(c: ConversationItem, ev: Event) {
  ev.stopPropagation();
  busyId.value = c.id;
  try {
    const { title } = await conv.regenTitle(c.id);
    c.title = title;
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "重新生成失败";
  } finally {
    busyId.value = null;
  }
}

async function remove(c: ConversationItem, ev: Event) {
  ev.stopPropagation();
  if (!confirm(`要把「${c.title}」忘掉吗？`)) return;
  busyId.value = c.id;
  try {
    await conv.remove(c.id);
    items.value = items.value.filter((x) => x.id !== c.id);
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "删除失败";
  } finally {
    busyId.value = null;
  }
}

onMounted(load);
</script>

<template>
  <div class="history-page">
    <div class="aura a1" aria-hidden="true"></div>
    <div class="aura a2" aria-hidden="true"></div>

    <AppNav />

    <main class="frame">
      <header class="hero">
        <p class="eyebrow">a long thin notebook</p>
        <h1 class="display display-l">
          她记得<br />
          <em>每一次说过的话</em>
        </h1>
        <p class="muted lede">
          这里是你跟小云的每一段对话 ——<br />
          点进去就能从那一句继续。
        </p>
        <div class="meta">
          <span class="meta-num">{{ total }}</span>
          <span class="meta-label">段对话 · 还在长</span>
        </div>
      </header>

      <section v-if="loading" class="state">
        <span class="loading-dots"><i></i><i></i><i></i></span>
        <p class="muted italic-en">让她翻一下笔记本…</p>
      </section>

      <section v-else-if="!total && !error" class="state empty">
        <div class="empty-orb" aria-hidden="true"></div>
        <h2 class="display display-m"><em>还没有故事</em>被记下</h2>
        <p class="muted">说点什么吧 —— 哪怕只是「今天有点累」。</p>
        <button class="nav-pill" @click="router.push('/chat')" data-hover>开始第一段 →</button>
      </section>

      <section v-else class="buckets">
        <p v-if="error" class="err">{{ error }}</p>

        <div v-for="(bucket, bi) in buckets" :key="bucket.label" class="bucket">
          <div class="bucket-head">
            <span class="bucket-num">{{ String(bi + 1).padStart(2, "0") }}</span>
            <div>
              <h3 class="display display-m bucket-label">{{ bucket.label }}</h3>
              <span class="bucket-hint italic-en">{{ bucket.hint }} · {{ bucket.items.length }}</span>
            </div>
          </div>

          <ul class="conv-list">
            <li
              v-for="(c, i) in bucket.items"
              :key="c.id"
              class="conv"
              :class="{ busy: busyId === c.id }"
              :style="{ '--rot': `${((c.id.charCodeAt(0) + i) % 5 - 2) * 0.4}deg`, '--d': `${0.05 * i}s` }"
              @click="open(c)"
              data-hover
            >
              <div class="conv-petal" aria-hidden="true"></div>
              <h4 class="conv-title">{{ c.title }}</h4>
              <div class="conv-meta">
                <time>{{ timeLabel(c.updated_at) }}</time>
                <span class="dot">·</span>
                <span class="id">{{ c.id.slice(0, 6) }}</span>
              </div>
              <div class="conv-actions">
                <button class="act regen" @click="regen(c, $event)" :disabled="busyId === c.id" data-hover title="基于内容重新生成标题">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M21 12a9 9 0 1 1-3-6.7l3-2.3v6h-6"/></svg>
                  <span>换个名字</span>
                </button>
                <button class="act danger" @click="remove(c, $event)" :disabled="busyId === c.id" data-hover title="删除">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m1 0v14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V6"/></svg>
                  <span>忘掉</span>
                </button>
              </div>
            </li>
          </ul>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
.history-page {
  position: relative;
  min-height: 100vh;
  isolation: isolate;
}
.aura {
  position: absolute;
  pointer-events: none;
  filter: blur(80px);
  z-index: 0;
  animation: drift 24s ease-in-out infinite alternate;
}
.a1 {
  width: 40vmax; height: 40vmax;
  top: -16vmax; right: -10vmax;
  background: radial-gradient(closest-side, var(--apricot) 0%, transparent 70%);
  opacity: 0.4;
}
.a2 {
  width: 36vmax; height: 36vmax;
  bottom: -16vmax; left: -10vmax;
  background: radial-gradient(closest-side, var(--sage) 0%, transparent 70%);
  opacity: 0.4;
  animation-delay: -10s;
}

.frame {
  position: relative;
  z-index: 5;
  max-width: 1080px;
  margin-inline: auto;
  padding: 4rem clamp(1rem, 3vw, 2.5rem) 6rem;
}

.hero {
  max-width: 36rem;
  margin-bottom: 4rem;
}
.hero h1 { margin: 1rem 0 1.5rem; }
.hero h1 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--apricot));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede { font-size: var(--t-body-l); margin-bottom: 1.5rem; }

.meta {
  display: inline-flex;
  align-items: baseline;
  gap: 0.7rem;
  padding-top: 1rem;
  border-top: 1px dashed var(--ink-whisper);
}
.meta-num {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 144, 'SOFT' 100;
  font-size: 2.5rem;
  color: var(--sage-deep);
  line-height: 1;
}
.meta-label {
  font-size: var(--t-small);
  color: var(--ink-soft);
}

/* state */
.state {
  padding: 6rem 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
}
.loading-dots {
  display: inline-flex;
  gap: 6px;
}
.loading-dots i {
  width: 8px; height: 8px;
  background: var(--sage-deep);
  border-radius: 50%;
  animation: pulse 1.2s ease-in-out infinite;
}
.loading-dots i:nth-child(2) { animation-delay: 0.15s; }
.loading-dots i:nth-child(3) { animation-delay: 0.3s; }
@keyframes pulse {
  0%, 100% { opacity: 0.35; transform: scale(0.85); }
  50%      { opacity: 1;    transform: scale(1.1); }
}

.empty .empty-orb {
  width: 12rem;
  height: 12rem;
  background: radial-gradient(closest-side, var(--apricot-soft), transparent 70%);
  border-radius: var(--bubble-1);
  filter: blur(8px);
  animation: morph 18s ease-in-out infinite alternate;
}
@keyframes morph {
  0% { border-radius: var(--bubble-1); }
  50% { border-radius: var(--bubble-3); }
  100% { border-radius: var(--bubble-4); }
}

.nav-pill {
  font-size: var(--t-small);
  color: var(--sage-deep);
  padding: 0.6rem 1.2rem;
  background: rgba(168, 216, 197, 0.2);
  border: 1px solid rgba(107, 143, 122, 0.3);
  border-radius: 999px;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}
.nav-pill:hover {
  background: var(--sage-deep);
  color: var(--bone);
  border-radius: var(--bubble-3);
}

.err {
  padding: 0.8rem 1rem;
  background: rgba(232, 184, 176, 0.2);
  color: #8B4530;
  border-radius: var(--bubble-3);
  margin-bottom: 1.5rem;
  font-family: var(--font-display);
  font-style: italic;
  font-size: 0.95rem;
}

/* buckets */
.bucket { margin-bottom: 4rem; }

.bucket-head {
  display: flex;
  align-items: baseline;
  gap: 1.5rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--ink-whisper);
}

.bucket-num {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 80;
  font-size: 2.6rem;
  color: var(--ink-whisper);
  font-feature-settings: 'tnum';
  line-height: 1;
}
.bucket-label {
  margin: 0;
  font-size: clamp(1.4rem, 2.5vw, 2rem);
}
.bucket-hint {
  display: block;
  font-size: var(--t-small);
  color: var(--ink-quiet);
  margin-top: 0.2rem;
}

.conv-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(20rem, 1fr));
  gap: 1.2rem;
}

.conv {
  position: relative;
  padding: 1.3rem 1.5rem 1.4rem;
  background: var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.15);
  border-radius: var(--bubble-2);
  cursor: pointer;
  transform: rotate(var(--rot, 0deg));
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1), box-shadow 0.4s, border-radius 1.2s ease;
  overflow: hidden;
  isolation: isolate;
  animation: card-in 0.7s cubic-bezier(0.22, 1, 0.36, 1) backwards;
  animation-delay: var(--d, 0s);
  box-shadow: 0 12px 30px -22px rgba(42, 61, 53, 0.15);
}

@keyframes card-in {
  0%   { opacity: 0; transform: translateY(14px) rotate(var(--rot, 0deg)); }
  100% { opacity: 1; transform: translateY(0)   rotate(var(--rot, 0deg)); }
}

.conv:hover {
  transform: rotate(0) translateY(-3px);
  box-shadow: var(--shadow-soft);
  border-radius: var(--bubble-3);
}
.conv.busy { pointer-events: none; opacity: 0.6; }

.conv-petal {
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: inherit;
  background: radial-gradient(ellipse at 80% 80%, var(--sage-soft) 0%, transparent 65%);
  opacity: 0.5;
  transition: opacity 0.5s, transform 0.6s;
}
.conv:hover .conv-petal {
  opacity: 1;
  transform: scale(1.1) rotate(6deg);
}

.conv-title {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100, 'wght' 450;
  font-size: 1.25rem;
  line-height: 1.35;
  color: var(--ink);
  margin: 0 0 0.6rem;
  /* clamp to 2 lines */
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.conv-meta {
  font-size: var(--t-small);
  color: var(--ink-quiet);
  display: flex;
  align-items: center;
  gap: 0.45rem;
  margin-bottom: 0.6rem;
}
.conv-meta .id {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  opacity: 0.7;
}

.conv-actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-top: 0.6rem;
  padding-top: 0.7rem;
  border-top: 1px dashed rgba(107, 143, 122, 0.25);
  opacity: 0;
  max-height: 0;
  overflow: hidden;
  transition: opacity 0.4s, max-height 0.5s;
}
.conv:hover .conv-actions {
  opacity: 1;
  max-height: 6rem;
}

.act {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.35rem 0.7rem;
  font-size: 0.8rem;
  color: var(--sage-deep);
  border: 1px solid rgba(107, 143, 122, 0.3);
  border-radius: 999px;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}
.act:hover {
  background: var(--sage-deep);
  color: var(--bone);
  transform: translateY(-1px);
}
.act.danger { color: #B5645B; border-color: rgba(181, 100, 91, 0.3); }
.act.danger:hover { background: #B5645B; color: var(--bone); }
.act:disabled { opacity: 0.5; cursor: wait; }

@media (max-width: 700px) {
  .bucket-head { flex-direction: column; gap: 0.4rem; }
  .conv-list { grid-template-columns: 1fr; }
}
</style>
