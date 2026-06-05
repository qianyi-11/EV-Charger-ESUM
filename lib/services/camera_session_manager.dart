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
  ResolutionPreset? _activePreset;

  CameraController? get controller => _controller;

  bool get isReady =>
      _controller != null && _controller!.value.isInitialized;

  /// [highQuality] uses [ResolutionPreset.high] for sharp still captures (OCR, EVDB, isolator).
  /// Charger live-polling uses the default medium preset.
  Future<CameraController> acquire({
    bool forVideo = false,
    bool highQuality = false,
    bool forceNew = false,
  }) async {
    final preset = forVideo
        ? ResolutionPreset.high
        : (highQuality ? ResolutionPreset.high : ResolutionPreset.medium);

    if (forceNew || (_activePreset != null && _activePreset != preset)) {
      await forceRelease();
    }

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
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _controller = controller;
      _activePreset = preset;
      _refCount = 1;

      if (kDebugMode) {
        debugPrint('[CameraSession] initialized preset=$preset');
      }

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
    _activePreset = null;
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
    await Future.delayed(const Duration(milliseconds: 350));
  }
}
