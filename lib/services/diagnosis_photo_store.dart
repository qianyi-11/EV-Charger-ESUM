import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies diagnosis captures to app storage so they survive until ticket submit.
class DiagnosisPhotoStore {
  static Future<String> persistCapture(XFile photo, String label) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'diagnosis_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final ext = p.extension(photo.path);
    final destPath = p.join(
      photosDir.path,
      '${label}_${DateTime.now().millisecondsSinceEpoch}${ext.isNotEmpty ? ext : '.jpg'}',
    );

    await File(photo.path).copy(destPath);
    return destPath;
  }
}
