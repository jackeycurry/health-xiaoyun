/**
 * Streaming PCM player for AI audio from DashScope realtime.
 *
 * Each `play(b64)` call enqueues an Int16 LE PCM chunk @ 24kHz, scheduled
 * back-to-back via `AudioBufferSourceNode.start(scheduledTime)` so chunks
 * play seamlessly without gaps. `stop()` cancels everything queued — used
 * for barge-in when the user starts speaking mid-reply.
 */
export class PcmPlayer {
  private ctx: AudioContext | null = null;
  private nextStartTime = 0;
  private sources: AudioBufferSourceNode[] = [];

  private ensure(): AudioContext {
    if (this.ctx) return this.ctx;
    const AC = (window.AudioContext || (window as any).webkitAudioContext) as typeof AudioContext;
    this.ctx = new AC({ sampleRate: 24000 });
    return this.ctx;
  }

  play(b64: string): void {
    if (!b64) return;
    const ctx = this.ensure();
    try {
      const bin = atob(b64);
      const bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      const samples = bytes.length / 2;
      const buf = ctx.createBuffer(1, samples, 24000);
      const channel = buf.getChannelData(0);
      const view = new DataView(bytes.buffer);
      for (let i = 0; i < samples; i++) {
        channel[i] = view.getInt16(i * 2, true) / 32768;
      }

      const src = ctx.createBufferSource();
      src.buffer = buf;
      src.connect(ctx.destination);

      const startAt = Math.max(ctx.currentTime, this.nextStartTime);
      src.start(startAt);
      src.onended = () => {
        const i = this.sources.indexOf(src);
        if (i >= 0) this.sources.splice(i, 1);
      };
      this.sources.push(src);
      this.nextStartTime = startAt + buf.duration;
    } catch (e) {
      console.error("[PcmPlayer] decode/play failed", e);
    }
  }

  /** True if any buffered audio is still scheduled to play. */
  get isPlaying(): boolean {
    const ctx = this.ctx;
    return !!ctx && this.nextStartTime > ctx.currentTime + 0.01;
  }

  /** Cancel everything queued (barge-in). */
  stop(): void {
    this.nextStartTime = 0;
    const sources = this.sources;
    this.sources = [];
    for (const s of sources) {
      try { s.stop(); } catch {}
      try { s.disconnect(); } catch {}
    }
  }

  dispose(): void {
    this.stop();
    try { this.ctx?.close(); } catch {}
    this.ctx = null;
  }
}
