import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum CheckPhase { instruction, capturing, analyzing, resultOff, resultOn }

class IsolatorCheckScreen extends StatefulWidget {
  const IsolatorCheckScreen({super.key});

  @override
  State<IsolatorCheckScreen> createState() => _IsolatorCheckScreenState();
}

class _IsolatorCheckScreenState extends State<IsolatorCheckScreen> {
  CheckPhase _phase = CheckPhase.instruction;
  bool _showInfo = false;
  
  // Progress tracker for analysis steps
  Map<String, bool> steps = {
    "detecting": false,
    "position": false,
    "complete": false,
  };

  void _handleCapture() async {
    setState(() => _phase = CheckPhase.capturing);
    
    // Simulate camera capture delay
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    setState(() => _phase = CheckPhase.analyzing);
    _runAnalysis();
  }

  void _runAnalysis() async {
    // 1. Detecting
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => steps["detecting"] = true);
    
    // 2. Position
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => steps["position"] = true);
    
    // 3. Complete
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => steps["complete"] = true);

    // Simulate isolator detection - randomly OFF or ON
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    
    final bool isOff = (DateTime.now().millisecond % 2 == 0); // Random boolean
    setState(() {
      _phase = isOff ? CheckPhase.resultOff : CheckPhase.resultOn;
    });
  }

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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          FadeInDown(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Power Issue Detected", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Let's check the isolator switch", style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          if (_phase == CheckPhase.instruction) _buildInstructionView(),
          if (_phase == CheckPhase.capturing) _buildCapturingView(),
          if (_phase == CheckPhase.analyzing) _buildAnalyzingView(),
          if (_phase == CheckPhase.resultOff) _buildResultView(isOff: true),
          if (_phase == CheckPhase.resultOn) _buildResultView(isOff: false),
        ],
      ),
    );
  }

  Widget _buildInstructionView() => FadeInUp(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Step 1: Locate Isolator", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setState(() => _showInfo = !_showInfo),
                icon: const Icon(Icons.info_outline, color: Colors.cyan),
                style: IconButton.styleFrom(backgroundColor: Colors.cyan.withOpacity(0.1)),
              ),
            ],
          ),
          
          // Expandable Info Box
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showInfo ? Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.05), border: Border.all(color: Colors.cyan.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Example of an isolator switch:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFF1E2436), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text("Isolator reference image", style: TextStyle(color: Colors.white54))),
                  )
                ],
              ),
            ) : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),
          const Text(
            "Point your camera at the isolator switch. The app will automatically detect and capture it.",
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleCapture,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Start Isolator Detection", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    ),
  );

  Widget _buildCapturingView() => FadeIn(
    child: Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A).withOpacity(0.5),
        border: Border.all(color: Colors.cyan, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Pulse(
          infinite: true,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, color: Colors.cyan, size: 64),
              SizedBox(height: 16),
              Text("Detecting isolator...", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildAnalyzingView() => FadeInUp(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.cyan, strokeWidth: 2)),
              SizedBox(width: 12),
              Text("Analyzing Isolator...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _buildAnalysisStep("Isolator detected", steps["detecting"]!),
          _buildAnalysisStep("Switch position: ${steps["position"]! ? (DateTime.now().millisecond % 2 == 0 ? "OFF" : "ON") : "Analyzing..."}", steps["position"]!),
          _buildAnalysisStep("Analysis complete", steps["complete"]!),
        ],
      ),
    ),
  );

  Widget _buildAnalysisStep(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(isComplete ? Icons.check_circle : Icons.circle_outlined, color: isComplete ? const Color(0xFF00FF88) : Colors.white24),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isComplete ? Colors.white : Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildResultView({required bool isOff}) {
    final color = isOff ? const Color(0xFFFF2D55) : const Color(0xFF00FF88);
    final title = isOff ? "Isolator is OFF" : "Isolator is ON";
    final sub = isOff ? "Power supply disconnected" : "Power confirmed at isolator";

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.2)), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(isOff ? Icons.warning_amber_rounded : Icons.check_circle, color: color),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            
            if (isOff) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1F35).withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Recommended Action:", style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 8),
                    Text("• Turn the isolator switch to ON position\n• Check if the breaker in EVDB has tripped", style: TextStyle(color: Colors.white54, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { /* Navigator.pushNamed(context, '/diagnosis/power-cut'); */ },
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("View Full Diagnosis", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ] else ...[
              const Text("Power is connected at the isolator. Let's check the EVDB (Electrical Vehicle Distribution Board).", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { /* Navigator.pushNamed(context, '/evdb-check'); */ },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Check EVDB", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}