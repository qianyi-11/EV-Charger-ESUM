import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class DiagnosticResultScreen extends StatelessWidget {
  final String errorCode;

  const DiagnosticResultScreen({super.key, this.errorCode = "8"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          FadeInDown(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
              title: Text("ERROR $errorCode", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              subtitle: const Text("May 19, 2026 • 7:03 PM", style: TextStyle(color: Colors.white54)),
            ),
          ),
          const SizedBox(height: 24),

          // Confidence Card
          FadeInUp(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AI Confidence Score", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text("96%", style: TextStyle(color: Colors.cyan, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: 0.96, backgroundColor: Colors.white10, color: Colors.cyan),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Explainability Section
          _buildInfoSection(
            title: "AI Explainability",
            icon: Icons.check_circle_outline,
            items: [
              "8 stable flashes identified over 3.2s",
              "Blink timing matched Error 8 pattern",
              "Signal stability confirmed at 96%"
            ],
          ),

          // Recommendations
          const SizedBox(height: 24),
          _buildInfoSection(
            title: "Technician Recommendations",
            icon: Icons.warning_amber_rounded,
            items: ["Stop charging operations immediately", "Isolate from grid", "Contact certified electrician"],
            isWarning: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required List<String> items, bool isWarning = false}) {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: isWarning ? Colors.orange : Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.circle, size: 6, color: Colors.white54),
                const SizedBox(width: 12),
                Text(item, style: const TextStyle(color: Colors.white70)),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}