import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OcrResultData {
  final bool success;
  final String extractedText;
  final String serialNumber;
  final String modelName;
  final String? brand;
  final String? inputVoltage;
  final String? outputCurrent;
  final bool isBlurry;
  final bool partialExtraction;

  OcrResultData({
    required this.success,
    required this.extractedText,
    required this.serialNumber,
    required this.modelName,
    this.brand,
    this.inputVoltage,
    this.outputCurrent,
    this.isBlurry = false,
    this.partialExtraction = false,
  });
}

class OcrHandler {
  final String baseUrl;

  OcrHandler({required this.baseUrl});

  Future<OcrResultData> processImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/vision/ocr'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      return OcrResultData(
        success: data['success'] ?? false,
        extractedText: _buildExtractedText(data),
        serialNumber:  data['serialNumber']  ?? 'Unknown',
        modelName:     data['modelName']     ?? 'Unknown',
        brand:         data['brand'],
        inputVoltage:  data['inputVoltage'],
        outputCurrent: data['outputCurrent'],
        isBlurry:      data['isBlurry'] ?? false,
        partialExtraction: data['partialExtraction'] ?? false,
      );
    } catch (e) {
      return OcrResultData(
        success: false,
        extractedText: 'OCR failed: $e',
        serialNumber: 'Unknown',
        modelName: 'Unknown',
        isBlurry: false,
        partialExtraction: false,
      );
    }
  }

  String _buildExtractedText(Map<String, dynamic> data) {
    return [
      if (data['brand']         != null) 'Brand: ${data['brand']}',
      if (data['modelName']     != null) 'Model: ${data['modelName']}',
      if (data['serialNumber']  != null) 'S/N: ${data['serialNumber']}',
      if (data['inputVoltage']  != null) 'Input: ${data['inputVoltage']}',
      if (data['outputCurrent'] != null) 'Output: ${data['outputCurrent']}',
    ].join('\n');
  }

  void dispose() {
    // nothing to close
  }
}