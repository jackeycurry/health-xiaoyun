<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import AppNav from "../components/AppNav.vue";
import { profile, type MemoryRow, type ProfileBase } from "../services/api";

const data = ref<{ profile: ProfileBase | null; memories: MemoryRow[] }>({
  profile: null,
  memories: [],
});
const loading = ref(true);
const error = ref<string | null>(null);

const editing = ref(false);
const saving = ref(false);
const form = reactive({
  gender: "" as string,
  age: null as number | null,
  height: null as number | null,
  weight: null as number | null,
});

const memoryBusy = ref<string | null>(null);

const categoryLabel: Record<string, string> = {
  personal: "本人",
  health:   "健康",
  habit:    "习惯",
  preference: "偏好",
  note:     "备注",
  diet:     "饮食",
  body:     "身体",
  sleep:    "睡眠",
  language: "语气",
  vital:    "指标",
  allergy:  "过敏",
  cycle:    "周期",
};
function labelOf(cat: string) {
  return categoryLabel[cat] ?? cat;
}

const stats = computed(() => {
  const p = data.value.profile;
  return [
    { key: "gender", label: "性别",  unit: "",   value: p?.gender ? (p.gender === "male" ? "男" : p.gender === "female" ? "女" : "其他") : null, shape: 1 },
    { key: "age",    label: "年龄",  unit: "岁", value: p?.age,                                                                                shape: 2 },
    { key: "height", label: "身高",  unit: "cm", value: p?.height,                                                                             shape: 3 },
    { key: "weight", label: "体重",  unit: "kg", value: p?.weight,                                                                             shape: 4 },
  ];
});

const sortedMemories = computed(() =>
  [...data.value.memories].sort((a, b) => (b.importance - a.importance) || (a.created_at < b.created_at ? 1 : -1))
);

async function load() {
  loading.value = true;
  error.value = null;
  try {
    data.value = await profile.get();
    if (data.value.profile) {
      const p = data.value.profile;
      form.gender = p.gender ?? "";
      form.age = p.age;
      form.height = p.height;
      form.weight = p.weight;
    }
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "加载失败";
  } finally {
    loading.value = false;
  }
}

function startEdit() {
  const p = data.value.profile;
  form.gender = p?.gender ?? "";
  form.age = p?.age ?? null;
  form.height = p?.height ?? null;
  form.weight = p?.weight ?? null;
  editing.value = true;
}

async function save() {
  saving.value = true;
  try {
    const updated = await profile.update({
      gender: form.gender || undefined,
      age: form.age ?? undefined,
      height: form.height ?? undefined,
      weight: form.weight ?? undefined,
    });
    data.value.profile = {
      ...updated,
      health_summary: data.value.profile?.health_summary ?? null,
      risk_tags: data.value.profile?.risk_tags ?? null,
    };
    editing.value = false;
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "保存失败";
  } finally {
    saving.value = false;
  }
}

async function forget(m: MemoryRow) {
  if (!confirm(`让她忘掉「${m.fact.slice(0, 20)}…」吗？`)) return;
  memoryBusy.value = m.id;
  try {
    await profile.deleteMemory(m.id);
    data.value.memories = data.value.memories.filter((x) => x.id !== m.id);
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "删除失败";
  } finally {
    memoryBusy.value = null;
  }
}

function fmtDate(iso: string) {
  const d = new Date(iso);
  return `${d.getMonth() + 1}月${d.getDate()}日`;
}

onMounted(load);
</script>

