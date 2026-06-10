import 'detected_fault.dart';
import 'diagnostic_state.dart';

/// Snapshot of the diagnosis result screen used for report preview and PDF export.
class DiagnosisReportData {
  final String errorCode;
  final String faultType;
  final String headlineTitle;
  final String? headlineSubtitle;
  final int confidencePercent;
  final List<String> analysisFindings;
  final List<String> recommendedActions;
  final String brand;
  final String model;
  final String serialNumber;
  final DateTime generatedAt;

  const DiagnosisReportData({
    required this.errorCode,
    required this.faultType,
    required this.headlineTitle,
    this.headlineSubtitle,
    required this.confidencePercent,
    required this.analysisFindings,
    required this.recommendedActions,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.generatedAt,
  });

  String get reportId =>
      'EV-${generatedAt.year}${generatedAt.month.toString().padLeft(2, '0')}${generatedAt.day.toString().padLeft(2, '0')}-${errorCode.toUpperCase()}';

  static String _headlineTitle(DetectedFault fault) {
    final detail = fault.faultDetail;
    final indicating =
        RegExp(r'indicating an? (.+?)\.?$', caseSensitive: false).firstMatch(detail);
    if (indicating != null) return indicating.group(1)!.trim();
    if (detail.length <= 48) return detail;
    final dot = detail.indexOf('. ');
    if (dot > 0) return detail.substring(0, dot);
    return fault.faultType;
  }

  static String? _headlineSubtitle(DetectedFault fault) {
    if (fault.faultDetail.toLowerCase().startsWith('wrong component specifications')) {
      return null;
    }
    final title = _headlineTitle(fault);
    if (fault.faultDetail.trim() == title.trim()) return null;
    return fault.faultDetail;
  }

  static List<String> _splitIntoBullets(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static DiagnosisReportData? fromDiagnosticState(
    DiagnosticState state, {
    required String errorCode,
    Map<String, dynamic>? activityRecord,
  }) {
    final isHistorical = activityRecord != null;
    final faults = isHistorical
        ? state.faultsFromActivityRecord(activityRecord)
        : state.resolvedFaults(errorCode);
    if (faults.isEmpty) return null;

    final primary = faults.first;
    final scanFindings = isHistorical
        ? state.scanFindingsFromActivityRecord(activityRecord)
        : state.scanFindings;

    final rawConfidence = isHistorical
        ? state.confidenceFromActivityRecord(activityRecord)
        : (state.scanConfidence > 0
            ? state.scanConfidence
            : (state.database[FaultCatalog.normalizeErrorCode(errorCode)] ??
                    state.database[errorCode])
                ?.confidence ??
                DiagnosticState.displayConfidenceDefault);

    final List<String> findings;
    if (errorCode.toLowerCase() == 'protection-issue' && scanFindings.isNotEmpty) {
      findings = scanFindings.map(FaultCatalog.simplifySpecFinding).toSet().toList();
    } else {
      findings = faults.expand((f) => _splitIntoBullets(f.faultDetail)).toSet().toList();
    }

    final actions =
        faults.expand((f) => _splitIntoBullets(f.recommendedAction)).toSet().toList();

    String display(String value) => value.trim().isEmpty ? '—' : value.trim();

    return DiagnosisReportData(
      errorCode: errorCode,
      faultType: primary.faultType,
      headlineTitle: _headlineTitle(primary),
      headlineSubtitle: _headlineSubtitle(primary),
      confidencePercent:
          (DiagnosticState.normalizeDisplayConfidence(rawConfidence) * 100).round(),
      analysisFindings: findings,
      recommendedActions: actions,
      brand: display(state.brand),
      model: display(state.chargerModel),
      serialNumber: display(state.serialNumber),
      generatedAt: DateTime.now(),
    );
  }
}
