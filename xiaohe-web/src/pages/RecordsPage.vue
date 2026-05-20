<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import AppNav from "../components/AppNav.vue";
import {
  health,
  type HealthRecord,
  type HealthRecordType,
  type LatestRecords,
} from "../services/api";

const records = ref<HealthRecord[]>([]);
const latest = ref<LatestRecords | null>(null);
const loading = ref(true);
const error = ref<string | null>(null);
const busy = ref(false);
const busyId = ref<string | null>(null);

const filterType = ref<"" | HealthRecordType>("");

type TypeMeta = {
  key: HealthRecordType;
  label: string;
  hint: string;
  unit: string;
  fields: { name: string; label: string; placeholder: string; type?: "number" | "text"; step?: string }[];
  shape: number;
  hue: "sage" | "apricot" | "cream" | "rose" | "moss";
};

const types: TypeMeta[] = [
  {
    key: "blood_pressure",
    label: "血压",
    hint: "Blood pressure",
    unit: "mmHg",
    fields: [
      { name: "systolic",  label: "收缩压 (高压)", placeholder: "118", type: "number" },
      { name: "diastolic", label: "舒张压 (低压)", placeholder: "76",  type: "number" },
    ],
    shape: 1,
    hue: "sage",
  },
  {
    key: "heart_rate",
    label: "心率",
    hint: "Heart rate",
    unit: "bpm",
    fields: [{ name: "value", label: "每分钟", placeholder: "72", type: "number" }],
    shape: 2,
    hue: "apricot",
  },
  {
    key: "blood_sugar",
    label: "血糖",
    hint: "Blood sugar",
    unit: "mmol/L",
    fields: [
      { name: "value", label: "数值",  placeholder: "5.6", type: "number", step: "0.1" },
      { name: "when",  label: "时段",  placeholder: "餐后 / 空腹", type: "text" },
    ],
    shape: 3,
    hue: "cream",
  },
  {
    key: "weight",
    label: "体重",
    hint: "Weight",
    unit: "kg",
    fields: [{ name: "value", label: "kg", placeholder: "62", type: "number", step: "0.1" }],
    shape: 4,
    hue: "rose",
  },
  {
    key: "temperature",
    label: "体温",
    hint: "Temperature",
    unit: "℃",
    fields: [{ name: "value", label: "℃", placeholder: "36.8", type: "number", step: "0.1" }],
    shape: 2,
    hue: "moss",
  },
];

const typeByKey = computed(() => Object.fromEntries(types.map((t) => [t.key, t])));

// ── add form ──
const adding = ref(false);
const addType = ref<HealthRecordType>("blood_pressure");
const addFields = reactive<Record<string, string>>({});
const addNote = ref("");
const addTime = ref(toLocalDatetime(new Date()));

