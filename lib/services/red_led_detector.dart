import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// On-device red LED detection (RGB heuristic). Fallback when server OpenCV is unavailable.
class RedLedDetector {
  static Future<RedLedResult> analyzeFile(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return analyzeBytes(bytes);
  }

  static Future<RedLedResult> analyzeBytes(Uint8List bytes) async {
    try {
      final decoded = await _decodeImage(bytes);
      final byteData = await decoded.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return const RedLedResult(detected: false, confidence: 0);
      }

      final width = decoded.width;
      final height = decoded.height;
      final y0 = (height * 0.08).floor();
      final y1 = (height * 0.65).floor();
      final x0 = (width * 0.15).floor();
      final x1 = (width * 0.85).floor();

      int redHits = 0;
      int sampled = 0;
      const step = 4;

      for (int y = y0; y < y1; y += step) {
        for (int x = x0; x < x1; x += step) {
          final i = (y * width + x) * 4;
          final r = byteData.getUint8(i);
          final g = byteData.getUint8(i + 1);
          final b = byteData.getUint8(i + 2);
          sampled++;

          // Stricter red detection checks to avoid false positives on warm lighting and wood tones
          if (r >= 130 && r > g * 1.5 && r > b * 1.5 && (r - g) >= 40) {
            redHits++;
          }
        }
      }

      decoded.dispose();

      final ratio = redHits / math.max(sampled, 1);
      final detected = ratio > 0.015; // Require a solid 1.5% ratio, eliminating the hyper-sensitive redHits >= 8 shortcut
      final confidence = math.min(0.99, ratio * 4.0);

      return RedLedResult(
        detected: detected,
        confidence: confidence,
        redRatio: ratio,
        method: 'on_device_rgba',
      );
    } catch (_) {
      return const RedLedResult(detected: false, confidence: 0);
    }
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }
}

class RedLedResult {
  final bool detected;
  final double confidence;
  final double redRatio;
  final String method;

  const RedLedResult({
    required this.detected,
    required this.confidence,
    this.redRatio = 0,
    this.method = 'none',
  });
}
