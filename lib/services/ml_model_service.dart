import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

/// The integration mode for the custom trained machine learning models.
enum MlIntegrationMode {
  /// Renders futuristic simulation overlays and guides (perfect for local UI developer previews).
  mock,

  /// Captures images/video frames and uploads them to a cloud-based server
  /// (e.g. Express/Python FastAPI server) hosting the YOLO, OpenCV, and OCR weights.
  /// (Highly recommended for protection of weights and immediate model hot-swaps).
  cloudApi,

  /// Performs offline, real-time local inference directly on-device using packaged `.tflite` or ONNX weights.
  localOnDevice,
}

/// The result returned from processing the technical specification plate.
class OcrResult {
  final bool success;
  final String brand;
  final String modelName;
  final String serialNumber;
  final double confidence;
  final String? errorMessage;

  OcrResult({
    required this.success,
    required this.brand,
    required this.modelName,
    required this.serialNumber,
    required this.confidence,
    this.errorMessage,
  });
}

/// The result returned from analyzing the charger body and panel indicator.
class ChargerDetectionResult {
  final bool success;
  final bool chargerDetected;
  final bool lightDetected;
  final String lightColor; // "RED", "GREEN", "OFF"
  final double confidence;
  final String? errorMessage;

  ChargerDetectionResult({
    required this.success,
    required this.chargerDetected,
    required this.lightDetected,
    required this.lightColor,
    required this.confidence,
    this.errorMessage,
  });
}

/// The result returned from counting blink frequencies inside the 15s recording stream.
class BlinkDetectionResult {
  final bool success;
  final int blinkCount;
  final String correlatedErrorCode;
  final double confidence;
  final String? errorMessage;

  BlinkDetectionResult({
    required this.success,
    required this.blinkCount,
    required this.correlatedErrorCode,
    required this.confidence,
    this.errorMessage,
  });
}

/// The result returned from analyzing the rotary isolator switch.
class IsolatorResult {
  final bool success;
  final bool isSwitchOn;
  final double confidence;
  final String? errorMessage;

  IsolatorResult({
    required this.success,
    required this.isSwitchOn,
    required this.confidence,
    this.errorMessage,
  });
}

/// The result returned from inspecting the EVDB breaker rail layouts.
class EvdbResult {
  final bool success;
  final bool isCompliant; // Check if matching 32A MCB and Type-B RCCB
  final String detectedMcbRating;
  final String detectedRccbRating;
  final double confidence;
  final String? errorMessage;

  EvdbResult({
    required this.success,
    required this.isCompliant,
    required this.detectedMcbRating,
    required this.detectedRccbRating,
    required this.confidence,
    this.errorMessage,
  });
}

/// Enterprise ML Model Integration Gateway Service
/// Centralizes all hooks for YOLO body classifiers, OpenCV flash frequency counters, and technical label OCRs.
class MlModelService {
  // Singleton pattern
  static final MlModelService _instance = MlModelService._internal();
  factory MlModelService() => _instance;
  MlModelService._internal();

  /// Change this configuration toggle to bind your trained model integration pathway!
  final MlIntegrationMode integrationMode = MlIntegrationMode.cloudApi;