<template>
  <div class="profile-page">
    <div class="aura a1" aria-hidden="true"></div>
    <div class="aura a2" aria-hidden="true"></div>

    <AppNav />

    <main class="frame">
      <header class="hero">
        <p class="eyebrow">a slow portrait — drawn from what you say</p>
        <h1 class="display display-l">
          小云<br />
          <em>眼中的你</em>
        </h1>
        <p class="muted lede">
          她不会问你健康问卷 ——<br />
          只会从你随口说的事里，慢慢拼出你这个人。
        </p>
      </header>

      <section v-if="loading" class="state">
        <span class="loading-dots"><i></i><i></i><i></i></span>
        <p class="muted italic-en">让她想一下你长什么样…</p>
      </section>

      <template v-else>
        <p v-if="error" class="err">{{ error }}</p>

        <!-- ── basic stats: 4 organic petals ── -->
        <section class="stats">
          <div class="stats-head">
            <h2 class="display display-m">基本信息</h2>
            <button v-if="!editing" class="nav-pill" @click="startEdit" data-hover>更新一下 →</button>
          </div>

          <div class="stats-grid" v-if="!editing">
            <article
              v-for="(s, i) in stats"
              :key="s.key"
              class="stat"
              :class="[`shape-${s.shape}`, s.value === null && 'empty']"
              :style="{ '--rot': `${(i - 1.5) * 1.4}deg`, '--d': `${i * 0.08}s` }"
            >
              <span class="stat-petal" aria-hidden="true"></span>
              <span class="stat-label">{{ s.label }}</span>
              <span class="stat-value">
                <template v-if="s.value !== null">
                  {{ s.value }}<small v-if="s.unit">{{ s.unit }}</small>
                </template>
                <template v-else>
                  <span class="stat-blank italic-en">还没告诉她</span>
                </template>
              </span>
            </article>
          </div>

          <form v-else class="edit-card" @submit.prevent="save">
            <div class="edit-grid">
              <label class="field">
                <span class="field-label">性别</span>
                <div class="seg">
                  <button type="button" :class="{ on: form.gender === 'female' }" @click="form.gender = 'female'" data-hover>女</button>
                  <button type="button" :class="{ on: form.gender === 'male' }" @click="form.gender = 'male'" data-hover>男</button>
                  <button type="button" :class="{ on: form.gender === 'other' }" @click="form.gender = 'other'" data-hover>其他</button>
                </div>
              </label>

              <label class="field">
                <span class="field-label">年龄</span>
                <input v-model.number="form.age" type="number" min="1" max="150" placeholder="—" />
              </label>

              <label class="field">
                <span class="field-label">身高 (cm)</span>
                <input v-model.number="form.height" type="number" min="30" max="280" placeholder="—" />
              </label>

              <label class="field">
                <span class="field-label">体重 (kg)</span>
                <input v-model.number="form.weight" type="number" min="1" max="500" placeholder="—" />
              </label>
            </div>

            <div class="edit-actions">
              <button type="button" class="quiet-btn" @click="editing = false" data-hover>取消</button>
              <button type="submit" class="pebble" :class="{ busy: saving }" :disabled="saving" data-hover>
                <span class="pebble-bg" aria-hidden="true"></span>
                <span>{{ saving ? "保存中…" : "记下" }}</span>
              </button>
            </div>
          </form>
        </section>

        <!-- ── AI summary + risk tags ── -->
        <section class="summary" v-if="data.profile?.health_summary || (data.profile?.risk_tags && data.profile.risk_tags.length)">
          <h2 class="display display-m">她对你的<em>整体印象</em></h2>
          <blockquote v-if="data.profile?.health_summary" class="summary-text">
            <span class="quote-mark">"</span>
            {{ data.profile.health_summary }}
            <span class="quote-mark close">"</span>
          </blockquote>
          <div v-if="data.profile?.risk_tags && data.profile.risk_tags.length" class="tags">
            <span class="tags-label">值得留意</span>
            <span v-for="t in data.profile.risk_tags" :key="t" class="tag">{{ t }}</span>
          </div>
        </section>

        <!-- ── memories ── -->
        <section class="memories">
          <div class="mem-head">
            <h2 class="display display-m">慢慢长出的<em>记忆</em></h2>
            <span class="mem-count">{{ sortedMemories.length }} 条 · 按重要度排</span>
          </div>

          <div v-if="!sortedMemories.length" class="state empty">
            <div class="empty-orb" aria-hidden="true"></div>
            <p class="muted">还没有记忆。<br />跟她多说几次话，她就开始记了。</p>
          </div>

          <ul v-else class="mem-list">
            <li
              v-for="(m, i) in sortedMemories"
              :key="m.id"
              class="mem"
              :class="{ busy: memoryBusy === m.id }"
              :style="{ '--imp': m.importance, '--rot': `${(i % 5 - 2) * 0.35}deg`, '--d': `${i * 0.05}s` }"
            >
              <div class="mem-petal" aria-hidden="true"></div>
              <div class="mem-row1">
                <span class="mem-cat">{{ labelOf(m.category) }}</span>
                <span class="mem-bar" :title="`重要度 ${Math.round(m.importance * 100)}%`">
                  <i :style="{ width: `${Math.round(m.importance * 100)}%` }"></i>
                </span>
                <button class="mem-forget" @click="forget(m)" :disabled="memoryBusy === m.id" data-hover title="让她忘掉">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M18 6 6 18M6 6l12 12"/></svg>
                </button>
              </div>
              <p class="mem-fact">{{ m.fact }}</p>
              <span class="mem-date italic-en">{{ fmtDate(m.created_at) }} 记下</span>
            </li>
          </ul>
        </section>
      </template>
    </main>
  </div>
