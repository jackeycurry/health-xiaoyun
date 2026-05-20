/**
 * Browser PCM audio recorder for DashScope realtime voice chat.
 *
 *   getUserMedia → AudioContext(16kHz) → ScriptProcessor (4096 buf) →
 *   Float32 → Int16 little-endian → base64 → onChunk(b64)
 *
 * Output matches `audio_recorder_web.dart` in the Flutter app exactly so the
 * backend (`/api/consult/voice/ws`) gets a byte-identical stream.
 *
 * Notes:
 *  - ScriptProcessor is deprecated in favor of AudioWorklet, but it's still
 *    supported everywhere and avoids the cross-origin worklet-file dance.
 *  - The AudioContext sampleRate=16000 hint isn't honored by every browser;
 *    most Chromium/Firefox builds *will* resample, but if `ctx.sampleRate`
 *    comes back different we'd need a manual resample. For our target
 *    (Chrome desktop) this just works.
 */
export class AudioRecorder {
  private ctx: AudioContext | null = null;
  private stream: MediaStream | null = null;
  private src: MediaStreamAudioSourceNode | null = null;
  private proc: ScriptProcessorNode | null = null;
  private gateGain = 1;

  async hasPermission(): Promise<boolean> {
    try {
      const s = await navigator.mediaDevices.getUserMedia({ audio: true });
      s.getTracks().forEach((t) => t.stop());
      return true;
    } catch {
      return false;
    }
  }

  async start(onChunk: (b64: string) => void): Promise<void> {
    this.stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      },
    });

    const AC = (window.AudioContext || (window as any).webkitAudioContext) as typeof AudioContext;
    this.ctx = new AC({ sampleRate: 16000 });
    await this.ctx.resume();

    this.src = this.ctx.createMediaStreamSource(this.stream);
    // 4096 samples @ 16kHz = ~256ms per chunk; small enough for low latency,
    // large enough to keep ws traffic sane.
    this.proc = this.ctx.createScriptProcessor(4096, 1, 1);

    this.proc.onaudioprocess = (e) => {
      const input = e.inputBuffer.getChannelData(0);
      const buf = new ArrayBuffer(input.length * 2);
      const view = new DataView(buf);
      const gate = this.gateGain;
      for (let i = 0; i < input.length; i++) {
        let s = Math.round(input[i] * gate * 32767);
        if (s > 32767) s = 32767;
        else if (s < -32768) s = -32768;
        view.setInt16(i * 2, s, true);
      }
      onChunk(bytesToBase64(new Uint8Array(buf)));
    };

    this.src.connect(this.proc);
    this.proc.connect(this.ctx.destination);
  }

  /**
   * Soft-mute the microphone while the AI is speaking. We don't `track.stop()`
   * — re-acquiring permission would prompt the user. Instead we attenuate
   * captured samples to ~5% so echo from speakers doesn't trigger the VAD.
   */
  gateOn() { this.gateGain = 0.05; }
  gateOff() { this.gateGain = 1; }

  stop(): void {
    try { this.proc?.disconnect(); } catch {}
    if (this.proc) this.proc.onaudioprocess = null;
    try { this.src?.disconnect(); } catch {}
    try { this.ctx?.close(); } catch {}
    this.stream?.getTracks().forEach((t) => t.stop());
    this.proc = null;
    this.src = null;
    this.ctx = null;
    this.stream = null;
  }
}

function bytesToBase64(bytes: Uint8Array): string {
  // chunked to avoid argument limit on String.fromCharCode for big buffers
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode.apply(null, Array.from(bytes.subarray(i, i + chunk)));
  }
  return btoa(binary);
}
