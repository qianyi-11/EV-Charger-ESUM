import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a still image from the device gallery for vision analysis.
class GalleryImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pick() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 4096,
      );
      return file;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GalleryImagePicker] pick failed: $e');
      }
      return null;
    }
  }
}
