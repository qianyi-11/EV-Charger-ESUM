import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResultData {
  final bool success;
  final String extractedText;
  final String serialNumber;
  final String modelName;

  OcrResultData({
    required this.success,
    required this.extractedText,
    required this.serialNumber,
    required this.modelName,
  });
}

class OcrHandler {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResultData> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      
      // Basic regex to find common Serial Number formats (S/N, SN, Serial)
      final snRegex = RegExp(r'(?:S\/N|SN|Serial(?: Number)?)\s*[:#-]?\s*([A-Za-z0-9]+)', caseSensitive: false);
      final modelRegex = RegExp(r'(?:Model|Type)\s*[:#-]?\s*([A-Za-z0-9\-]+)', caseSensitive: false);

      String serialNumber = 'Unknown';
      String modelName = 'Unknown';

      final snMatch = snRegex.firstMatch(text);
      if (snMatch != null && snMatch.groupCount >= 1) {
        serialNumber = snMatch.group(1) ?? 'Unknown';
      } else if (text.trim().isNotEmpty) {
        serialNumber = text.replaceAll('\n', ' '); // Show raw text to prove it works
      }

      final modelMatch = modelRegex.firstMatch(text);
      if (modelMatch != null && modelMatch.groupCount >= 1) {
        modelName = modelMatch.group(1) ?? 'Unknown';
      } else {
        modelName = "Raw Extract:";
      }

      return OcrResultData(
        success: true,
        extractedText: text,
        serialNumber: serialNumber,
        modelName: modelName,
      );
    } catch (e) {
      return OcrResultData(
        success: false,
        extractedText: '',
        serialNumber: 'Unknown',
        modelName: 'Unknown',
      );
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
