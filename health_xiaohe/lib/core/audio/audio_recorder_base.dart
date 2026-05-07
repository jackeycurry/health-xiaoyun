import 'dart:async';

abstract class AudioRecorderBase {
  Future<bool> hasPermission();
  Future<void> startRecording(void Function(String base64) onData);
  Future<void> stopRecording();
  void dispose();
}
