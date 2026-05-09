import 'dart:async';

abstract class AudioRecorderBase {
  Future<bool> hasPermission();
  Future<void> startRecording(void Function(String base64) onData);
  Future<void> stopRecording();
  void dispose();
  void gateOn() {}   // 压低麦克风，仅通过大声说话
  void gateOff() {}  // 恢复正常收音
  void mute() {}     // 完全静音麦克风（停止发送音频块）
  void unmute() {}   // 恢复发送音频
}
