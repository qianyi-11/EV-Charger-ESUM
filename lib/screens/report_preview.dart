import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  final Map<String, dynamic> reportData = const {
    "reportId": "EVA-2026-05-14-001",
    "generatedAt": "May 14, 2026 • 2:45 PM",
    "chargerModel": "Tesla Wall Connector Gen 3",
    "location": "Station A - Bay 3",
    "errorCode": "Error 8",
    "errorName": "RCCB Fault Detected",
    "severity": "Critical",
    "confidence": 96,
    "detectionTime": "3.2 seconds",
    "flashCount": 8,
    "operator": "System Auto-Detect",
  };

  final List<String> diagnosticSummary = const [
    "Residual Current Circuit Breaker fault detected",
    "8 stable LED flash patterns identified",
    "Signal confidence: 96% (High reliability)",
    "Automated detection completed in 3.2 seconds",
  ];

  final List<String> suggestedFixes = const [
    "Isolate charger from electrical grid immediately",
    "Contact certified electrician for RCCB inspection",
    "Check for moisture ingress in electrical compartment",
    "Verify grounding connections and cable integrity",
    "Test RCCB mechanism before restoring service",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Back to Dashboard", style: TextStyle(color: Colors.white54, fontSize: 16)),
        titleSpacing: 0,
      ),
      body: FadeInUp(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildReportHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader("Charger Information", Colors.cyan),
                    _buildChargerInfo(),
                    const SizedBox(height: 24),

                    _buildSectionHeader("Error Detected", const Color(0xFFFF2D55)),
                    _buildErrorDetected(),
                    const SizedBox(height: 24),

                    _buildSectionHeader("Diagnostic Summary", const Color(0xFF00FF88)),
                    _buildListCard(diagnosticSummary, Icons.check_circle, const Color(0xFF00FF88)),
                    const SizedBox(height: 24),

                    _buildSectionHeader("Recommended Actions", Colors.orange),
                    _buildNumberedListCard(suggestedFixes, Colors.orange),
                    const SizedBox(height: 24),

                    _buildFooterDisclaimer(),
                  ],
                ),
              ),
              _buildBottomActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00D4FF)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Diagnostic Report", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(reportData["reportId"], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(reportData["severity"].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat("Generated", reportData["generatedAt"]),
              _buildHeaderStat("Operator", reportData["operator"]),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChargerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Model", style: TextStyle(color: Colors.white54)),
            Text(reportData["chargerModel"], style: const TextStyle(color: Colors.white)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Location", style: TextStyle(color: Colors.white54)),
            Text(reportData["location"], style: const TextStyle(color: Colors.white)),
          ]),
        ],
      ),
    );
  }

  Widget _buildErrorDetected() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFF2D55).withOpacity(0.1), border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.2)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF2D55)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reportData["errorCode"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(reportData["errorName"], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat("Confidence", "${reportData["confidence"]}%"),
              _buildSmallStat("Detection Time", reportData["detectionTime"]),
              _buildSmallStat("Flash Pattern", "${reportData["flashCount"]} flashes"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildListCard(List<String> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 14))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNumberedListCard(List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${entry.key + 1}.", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 14))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFooterDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.05), border: Border.all(color: Colors.cyan.withOpacity(0.2)), borderRadius: BorderRadius.circular(16)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AI Model Version", style: TextStyle(color: Colors.white54, fontSize: 12)),
          SizedBox(height: 4),
          Text("EVision AI v2.4.1 - Industrial EV Diagnostics", style: TextStyle(color: Colors.white, fontSize: 14)),
          SizedBox(height: 8),
          Text("This report was generated using advanced computer vision and AI pattern recognition. All diagnostic information should be verified by a certified technician.", style: TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white10)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text("Export PDF", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text("Share"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.cyan, side: const BorderSide(color: Colors.white10), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text("Print"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.cyan, side: const BorderSide(color: Colors.white10), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}