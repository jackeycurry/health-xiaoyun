// Web 平台音频录制 — 通过 dart:html CustomEvent 与 JS 通信（避免已废弃的 dart:js allowInterop）
// 包含重采样逻辑：始终输出 16kHz PCM 给 DashScope
import 'dart:async';
import 'dart:html' as html;
import 'audio_recorder_base.dart';

class AudioRecorder extends AudioRecorderBase {
  var _isRecording = false;
  html.EventListener? _audioListener;

  @override
  Future<bool> hasPermission() async {
    try {
      final c = Completer<bool>();

      void onResult(html.Event e) {
        final detail = (e as html.CustomEvent).detail;
        c.complete(detail == true);
        html.window.removeEventListener('__permResult', onResult);
      }

      html.window.addEventListener('__permResult', onResult);

      _injectScript('''
(function() {
  try {
    navigator.permissions.query({name: 'microphone'}).then(function(result) {
      window.dispatchEvent(new CustomEvent('__permResult', {
        detail: result.state === 'granted' || result.state === 'prompt'
      }));
    }).catch(function() {
      window.dispatchEvent(new CustomEvent('__permResult', {detail: true}));
    });
  } catch(e) {
    window.dispatchEvent(new CustomEvent('__permResult', {detail: true}));
  }
})()
''');
      return c.future;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<void> startRecording(void Function(String base64) onData) async {
    _injectScript('''
if (window.__audioCtx) { window.__audioCtx.close(); }
if (window.__audioStream) { window.__audioStream.getTracks().forEach(function(t){t.stop()}); }
''');

    _isRecording = true;

    // 直接传递 base64 字符串，无编解码，与 voice_test.html 完全一致
    _audioListener = (html.Event e) {
      if (!_isRecording) return;
      final b64 = (e as html.CustomEvent).detail as String? ?? '';
      if (b64.isEmpty) return;
      onData(b64);
    };
    html.window.addEventListener('__audioData', _audioListener!);

    // 注入 JS 录音脚本 — Qwen-Omni-Realtime 标准格式
    _injectScript('''
(async function() {
  try {
    var stream = await navigator.mediaDevices.getUserMedia({audio: true});
    console.log('[AudioRecorder] acquired microphone stream');

    var targetSampleRate = 16000;
    var ctx = new (window.AudioContext||window.webkitAudioContext)({sampleRate: targetSampleRate});
    var actualSampleRate = ctx.sampleRate || targetSampleRate;
    console.log('[AudioRecorder] sampleRate: ' + ctx.sampleRate + ' target: ' + targetSampleRate);
    await ctx.resume();
    console.log('[AudioRecorder] state: ' + ctx.state);

    stream.getTracks().forEach(function(t) { t.enabled = true; });

    function resampleToTarget(input, inputSampleRate, outputSampleRate) {
      if (inputSampleRate === outputSampleRate) return input;
      var ratio = inputSampleRate / outputSampleRate;
      var newLength = Math.round(input.length / ratio);
      var result = new Float32Array(newLength);
      for (var i = 0; i < newLength; i++) {
        var position = i * ratio;
        var leftIndex = Math.floor(position);
        var rightIndex = Math.min(leftIndex + 1, input.length - 1);
        var fraction = position - leftIndex;
        result[i] = input[leftIndex] + (input[rightIndex] - input[leftIndex]) * fraction;
      }
      return result;
    }

    var FRAME_SIZE = 320; // 20ms at 16kHz (DashScope VAD requires 10-20ms frames)
    var src = ctx.createMediaStreamSource(stream);
    var proc = ctx.createScriptProcessor(FRAME_SIZE, 1, 1);
    var chunkCount = 0;

    proc.onaudioprocess = function(e) {
      try {
        var data = e.inputBuffer.getChannelData(0);
        var pcm16k = resampleToTarget(data, actualSampleRate, targetSampleRate);

        // Float32 → Int16 小端序 (标准 PCM 格式)
        var buf = new ArrayBuffer(pcm16k.length * 2);
        var view = new DataView(buf);
        for (var i = 0; i < pcm16k.length; i++) {
          var sample = Math.max(-1, Math.min(1, pcm16k[i]));
          var int16 = sample < 0 ? sample * 0x8000 : sample * 0x7FFF;
          view.setInt16(i * 2, int16, true); // true = little-endian
        }

        // ArrayBuffer → binary → base64
        var bytes = new Uint8Array(buf);
        var binary = '';
        for (var i = 0; i < bytes.length; i++) {
          binary += String.fromCharCode(bytes[i]);
        }

        chunkCount++;
        if (chunkCount <= 3) console.log('[AudioRecorder] Chunk #'+chunkCount+' frame='+FRAME_SIZE);
        window.dispatchEvent(new CustomEvent('__audioData', {detail: btoa(binary)}));
      } catch(e) { console.error('[AudioRecorder] error:', e && e.message || e); }
    };

    src.connect(proc);
    proc.connect(ctx.destination);

    window.__audioCtx = ctx;
    window.__audioSrc = src;
    window.__audioProc = proc;
    window.__audioStream = stream;
    window.__audioSampleRate = actualSampleRate;
    console.log('[AudioRecorder] JS recording started frameSize='+FRAME_SIZE);
  } catch(e) { console.error('[AudioRecorder] setup error:', e && e.message || String(e)); }
})()
''');
  }

  @override
  Future<void> stopRecording() async {
    _isRecording = false;
    if (_audioListener != null) {
      html.window.removeEventListener('__audioData', _audioListener!);
      _audioListener = null;
    }
    _injectScript('''
try {
  var p = window.__audioProc; if(p) { p.disconnect(); p.onaudioprocess = null; }
  var s = window.__audioSrc; if(s) s.disconnect();
  var c = window.__audioCtx; if(c) c.close();
  var t = window.__audioStream; if(t) t.getTracks().forEach(function(x){x.stop()});
} catch(e) {}
delete window.__audioCtx;
delete window.__audioSrc;
delete window.__audioProc;
delete window.__audioStream;
delete window.__audioSampleRate;
''');
  }

  @override
  void dispose() {
    stopRecording();
  }

  void _injectScript(String code) {
    final script = html.ScriptElement();
    script.text = code;
    html.document.body?.append(script);
    script.remove();
  }
}
