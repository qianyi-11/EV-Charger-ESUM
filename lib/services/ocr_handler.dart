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
  final double? powerRatingKw;
  final double? confidence;
  final bool isBlurry;
  final bool partialExtraction;
  final bool quotaExceeded;
  final String? reason;

  OcrResultData({
    required this.success,
    required this.extractedText,
    required this.serialNumber,
    required this.modelName,
    this.brand,
    this.inputVoltage,
    this.outputCurrent,
    this.powerRatingKw = null,
    this.confidence = null,
    this.isBlurry = false,
    this.partialExtraction = false,
    this.quotaExceeded = false,
    this.reason,
  });
}

class OcrHandler {
  final String baseUrl;

  OcrHandler({required this.baseUrl});

  Future<OcrResultData> processImage(File imageFile) async {
      try {
      print('====== OCR HANDLER START ======');
      print('Sending to: $baseUrl/api/vision/ocr');
      print('File path: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/vision/ocr'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      print('Request built, sending...');

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      
      print('Response received: ${streamedResponse.statusCode}');
      
      final response = await http.Response.fromStream(streamedResponse);

      print('Response body: ${response.body}');

      final dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode != 200) {
        final errorText = body is Map
            ? (body['error']?.toString() ?? body['reason']?.toString())
            : null;
        final message = errorText ?? 'Server error: ${response.statusCode}';
        final quotaExceeded = message.contains('429') ||
            message.toLowerCase().contains('quota');
        return OcrResultData(
          success: false,
          extractedText: message,
          serialNumber: 'Unknown',
          modelName: 'Unknown',
          quotaExceeded: quotaExceeded,
          reason: quotaExceeded
              ? 'Gemini API quota exceeded. Wait a minute or check billing.'
              : message,
        );
      }

      final data = body as Map<String, dynamic>;

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
        quotaExceeded: data['quotaExceeded'] ?? false,
        reason: data['reason']?.toString(),
      );
    } catch (e) {
      print('====== OCR HANDLER ERROR: $e ======');
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