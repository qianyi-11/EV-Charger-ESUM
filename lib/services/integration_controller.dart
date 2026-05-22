import 'dart:io';
import 'ocr_handler.dart';
import 'routing_engine.dart';
import 'report_generator.dart';
import 'offline_manager.dart';
import '../models/diagnostic_state.dart';

class IntegrationController {
  // Android Emulator: http://10.0.2.2:5000
  // Real phone on same network: http://10.164.38.19:5000
  final OcrHandler _ocrHandler = OcrHandler(baseUrl: 'http://10.164.38.19:5000');
  final RoutingEngine _routingEngine = RoutingEngine();
  final ReportGenerator _reportGenerator = ReportGenerator();
  final OfflineManager _offlineManager = OfflineManager();

  OcrResultData? _ocrCache;

  // Singleton pattern
  static final IntegrationController _instance = IntegrationController._internal();
  factory IntegrationController() => _instance;

  IntegrationController._internal() {
    _offlineManager.initDatabase();
  }

  /// Step 1: Run OCR on the spec plate
  Future<OcrResultData> executeOcrScan(File imageFile) async {
    _ocrCache = await _ocrHandler.processImage(imageFile);
    
    // Save specs to DiagnosticState
    if (_ocrCache != null) {
      final diagnosticState = DiagnosticState();
      diagnosticState.saveSpecsFromOcr({
        'inputVoltage': _ocrCache!.inputVoltage,
        'outputCurrent': _ocrCache!.outputCurrent,
      });
    }
    
    return _ocrCache!;
  }

  /// Step 2: Combine AI Results and Route
  Future<RoutingDecision> processDiagnosticsAndRoute({
    required bool isChargerDead,
    required bool isIsolatorOff,
    required bool isMcbMissingOrWrong,
    required bool isSolidRedLight,
    required int flashCount,
    File? evidenceImage,
  }) async {
    // 1. Evaluate Logic Tree
    final decision = _routingEngine.evaluateFault(
      isChargerDead: isChargerDead,
      isIsolatorOff: isIsolatorOff,
      isMcbMissingOrWrong: isMcbMissingOrWrong,
      isSolidRedLight: isSolidRedLight,
      flashCount: flashCount,
    );

    // 2. If it's an After-Sales issue, auto-generate report & queue it offline
    if (decision.directive == ActionDirective.routeToAfterSales) {
      final reportData = DiagnosticReport(
        timestamp: DateTime.now().toIso8601String(),
        serialNumber: _ocrCache?.serialNumber ?? 'Unknown S/N',
        modelName: _ocrCache?.modelName ?? 'Unknown Model',
        faultType: decision.faultType.toString(),
        actionDirective: decision.actionDescription,
        confidenceScore: 0.95, // Aggregated confidence 
        screenshot: evidenceImage,
      );

      final pdfFile = await _reportGenerator.generateDiagnosticPdf(reportData);

      await _offlineManager.queueReport(
        timestamp: reportData.timestamp,
        serialNumber: reportData.serialNumber,
        modelName: reportData.modelName,
        faultType: reportData.faultType,
        actionDirective: reportData.actionDirective,
        confidenceScore: reportData.confidenceScore,
        pdfPath: pdfFile.path,
      );

      // Attempt immediate sync
      await _offlineManager.syncPendingReports();
    }

    return decision;
  }
}
