<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import AppNav from "../components/AppNav.vue";
import { AudioRecorder } from "../lib/audio/recorder";
import { PcmPlayer } from "../lib/audio/player";
import { CameraCapture } from "../lib/video/camera";
import { VoiceSession } from "../lib/voice-session";

type CallStatus =
  | "connecting"      // ws handshake
  | "listening"       // ready, mic open, nobody talking
  | "user-talking"    // VAD detected user speech
  | "ai-talking"      // AI audio playing
  | "error"
  | "ended";

const route = useRoute();
const router = useRouter();

const status = ref<CallStatus>("connecting");
const errorMsg = ref<string | null>(null);
const conversationId = ref<string | null>(null);
const userTranscript = ref<string>("");
const aiTranscript = ref<string>("");
const muted = ref(false);
const videoOn = ref(false);
const videoBusy = ref(false);
const videoEl = ref<HTMLVideoElement | null>(null);
const elapsed = ref(0); // seconds since connect

const recorder = new AudioRecorder();
const player = new PcmPlayer();
const camera = new CameraCapture();
let session: VoiceSession | null = null;
let drainPoll = 0;
let tickTimer = 0;
let startTs = 0;

const statusLabel = computed(() => {
  switch (status.value) {
    case "connecting":    return "正在接通…";
    case "listening":     return "在听你说";
    case "user-talking":  return "嗯，我听着";
    case "ai-talking":    return "小云在说…";
    case "error":         return errorMsg.value ?? "出错了";
    case "ended":         return "通话结束";
  }
});

const subLabel = computed(() => {
  switch (status.value) {
    case "connecting":    return "麦克风正在唤醒";
    case "listening":     return "随时说一句吧 —— 说完她会回";
    case "user-talking":  return "继续说，我不打断你";
    case "ai-talking":    return "等她说完，再回你";
    case "error":         return "可以试试重连";
    case "ended":         return "已挂断";
  }
});

const elapsedFmt = computed(() => {
  const m = Math.floor(elapsed.value / 60);
  const s = elapsed.value % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
});

function setStatus(s: CallStatus) {
  status.value = s;
}

async function start() {
  errorMsg.value = null;
  setStatus("connecting");

  session = new VoiceSession({
    onConnected: async (cid) => {
      conversationId.value = cid ?? null;
      startTs = Date.now();
      tickTimer = window.setInterval(() => {
        elapsed.value = Math.floor((Date.now() - startTs) / 1000);
      }, 1000);

      // Don't claim we're "listening" until the mic is actually capturing —
      // permission prompt can hang for a long time.
      try {
        await recorder.start((b64) => {
          if (!muted.value) session?.sendAudio(b64);
        });
        setStatus("listening");
      } catch (e: any) {
        errorMsg.value = "麦克风启动失败 —— 请在浏览器允许麦克风权限";
        setStatus("error");
      }
    },
    onAiTextDelta: (delta) => {
      aiTranscript.value += delta;
    },
    onAiText: (full) => {
      // backend signals the final transcript for this reply — use it as the source of truth
      aiTranscript.value = full;
    },
    onAudio: (b64) => {
      if (status.value !== "ai-talking") {
        setStatus("ai-talking");
        recorder.gateOn(); // soft-mute mic while speaker is playing AI voice
      }
      player.play(b64);
    },
    onUserText: (text) => {
      userTranscript.value = text;
    },
    onSpeechStarted: () => {
      // user is talking — if AI was speaking, barge-in: cancel its audio
      player.stop();
      recorder.gateOff();
      setStatus("user-talking");
      // start a new transcript window
      aiTranscript.value = "";
    },
    onSpeechStopped: () => {
      if (status.value === "user-talking") setStatus("listening");
    },
    onDone: () => {
      // backend says AI's reply is done — but `player` may still have buffered audio
      // queued. Poll the player until its scheduler drains, then return to listening.
      if (drainPoll) clearInterval(drainPoll);
      drainPoll = window.setInterval(() => {
        if (!player.isPlaying) {
          clearInterval(drainPoll);
          drainPoll = 0;
          recorder.gateOff();
          if (status.value === "ai-talking") setStatus("listening");
        }
      }, 200);
    },
    onError: (msg) => {
      errorMsg.value = msg;
      setStatus("error");
    },
    onClose: () => {
      if (tickTimer) { clearInterval(tickTimer); tickTimer = 0; }
      if (drainPoll) { clearInterval(drainPoll); drainPoll = 0; }
      if (status.value !== "error" && status.value !== "ended") {
        setStatus("ended");
      }
    },
  });

  const fromConv = route.query.conversationId as string | undefined;
  session.connect(fromConv);
}

