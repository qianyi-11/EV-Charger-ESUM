import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../models/diagnosis_report_data.dart';
import '../services/report_generator.dart';

class ReportPreviewScreen extends StatefulWidget {
  final String? errorCode;
  final Map<String, dynamic>? activityRecord;

  const ReportPreviewScreen({
    super.key,
    this.errorCode,
    this.activityRecord,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  static const Color _accentCyan = Color(0xFF00D1FF);

  AdaptiveTheme get _t => context.adaptive;

  bool _exporting = false;

  DiagnosisReportData? get _report {
    final state = DiagnosticState();
    final code = widget.errorCode ??
        (widget.activityRecord?['code'] as String?) ??
        (state.recentActivity.isNotEmpty ? state.recentActivity.first['code'] as String? : null);
    if (code == null || code.isEmpty) return null;
    return DiagnosisReportData.fromDiagnosticState(
      state,
      errorCode: code,
      activityRecord: widget.activityRecord,
    );
  }

  Future<void> _exportPdf(DiagnosisReportData report) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ReportGenerator().generateDiagnosisPdfBytes(report);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${report.reportId}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _t.textPrimary),
        title: Text(
          'Diagnostic Report',
          style: TextStyle(color: _t.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: report == null
          ? _buildEmptyState()
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildReportBody(report),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _exporting ? null : () => _exportPdf(report),
                        icon: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download, color: Colors.white),
                        label: Text(
                          _exporting ? 'Preparing PDF...' : 'Export PDF',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: _t.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              'No diagnosis data available',
              style: TextStyle(color: _t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a diagnosis first, then open Generate Report from the result page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _t.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportBody(DiagnosisReportData report) {
    final generated = report.generatedAt
        .toIso8601String()
        .substring(0, 19)
        .replaceFirst('T', ' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Report ID: ${report.reportId}',
          style: TextStyle(color: _t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Generated: $generated',
          style: TextStyle(color: _t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          icon: Icons.ev_station_outlined,
          iconColor: _accentCyan,
          title: 'Charger Specification Details',
          child: Column(
            children: [
              _buildSpecRow('Brand', report.brand),
              _buildSpecRow('Model', report.model),
              _buildSpecRow('Serial Number', report.serialNumber),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildHeaderSection(report),
        const SizedBox(height: 20),
        _buildConfidenceCard(report.confidencePercent),
        const SizedBox(height: 20),
        _buildSectionCard(
          icon: Icons.bolt_rounded,
          iconColor: _accentCyan,
          title: 'Diagnostic Explanation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analysis findings:',
                style: TextStyle(
                  color: _accentCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...report.analysisFindings.map(_buildBulletItem),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.warningOrange,
          title: 'Recommended Actions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: report.recommendedActions.map(_buildBulletItem).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeaderSection(DiagnosisReportData report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _accentCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentCyan.withValues(alpha: 0.35)),
          ),
          child: Text(
            report.faultType,
            style: const TextStyle(
              color: _accentCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          report.headlineTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _t.textPrimary,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        if (report.headlineSubtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            report.headlineSubtitle!,
            style: TextStyle(color: _t.textSecondary, fontSize: 14, height: 1.45),
          ),
        ],
      ],
    );
  }

  Widget _buildConfidenceCard(int percent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _t.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _t.subtleBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AI Confidence Score',
            style: TextStyle(color: _t.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              color: _accentCyan,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: _t.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _t.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _t.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _t.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: _t.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _t.sectionDivider),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: const BoxDecoration(color: _accentCyan, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _t.textPrimary, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