  /// Your Cloud-based ML API base URL (Option A)
  String get cloudApiBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return "http://$host:5000/api/vision";
    }
    // IMPORTANT: Change this to your Laptop's WiFi IP Address!
    return "http://10.164.37.49:5000/api/vision";
  }

  // Helper for localtunnel
  Map<String, String> get _headers => {
    "Bypass-Tunnel-Reminder": "true",
  };

  // ===========================================================================
  // STEP 1: SPECIFICATION PLATE OCR
  // ===========================================================================
  Future<OcrResult> processSpecPlate(XFile imageFile) async {
    if (kDebugMode) {
      print("[ML Service] Spec Plate Upload Initiated: ${imageFile.path}");
    }

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        // Standard high-fidelity simulator latency
        await Future.delayed(const Duration(milliseconds: 2400));
        return OcrResult(
          success: true,
          brand: "Tesla",
          modelName: "Tesla Wall Connector Gen 3",
          serialNumber: "TWC-2024-A8F3E2",
          confidence: 0.98,
        );

      case MlIntegrationMode.cloudApi:
        try {
          final uri = Uri.parse("$cloudApiBaseUrl/ocr");
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ));
          
          final response = await request.send();
          if (response.statusCode == 200) {
            final responseBody = await response.stream.bytesToString();
            final json = jsonDecode(responseBody);
            return OcrResult(
              success: json['success'] ?? false,
              brand: json['brand'] ?? 'Unknown',
              modelName: json['modelName'] ?? 'Unknown',
              serialNumber: json['serialNumber'] ?? 'Unknown',
              confidence: (json['confidence'] ?? 0.0).toDouble(),
            );
          } else {
            throw Exception("Server returned status: ${response.statusCode}");
          }
        } catch (e) {
          return OcrResult(
            success: false,
            brand: "Unknown",
            modelName: "Unknown",
            serialNumber: "Unknown",
            confidence: 0.0,
            errorMessage: e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        throw UnimplementedError("Option B: On-device local OCR model engine weights not loaded.");
    }
  }

  // ===========================================================================
  // STEP 2: CHARGER BODY & LED DETECTION
  // ===========================================================================
  Future<ChargerDetectionResult> processChargerFrame(XFile imageFile) async {
    if (kDebugMode) {
      print("[ML Service] Charger Body Recognition Frame Received: ${imageFile.path}");
    }

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        await Future.delayed(const Duration(milliseconds: 1500));
        return ChargerDetectionResult(
          success: true,
          chargerDetected: true,
          lightDetected: true,
          lightColor: "RED",
          confidence: 0.94,
        );

      case MlIntegrationMode.cloudApi:
        try {
          final uri = Uri.parse("$cloudApiBaseUrl/detect-gateway");
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ));
          
          final response = await request.send();
          if (response.statusCode == 200) {
            final json = jsonDecode(await response.stream.bytesToString());
            return ChargerDetectionResult(
              success: json['success'] ?? false,
              chargerDetected: json['chargerDetected'] ?? false,
              lightDetected: json['lightDetected'] ?? false,
              lightColor: json['lightColor'] ?? "OFF",
              confidence: (json['confidence'] ?? 0.0).toDouble(),
            );
          } else {
            throw Exception("Server returned status: ${response.statusCode}");
          }
        } catch (e) {
          return ChargerDetectionResult(
            success: false,
            chargerDetected: false,
            lightDetected: false,
            lightColor: "OFF",
            confidence: 0.0,
            errorMessage: e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        throw UnimplementedError("Option B: Packaged local YOLOv8 weights are missing in assets.");
    }
  }

  // ===========================================================================
  // STEP 3: CONTROLLED 15-SECOND BLINK RECORDER
  // ===========================================================================
  Future<BlinkDetectionResult> processBlinkVideo(XFile videoFile) async {
    if (kDebugMode) {
      print("[ML Service] Blink Recording Processing Initiated: ${videoFile.path}");
    }

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        await Future.delayed(const Duration(milliseconds: 2500));
        return BlinkDetectionResult(
          success: true,
          blinkCount: 8,
          correlatedErrorCode: "blink-8",
          confidence: 0.99,
        );

      case MlIntegrationMode.cloudApi:
        try {
          final uri = Uri.parse("$cloudApiBaseUrl/analyze-pulses");
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'video',
              videoFile.path,
            ));
          
          final response = await request.send();
          if (response.statusCode == 200) {
            final json = jsonDecode(await response.stream.bytesToString());
            return BlinkDetectionResult(
              success: json['success'] ?? false,
              blinkCount: json['blinkCount'] ?? 0,
              correlatedErrorCode: json['correlatedErrorCode'] ?? "unknown",
              confidence: (json['confidence'] ?? 0.0).toDouble(),
            );
          } else {
            throw Exception("Server returned status: ${response.statusCode}");
          }
        } catch (e) {
          return BlinkDetectionResult(
            success: false,
            blinkCount: 0,
            correlatedErrorCode: "unknown",
            confidence: 0.0,
            errorMessage: e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        throw UnimplementedError("Option B: On-device OpenCV frame analysis bindings missing.");
    }
  }

  // ===========================================================================
  // STEP 4: POWER ISSUE ISOLATOR STATUS
  // ===========================================================================
  Future<IsolatorResult> processIsolatorFrame(XFile imageFile) async {
    if (kDebugMode) {
      print("[ML Service] Isolator Switch Image Frame: ${imageFile.path}");
    }

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        await Future.delayed(const Duration(milliseconds: 2400));
        return IsolatorResult(
          success: true,
          isSwitchOn: false,
          confidence: 0.95,
        );

      case MlIntegrationMode.cloudApi:
        try {
          final uri = Uri.parse("$cloudApiBaseUrl/analyze-isolator");
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ));
          final response = await request.send();
          if (response.statusCode == 200) {
            final json = jsonDecode(await response.stream.bytesToString());
            return IsolatorResult(
              success: json['success'] ?? false,
              isSwitchOn: json['isSwitchOn'] ?? false,
              confidence: (json['confidence'] ?? 0.0).toDouble(),
            );
          } else {
            throw Exception("Server returned status: ${response.statusCode}");
          }
        } catch (e) {
          return IsolatorResult(
            success: false,
            isSwitchOn: false,
            confidence: 0.0,
            errorMessage: e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        throw UnimplementedError("Option B: Local Isolator YOLO weights not loaded.");
    }
  }

  // ===========================================================================
  // STEP 5: DISTRIBUTION BOARD BREAKER COMPLIANCE
  // ===========================================================================
  Future<EvdbResult> processEvdbFrame(XFile imageFile) async {
    if (kDebugMode) {
      print("[ML Service] EVDB Board Image Frame: ${imageFile.path}");
    }

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        await Future.delayed(const Duration(milliseconds: 3000));
        return EvdbResult(
          success: true,
          isCompliant: false,
          detectedMcbRating: "16A",
          detectedRccbRating: "Type A (Incompatible)",
          confidence: 0.93,
        );

      case MlIntegrationMode.cloudApi:
        try {
          final uri = Uri.parse("$cloudApiBaseUrl/analyze-evdb");
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ));
          final response = await request.send();
          if (response.statusCode == 200) {
            final json = jsonDecode(await response.stream.bytesToString());
            return EvdbResult(
              success: json['success'] ?? false,
              isCompliant: json['isCompliant'] ?? false,
              detectedMcbRating: json['detectedMcbRating'] ?? "Unknown",
              detectedRccbRating: json['detectedRccbRating'] ?? "Unknown",
              confidence: (json['confidence'] ?? 0.0).toDouble(),
              errorMessage: json['errorMessage'],
            );
          } else {
            throw Exception("Server returned status: ${response.statusCode}");
          }
        } catch (e) {
          return EvdbResult(
            success: false,
            isCompliant: false,
            detectedMcbRating: "Unknown",
            detectedRccbRating: "Unknown",
            confidence: 0.0,
            errorMessage: e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        throw UnimplementedError("Option B: Packaged local MCB/RCCB classification weights are missing.");
    }
  }

  // ===========================================================================
  // STEP 6: COGNITIVE AI CHAT ASSISTANT
  // ===========================================================================
  Future<String> chatWithAi(String message, List<Map<String, dynamic>> history) async {
    try {
      final apiKey = "AIzaSyBPjbOVvDX9eBs8RRfqtgCY0QyRAPZIH98";
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system('''You are the Guardrailed AI Assistant for a Smart EV Charger App. 
Your goal is to triage user issues dynamically by asking clarifying questions, identifying the specific root cause, and providing structured next actions.
Your role is to:
Assist users in identifying EV charger problems
Provide structured troubleshooting guidance with only text-based
Explain possible causes clearly and professionally
Guide users safely toward the next action
Maintain a calm, technical, and trustworthy tone
You are NOT a casual chatbot.
You behave like a professional EV charging technical support engineer.

CRITICAL RULES:
1. Speak in a highly structured format using the exact keys: [Symptom], [Root Cause], [Advised Action].
2. Never invent error code names. Stick strictly to the exact hardware symptoms.
'''),
      );

      final chatHistory = history.map((msg) {
        return Content(msg['isUser'] ? 'user' : 'model', [TextPart(msg['text'] ?? '')]);
      }).toList();

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(message));
      
      return response.text ?? "Sorry, no response returned from Gemini.";
    } catch (e) {
      return "Connection Error: Failed to contact diagnostic AI core backend. (${e.toString()})";
    }
  }
}
