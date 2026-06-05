import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Captures a still photo after a short autofocus settle.
class SharpCapture {
  /// Lock focus/exposure on centre, brief settle, then take picture.
  static Future<XFile> takePicture(
    CameraController controller, {
    Duration focusDelay = const Duration(milliseconds: 350),
  }) async {
    if (!controller.value.isInitialized) {
      throw StateError('Camera not initialized');
    }

    try {
      if (controller.value.focusMode != FocusMode.locked) {
        await controller.setFocusMode(FocusMode.auto);
      }
      if (controller.value.exposureMode != ExposureMode.locked) {
        await controller.setExposureMode(ExposureMode.auto);
      }
      await controller.setFocusPoint(const Offset(0.5, 0.5));
      await controller.setExposurePoint(const Offset(0.5, 0.5));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SharpCapture] focus/exposure setup: $e');
      }
    }

    if (focusDelay > Duration.zero) {
      await Future.delayed(focusDelay);
    }

    return controller.takePicture();
  }
}
