// Web 平台 PCM 音频播放器 — 24kHz Int16 little-endian → Float32 → AudioContext
// 支持 barge-in: stop() 立即终止当前播放和所有排队音频
import 'dart:js' as js;
import 'audio_player_base.dart';

class AudioPlayer extends AudioPlayerBase {
  bool _initialized = false;

  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    js.context.callMethod('eval', ['''
window.__playAudioCtx = new (window.AudioContext||window.webkitAudioContext)({sampleRate: 24000});
window.__playNextTime = 0;
window.__playSources = [];
window.__playAudio = function(b64) {
  if (!b64) return;
  try {
    var ctx = window.__playAudioCtx;
    var binary = atob(b64);
    var bytes = new Uint8Array(binary.length);
    for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    var samples = bytes.length / 2;
    var buf = ctx.createBuffer(1, samples, 24000);
    var channel = buf.getChannelData(0);
    var view = new DataView(bytes.buffer);
    for (var i = 0; i < samples; i++) {
      channel[i] = view.getInt16(i * 2, true) / 32768;
    }
    var src = ctx.createBufferSource();
    src.buffer = buf;
    src.connect(ctx.destination);
    var now = ctx.currentTime;
    var startTime = Math.max(now, window.__playNextTime);
    src.start(startTime);
    src.onended = function() {
      var idx = window.__playSources.indexOf(src);
      if (idx >= 0) window.__playSources.splice(idx, 1);
    };
    window.__playSources.push(src);
    window.__playNextTime = startTime + buf.duration;
  } catch(e) { console.error('[AudioPlayer] play error:', e); }
};
window.__stopAllAudio = function() {
  window.__playNextTime = 0;
  var sources = window.__playSources;
  window.__playSources = [];
  for (var i = 0; i < sources.length; i++) {
    try { sources[i].stop(); } catch(e) {}
    try { sources[i].disconnect(); } catch(e) {}
  }
};
''']);
  }

  @override
  Future<void> play(String base64Pcm) async {
    _ensureInit();
    js.context.callMethod('eval', ['window.__playAudio("$base64Pcm")']);
  }

  @override
  void stop() {
    _ensureInit();
    js.context.callMethod('eval', ['window.__stopAllAudio()']);
  }

  @override
  void dispose() {
    stop();
    js.context.callMethod('eval', ['''
try { window.__playAudioCtx?.close(); } catch(e) {}
delete window.__playAudioCtx;
delete window.__playNextTime;
delete window.__playSources;
delete window.__playAudio;
delete window.__stopAllAudio;
''']);
    _initialized = false;
  }
}
