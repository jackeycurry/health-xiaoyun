import { getToken } from "../services/api";

/**
 * Frames the backend sends us (see backend/routers/voice.py).
 */
export type ServerEvent =
  | { type: "connected"; conversation_id?: string }
  | { type: "text"; data: string }         // AI text transcript delta (streaming)
  | { type: "audio"; data: string }        // AI audio PCM delta (base64)
  | { type: "ai_text"; data: string }      // AI complete text for one reply
  | { type: "user_text"; data: string }    // user speech transcribed
  | { type: "speech_started" }             // user started talking → barge-in
  | { type: "speech_stopped" }
  | { type: "done" }                       // one AI reply finished
  | { type: "error"; data: string };

export interface VoiceCallbacks {
  onConnected?: (conversationId?: string) => void;
  onAiText?: (full: string) => void;
  onAiTextDelta?: (delta: string) => void;
  onAudio?: (b64: string) => void;
  onUserText?: (text: string) => void;
  onSpeechStarted?: () => void;
  onSpeechStopped?: () => void;
  onDone?: () => void;
  onError?: (msg: string) => void;
  onClose?: (code: number, reason: string) => void;
}

/**
 * Thin wrapper around the voice WebSocket.
 *
 * - Auth: token goes in the query string. EventSource-style headers don't
 *   apply to WebSocket either; the backend has explicit `?token=` fallback.
 * - Heartbeat: 15s ping (backend ignores body, but it keeps any reverse
 *   proxy from idle-killing the connection).
 */
export class VoiceSession {
  private ws: WebSocket | null = null;
  private heartbeat = 0;

  constructor(private cb: VoiceCallbacks) {}

  get readyState(): number {
    return this.ws?.readyState ?? WebSocket.CLOSED;
  }

  connect(conversationId?: string): void {
    const token = getToken();
    if (!token) {
      this.cb.onError?.("未登录");
      return;
    }
    const proto = location.protocol === "https:" ? "wss:" : "ws:";
    const qs = new URLSearchParams({ token });
    if (conversationId) qs.set("conversation_id", conversationId);
    const url = `${proto}//${location.host}/api/consult/voice/ws?${qs.toString()}`;

    const ws = new WebSocket(url);
    this.ws = ws;

    ws.onopen = () => {
      // start heartbeat after open
      this.heartbeat = window.setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: "ping" }));
        }
      }, 15000);
    };

    ws.onmessage = (ev) => {
      if (typeof ev.data !== "string") return;
      let msg: ServerEvent;
      try { msg = JSON.parse(ev.data); } catch { return; }

      switch (msg.type) {
        case "connected":       this.cb.onConnected?.(msg.conversation_id); break;
        case "text":            this.cb.onAiTextDelta?.(msg.data); break;
        case "audio":           this.cb.onAudio?.(msg.data); break;
        case "ai_text":         this.cb.onAiText?.(msg.data); break;
        case "user_text":       this.cb.onUserText?.(msg.data); break;
        case "speech_started":  this.cb.onSpeechStarted?.(); break;
        case "speech_stopped":  this.cb.onSpeechStopped?.(); break;
        case "done":            this.cb.onDone?.(); break;
        case "error":           this.cb.onError?.(msg.data); break;
      }
    };

    ws.onerror = () => {
      this.cb.onError?.("WebSocket 连接出错");
    };

    ws.onclose = (e) => {
      clearInterval(this.heartbeat);
      this.heartbeat = 0;
      this.cb.onClose?.(e.code, e.reason);
    };
  }

  sendAudio(b64: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type: "audio", data: b64 }));
    }
  }

  sendImage(b64: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type: "image", data: b64 }));
    }
  }

  commit(): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type: "commit" }));
    }
  }

  close(): void {
    if (this.heartbeat) clearInterval(this.heartbeat);
    this.heartbeat = 0;
    try {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: "stop" }));
      }
    } catch {}
    try { this.ws?.close(); } catch {}
    this.ws = null;
  }
}