</template>

<style scoped>
.profile-page { position: relative; min-height: 100vh; isolation: isolate; }
.aura {
  position: absolute;
  pointer-events: none;
  filter: blur(80px);
  z-index: 0;
  animation: drift 24s ease-in-out infinite alternate;
}
.a1 {
  width: 42vmax; height: 42vmax;
  top: -16vmax; left: -10vmax;
  background: radial-gradient(closest-side, var(--sage) 0%, transparent 70%);
  opacity: 0.4;
}
.a2 {
  width: 36vmax; height: 36vmax;
  bottom: -20vmax; right: -10vmax;
  background: radial-gradient(closest-side, var(--apricot) 0%, transparent 70%);
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

.hero { max-width: 38rem; margin-bottom: 4rem; }
.hero h1 { margin: 1rem 0 1.5rem; }
.hero h1 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--apricot));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede { font-size: var(--t-body-l); }

.state {
  padding: 4rem 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.2rem;
  text-align: center;
}
.loading-dots { display: inline-flex; gap: 6px; }
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

.err {
  padding: 0.8rem 1rem;
  background: rgba(232, 184, 176, 0.2);
  color: #8B4530;
  border-radius: var(--bubble-3);
  margin-bottom: 1.5rem;
  font-family: var(--font-display);
  font-style: italic;
}

/* ── stats petals ── */
.stats { margin-bottom: 5rem; }
.stats-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--ink-whisper);
}
.stats-head h2 { margin: 0; }
.nav-pill {
  font-size: var(--t-small);
  color: var(--sage-deep);
  padding: 0.4rem 1rem;
  background: rgba(168, 216, 197, 0.18);
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
  gap: 1.2rem;
}

.stat {
  position: relative;
  padding: 1.6rem 1.4rem 1.4rem;
  background: var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.15);
  border-radius: var(--bubble-1);
  transform: rotate(var(--rot, 0deg));
  isolation: isolate;
  overflow: hidden;
  min-height: 8rem;
  animation: card-in 0.8s cubic-bezier(0.22, 1, 0.36, 1) backwards;
  animation-delay: var(--d, 0s);
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1), border-radius 1.2s ease;
}
.stat:hover { transform: rotate(0) translateY(-3px); }
.shape-1 { border-radius: var(--bubble-1); }
.shape-2 { border-radius: var(--bubble-2); }
.shape-3 { border-radius: var(--bubble-3); }
.shape-4 { border-radius: var(--bubble-4); }

@keyframes card-in {
  0%   { opacity: 0; transform: translateY(14px) rotate(var(--rot, 0deg)); }
  100% { opacity: 1; transform: translateY(0)   rotate(var(--rot, 0deg)); }
}

