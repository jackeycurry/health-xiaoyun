// Native 平台摄像头 — 暂未实现
import 'camera_capture_base.dart';

class CameraCapture extends CameraCaptureBase {
  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> startCapture(void Function(String base64Jpeg) onFrame) async {}

  @override
  Future<void> stopCapture() async {}

  @override
  void dispose() {}
}
