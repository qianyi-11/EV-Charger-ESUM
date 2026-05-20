import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum Phase { instruction, photoMode, analyzing, resultOk, resultMissing, resultWrongSpec }

class PhotoEVDBScreen extends StatefulWidget {
  const PhotoEVDBScreen({super.key});

  @override
  State<PhotoEVDBScreen> createState() => _PhotoEVDBScreenState();
}

class _PhotoEVDBScreenState extends State<PhotoEVDBScreen> {
  Phase _phase = Phase.instruction;
  
  Map<String, String> clarity = {
    "brightness": "dark",
    "stability": "shaking",
    "focus": "blurry",
  };

  Map<String, bool> analysisSteps = {
    "evdb_detected": false,
    "mcb_check": false,
    "rccb_check": false,
    "complete": false,
  };

  String issueFound = "none";
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) setState(fn);
  }

  void _startPhotoMode() async {
    _safeSetState(() => _phase = Phase.photoMode);

    await Future.delayed(const Duration(milliseconds: 1500));
    _safeSetState(() => clarity["brightness"] = "good");

    await Future.delayed(const Duration(milliseconds: 1000));
    _safeSetState(() => clarity["stability"] = "steady");

    await Future.delayed(const Duration(milliseconds: 1000));
    _safeSetState(() => clarity["focus"] = "sharp");
  }

  void _handleCapture() async {
    _safeSetState(() => _phase = Phase.analyzing);

    await Future.delayed(const Duration(milliseconds: 600));
    _safeSetState(() => analysisSteps["evdb_detected"] = true);

    await Future.delayed(const Duration(milliseconds: 600));
    _safeSetState(() => analysisSteps["mcb_check"] = true);

    await Future.delayed(const Duration(milliseconds: 600));
    _safeSetState(() => analysisSteps["rccb_check"] = true);

    await Future.delayed(const Duration(milliseconds: 600));
    _safeSetState(() => analysisSteps["complete"] = true);

    await Future.delayed(const Duration(milliseconds: 600));
    
    // Simulate issue detection
    final rand = DateTime.now().millisecond;
    issueFound = rand % 3 == 0 ? "missing" : rand % 2 == 0 ? "wrong_spec" : "none";
    
    _safeSetState(() {
      if (issueFound == "none") _phase = Phase.resultOk;
      else if (issueFound == "missing") _phase = Phase.resultMissing;
      else _phase = Phase.resultWrongSpec;
    });
  }

  bool get _isReadyToCapture => 
    clarity["brightness"] == "good" && 
    clarity["stability"] == "steady" && 
    clarity["focus"] == "sharp";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1a1f35), Colors.black]))),
          
          Positioned(
            top: 50, left: 24,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white10),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
            child: ListView(
              children: [
                if (_phase == Phase.instruction) _buildInstructionView(),
                if (_phase == Phase.photoMode) _buildPhotoModeView(),
                if (_phase == Phase.analyzing) _buildAnalyzingView(),
                if (_phase == Phase.resultMissing || _phase == Phase.resultWrongSpec) _buildIssueResultView(),
                if (_phase == Phase.resultOk) _buildOkResultView(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInstructionView() => FadeInUp(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EVDB Inspection", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Check Electrical Vehicle Distribution Board", style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("We're checking:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildChecklistItem("1", "MCB (Miniature Circuit Breaker)", "Presence and specifications"),
              const SizedBox(height: 12),
              _buildChecklistItem("2", "RCCB (Residual Current Circuit Breaker)", "Presence and specifications"),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startPhotoMode,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take EVDB Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              )
            ],
          ),
        )
      ],
    ),
  );

  Widget _buildChecklistItem(String num, String title, String sub) => Row(
    children: [
      Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Text(num, style: const TextStyle(color: Colors.cyan, fontSize: 12)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]))
    ],
  );

  Widget _buildPhotoModeView() => FadeIn(
    child: Column(
      children: [
        Container(
          height: 350, width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.cyan, width: 2), borderRadius: BorderRadius.circular(24), color: const Color(0xFF0A0E1A).withOpacity(0.5)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.my_location, color: Colors.cyan, size: 64),
              if (clarity["stability"] == "steady")
                FadeIn(child: Container(width: 120, height: 120, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00FF88), width: 2), borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Photo Quality Indicators", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildIndicatorRow("Brightness", clarity["brightness"]!),
              _buildIndicatorRow("Stability", clarity["stability"]!),
              _buildIndicatorRow("Focus", clarity["focus"]!),
              if (_isReadyToCapture)
                FadeInUp(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF00FF88).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.2))),
                    child: const Text("✓ Ready to capture!", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00FF88))),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isReadyToCapture ? _handleCapture : null,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Capture Photo", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black, disabledBackgroundColor: Colors.grey.shade900, disabledForegroundColor: Colors.white54, padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        )
      ],
    ),
  );

  Widget _buildIndicatorRow(String label, String value) {
    bool isGood = value == "good" || value == "steady" || value == "sharp";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(isGood ? Icons.check_circle : Icons.warning_amber_rounded, color: isGood ? const Color(0xFF00FF88) : Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isGood ? Colors.white : Colors.white54)),
          ]),
          Text(value.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() => FadeInUp(
    child: Column(
      children: [
        Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF1E2436), borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("Captured EVDB image", style: TextStyle(color: Colors.white54)))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.cyan, strokeWidth: 2)),
                SizedBox(width: 12),
                Text("Analyzing EVDB...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 24),
              _buildAnalysisStep("EVDB detected", analysisSteps["evdb_detected"]!),
              _buildAnalysisStep("MCB check: ${analysisSteps["mcb_check"]! ? (issueFound != "none" ? "Issue Found" : "OK") : "Scanning..."}", analysisSteps["mcb_check"]!, isError: issueFound != "none" && analysisSteps["mcb_check"]!),
              _buildAnalysisStep("RCCB check: ${analysisSteps["rccb_check"]! ? "OK" : "Scanning..."}", analysisSteps["rccb_check"]!),
              _buildAnalysisStep("Analysis complete", analysisSteps["complete"]!),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildAnalysisStep(String text, bool isComplete, {bool isError = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Icon(isComplete ? (isError ? Icons.cancel : Icons.check_circle) : Icons.circle_outlined, color: isComplete ? (isError ? Colors.redAccent : const Color(0xFF00FF88)) : Colors.white24),
      const SizedBox(width: 12),
      Text(text, style: TextStyle(color: isComplete ? Colors.white : Colors.white54)),
    ]),
  );

  Widget _buildIssueResultView() => FadeInUp(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), border: Border.all(color: Colors.redAccent.withOpacity(0.2)), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.cancel, color: Colors.redAccent)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_phase == Phase.resultMissing ? "Missing Component" : "Wrong Specification", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Protection Issue", style: TextStyle(color: Colors.white54, fontSize: 14)),
          ])
        ]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("View Full Diagnosis", style: TextStyle(fontWeight: FontWeight.bold))))
      ]),
    ),
  );

  Widget _buildOkResultView() => FadeInUp(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF00FF88).withOpacity(0.1), border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.2)), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF00FF88).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle, color: Color(0xFF00FF88))),
          const SizedBox(width: 16),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("EVDB Check Passed", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("All components verified", style: TextStyle(color: Colors.white54, fontSize: 14)),
          ])
        ]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/home'), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Back to Home", style: TextStyle(fontWeight: FontWeight.bold))))
      ]),
    ),
  );
}