import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../services/firebase_service.dart';

class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = DiagnosticState();
    final String? savedId = state.savedReportId;

    if (savedId != null) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: FirebaseService().getScanResult(savedId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.electricBlue),
              ),
            );
          }

          final firestoreData = snapshot.data;
          return _buildReportContent(context, state, savedId, firestoreData);
        },
      );
    } else {
      return _buildReportContent(context, state, null, null);
    }
  }

  Widget _buildReportContent(
    BuildContext context,
    DiagnosticState state,
    String? reportId,
    Map<String, dynamic>? firestoreData,
  ) {
    // Extract info
    final String activeCode = firestoreData != null
        ? firestoreData['targetErrorCode']
        : (state.recentActivity.isNotEmpty
            ? state.recentActivity.first["code"]
            : "blink-8");
            
    final info = state.database[activeCode] ?? state.database["blink-8"]!;

    Color severityColor = AppColors.successGreen;
    String severityText = "PASSED";
    if (info.severity == DiagnosisSeverity.critical) {
      severityColor = AppColors.dangerRed;
      severityText = "CRITICAL";
    } else if (info.severity == DiagnosisSeverity.warning) {
      severityColor = AppColors.warningOrange;
      severityText = "WARNING";
    }

    final displayModel = firestoreData != null
        ? firestoreData['chargerModel']
        : (state.chargerModel == "Unknown Charger" ? "Tesla Wall Connector Gen 3" : state.chargerModel);

    final displaySerial = firestoreData != null
        ? firestoreData['serialNumber']
        : (state.serialNumber == "Unknown Serial" ? "TWC-2024-A8F3E2" : state.serialNumber);

    final String displayReportId = reportId != null 
        ? "FIRE-${reportId.toUpperCase().substring(0, reportId.length > 8 ? 8 : reportId.length)}" 
        : "EVA-2026-05-14-001";
        
    final String displayTimestamp = firestoreData != null
        ? (firestoreData['timestamp'] != null 
            ? (firestoreData['timestamp'] as Timestamp).toDate().toString().substring(0, 19)
            : DateTime.now().toString().substring(0, 19))
        : "2026-05-20 16:20:45";

    final String displayOperator = firestoreData != null ? "Firebase Cloud Sync" : "System Auto-Detect";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Diagnostic Report Preview"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable PDF Preview Page Sheet
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Report Header Strip (blue gradient)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.electricBlue, Color(0xFF005F80)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "DIAGNOSTIC REPORT",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 0.5),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    severityText,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildHeaderMetaRow("Report ID:", displayReportId),
                            const SizedBox(height: 4),
                            _buildHeaderMetaRow("Timestamp:", displayTimestamp),
                            const SizedBox(height: 4),
                            _buildHeaderMetaRow("Operator:", displayOperator),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Charger Information Card
                      _buildSectionTitle("CHARGER SPECIFICATION DETAILS", AppColors.electricBlue),
                      const SizedBox(height: 8),
                      GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildDataField("Model Ident:", displayModel),
                            const SizedBox(height: 8),
                            _buildDataField("Serial Number:", displaySerial),
                            const SizedBox(height: 8),
                            _buildDataField("Deployment Location:", "Station A - Bay 3"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Error Detected Card
                      _buildSectionTitle("CRITICAL SAFETY BREAKER DETAILS", AppColors.dangerRed),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: severityColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: severityColor, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${info.code}: ${info.name}",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: severityColor, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "AI Confidence Level: ${(info.confidence * 100).toInt()}% • Code parameters confirmed",
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Diagnostic Summary Findings
                      _buildSectionTitle("DIAGNOSTIC SUMMARY FINDINGS", AppColors.successGreen),
                      const SizedBox(height: 8),
                      ...List.generate(
                        info.findings.length,
                        (index) => _buildChecklistSummaryItem(info.findings[index]),
                      ),
                      const SizedBox(height: 20),

                      // 5. Recommended Actions Card
                      _buildSectionTitle("FIELD RECOMMENDATIONS", AppColors.warningOrange),
                      const SizedBox(height: 8),
                      ...List.generate(
                        info.immediateActions.length,
                        (index) => _buildNumberedActionItem(index + 1, info.immediateActions[index]),
                      ),
                      const SizedBox(height: 20),

                      // 6. AI Model Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.electricBlue.withOpacity(0.1)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Model Version: EVision AI v2.4.1",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.electricBlue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Disclaimer: Telemetric findings represent machine-vision estimates. Structural wiring and voltage safety loops must be mechanically verified by licensed specialists.",
                              style: TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action buttons layout
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full width Export PDF
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Exporting diagnostic PDF document: $displayReportId ... saved to local downloads."),
                          backgroundColor: AppColors.secondaryBg,
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.electricBlue, Color(0xFF007A99)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, color: Colors.black, size: 20),
                            SizedBox(width: 10),
                            Text("Export PDF Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Half width buttons row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryActionButton(
                          title: "Share",
                          icon: Icons.share_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Diagnostic data package synchronized for sharing.")),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSecondaryActionButton(
                          title: "Print",
                          icon: Icons.print_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Connecting to local network printer devices...")),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetaRow(String label, String val) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Text(val, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "monospace")),
      ],
    );
  }

  Widget _buildSectionTitle(String text, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          color: accentColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: accentColor, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildDataField(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildChecklistSummaryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: AppColors.successGreen, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedActionItem(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$num. ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warningOrange),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.electricBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
