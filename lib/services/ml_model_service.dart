import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'red_led_detector.dart';

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
    // IMPORTANT: Use your dev machine's WiFi IP so a real phone on the same network can reach the API.
    return "http://10.168.36.67:5000/api/vision";
  }

  /// Base URL for non-vision API routes (e.g. /api/chat).
  String get cloudServerApiBaseUrl {
    return cloudApiBaseUrl.replaceFirst('/api/vision', '/api');
  }

  List<Map<String, dynamic>> _sanitizeChatHistory(List<Map<String, dynamic>> history) {
    int startIndex = 0;
    while (startIndex < history.length && history[startIndex]['isUser'] != true) {
      startIndex += 1;
    }

    return history
        .skip(startIndex)
        .map((msg) => {
              'isUser': msg['isUser'] == true,
              'text': (msg['text'] ?? '').toString(),
            })
        .where((msg) => (msg['text'] as String).trim().isNotEmpty)
        .toList();
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
            var lightDetected = json['lightDetected'] ?? false;
            var lightColor = (json['lightColor'] ?? "OFF").toString();
            var confidence = (json['confidence'] ?? 0.0).toDouble();

            if (!lightDetected) {
              final local = await RedLedDetector.analyzeFile(imageFile.path);
              if (local.detected) {
                lightDetected = true;
                lightColor = "RED";
                confidence = math.max(confidence, local.confidence);
                if (kDebugMode) {
                  print("[ML Service] On-device red fallback: ratio=${local.redRatio}");
                }
              }
            }

            return ChargerDetectionResult(
              success: json['success'] ?? true,
              chargerDetected: json['chargerDetected'] ?? true,
              lightDetected: lightDetected,
              lightColor: lightColor,
              confidence: confidence,
            );
          } else {
            throw Exception("Server returned status: ${response.statusCode}");
          }
        } catch (e) {
          if (kDebugMode) {
            print("[ML Service] Gateway API error, trying on-device red: $e");
          }
          final local = await RedLedDetector.analyzeFile(imageFile.path);
          return ChargerDetectionResult(
            success: true,
            chargerDetected: true,
            lightDetected: local.detected,
            lightColor: local.detected ? "RED" : "OFF",
            confidence: local.confidence,
            errorMessage: local.detected ? null : e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        throw UnimplementedError("Option B: Packaged local YOLOv8 weights are missing in assets.");
    }
  }

  /// OpenCV red LED scan during the live search window (lighter than full gateway detect).
  Future<ChargerDetectionResult> processChargerRedLight(XFile imageFile) async {
    if (kDebugMode) {
      print("[ML Service] OpenCV red LED frame: ${imageFile.path}");
    }

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        await Future.delayed(const Duration(milliseconds: 200));
        return ChargerDetectionResult(
          success: true,
          chargerDetected: true,
          lightDetected: true,
          lightColor: "RED",
          confidence: 0.92,
        );

      case MlIntegrationMode.cloudApi:
        try {
          final uri = Uri.parse("$cloudApiBaseUrl/detect-red-light");
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ));

          final response = await request.send();
          if (response.statusCode == 200) {
            final json = jsonDecode(await response.stream.bytesToString());
            var lightDetected = json['lightDetected'] ?? false;
            var lightColor = (json['lightColor'] ?? "OFF").toString();
            var confidence = (json['confidence'] ?? 0.0).toDouble();

            if (!lightDetected) {
              final local = await RedLedDetector.analyzeFile(imageFile.path);
              if (local.detected) {
                lightDetected = true;
                lightColor = "RED";
                confidence = math.max(confidence, local.confidence);
                if (kDebugMode) {
                  print("[ML Service] On-device red poll hit: ratio=${local.redRatio}");
                }
              }
            }

            return ChargerDetectionResult(
              success: json['success'] ?? true,
              chargerDetected: true,
              lightDetected: lightDetected,
              lightColor: lightColor,
              confidence: confidence,
            );
          }
          throw Exception("Server returned status: ${response.statusCode}");
        } catch (e) {
          if (kDebugMode) {
            print("[ML Service] Red-light API error, on-device fallback: $e");
          }
          final local = await RedLedDetector.analyzeFile(imageFile.path);
          return ChargerDetectionResult(
            success: true,
            chargerDetected: true,
            lightDetected: local.detected,
            lightColor: local.detected ? "RED" : "OFF",
            confidence: local.confidence,
            errorMessage: local.detected ? null : e.toString(),
          );
        }

      case MlIntegrationMode.localOnDevice:
        final local = await RedLedDetector.analyzeFile(imageFile.path);
        return ChargerDetectionResult(
          success: true,
          chargerDetected: true,
          lightDetected: local.detected,
          lightColor: local.detected ? "RED" : "OFF",
          confidence: local.confidence,
        );
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
    final sanitizedHistory = _sanitizeChatHistory(history);

    switch (integrationMode) {
      case MlIntegrationMode.mock:
        return _mockChatResponse(message);
      case MlIntegrationMode.cloudApi:
        return _chatViaServer(message, sanitizedHistory);
      case MlIntegrationMode.localOnDevice:
        return _chatViaGeminiDirect(message, sanitizedHistory);
    }
  }

  String _mockChatResponse(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('cannot charge') || normalized.contains('not working')) {
      return '[Symptom]: Vehicle not receiving power.\n[Root Cause]: Ambient system state unknown.\n[Advised Action]: Please check the status indicator lights on the front face of the charger. Is it completely dark (no light), solid red, or blinking red?';
    }
    if (normalized.contains('no light') || normalized.contains('no power') || normalized.contains('dead')) {
      return '[Symptom]: Charger display/LEDs are completely unlit.\n[Root Cause]: Upstream power supply interruption.\n[Advised Action]: Inspect the physical Isolator switch near the charger. If it is OFF, safely flip it to ON. If the Isolator is already ON, check your main EVDB for tripped breakers. If the unit remains dark, tap [Start Diagnosis].';
    }
    return '[Root Cause]: No diagnostic input provided\n[Advised Action]: EVision AI is ready. Tap [Start Diagnosis] to begin charger fault detection. Alternatively, briefly describe your issue (e.g. "red blinking light" or "no power") for guided troubleshooting.';
  }

  Future<String> _chatViaServer(String message, List<Map<String, dynamic>> history) async {
    try {
      final uri = Uri.parse('$cloudServerApiBaseUrl/chat');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ..._headers,
        },
        body: jsonEncode({
          'message': message,
          'history': history,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = json['reply']?.toString().trim();
        if (reply != null && reply.isNotEmpty) {
          return reply;
        }
        throw Exception('Server returned an empty reply');
      }

      final errorBody = response.body.trim();
      throw Exception('Server error ${response.statusCode}${errorBody.isNotEmpty ? ': $errorBody' : ''}');
    } catch (e) {
      return 'Connection Error: Failed to reach the diagnostic AI server at $cloudServerApiBaseUrl/chat. Start the server in /server and ensure GEMINI_API_KEY is set in server/.env. (${e.toString()})';
    }
  }

  Future<String> _chatViaGeminiDirect(String message, List<Map<String, dynamic>> history) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      return 'Connection Error: GEMINI_API_KEY is not configured for direct on-device chat.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(r'''You are the Guardrailed AI Assistant for a Smart EV Charger App.
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
3. If the user's issue cannot be triaged using standard guides, reply with:
   "[Symptom]: Unknown
[Root Cause]: Unrecognized anomaly
[Advised Action]: Please tap [Start Diagnosis] button below to identify the issue and root cause."
4. If any protection component is missing or broken, advise the user to not touch it.
5. Never use emojis, never give generic advice.
6. Only answer questions related to this app. Politely refuse unrelated questions.
'''),
      );

      final chatHistory = <Content>[];
      for (final msg in history) {
        final text = (msg['text'] ?? '').toString().trim();
        if (text.isEmpty) continue;
        if (msg['isUser'] == true) {
          chatHistory.add(Content.text(text));
        } else {
          chatHistory.add(Content.model([TextPart(text)]));
        }
      }

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(message));
      return response.text?.trim().isNotEmpty == true
          ? response.text!.trim()
          : 'Sorry, no response returned from Gemini.';
    } catch (e) {
      return 'Connection Error: Failed to contact diagnostic AI core backend. (${e.toString()})';
    }
  }
}
