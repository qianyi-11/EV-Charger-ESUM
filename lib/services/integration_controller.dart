import 'dart:io';
import 'ocr_handler.dart';
import 'routing_engine.dart';
import 'report_generator.dart';
import 'offline_manager.dart';
import 'server_connectivity_service.dart'; // ← add this import
import '../models/diagnostic_state.dart';
import '../models/diagnosis_report_data.dart';

class IntegrationController {
  OcrHandler? _ocrHandler;
  final RoutingEngine _routingEngine = RoutingEngine();
  final ReportGenerator _reportGenerator = ReportGenerator();
  final OfflineManager _offlineManager = OfflineManager();

  OcrResultData? _ocrCache;

  // Singleton pattern
  static final IntegrationController _instance = IntegrationController._internal();
  factory IntegrationController() => _instance;

  IntegrationController._internal() {
    _offlineManager.initDatabase();
    _initOcrHandler();
  }

  Future<void> _initOcrHandler() async {
  try {
    final connectivity = ServerConnectivityService.instance;
    
    // Initialize if not already done
    if (!connectivity.isInitialized) {
      await connectivity.initialize();
    }
    
    // Use visionBaseUrl but strip /api/vision since OcrHandler adds its own path
    final visionUrl = connectivity.visionBaseUrl;
    final baseUrl = visionUrl.replaceFirst('/api/vision', '');
    
    _ocrHandler = OcrHandler(baseUrl: baseUrl);
    print('[IntegrationController] OcrHandler initialized with: $baseUrl');
  } catch (e) {
    print('[IntegrationController] Failed to get base URL: $e');
    _ocrHandler = OcrHandler(baseUrl: 'http://10.164.232.243');
  }
}

  /// Step 1: Run OCR on the spec plate
  Future<OcrResultData> executeOcrScan(File imageFile) async {
    // Always re-resolve URL fresh, don't rely on constructor init
    final connectivity = ServerConnectivityService.instance;
    if (!connectivity.isInitialized) {
      await connectivity.initialize();
    }
    
    // Rebuild OcrHandler every time with the current resolved URL
    final visionUrl = connectivity.visionBaseUrl;
    final baseUrl = visionUrl.replaceFirst('/api/vision', '');
    _ocrHandler = OcrHandler(baseUrl: baseUrl);
    
    print('[IntegrationController] Using baseUrl: $baseUrl');

    _ocrCache = await _ocrHandler!.processImage(imageFile); // ← note the !

    print('====== OCR RESULT ======');
    print('success: ${_ocrCache?.success}');
    print('brand: ${_ocrCache?.brand}');
    print('model: ${_ocrCache?.modelName}');
    print('serial: ${_ocrCache?.serialNumber}');
    print('inputVoltage: ${_ocrCache?.inputVoltage}');
    print('outputCurrent: ${_ocrCache?.outputCurrent}');
    print('extractedText: ${_ocrCache?.extractedText}');
    print('========================');

    if (_ocrCache != null && _ocrCache!.success) {
      final diagnosticState = DiagnosticState();
      diagnosticState.updateOcr(
        _ocrCache!.modelName,
        _ocrCache!.serialNumber,
        brandVal: _ocrCache!.brand,
        voltage:  _ocrCache!.inputVoltage,
        current:  _ocrCache!.outputCurrent,
      );
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
    final decision = _routingEngine.evaluateFault(
      isChargerDead: isChargerDead,
      isIsolatorOff: isIsolatorOff,
      isMcbMissingOrWrong: isMcbMissingOrWrong,
      isSolidRedLight: isSolidRedLight,
      flashCount: flashCount,
    );

    if (decision.directive == ActionDirective.routeToAfterSales) {
      final diagnosticState = DiagnosticState();
      final report = DiagnosisReportData.fromDiagnosticState(
        diagnosticState,
        errorCode: decision.errorCode,
      );

      if (report != null) {
        final pdfFile = await _reportGenerator.saveDiagnosisPdf(report);

        await _offlineManager.queueReport(
          timestamp: report.generatedAt.toIso8601String(),
          serialNumber: report.serialNumber,
          modelName: report.model,
          faultType: report.faultType,
          actionDirective: report.recommendedActions.join(' '),
          confidenceScore: report.confidencePercent / 100.0,
          pdfPath: pdfFile.path,
        );

        await _offlineManager.syncPendingReports();
      }
    }

    return decision;
  }
}