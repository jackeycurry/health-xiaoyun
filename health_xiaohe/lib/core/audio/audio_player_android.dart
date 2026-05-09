// Android 平台 PCM 音频播放 — 使用 MethodChannel + AudioTrack 实现低延迟播放
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'audio_player_base.dart';

class AudioPlayer extends AudioPlayerBase {
  static const _channel = MethodChannel('com.healthxiaohe/audio_player');
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await _channel.invokeMethod('init', {'sampleRate': 24000, 'channels': 1});
  }

  @override
  Future<void> play(String base64Pcm) async {
    if (base64Pcm.isEmpty) return;
    await _ensureInit();
    final bytes = base64Decode(base64Pcm);
    await _channel.invokeMethod('play', bytes);
  }

  @override
  void stop() {
    _channel.invokeMethod('stop');
  }

  @override
  void dispose() {
    _initialized = false;
    _channel.invokeMethod('dispose');
  }
}