function toLocalDatetime(d: Date) {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function resetAdd() {
  Object.keys(addFields).forEach((k) => delete addFields[k]);
  addNote.value = "";
  addTime.value = toLocalDatetime(new Date());
}

function startAdd(t: HealthRecordType) {
  addType.value = t;
  resetAdd();
  adding.value = true;
}

const currentMeta = computed(() => typeByKey.value[addType.value] as TypeMeta);

async function submit() {
  busy.value = true;
  error.value = null;
  try {
    const value: Record<string, any> = {};
    for (const f of currentMeta.value.fields) {
      const raw = addFields[f.name];
      if (raw === undefined || raw === "") continue;
      value[f.name] = f.type === "number" ? Number(raw) : raw;
    }
    if (Object.keys(value).length === 0) {
      error.value = "至少填一个值";
      return;
    }
    const rec = await health.create({
      type: addType.value,
      value,
      recorded_at: new Date(addTime.value).toISOString(),
      note: addNote.value || undefined,
    });
    records.value = [rec, ...records.value];
    latest.value = { ...latest.value!, [addType.value]: value };
    adding.value = false;
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "保存失败";
  } finally {
    busy.value = false;
  }
}

async function remove(r: HealthRecord) {
  if (!confirm(`要忘掉这条记录吗？`)) return;
  busyId.value = r.id;
  try {
    await health.remove(r.id);
    records.value = records.value.filter((x) => x.id !== r.id);
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "删除失败";
  } finally {
    busyId.value = null;
  }
}

async function load() {
  loading.value = true;
  error.value = null;
  try {
    const [list, lat] = await Promise.all([health.list({ limit: 100 }), health.latest()]);
    records.value = list;
    latest.value = lat;
  } catch (e: any) {
    error.value = e?.response?.data?.detail || e?.message || "加载失败";
  } finally {
    loading.value = false;
  }
}

const filtered = computed(() => {
  if (!filterType.value) return records.value;
  return records.value.filter((r) => r.type === filterType.value);
});

function fmtValue(r: HealthRecord) {
  switch (r.type) {
    case "blood_pressure":
      return `${r.value.systolic ?? "—"}/${r.value.diastolic ?? "—"}`;
    case "blood_sugar":
      return `${r.value.value}${r.value.when ? ` · ${r.value.when}` : ""}`;
    default:
      return String(r.value.value ?? "—");
  }
}

function fmtLatest(t: TypeMeta, v: any) {
  if (!v) return null;
  switch (t.key) {
    case "blood_pressure": return `${v.systolic}/${v.diastolic}`;
    default: return String(v.value ?? "—");
  }
}

function fmtTime(iso: string) {
  const d = new Date(iso);
  const now = new Date();
  const sameDay = d.toDateString() === now.toDateString();
  const hm = `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  if (sameDay) return `今天 ${hm}`;
  return `${d.getMonth() + 1}月${d.getDate()}日 ${hm}`;
}

onMounted(load);
</script>

<template>
  <div class="records-page">
    <div class="aura a1" aria-hidden="true"></div>
    <div class="aura a2" aria-hidden="true"></div>

    <AppNav />

    <main class="frame">
      <header class="hero">
        <p class="eyebrow">a quiet ledger for your body</p>
        <h1 class="display display-l">
          身体<br />
          <em>在说什么</em>
        </h1>
        <p class="muted lede">
          血压、心率、体重、体温、血糖 ——<br />
          记下来，让小云替你看趋势。
        </p>
      </header>

      <section v-if="loading" class="state">
        <span class="loading-dots"><i></i><i></i><i></i></span>
        <p class="muted italic-en">让她翻一下记录…</p>
      </section>

      <template v-else>
        <p v-if="error" class="err">{{ error }}</p>

        <!-- ── latest petals ── -->
        <section class="latest">
          <div class="sec-head">
            <h2 class="display display-m">最近一次</h2>
            <span class="sec-hint italic-en">点任意一朵 + 一条</span>
          </div>

          <div class="petals">
            <button
              v-for="(t, i) in types"
              :key="t.key"
              class="petal"
              :class="[`shape-${t.shape}`, `hue-${t.hue}`]"
              :style="{ '--rot': `${(i - 2) * 1.6}deg`, '--d': `${i * 0.08}s` }"
              @click="startAdd(t.key)"
              data-hover
            >
              <span class="petal-bg" aria-hidden="true"></span>
              <span class="petal-head">
                <span class="petal-label">{{ t.label }}</span>
                <span class="petal-hint">{{ t.hint }}</span>
              </span>
              <span v-if="fmtLatest(t, latest && latest[t.key])" class="petal-value">
                {{ fmtLatest(t, latest && latest[t.key]) }}<small>{{ t.unit }}</small>
              </span>
              <span v-else class="petal-empty italic-en">还没记过</span>
              <span class="petal-plus" aria-hidden="true">+</span>
            </button>
          </div>
        </section>

        <!-- ── add form ── -->
        <section v-if="adding" class="add">
          <div class="add-card">
            <header class="add-head">
              <h3 class="display display-m">
                记一次 <em>{{ currentMeta.label }}</em>
              </h3>
              <button class="quiet-btn" @click="adding = false" data-hover>取消</button>
            </header>

            <form @submit.prevent="submit">
              <div class="add-fields">
                <label v-for="f in currentMeta.fields" :key="f.name" class="field">
                  <span class="field-label">{{ f.label }}</span>
                  <input
                    v-model="addFields[f.name]"
                    :type="f.type ?? 'text'"
                    :step="f.step"
                    :placeholder="f.placeholder"
                    :disabled="busy"
                  />
                </label>

                <label class="field">
                  <span class="field-label">什么时候</span>
                  <input v-model="addTime" type="datetime-local" :disabled="busy" />
                </label>
              </div>

              <label class="field note-field">
                <span class="field-label">想加一句话吗？（可选）</span>
                <textarea
                  v-model="addNote"
                  rows="2"
                  placeholder="比如：早上起床测的，刚跑完步…"
                  :disabled="busy"
                ></textarea>
              </label>

              <div class="add-actions">
                <button type="submit" class="pebble" :disabled="busy" data-hover>
                  <span class="pebble-bg" aria-hidden="true"></span>
                  <span>{{ busy ? "记着…" : "记下" }}</span>
                </button>
              </div>
            </form>
          </div>
        </section>

        <!-- ── history list ── -->
        <section class="history">
          <div class="sec-head">
            <h2 class="display display-m">全部 <em>{{ records.length }}</em> 条</h2>
            <div class="filter">
              <button :class="{ on: !filterType }" @click="filterType = ''" data-hover>全部</button>
              <button
                v-for="t in types"
                :key="t.key"
                :class="{ on: filterType === t.key }"
                @click="filterType = t.key"
                data-hover
              >{{ t.label }}</button>
            </div>
          </div>

          <div v-if="!filtered.length" class="state empty">
            <div class="empty-orb" aria-hidden="true"></div>
            <p class="muted">{{ filterType ? "这一类还没记过。" : "还没有记录。" }}</p>
          </div>

          <ul v-else class="rec-list">
            <li
              v-for="(r, i) in filtered"
              :key="r.id"
              class="rec"
              :class="[`hue-${typeByKey[r.type].hue}`, { busy: busyId === r.id }]"
              :style="{ '--d': `${i * 0.04}s` }"
            >
              <span class="rec-dot" aria-hidden="true"></span>
              <span class="rec-type">{{ typeByKey[r.type].label }}</span>
              <span class="rec-value">
                {{ fmtValue(r) }}<small>{{ typeByKey[r.type].unit }}</small>
              </span>
              <span class="rec-time">{{ fmtTime(r.recorded_at) }}</span>
              <span class="rec-note" v-if="r.note">{{ r.note }}</span>
              <button class="rec-del" @click="remove(r)" :disabled="busyId === r.id" data-hover title="删除">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M18 6 6 18M6 6l12 12"/></svg>
              </button>
            </li>
          </ul>
        </section>
      </template>
    </main>
  </div>
</template>

<style scoped>
.records-page { position: relative; min-height: 100vh; isolation: isolate; }
.aura {
  position: absolute;
  pointer-events: none;
  filter: blur(80px);
  z-index: 0;
  animation: drift 24s ease-in-out infinite alternate;
}
.a1 {
  width: 38vmax; height: 38vmax;
  top: -14vmax; right: -10vmax;
  background: radial-gradient(closest-side, var(--cream) 0%, transparent 70%);
  opacity: 0.4;
}
.a2 {
  width: 36vmax; height: 36vmax;
  bottom: -18vmax; left: -10vmax;
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

.hero { max-width: 36rem; margin-bottom: 4rem; }
.hero h1 { margin: 1rem 0 1.5rem; }
.hero h1 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--cream), var(--sage-deep));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede { font-size: var(--t-body-l); }

.sec-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 1rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--ink-whisper);
}
.sec-head h2 { margin: 0; }
.sec-head h2 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--apricot));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.sec-hint { font-size: var(--t-small); color: var(--ink-quiet); }

.state {
  padding: 4rem 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.2rem;
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
  50%      { opacity: 1; transform: scale(1.1); }
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

/* ── petals ── */
.latest { margin-bottom: 4rem; }
.petals {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
  gap: 1.2rem;
}
.petal {
  position: relative;
  padding: 1.4rem 1.4rem 1.6rem;
  background: var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.15);
  border-radius: var(--bubble-1);
  cursor: pointer;
  transform: rotate(var(--rot, 0deg));
  isolation: isolate;
  overflow: hidden;
  text-align: left;
  min-height: 9rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1), border-radius 1.2s ease, box-shadow 0.5s;
  animation: card-in 0.8s cubic-bezier(0.22, 1, 0.36, 1) backwards;
  animation-delay: var(--d, 0s);
}
@keyframes card-in {
  0%   { opacity: 0; transform: translateY(14px) rotate(var(--rot, 0deg)); }
  100% { opacity: 1; transform: translateY(0)   rotate(var(--rot, 0deg)); }
}
.petal:hover {
  transform: rotate(0) translateY(-4px) scale(1.02);
  border-radius: var(--bubble-3);
  box-shadow: var(--shadow-bloom);
}
.shape-1 { border-radius: var(--bubble-1); }
.shape-2 { border-radius: var(--bubble-2); }
.shape-3 { border-radius: var(--bubble-3); }
.shape-4 { border-radius: var(--bubble-4); }

.petal-bg {
  position: absolute;
  inset: 0; z-index: -1;
  border-radius: inherit;
  opacity: 0.45;
  animation: petal-rotate 14s ease-in-out infinite alternate;
}
@keyframes petal-rotate {
  0% { transform: scale(1) rotate(0deg); }
  100% { transform: scale(1.18) rotate(8deg); }
}
.hue-sage    .petal-bg { background: radial-gradient(ellipse at 30% 70%, var(--sage-soft) 0%, transparent 65%); }
.hue-apricot .petal-bg { background: radial-gradient(ellipse at 70% 30%, var(--apricot-soft) 0%, transparent 65%); }
.hue-cream   .petal-bg { background: radial-gradient(ellipse at 50% 50%, var(--cream) 0%, transparent 65%); }
.hue-rose    .petal-bg { background: radial-gradient(ellipse at 30% 80%, var(--rose) -10%, transparent 65%); }
.hue-moss    .petal-bg { background: radial-gradient(ellipse at 80% 20%, var(--sage) -10%, transparent 65%); }

.petal-head { display: flex; flex-direction: column; gap: 0.1rem; }
.petal-label {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100;
  font-size: 1.3rem;
  color: var(--ink);
}
.petal-hint {
  font-size: var(--t-micro);
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--ink-quiet);
}

.petal-value {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 144, 'SOFT' 80, 'wght' 350;
  font-size: clamp(1.7rem, 3.2vw, 2.4rem);
  color: var(--ink);
  line-height: 1;
  margin-top: auto;
}
.petal-value small {
  font-size: 0.4em;
  color: var(--ink-soft);
  margin-left: 0.3em;
}
.petal-empty {
  font-size: 0.9rem;
  color: var(--ink-quiet);
  margin-top: auto;
  font-style: italic;
}

.petal-plus {
  position: absolute;
  top: 1rem;
  right: 1.2rem;
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.6);
  border: 1px solid rgba(107, 143, 122, 0.3);
  color: var(--sage-deep);
  font-size: 1.1rem;
  line-height: 1;
  transition: all 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}
.petal:hover .petal-plus {
  transform: rotate(90deg) scale(1.15);
  background: var(--sage-deep);
  color: var(--bone);
}

/* ── add form ── */
.add { margin-bottom: 4rem; }
.add-card {
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.7), rgba(168, 216, 197, 0.12)),
    var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.25);
  border-radius: var(--bubble-2);
  padding: 2rem;
  box-shadow: var(--shadow-soft);
  animation: card-in 0.7s cubic-bezier(0.22, 1, 0.36, 1) backwards;
}
.add-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 1.8rem;
}
.add-head h3 { margin: 0; }
.add-head h3 em {
  font-style: normal;
  font-variation-settings: 'opsz' 144, 'SOFT' 100, 'wght' 500;
  background: linear-gradient(120deg, var(--sage-deep), var(--apricot));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.add-fields {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr));
  gap: 1.2rem 1.5rem;
  margin-bottom: 1.5rem;
}
.field-label {
  display: block;
  font-size: var(--t-micro);
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  margin-bottom: 0.4rem;
}
.field input, .field textarea {
  width: 100%;
  padding: 0.6rem 0;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100;
  font-size: 1.2rem;
  color: var(--ink);
  background: transparent;
  border: none;
  border-bottom: 1px solid var(--ink-whisper);
  outline: none;
  resize: none;
  transition: border-color 0.4s;
}
.field textarea { font-size: 1rem; }
.field input:focus, .field textarea:focus { border-color: var(--sage-deep); }
.note-field { margin-bottom: 1.5rem; }
.add-actions {
  display: flex;
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
  inset: 0; z-index: -1;
  border-radius: inherit;
  background: linear-gradient(135deg, var(--sage) 0%, var(--apricot) 100%);
  opacity: 0.85;
}

/* ── filter chips ── */
.filter {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}
.filter button {
  padding: 0.32rem 0.9rem;
  font-size: 0.82rem;
  color: var(--ink-soft);
  background: rgba(168, 216, 197, 0.12);
  border: 1px solid rgba(107, 143, 122, 0.22);
  border-radius: 999px;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}
.filter button.on,
.filter button:hover {
  background: var(--sage-deep);
  color: var(--bone);
}

/* ── history list ── */
.history { margin-bottom: 3rem; }
.empty .empty-orb {
  width: 9rem; height: 9rem;
  background: radial-gradient(closest-side, var(--cream), transparent 70%);
  border-radius: var(--bubble-1);
  filter: blur(6px);
  animation: morph 18s ease-in-out infinite alternate;
}
@keyframes morph {
  0% { border-radius: var(--bubble-1); }
  50% { border-radius: var(--bubble-3); }
  100% { border-radius: var(--bubble-4); }
}

.rec-list {
  list-style: none;
  padding: 0;
  margin: 0;
  border-top: 1px solid var(--ink-whisper);
}

.rec {
  display: grid;
  grid-template-columns: 12px 5rem auto 1fr auto auto;
  align-items: center;
  gap: 1rem;
  padding: 1.1rem 0.5rem;
  border-bottom: 1px dashed rgba(107, 143, 122, 0.18);
  animation: row-in 0.6s cubic-bezier(0.22, 1, 0.36, 1) backwards;
  animation-delay: var(--d, 0s);
  transition: background 0.3s;
}
@keyframes row-in {
  0%   { opacity: 0; transform: translateY(8px); }
  100% { opacity: 1; transform: translateY(0); }
}
.rec:hover { background: rgba(168, 216, 197, 0.06); }
.rec.busy { opacity: 0.5; pointer-events: none; }

.rec-dot {
  width: 10px; height: 10px;
  border-radius: 50%;
  background: var(--sage-deep);
  margin-left: 1px;
}
.hue-sage    .rec-dot { background: var(--sage-deep); }
.hue-apricot .rec-dot { background: var(--apricot); }
.hue-cream   .rec-dot { background: var(--cream); border: 1px solid var(--ink-whisper); }
.hue-rose    .rec-dot { background: var(--rose); }
.hue-moss    .rec-dot { background: var(--sage); }

.rec-type {
  font-size: var(--t-small);
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: var(--ink-quiet);
}
.rec-value {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 80, 'wght' 400;
  font-size: 1.6rem;
  color: var(--ink);
  line-height: 1;
}
.rec-value small {
  font-size: 0.5em;
  color: var(--ink-soft);
  margin-left: 0.3em;
}
.rec-time {
  font-size: var(--t-small);
  color: var(--ink-soft);
  font-family: var(--font-display);
  font-style: italic;
  font-variation-settings: 'opsz' 14, 'SOFT' 100;
}
.rec-note {
  font-size: 0.9rem;
  color: var(--ink-soft);
  font-style: italic;
  /* clamp */
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-align: right;
}
.rec-del {
  width: 26px; height: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: var(--ink-quiet);
  cursor: pointer;
  transition: all 0.3s;
}
.rec-del:hover {
  background: rgba(232, 184, 176, 0.3);
  color: #B5645B;
}

@media (max-width: 800px) {
  .rec {
    grid-template-columns: 10px 1fr auto;
    gap: 0.5rem 0.8rem;
  }
  .rec-time, .rec-note { grid-column: 2 / -1; font-size: 0.78rem; text-align: left; }
  .rec-del { grid-column: 3; grid-row: 1; }
}
</style>
