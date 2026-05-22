import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Ensures only one [CameraController] exists app-wide (prevents black/red preview
/// when navigating from charger detection to video recording).
class CameraSessionManager {
  CameraSessionManager._();
  static final CameraSessionManager instance = CameraSessionManager._();

  CameraController? _controller;
  int _refCount = 0;
  bool _initializing = false;

  CameraController? get controller => _controller;

  bool get isReady =>
      _controller != null && _controller!.value.isInitialized;

  Future<CameraController> acquire({
    bool forVideo = false,
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) async {
    if (_controller != null && _controller!.value.isInitialized) {
      _refCount++;
      return _controller!;
    }

    while (_initializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_controller != null && _controller!.value.isInitialized) {
      _refCount++;
      return _controller!;
    }

    _initializing = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera hardware detected.');
      }

      final controller = CameraController(
        cameras.first,
        forVideo ? ResolutionPreset.high : resolution,
        enableAudio: false, // Visual frames only; eliminates mic permission checks completely
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _controller = controller;
      _refCount = 1;
      return controller;
    } finally {
      _initializing = false;
    }
  }

  void release() {
    if (_refCount > 0) _refCount--;
  }

  Future<void> forceRelease() async {
    _refCount = 0;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        if (controller.value.isRecordingVideo) {
          await controller.stopVideoRecording();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CameraSession] stopVideoRecording on release: $e');
        }
      }
      try {
        await controller.dispose();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CameraSession] dispose: $e');
        }
      }
    }
    // Brief pause lets the Android camera HAL release before the next screen opens.
    await Future.delayed(const Duration(milliseconds: 350));
  }
}