function hangup() {
  try { recorder.stop(); } catch {}
  try { player.stop(); } catch {}
  try { camera.stop(); } catch {}
  videoOn.value = false;
  session?.close();
  session = null;
  if (drainPoll) { clearInterval(drainPoll); drainPoll = 0; }
  if (tickTimer) { clearInterval(tickTimer); tickTimer = 0; }
  setStatus("ended");
}

function toggleMute() {
  muted.value = !muted.value;
}

async function toggleVideo() {
  if (videoBusy.value) return;
  if (videoOn.value) {
    try { camera.stop(); } catch {}
    if (videoEl.value) videoEl.value.srcObject = null;
    videoOn.value = false;
    return;
  }
  videoBusy.value = true;
  try {
    const stream = await camera.start({
      width: 640,
      height: 480,
      fps: 1,
      quality: 0.7,
      onFrame: (b64) => { session?.sendImage(b64); },
    });
    if (videoEl.value) {
      videoEl.value.srcObject = stream;
      await videoEl.value.play().catch(() => {});
    }
    videoOn.value = true;
  } catch (e: any) {
    errorMsg.value = "摄像头启动失败 —— 请检查浏览器权限";
  } finally {
    videoBusy.value = false;
  }
}

function backToChat() {
  hangup();
  if (conversationId.value) {
    router.push({ path: "/chat", query: { conversationId: conversationId.value } });
  } else {
    router.push("/chat");
  }
}

onMounted(start);
onUnmounted(hangup);
</script>

<template>
  <div class="call-page" :class="`s-${status}`">
    <div class="aura a1" aria-hidden="true"></div>
    <div class="aura a2" aria-hidden="true"></div>

    <AppNav>
      <template #extra>
        <span class="convo-id" v-if="conversationId">· 续接 {{ conversationId.slice(0, 8) }}</span>
        <span class="timer">{{ elapsedFmt }}</span>
      </template>
    </AppNav>

    <main class="frame">
      <!-- ── breathing orb ── -->
      <div class="stage">
        <div class="orb-wrap" :class="{ 'with-video': videoOn }" aria-hidden="true">
          <span class="orb orb-back"></span>
          <span class="orb orb-mid"></span>
          <span class="orb orb-front"></span>
          <span class="orb-pulse" v-if="status === 'ai-talking' && !videoOn"></span>

          <!-- video preview takes over the orb space when on -->
          <video
            ref="videoEl"
            class="cam-preview"
            :class="{ on: videoOn }"
            autoplay
            playsinline
            muted
          ></video>

          <!-- organic filter overlays: order matters (drawn bottom → top) -->
          <span class="cam-tint"     :class="{ on: videoOn }" aria-hidden="true"></span>
          <span class="cam-vignette" :class="{ on: videoOn }" aria-hidden="true"></span>
          <span class="cam-grain"    :class="{ on: videoOn }" aria-hidden="true"></span>

          <!-- subtle pulse ring during AI playback, even with video on -->
          <span class="orb-pulse video-pulse" v-if="status === 'ai-talking' && videoOn"></span>
        </div>

        <div class="caption">
          <p class="eyebrow">{{ statusLabel }}</p>
          <p class="muted sub">{{ subLabel }}</p>
        </div>
      </div>

      <!-- ── transcript ── -->
      <section class="transcript" v-if="userTranscript || aiTranscript">
        <div v-if="userTranscript" class="line user">
          <span class="role">你说</span>
          <p class="text">{{ userTranscript }}</p>
        </div>
        <div v-if="aiTranscript" class="line ai">
          <span class="role">
            小云
            <span class="streaming" v-if="status === 'ai-talking'">
              <i></i><i></i><i></i>
            </span>
          </span>
          <p class="text">{{ aiTranscript }}</p>
        </div>
      </section>

      <!-- ── controls ── -->
      <div class="controls">
        <button class="ctrl" :class="{ on: muted }" @click="toggleMute" data-hover>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <path v-if="!muted" d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3zM19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" />
            <path v-else d="M2 2l20 20M19 10v2a7 7 0 0 1-1 3.5M5 10v2a7 7 0 0 0 12 5M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 .88 2.12" />
          </svg>
          <span>{{ muted ? "已静音" : "静音麦克风" }}</span>
        </button>

        <button class="ctrl" :class="{ on: videoOn, busy: videoBusy }" @click="toggleVideo" :disabled="videoBusy" data-hover>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <path v-if="!videoOn" d="M23 7l-7 5 7 5V7zM14 5H3a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z" />
            <path v-else d="M2 2l20 20M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2m5 0h4a2 2 0 0 1 2 2v4M23 7v10l-5-3.6" />
          </svg>
          <span>{{ videoOn ? "关摄像头" : "开摄像头" }}</span>
        </button>

        <button class="ctrl hangup" @click="hangup" data-hover>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 9c-3 0-5.5.6-7.5 1.7L3 13c-.6.4-1.4.3-1.8-.3l-1-1.4c-.4-.6-.3-1.4.3-1.9C3.6 7.8 7.5 6.5 12 6.5s8.4 1.3 11.5 3c.6.4.7 1.2.3 1.8l-1 1.4c-.4.6-1.2.7-1.8.3l-1.5-1.3C17.5 9.6 15 9 12 9z" transform="rotate(135 12 12)" />
          </svg>
          <span>挂断</span>
        </button>

        <button class="ctrl" @click="backToChat" data-hover v-if="status === 'ended' || status === 'error'">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" />
          </svg>
          <span>回到对话</span>
        </button>
      </div>
    </main>
  </div>
