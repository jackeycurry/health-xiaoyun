import 'dart:async';

abstract class CameraCaptureBase {
  Future<bool> hasPermission();
  Future<void> startCapture(void Function(String base64Jpeg) onFrame);
  Future<void> stopCapture();
  void dispose();
}
