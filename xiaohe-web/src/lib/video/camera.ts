/**
 * Camera capture for video voice chat.
 *
 *   getUserMedia → returned MediaStream is attached by the page to a <video>
 *   element for preview. Internally we also draw the current frame into an
 *   offscreen canvas once per second and call `onFrame(base64Jpeg)`.
 *
 * DashScope realtime only needs sparse frames — backend caches the latest
 * `image` and piggybacks it onto the next `input_audio_buffer.append`, so
 * 1 fps is plenty and keeps ws bandwidth tame.
 */

export interface CameraOptions {
  width?: number;
  height?: number;
  frameRate?: number;       // capture stream rate (browser hint)
  fps?: number;             // jpeg send rate
  quality?: number;         // 0..1, jpeg quality
  onFrame: (b64Jpeg: string) => void;
}

export class CameraCapture {
  private stream: MediaStream | null = null;
  private canvas: HTMLCanvasElement | null = null;
  private ctx: CanvasRenderingContext2D | null = null;
  private timer = 0;
  private video: HTMLVideoElement | null = null;

  async hasPermission(): Promise<boolean> {
    try {
      const s = await navigator.mediaDevices.getUserMedia({ video: true });
      s.getTracks().forEach((t) => t.stop());
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Acquire camera and start frame loop. Caller binds the returned stream
   * to a <video> element for preview.
   */
  async start(opts: CameraOptions): Promise<MediaStream> {
    const width = opts.width ?? 640;
    const height = opts.height ?? 480;
    const fps = opts.fps ?? 1;
    const quality = opts.quality ?? 0.7;

    this.stream = await navigator.mediaDevices.getUserMedia({
      video: {
        width,
        height,
        frameRate: opts.frameRate ?? 15,
      },
    });

    // Internal video element to read frames from. Page-owned <video> for
    // preview is separate; we don't need it to drive the canvas (we use our
    // own hidden one for frame extraction, decoupled from any DOM lifecycle).
    this.video = document.createElement("video");
    this.video.autoplay = true;
    this.video.playsInline = true;
    this.video.muted = true;
    this.video.srcObject = this.stream;
    await this.video.play().catch(() => { /* play() returns rejected promise on some browsers; we don't care */ });

    this.canvas = document.createElement("canvas");
    this.canvas.width = width;
    this.canvas.height = height;
    this.ctx = this.canvas.getContext("2d");

    const intervalMs = Math.round(1000 / fps);
    this.timer = window.setInterval(() => {
      const v = this.video;
      const cv = this.canvas;
      const cx = this.ctx;
      if (!v || !cv || !cx) return;
      // readyState 2 = HAVE_CURRENT_DATA — frame is paintable
      if (v.readyState < 2) return;
      cx.drawImage(v, 0, 0, cv.width, cv.height);
      const dataUrl = cv.toDataURL("image/jpeg", quality);
      const b64 = dataUrl.split(",")[1] ?? "";
      if (b64) opts.onFrame(b64);
    }, intervalMs);

    return this.stream;
  }

  stop(): void {
    if (this.timer) { clearInterval(this.timer); this.timer = 0; }
    this.stream?.getTracks().forEach((t) => t.stop());
    if (this.video) {
      this.video.pause();
      this.video.srcObject = null;
      this.video = null;
    }
    this.canvas = null;
    this.ctx = null;
    this.stream = null;
  }
}
