// Android 平台录音 — MethodChannel 直连原生 AudioRecord + 硬件回声消除
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'audio_recorder_base.dart';

class AudioRecorder extends AudioRecorderBase {
  static const _channel = MethodChannel('com.healthxiaohe/audio_recorder');
  StreamSubscription<Uint8List>? _sub;
  bool _gate = false; // true=压低麦克风，仅通过大声说话
  bool _muted = false; // true=完全静音，不发送任何音频

  void gateOn() => _gate = true;
  void gateOff() => _gate = false;
  void mute() => _muted = true;
  void unmute() => _muted = false;

  @override
  Future<bool> hasPermission() async {
    try {
      await _channel.invokeMethod('start', {'sampleRate': 16000});
      await _channel.invokeMethod('stop');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startRecording(void Function(String base64) onData) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onAudio') return;
      final bytes = call.arguments as Uint8List;
      if (bytes.isEmpty) return;

      // 完全静音模式 — AI说话时阻止回声循环
      if (_muted) return;

      // 噪声门：压低模式下只通过大声说话，过滤音箱回声
      if (_gate && !_isLoud(bytes)) return;

      onData(base64Encode(bytes));
    });
    await _channel.invokeMethod('start', {'sampleRate': 16000});
  }

  bool _isLoud(Uint8List pcm) {
    final view = ByteData.view(pcm.buffer, pcm.offsetInBytes, pcm.length);
    var peak = 0;
    for (var i = 0; i < pcm.length - 1; i += 2) {
      final s = view.getInt16(i, Endian.little).abs();
      peak = max(peak, s);
    }
    return peak > 5000; // 必须大声才能通过（约15%最大振幅，过滤扬声器回声）
  }

  @override
  Future<void> stopRecording() async {
    _channel.setMethodCallHandler(null);
    await _channel.invokeMethod('stop');
  }

  @override
  void dispose() {
    stopRecording();
  }
}