</template>

<style scoped>
.call-page {
  position: relative;
  min-height: 100vh;
  isolation: isolate;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.aura {
  position: absolute;
  pointer-events: none;
  filter: blur(80px);
  z-index: 0;
  animation: drift 22s ease-in-out infinite alternate;
}
.a1 {
  width: 48vmax; height: 48vmax;
  top: -18vmax; left: -10vmax;
  background: radial-gradient(closest-side, var(--sage) 0%, transparent 70%);
  opacity: 0.55;
}
.a2 {
  width: 42vmax; height: 42vmax;
  bottom: -18vmax; right: -10vmax;
  background: radial-gradient(closest-side, var(--apricot) 0%, transparent 70%);
  opacity: 0.5;
  animation-delay: -10s;
}

.convo-id {
  font-family: var(--font-mono);
  font-size: 0.78rem;
  color: var(--ink-quiet);
  letter-spacing: 0.05em;
}
.timer {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 80;
  font-feature-settings: 'tnum';
  font-size: 1rem;
  color: var(--ink);
  letter-spacing: 0.06em;
}

.frame {
  position: relative;
  z-index: 5;
  flex: 1;
  display: grid;
  grid-template-rows: 1fr auto auto;
  gap: 2rem;
  padding: 2rem clamp(1rem, 3vw, 3rem) 3rem;
  max-width: 720px;
  margin-inline: auto;
  width: 100%;
}

/* ── orb stage ── */
.stage {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2.5rem;
  text-align: center;
}

.orb-wrap {
  position: relative;
  width: clamp(15rem, 36vmin, 22rem);
  aspect-ratio: 1;
}

.orb {
  position: absolute;
  inset: 0;
  border-radius: var(--bubble-1);
  will-change: border-radius, transform, opacity;
}

.orb-back {
  background: radial-gradient(ellipse at 30% 30%, rgba(244, 197, 176, 0.7), transparent 65%);
  animation: orb-morph 18s ease-in-out infinite alternate;
  filter: blur(20px);
  transform: scale(1.1);
}
.orb-mid {
  background: radial-gradient(ellipse at 60% 50%, rgba(168, 216, 197, 0.95), rgba(168, 216, 197, 0.5) 55%, transparent 78%);
  animation: orb-morph 14s ease-in-out infinite alternate-reverse;
  filter: blur(2px);
}
.orb-front {
  background: radial-gradient(ellipse at 40% 60%, rgba(245, 230, 201, 0.7), transparent 65%);
  animation: orb-morph 22s ease-in-out infinite alternate;
  transform: scale(0.7);
}

@keyframes orb-morph {
  0%   { border-radius: var(--bubble-1); transform: scale(1)    rotate(0deg); }
  25%  { border-radius: var(--bubble-2); transform: scale(1.04) rotate(2deg); }
  50%  { border-radius: var(--bubble-3); transform: scale(0.98) rotate(-1deg); }
  75%  { border-radius: var(--bubble-4); transform: scale(1.03) rotate(3deg); }
  100% { border-radius: var(--bubble-1); transform: scale(1)    rotate(0deg); }
}

/* status modifiers */
.s-connecting .orb-mid { animation-duration: 4s; filter: blur(4px) saturate(0.7); }
.s-connecting .orb-back, .s-connecting .orb-front { opacity: 0.5; }

.s-listening .orb-mid { background: radial-gradient(ellipse at 60% 50%, rgba(168, 216, 197, 0.95), rgba(168, 216, 197, 0.5) 55%, transparent 78%); }

.s-user-talking .orb-mid {
  background: radial-gradient(ellipse at 60% 50%, rgba(107, 143, 122, 0.95), rgba(107, 143, 122, 0.5) 55%, transparent 78%);
  animation-duration: 3s;
}

.s-ai-talking .orb-mid {
  background: radial-gradient(ellipse at 60% 50%, rgba(244, 197, 176, 1), rgba(244, 197, 176, 0.55) 55%, transparent 78%);
  animation-duration: 2.5s;
}

.s-error .orb-mid {
  background: radial-gradient(ellipse at 60% 50%, rgba(232, 184, 176, 0.85), transparent 75%);
}

.s-ended .orb-back, .s-ended .orb-mid, .s-ended .orb-front {
  animation-play-state: paused;
  filter: blur(8px) grayscale(0.6);
  opacity: 0.4;
}

/* AI talking pulse ring */
.orb-pulse {
  position: absolute;
  inset: -8%;
  border-radius: 50%;
  border: 2px solid rgba(244, 197, 176, 0.6);
  animation: orb-pulse 1.6s ease-out infinite;
}
.orb-pulse.video-pulse {
  border-color: rgba(244, 197, 176, 0.85);
  inset: -4%;
}
@keyframes orb-pulse {
  0%   { transform: scale(0.9); opacity: 0.7; }
  100% { transform: scale(1.35); opacity: 0; }
}

/* ── camera preview + organic overlays ──
   The preview reads as a softly mirrored "skin" of the orb. We layer:
     (1) video itself, with a warm sepia-leaning filter
     (2) sage→apricot color tint blended soft-light
     (3) radial vignette feathering the edges into the page bg
     (4) faint paper grain matching the global body texture
   All four share .cam-* and follow `.on` for synchronized fade.            */
.cam-preview,
.cam-tint,
.cam-vignette,
.cam-grain {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  border-radius: var(--bubble-1);
  pointer-events: none;
  opacity: 0;
  animation: cam-breathe 18s ease-in-out infinite alternate;
  transition: opacity 0.7s cubic-bezier(0.22, 1, 0.36, 1);
}
.cam-preview.on,
.cam-tint.on,
.cam-vignette.on,
.cam-grain.on { opacity: 1; }

.cam-preview {
  object-fit: cover;
  z-index: 2;
  background: var(--bone-deep);
  box-shadow: var(--shadow-bloom);
  border: 1px solid rgba(255, 255, 255, 0.55);
  /* scaleX(-1) on a top-level transform would be clobbered by morph anims
     that also set transform. We morph only border-radius here so the mirror
     flip stays stable. */
  transform: scaleX(-1);
  /* warm, slightly-faded color grade — like soft morning light */
  filter: saturate(1.12) brightness(1.05) contrast(0.94) sepia(0.06) hue-rotate(-4deg);
}

/* (2) color tint — sage from one corner, apricot from the other */
.cam-tint {
  z-index: 3;
  background:
    linear-gradient(135deg,
      rgba(244, 197, 176, 0.22) 0%,
      transparent 40%,
      rgba(168, 216, 197, 0.20) 100%);
  mix-blend-mode: soft-light;
}
.cam-tint.on { opacity: 0.95; }

/* (3) vignette — feather the edges so the video melts into the page */
.cam-vignette {
  z-index: 4;
  background: radial-gradient(closest-side,
    transparent 50%,
    rgba(248, 244, 237, 0.45) 88%,
    rgba(248, 244, 237, 0.85) 100%);
}

/* (4) grain — same SVG turbulence as global body, just slightly stronger */
.cam-grain {
  z-index: 5;
  mix-blend-mode: multiply;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='240' height='240'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2' seed='8'/><feColorMatrix values='0 0 0 0 0.16  0 0 0 0 0.24  0 0 0 0 0.21  0 0 0 0.85 0'/></filter><rect width='100%25' height='100%25' filter='url(%23n)'/></svg>");
  background-size: 220px 220px;
}
.cam-grain.on { opacity: 0.12; }

@keyframes cam-breathe {
  0%   { border-radius: var(--bubble-1); }
  33%  { border-radius: var(--bubble-2); }
  66%  { border-radius: var(--bubble-3); }
  100% { border-radius: var(--bubble-4); }
}

/* when video is on, dim background orb layers so the preview reads cleanly */
.orb-wrap.with-video .orb-back { opacity: 0.25; }
.orb-wrap.with-video .orb-mid  { opacity: 0; }
.orb-wrap.with-video .orb-front { opacity: 0.18; }

.caption {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.eyebrow {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 80, 'SOFT' 100, 'wght' 400;
  font-size: clamp(1.6rem, 3.4vw, 2.4rem);
  color: var(--ink);
  letter-spacing: -0.01em;
  text-transform: none;
}
.sub {
  font-size: var(--t-body);
  color: var(--ink-soft);
}

/* ── transcript ── */
.transcript {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-height: 22vh;
  overflow-y: auto;
  padding: 1rem 1.3rem;
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.5), rgba(168, 216, 197, 0.1)),
    rgba(248, 244, 237, 0.6);
  border: 1px solid rgba(107, 143, 122, 0.18);
  border-radius: var(--bubble-2);
  backdrop-filter: blur(6px);
}

