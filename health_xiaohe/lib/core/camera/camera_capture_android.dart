// Android 平台摄像头采集 — 使用 camera 包
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'camera_capture_base.dart';

class CameraCapture extends CameraCaptureBase {
  CameraController? _controller;
  Timer? _timer;
  bool _capturing = false;

  @override
  Future<bool> hasPermission() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return false;
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    // camera 包内部会请求权限
    return true;
  }

  @override
  Future<void> startCapture(void Function(String base64Jpeg) onFrame) async {
    if (!await hasPermission()) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();

    _capturing = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_capturing || _controller == null || !_controller!.value.isInitialized) return;
      try {
        final image = await _controller!.takePicture();
        final bytes = await image.readAsBytes();
        final b64 = base64Encode(bytes);
        onFrame(b64);
      } catch (e) {
        print('[Camera] capture error: $e');
      }
    });

    print('[Camera] Android capture started at 1fps');
  }

  @override
  Future<void> stopCapture() async {
    _capturing = false;
    _timer?.cancel();
    _timer = null;
    await _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    stopCapture();
  }
}
