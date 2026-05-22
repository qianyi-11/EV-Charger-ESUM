import 'dart:async';
import 'dart:convert';

import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'red_led_detector.dart';
import 'server_connectivity_service.dart';
import '../models/diagnostic_state.dart';

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

  /// Cloud ML API base URL — always resolved via [ServerConnectivityService].
  String get cloudApiBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return "http://$host:5000/api/vision";
    }
    return ServerConnectivityService.instance.visionBaseUrl;
  }

  /// Base URL for non-vision API routes (e.g. /api/chat).
  String get cloudServerApiBaseUrl =>
      ServerConnectivityService.instance.apiBaseUrl;

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
          if (kDebugMode) {
            print("[ML Service] Upload URL: $uri");
          }
          
          // Get video file size
          final videoFileInfo = await videoFile.readAsBytes();
          final fileSizeKb = videoFileInfo.length / 1024;
          if (kDebugMode) {
            print("[ML Service] Video file: ${videoFile.path}");
            print("[ML Service] Video size: ${fileSizeKb.toStringAsFixed(2)} KB");
            print("[ML Service] Starting multipart upload...");
          }
          
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'video',
              videoFile.path,
            ));
          
          if (kDebugMode) {
            print("[ML Service] Upload request prepared, sending to server...");
          }
          
          final startTime = DateTime.now();
          final response = await request.send();
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);
          
          if (kDebugMode) {
            print("[ML Service] Server response received in ${duration.inMilliseconds}ms");
            print("[ML Service] HTTP Status: ${response.statusCode}");
          }
          
          if (response.statusCode == 200) {
            final responseBody = await response.stream.bytesToString();
            if (kDebugMode) {
              print("[ML Service] Response body: $responseBody");
            }
            
            final json = jsonDecode(responseBody);
            final result = BlinkDetectionResult(
              success: json['success'] ?? false,
              blinkCount: json['blinkCount'] ?? 0,
              correlatedErrorCode: json['correlatedErrorCode'] ?? "unknown",
              confidence: (json['confidence'] ?? 0.0).toDouble(),
            );
            
            if (kDebugMode) {
              print("[ML Service] ✅ Blink detection result: count=${result.blinkCount}, confidence=${result.confidence.toStringAsFixed(2)}");
            }
            
            return result;
          } else {
            final errorBody = await response.stream.bytesToString();
            throw Exception("Server returned status: ${response.statusCode}. Body: $errorBody");
          }
        } catch (e) {
          if (kDebugMode) {
            print("[ML Service] ❌ Error during video processing: $e");
          }
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
          final state = DiagnosticState();
          
          final request = http.MultipartRequest("POST", uri)
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ));
          
          // Send specs as form fields alongside the image
          if (state.inputVoltage.isNotEmpty) {
            request.fields['inputVoltage'] = state.inputVoltage;
          }
          if (state.outputCurrent.isNotEmpty) {
            request.fields['outputCurrent'] = state.outputCurrent;
          }
          
          if (kDebugMode) {
            print("[ML Service] EVDB upload with specs: inputVoltage=${state.inputVoltage}, outputCurrent=${state.outputCurrent}");
          }
          
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

  /// Stable fallback response that checks both technical knowledge items and normal chatbot inputs offline.
  String fallbackResponse(String message) {
    return _mockChatResponse(message);
  }

  String _mockChatResponse(String message) {
    final state = DiagnosticState();
    final normalized = message.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');

    // Check if there is no scan history at all
    final bool hasNoScans = !state.ocrCompleted && state.recentActivity.isEmpty;

    // SCENARIO 1: No Scan History + Contextual/Specific charger questions
    if (hasNoScans) {
      // General or specific error code query "What does Error 8 mean?" (Explain generally but warn of empty state)
      if (normalized.contains('error 8') || normalized.contains('error8')) {
        return '🔌 **Error 8 (Residual Current Circuit Breaker Fault)**\n\n'
            'Error 8 indicates an RCCB (Residual Current Circuit Breaker) Fault or charging cable leakage. The charger\'s internal sensors detected current leaking to earth (>30mA), or insulation compromise in the cord, and instantly cut the electrical feed to ensure absolute safety.\n\n'
            '⚠️ *Note: Since there is no active scan history for your charger, I cannot verify if your device is experiencing this fault. Please run a diagnosis scan first.*';
      }

      // If they ask about safety, continuing charging, or how to fix their device when there is no scan history:
      if (normalized.contains('dangerous') || 
          normalized.contains('continue charging') || 
          normalized.contains('can customer continue') ||
          normalized.contains('how to fix') || 
          normalized.contains('fix this') ||
          normalized.contains('history') || 
          normalized.contains('scan') || 
          normalized.contains('my charger') || 
          normalized.contains('my device') || 
          normalized.contains('diagnosis') ||
          normalized.contains('error') ||
          normalized.contains('status') ||
          normalized.contains('report')) {
        return '🔌 **No Scan History Found**\n\n'
            'I currently do not see any active diagnostic telemetry or scan history for your charger. Therefore, I cannot determine if there is a safety risk, if it is safe to charge, or how to resolve any issues.\n\n'
            'To start:\n'
            '1. Go back to the Dashboard.\n'
            '2. Tap **Start Diagnosis** to capture your charger\'s status panel or specification plate.\n'
            '3. Once completed, I will analyze the exact results and guide you with real-time solutions.';
      }

      // For general unrelated queries when no scans
      return '🔌 **No Scan History Found**\n\n'
          'To assist you with custom queries, I need a technical or visual scan of your charger.\n\n'
          'Please tap **Start Diagnosis** on the Dashboard to scan the charger LED display or specification label. This allows me to perform real-time diagnostic matching without fake or generic information.';
    }

    // SCENARIO 2: Active Scan History exists! Answer dynamically based on the actual scanned code.
    final String activeCode = state.recentActivity.isNotEmpty ? state.recentActivity.first["code"] ?? "blink-8" : "blink-8";

    // 2.1 Charger Details scenario:
    if (normalized.contains('what is my charger') || 
        normalized.contains('my charger model') || 
        normalized.contains('serial') || 
        normalized.contains('what did i scan') || 
        normalized.contains('latest scan') || 
        normalized.contains('my scan') || 
        normalized.contains('history')) {
      final chargerName = state.chargerModel;
      final sn = state.serialNumber;
      final latest = state.recentActivity.isNotEmpty ? state.recentActivity.first : null;
      
      String response = '📊 **Your Scanned Charger Details**\n\n'
          '• **Charger Model:** $chargerName\n'
          '• **Serial Number:** $sn\n';
      
      if (latest != null) {
        response += '• **Latest Diagnostic:** ${latest["description"]} (Code: ${latest["code"]?.toUpperCase()})\n'
            '• **Scan Date:** ${latest["timestamp"]}\n\n'
            'Please ask me how to fix this error or if it represents a safety risk!';
      } else {
        response += '\nNo active errors have been recorded in the session logs yet.';
      }
      return response;
    }

    // 2.2 Question about Error 8 generally:
    if (normalized.contains('error 8') || normalized.contains('error8')) {
      String confirmation = "";
      if (activeCode == "blink-8") {
        confirmation = "\n\n✅ *Your active charger scan confirms that your device is experiencing this leakage fault.*";
      } else {
        confirmation = "\n\n⚠️ *Note: Your active scan actually reports a **$activeCode** error, not Error 8.*";
      }
      return 'Error 8 indicates an RCCB (Residual Current Circuit Breaker) Fault or charging cable leakage. The charger\'s internal sensors detected current leaking to earth (>30mA), or insulation compromise in the cord, and instantly cut the electrical feed to ensure absolute safety.' + confirmation;
    }

    // 2.3 Danger/Safety Scenarios based on activeCode:
    if (normalized.contains('dangerous') || normalized.contains('is it safe')) {
      switch (activeCode) {
        case 'power-cut':
          return 'There is no danger. The primary power isolation switch is simply in the OFF position. This cuts all electrical feed to the system. Reactivating it is safe.';
        case 'protection-issue':
          return '⚠️ **CRITICAL SAFETY HAZARD**\n\nYes, this is highly dangerous! An incompatible or missing breaker component was detected in the EV Distribution Board (EVDB). Operating the charger under these conditions represents a significant safety hazard (fire risk). **DO NOT** attempt to touch or reactivate the breakers. An after-sales technician has been automatically contacted to resolve this.';
        case 'blink-6':
          return '⚠️ **CRITICAL EARTH LOOP FAULT**\n\nYes, a critical grounding fault was detected. Stray neutral-to-earth potential exceeds safe operating thresholds. Operating the charger without proper protective grounding is hazardous. The charging vehicle must be disconnected immediately.';
        case 'blink-7':
          return 'There is no immediate danger. The Emergency Stop button has been physically depressed, isolating the charger output. However, please inspect the physical casing for any active hazard or smoke before resetting it.';
        case 'blink-8':
          return 'There is no immediate danger. The EVision AI safety relay reacted in milliseconds to isolate the high-voltage lines. However, you should avoid touching the charging plug contacts or vehicle sockets while moisture checks are pending.';
        case 'blink-9':
          return 'There is no danger. The micro-controller has entered a locked state due to an internal firmware crash. A simple system reboot is needed.';
        default:
          return 'No critical safety hazards are active. The charger is reporting a standard diagnostic state.';
      }
    }

    // 2.4 Charging continuity Scenarios based on activeCode:
    if (normalized.contains('continue charging') || normalized.contains('can customer continue')) {
      switch (activeCode) {
        case 'power-cut':
          return 'No, charging cannot continue because the isolator switch is OFF and power is completely cut to the unit.';
        case 'protection-issue':
          return '❌ **CHARGING BLOCKED**\n\nAbsolutely not. Charging is locked out until the distribution board breaker components are replaced by a qualified technician to prevent electrical fire.';
        case 'blink-6':
          return '❌ **CHARGING BLOCKED**\n\nNo, charging is blocked by the safety system due to the grounding/earth fault. Disconnect the vehicle immediately.';
        case 'blink-7':
          return '❌ **CHARGING BLOCKED**\n\nNo, charging is cut off because the Emergency Stop button is depressed. Twist the red mushroom button clockwise to reset.';
        case 'blink-8':
          return 'Charging is locked out until the leakage fault is resolved. The system blocks current delivery to secure the vehicle battery and charger casing. Please keep the charging plug securely locked in the side dock for now.';
        case 'blink-9':
          return '❌ **CHARGING BLOCKED**\n\nNo, charging is blocked until the system is rebooted. Toggle the main power isolator OFF for 30 seconds, then back ON.';
        default:
          return 'Yes, there are no active safety faults blocking charging. You can proceed with charging normally.';
      }
    }

    // 2.5 Repair steps Scenarios based on activeCode:
    if (normalized.contains('how to fix') || normalized.contains('fix this') || normalized.contains('resolve')) {
      switch (activeCode) {
        case 'power-cut':
          return 'Follow these steps:\n1) Locate the primary isolator switch/lever beside the charger.\n2) Carefully flip the isolator toggle to the ON position.\n3) Wait 10 seconds for the charger boot sequence to initialize.';
        case 'protection-issue':
          return '❌ **DO NOT ATTEMPT SELF-REPAIR**\n\n1) Keep the main isolator switch OFF.\n2) Do NOT touch the distribution board breakers.\n3) Wait for the dispatched technician to replace the standard MCB with an approved EV-rated Class A Type-A/B RCCB.';
        case 'blink-6':
          return '1) Disconnect the charging vehicle immediately.\n2) Ensure no active charging sessions are forced via overrides.\n3) Wait for the dispatched maintenance team to inspect the grounding terminal blocks and earth conductor continuity.';
        case 'blink-7':
          return 'Follow these steps:\n1) Inspect the physical charger for any active hazard or smoke.\n2) Locate the red mushroom Emergency Stop button on the side panel.\n3) Twist the red button clockwise to pop it back out into ready status.';
        case 'blink-8':
          return 'Follow these steps: 1) Disconnect the plug from the car. 2) Inspect the cable sheath and connector pin slots for water, dirt, or cuts. 3) Wipe the connector dry if wet. 4) If clear, toggle the main power isolator switch OFF, wait 30 seconds, then toggle back ON. A technician is already dispatched to run insulation diagnostics if the error persists.';
        case 'blink-9':
          return 'Follow these steps:\n1) Locate the main power isolator switch or breaker and flip it OFF.\n2) Wait at least 30 seconds for the internal capacitors to discharge fully.\n3) Flip the switch back ON and monitor the LED indicator boots normally.';
        default:
          return 'No repairs are needed since there is no active fault. If you are experiencing issues, please run a diagnostics scan.';
      }
    }

    // General fallback for unknown custom questions when scans exist
    return '🔌 **EVision AI Connection Offline**\n\n'
        'I am currently unable to reach the EVision AI Diagnostics Server to provide a real-time response to your question.\n\n'
        'To enable real-time AI diagnostics, please check that:\n'
        '1. The EVision backend proxy server is running (`npm start` inside the `/server` directory).\n'
        '2. Your phone and host computer are connected to the **same Wi-Fi network**.\n'
        '3. Your host PC\'s IP address matches the configuration set under **App Settings → Dev Server**.\n\n'
        '*(Note: Suggested preset questions remain available offline at any time!)*';
  }

  Future<String> _chatViaServer(String message, List<Map<String, dynamic>> history) async {
    try {
      final uri = Uri.parse('$cloudServerApiBaseUrl/chat');
      final state = DiagnosticState();
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ..._headers,
        },
        body: jsonEncode({
          'message': message,
          'history': history,
          'diagnosticState': {
            'ocrCompleted': state.ocrCompleted,
            'chargerModel': state.chargerModel,
            'serialNumber': state.serialNumber,
            'recentActivity': state.recentActivity,
            'selectedBranch': state.selectedBranch,
            'isIsolatorOn': state.isIsolatorOn,
            'isEvdbOk': state.isEvdbOk,
            'blinksCounted': state.blinksCounted,
            'targetErrorCode': state.targetErrorCode,
          }
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
      if (kDebugMode) {
        print("[ML Service] Chat server connection error: $e. Falling back to local offline response.");
      }
      return _mockChatResponse(message);
    }
  }

  Future<String> _chatViaGeminiDirect(String message, List<Map<String, dynamic>> history) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      if (kDebugMode) {
        print("[ML Service] Direct Gemini key missing. Falling back to local response.");
      }
      return _mockChatResponse(message);
    }

    try {
      final state = DiagnosticState();
      final bool hasNoScans = !state.ocrCompleted && state.recentActivity.isEmpty;
      final String activeError = state.recentActivity.isNotEmpty ? state.recentActivity.first['code'] ?? 'unknown' : 'none';

      String systemInstructionText = r'''You are the Guardrailed AI Assistant for a Smart EV Charger App.
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
''';

      if (hasNoScans) {
        systemInstructionText += r'''
7. IMPORTANT: There is NO active scan history or diagnostic data currently available for this charger.
If the user asks about dangerous conditions, continuing charging, how to fix, or diagnostic status, you MUST politely state:
"🔌 No Scan History Found. I currently do not see any active diagnostic telemetry or scan history for your charger. Therefore, I cannot determine if there is a safety risk, if it is safe to charge, or how to resolve any issues. Please go back to the Dashboard and tap [Start Diagnosis] to scan your charger status panel or specification plate so that I can provide real-time guidance."
Do NOT output any simulated RCCB/Error 8 instructions when there is no scan history.
''';
      } else {
        systemInstructionText += '''
7. ACTIVE TELEMETRY CONTEXT:
- Charger Model: ${state.chargerModel}
- Serial Number: ${state.serialNumber}
- Active Diagnosed Fault: $activeError
- Current Branch: Branch ${state.selectedBranch}
- Isolator Switch State: ${state.isIsolatorOn ? 'ON' : 'OFF'}
- EVDB Specification Status: ${state.isEvdbOk ? 'Incompatible Board or Breaker Detected' : 'Board spec checks passed'}
- Blinks Counted: ${state.blinksCounted}

Provide direct, highly accurate responses tailored specifically to this active error:
- If 'power-cut': Explain that the Isolator Switch is OFF and must be turned ON.
- If 'protection-issue': Explain that the EV Distribution Board (EVDB) breaker capacity/MCB specification is incorrect/wrong board spec. Advise them a technician is auto-contacted, and DO NOT touch the board.
- If 'blink-6': Explain that there is a Grounding/PE open-circuit fault. Advise keeping clear and that a technician is on the way.
- If 'blink-7': Explain that the Emergency Stop (E-Stop) button is pressed. Advise twisting it clockwise to reset.
- If 'blink-8': Explain that there is an RCCB earth leakage fault. Advise unplugging and checking for damage/water.
- If 'blink-9': Explain that there is a microcontroller/control loop hang. Advise power cycling the main isolator switch.
- If 'charger-issue': Explain that a general internal overtemperature or cooling fan hardware fault is active.
Never output fake RCCB (Error 8) information if the active scanned error code is different.
''';
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstructionText),
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
          : _mockChatResponse(message);
    } catch (e) {
      if (kDebugMode) {
        print("[ML Service] Direct Gemini error: $e. Falling back to local response.");
      }
      return _mockChatResponse(message);
    }
  }
}