.stat-petal {
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: inherit;
  background: radial-gradient(ellipse at 20% 80%, var(--sage-soft) 0%, transparent 60%);
  opacity: 0.6;
  animation: petal-rotate 16s ease-in-out infinite alternate;
}
.shape-2 .stat-petal { background: radial-gradient(ellipse at 70% 30%, var(--apricot-soft) 0%, transparent 60%); }
.shape-3 .stat-petal { background: radial-gradient(ellipse at 50% 50%, var(--cream) 0%, transparent 60%); }
.shape-4 .stat-petal { background: radial-gradient(ellipse at 30% 30%, var(--rose) -10%, transparent 60%); }

@keyframes petal-rotate {
  0% { transform: scale(1) rotate(0deg); }
  100% { transform: scale(1.15) rotate(10deg); }
}

.stat-label {
  display: block;
  font-size: var(--t-micro);
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  margin-bottom: 0.6rem;
}
.stat-value {
  display: block;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 144, 'SOFT' 80, 'wght' 350;
  font-size: clamp(2rem, 4vw, 2.8rem);
  color: var(--ink);
  line-height: 1;
}
.stat-value small {
  font-size: 0.5em;
  color: var(--ink-soft);
  margin-left: 0.3em;
}
.stat-blank {
  font-size: 0.95rem;
  color: var(--ink-quiet);
  font-style: italic;
}
.stat.empty .stat-petal { opacity: 0.3; }

/* edit card */
.edit-card {
  background: var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.18);
  border-radius: var(--bubble-2);
  padding: 2rem;
  box-shadow: var(--shadow-soft);
}
.edit-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
  gap: 1.5rem 2rem;
  margin-bottom: 2rem;
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
  padding: 0.7rem 0;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100;
  font-size: 1.5rem;
  color: var(--ink);
  background: transparent;
  border: none;
  border-bottom: 1px solid var(--ink-whisper);
  outline: none;
  transition: border-color 0.4s;
}
.field input:focus { border-color: var(--sage-deep); }
.seg {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}
.seg button {
  padding: 0.5rem 1rem;
  font-size: 0.95rem;
  color: var(--ink-soft);
  background: rgba(168, 216, 197, 0.12);
  border: 1px solid rgba(107, 143, 122, 0.25);
  border-radius: 999px;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}
.seg button.on {
  background: var(--sage-deep);
  color: var(--bone);
}

.edit-actions {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  justify-content: flex-end;
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
  transform: scaleX(0); transform-origin: right;
  transition: transform 0.5s cubic-bezier(0.22, 1, 0.36, 1);
}
.quiet-btn:hover::after { transform: scaleX(1); transform-origin: left; }

.pebble {
  position: relative;
  padding: 0.7rem 2rem;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100, 'wght' 500;
  font-size: 1.05rem;
  color: var(--ink);
  border-radius: var(--bubble-2);
  cursor: pointer;
  isolation: isolate;
  transition: border-radius 1s, transform 0.5s;
}
.pebble:disabled { opacity: 0.6; cursor: wait; }
.pebble:hover:not(:disabled) { border-radius: var(--bubble-3); transform: translateY(-2px); }
.pebble-bg {
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: inherit;
  background: linear-gradient(135deg, var(--sage) 0%, var(--apricot) 100%);
  opacity: 0.85;
}

/* ── summary ── */
.summary { margin-bottom: 5rem; }
.summary h2 { margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 1px solid var(--ink-whisper); }
.summary h2 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--apricot), var(--sage-deep));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.summary-text {
  margin: 0 0 1.5rem;
  padding: 2rem clamp(2rem, 4vw, 3rem);
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100, 'wght' 350;
  font-style: italic;
  font-size: clamp(1.1rem, 1.6vw, 1.4rem);
  line-height: 1.65;
  color: var(--ink);
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.6), rgba(168, 216, 197, 0.12)),
    var(--bone);
  border-radius: var(--bubble-3);
  position: relative;
  border-left: 3px solid var(--sage-deep);
}
.quote-mark {
  font-size: 2.4em;
  color: var(--sage-deep);
  vertical-align: -0.4em;
  line-height: 0;
  margin-right: 0.1em;
}
.quote-mark.close { margin-right: 0; margin-left: 0.1em; }

