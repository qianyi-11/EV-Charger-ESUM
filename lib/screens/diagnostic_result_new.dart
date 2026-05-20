import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class DiagnosisResultNewScreen extends StatelessWidget {
  final String errorCode; // e.g., "blink-8"

  const DiagnosisResultNewScreen({super.key, this.errorCode = "blink-8"});

  @override
  Widget build(BuildContext context) {
    // In a real app, this would come from a data provider or service
    final data = _getDiagnosisData(errorCode);

    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 170,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white38,
            size: 18,
          ),
          label: const Text(
            "Back to Dashboard",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (data['requiresTechnician'] == true)
            _buildTopNotification(data['technicianNote']),
          if (data['requiresTechnician'] == true) const SizedBox(height: 16),
          FadeInDown(child: _buildHeader(data)),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildSummaryCards(data),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildActionStepsCard(data),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['code'],
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description'],
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white24,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data['timestamp'],
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: data['levelColor'].withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: data['levelColor'].withOpacity(0.25)),
              ),
              child: Text(
                data['level'],
                style: TextStyle(
                  color: data['levelColor'],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "AI Confidence",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              "${data['confidence']}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRainbowProgress(data['confidence'] / 100),
      ],
    ),
  );

  Widget _buildRainbowProgress(double value) => Container(
    height: 12,
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(99),
    ),
    child: FractionallySizedBox(
      widthFactor: value.clamp(0.0, 1.0),
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF00FF88),
              Color(0xFF00D4FF),
              Color(0xFF7E5AFF),
              Color(0xFFFF5E7D),
              Color(0xFFFFD24A),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    ),
  );

  Widget _buildSummaryCards(Map<String, dynamic> data) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _buildObservationCard(data)),
      const SizedBox(width: 12),
      Expanded(child: _buildFaultTypeCard(data)),
    ],
  );

  Widget _buildObservationCard(Map<String, dynamic> data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF06111D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.remove_red_eye, color: Color(0xFF00D4FF), size: 22),
            SizedBox(width: 12),
            Text(
              "Observation",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...((data['observation'] as List<String>).map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.brightness_1,
                    color: Color(0xFF00D4FF),
                    size: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );

  Widget _buildFaultTypeCard(Map<String, dynamic> data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF20090F),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.report_problem, color: Color(0xFFFF2D55), size: 22),
            SizedBox(width: 12),
            Text(
              "Fault Type",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          data['faultType'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...((data['faultTypeDetails'] as List<String>).map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.brightness_1,
                    color: Color(0xFFFF2D55),
                    size: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );

  Widget _buildActionStepsCard(Map<String, dynamic> data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.lightbulb_outline, color: Color(0xFF7E5AFF), size: 22),
            SizedBox(width: 12),
            Text(
              "Action Steps",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          data['actionSubtitle'],
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...((data['actionSteps'] as List<String>).map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7E5AFF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );

  Widget _buildDiagnosticExplanation(Map<String, dynamic> data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bolt, color: Color(0xFF00D4FF), size: 22),
            SizedBox(width: 12),
            Text(
              "Diagnostic Explanation",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Analysis findings:",
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...((data['analysisFindings'] as List<String>).map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.circle, color: Color(0xFF00D4FF), size: 6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );

  Widget _buildRecommendedActions(Map<String, dynamic> data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFFFD24A),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              data['actionTitle'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          data['actionSubtitle'],
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...((data['recommendations'] as List<String>).map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.circle, color: Color(0xFF00D4FF), size: 6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF071B2D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.description, size: 18),
          label: const Text(
            "Generate Report",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {},
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text(
            "Ask AI",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {},
        ),
      ),
    ],
  );

  Widget _buildTopNotification(String message) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF2A0B12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.18)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.build_circle, color: Color(0xFFFF2D55), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Technician Contacted",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // Simplified data getter for demonstration
  Map<String, dynamic> _getDiagnosisData(String code) {
    switch (code) {
      case 'ground-fault':
        return {
          "code": "ERR-003",
          "name": "Ground Fault Detected",
          "description":
              "The charger detected an imbalance between live and earth conductors.",
          "timestamp": "May 19, 2026 · 04:12 PM",
          "level": "Warning",
          "levelColor": Colors.orange,
          "confidence": 88,
          "observation": [
            "Charger is powered but showing no stable red light",
            "Ground leakage signature detected",
          ],
          "faultType": "Supply Issue",
          "faultTypeDetails": ["No Light", "Blinking Red Light"],
          "analysisFindings": [
            "Current drift exceeds threshold",
            "Ground leakage present",
            "Signal timing shows earth leakage signature",
          ],
          "actionSubtitle":
              "Technician has been automatically notified with diagnostic data.",
          "actionSteps": [
            "Inspect earthing connection",
            "Reset the charger and monitor again",
            "Verify the input conductor insulation",
            "Check earth leakage detection settings",
          ],
          "requiresTechnician": true,
          "technicianNote":
              "A technician has been notified and should contact you shortly.",
        };
      case 'system-ok':
        return {
          "code": "OK-000",
          "name": "System Nominal",
          "description":
              "No faults were detected in the most recent system scan.",
          "timestamp": "May 18, 2026 · 11:05 AM",
          "level": "Normal",
          "levelColor": const Color(0xFF00FF88),
          "confidence": 99,
          "observation": [
            "Charger indicator is normal",
            "No fault condition detected",
          ],
          "faultType": "System Nominal",
          "faultTypeDetails": ["No Fault"],
          "analysisFindings": [
            "No abnormal current patterns",
            "All diagnostic checks passed",
            "Charger is operating normally",
          ],
          "actionSubtitle": "No further action required at this time.",
          "actionSteps": [
            "Continue regular maintenance",
            "Review history if new alerts appear",
          ],
          "requiresTechnician": false,
        };
      default:
        return {
          "code": "ERR-008",
          "name": "RCCB Fault Detected",
          "description":
              "The system detected a residual current circuit breaker fault from the latest charging session.",
          "timestamp": "May 20, 2026 · 09:38 AM",
          "level": "Critical",
          "levelColor": const Color(0xFFFF2D55),
          "confidence": 96,
          "observation": [
            "8 stable red light flashes identified",
            "Blink pattern matched Error 8 signature",
            "Signal timing: 400ms intervals with 2s pause",
          ],
          "faultType": "Charger Issue",
          "faultTypeDetails": ["Red Light", "No Light", "Blinking Red Light"],
          "analysisFindings": [
            "8 stable red light flashes identified",
            "Blink pattern matched Error 8 signature",
            "Signal timing: 400ms intervals with 2s pause",
            "Pattern confidence: 96%",
          ],
          "actionSubtitle":
              "Technician has been automatically notified with diagnostic data.",
          "actionSteps": [
            "Isolate power",
            "Call electrician",
            "Verify RCCB trip sensitivity",
            "Inspect charging connector and cable",
            "Check for moisture or ingress",
          ],
          "requiresTechnician": true,
          "technicianNote":
              "A technician has been notified and will reach out with next steps.",
        };
    }
  }
}