.line { display: flex; gap: 0.8rem; align-items: flex-start; }
.line .role {
  flex-shrink: 0;
  width: 3.2rem;
  font-size: var(--t-micro);
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--ink-quiet);
  padding-top: 0.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}
.line .text {
  flex: 1;
  font-size: 0.98rem;
  line-height: 1.55;
  color: var(--ink);
}
.line.ai .text {
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 24, 'SOFT' 100, 'wght' 400;
}

.streaming { display: inline-flex; gap: 2px; }
.streaming i {
  width: 3px; height: 8px;
  background: var(--sage-deep);
  border-radius: 2px;
  animation: pulse 1.2s ease-in-out infinite;
}
.streaming i:nth-child(2) { animation-delay: 0.15s; }
.streaming i:nth-child(3) { animation-delay: 0.30s; }
@keyframes pulse {
  0%, 100% { transform: scaleY(0.5); opacity: 0.5; }
  50%      { transform: scaleY(1);   opacity: 1; }
}

/* ── controls ── */
.controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.ctrl {
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.85rem 1.4rem;
  font-family: var(--font-display);
  font-variation-settings: 'opsz' 18, 'SOFT' 100;
  font-size: 0.95rem;
  color: var(--ink);
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.7), rgba(168, 216, 197, 0.12)),
    var(--bone);
  border: 1px solid rgba(107, 143, 122, 0.25);
  border-radius: var(--bubble-1);
  cursor: pointer;
  transition: all 0.5s cubic-bezier(0.22, 1, 0.36, 1);
}
.ctrl:hover {
  transform: translateY(-2px) rotate(-1deg);
  border-radius: var(--bubble-3);
  box-shadow: var(--shadow-soft);
}
.ctrl.on {
  background: var(--sage-deep);
  color: var(--bone);
  border-color: var(--sage-deep);
}
.ctrl.hangup {
  background: linear-gradient(135deg, var(--rose), #C77968);
  color: var(--bone);
  border-color: rgba(181, 100, 91, 0.4);
}
.ctrl.hangup:hover {
  transform: translateY(-2px) rotate(2deg);
}

@media (max-width: 700px) {
  .ctrl span { display: none; }
  .ctrl { padding: 0.85rem; }
  .transcript { max-height: 30vh; }
}
</style>