.tags { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; }
.tags-label {
  font-size: var(--t-micro);
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  margin-right: 0.5rem;
}
.tag {
  padding: 0.3rem 0.85rem;
  font-size: 0.85rem;
  color: #B5645B;
  background: rgba(232, 184, 176, 0.25);
  border: 1px solid rgba(181, 100, 91, 0.3);
  border-radius: 999px;
}

/* ── memories ── */
.mem-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--ink-whisper);
  flex-wrap: wrap;
  gap: 1rem;
}
.mem-head h2 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--apricot), var(--sage-deep));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.mem-count {
  font-size: var(--t-small);
  color: var(--ink-quiet);
}

.empty .empty-orb {
  width: 9rem; height: 9rem;
  background: radial-gradient(closest-side, var(--apricot-soft), transparent 70%);
  border-radius: var(--bubble-1);
  filter: blur(6px);
  animation: morph 18s ease-in-out infinite alternate;
}
@keyframes morph {
  0% { border-radius: var(--bubble-1); }
  50% { border-radius: var(--bubble-3); }
  100% { border-radius: var(--bubble-4); }
}

.mem-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(18rem, 1fr));
  gap: 1.1rem;
}

.mem {
  position: relative;
  padding: 1.2rem 1.4rem;
  background: var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.15);
  border-radius: var(--bubble-3);
  isolation: isolate;
  overflow: hidden;
  transform: rotate(var(--rot, 0deg));
  animation: card-in 0.8s cubic-bezier(0.22, 1, 0.36, 1) backwards;
  animation-delay: var(--d, 0s);
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
  /* importance affects shadow strength */
  box-shadow: 0 12px 30px -22px rgba(42, 61, 53, calc(0.1 + var(--imp, 0.5) * 0.25));
}
.mem:hover {
  transform: rotate(0) translateY(-3px);
}
.mem.busy { opacity: 0.5; pointer-events: none; }

.mem-petal {
  position: absolute;
  inset: 0; z-index: -1;
  border-radius: inherit;
  background: radial-gradient(ellipse at 80% 20%, var(--sage-soft) 0%, transparent 65%);
  opacity: calc(0.3 + var(--imp, 0.5) * 0.5);
}

.mem-row1 {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  margin-bottom: 0.6rem;
}
.mem-cat {
  font-size: var(--t-micro);
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--sage-deep);
  font-weight: 500;
}
.mem-bar {
  flex: 1;
  height: 3px;
  background: rgba(107, 143, 122, 0.18);
  border-radius: 2px;
  overflow: hidden;
}
.mem-bar i {
  display: block;
  height: 100%;
  background: linear-gradient(90deg, var(--sage-deep), var(--apricot));
  border-radius: 2px;
  transition: width 1s cubic-bezier(0.22, 1, 0.36, 1);
}
.mem-forget {
  width: 26px; height: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: var(--ink-quiet);
  cursor: pointer;
  transition: all 0.3s;
}
.mem-forget:hover {
  background: rgba(232, 184, 176, 0.3);
  color: #B5645B;
}

.mem-fact {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100, 'wght' 400;
  font-size: 1.02rem;
  line-height: 1.5;
  color: var(--ink);
  margin-bottom: 0.6rem;
}
.mem-date {
  font-size: 0.78rem;
  color: var(--ink-quiet);
}

@media (max-width: 700px) {
  .stats-grid { grid-template-columns: 1fr 1fr; }
  .mem-list { grid-template-columns: 1fr; }
  .edit-grid { grid-template-columns: 1fr; }
}
</style>
