import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum Phase { instruction, photoMode, analyzing, resultOff, resultOn }

class PhotoIsolatorScreen extends StatefulWidget {
  const PhotoIsolatorScreen({super.key});

  @override
  State<PhotoIsolatorScreen> createState() => _PhotoIsolatorScreenState();
}

class _PhotoIsolatorScreenState extends State<PhotoIsolatorScreen> {
  Phase _phase = Phase.instruction;
  bool _showInfo = false;

  Map<String, String> clarity = {
    "brightness": "dark",
    "stability": "shaking",
    "focus": "blurry",
  };

  Map<String, bool> analysisSteps = {
    "detecting": false,
    "position": false,
    "complete": false,
  };

  String isolatorStatus = "off";
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

    await Future.delayed(const Duration(milliseconds: 800));
    _safeSetState(() => analysisSteps["detecting"] = true);

    await Future.delayed(const Duration(milliseconds: 800));
    _safeSetState(() => analysisSteps["position"] = true);

    await Future.delayed(const Duration(milliseconds: 800));
    _safeSetState(() => analysisSteps["complete"] = true);

    await Future.delayed(const Duration(milliseconds: 600));
    
    // Simulate isolator detection
    final rand = DateTime.now().millisecond;
    isolatorStatus = rand % 2 == 0 ? "off" : "on";
    
    _safeSetState(() {
      _phase = isolatorStatus == "off" ? Phase.resultOff : Phase.resultOn;
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
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, 
                end: Alignment.bottomCenter, 
                colors: [Color(0xFF1a1f35), Colors.black]
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50, left: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white10),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
            child: ListView(
              children: [
                if (_phase == Phase.instruction) _buildInstructionView(),
                if (_phase == Phase.photoMode) _buildPhotoModeView(),
                if (_phase == Phase.analyzing) _buildAnalyzingView(),
                if (_phase == Phase.resultOff) _buildResultView(isOff: true),
                if (_phase == Phase.resultOn) _buildResultView(isOff: false),
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
        const Text("Power Issue Detected", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Let's check the isolator switch", style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        
        Container(
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
              
              // Animated Info Box
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
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(color: const Color(0xFF1E2436), borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text("Reference image", style: TextStyle(color: Colors.white54))),
                      )
                    ],
                  ),
                ) : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),
              const Text("Take a clear photo of the isolator switch. Follow the on-screen guides for best quality.", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startPhotoMode,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Isolator Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              )
            ],
          ),
        )
      ],
    ),
  );

  Widget _buildPhotoModeView() => FadeIn(
    child: Column(
      children: [
        // Viewfinder
        Container(
          height: 350, width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.cyan, width: 2), borderRadius: BorderRadius.circular(24), color: const Color(0xFF0A0E1A).withOpacity(0.5)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.camera_alt, color: Colors.cyan, size: 64),
              const Icon(Icons.my_location, color: Colors.cyan, size: 100), // Crosshair
              if (clarity["stability"] == "steady")
                FadeIn(child: Container(width: 120, height: 120, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00FF88), width: 2), borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Quality Indicators
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
        
        // Capture Button
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
        Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF1E2436), borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("Captured isolator image", style: TextStyle(color: Colors.white54)))),
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
                Text("Analyzing Isolator...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 24),
              _buildAnalysisStep("Isolator detected", analysisSteps["detecting"]!),
              _buildAnalysisStep("Switch position: ${analysisSteps["position"]! ? isolatorStatus.toUpperCase() : "Analyzing..."}", analysisSteps["position"]!),
              _buildAnalysisStep("Analysis complete", analysisSteps["complete"]!),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildAnalysisStep(String text, bool isComplete) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Icon(isComplete ? Icons.check_circle : Icons.circle_outlined, color: isComplete ? const Color(0xFF00FF88) : Colors.white24),
      const SizedBox(width: 12),
      Text(text, style: TextStyle(color: isComplete ? Colors.white : Colors.white54)),
    ]),
  );

  Widget _buildResultView({required bool isOff}) {
    final color = isOff ? const Color(0xFFFF2D55) : const Color(0xFF00FF88);
    final title = isOff ? "Isolator is OFF" : "Isolator is ON";
    final sub = isOff ? "Power supply disconnected" : "Power confirmed";

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.2)), borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(isOff ? Icons.warning_amber_rounded : Icons.check_circle, color: color)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ])
          ]),
          const SizedBox(height: 24),
          
          if (isOff)
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { /* Navigator.pushNamed(context, '/diagnosis/power-cut'); */ }, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("View Full Diagnosis", style: TextStyle(fontWeight: FontWeight.bold))))
          else ...[
            const Text("Power is connected at the isolator. Let's check the EVDB next.", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { /* Navigator.pushNamed(context, '/photo-evdb'); */ }, icon: const Icon(Icons.camera_alt), label: const Text("Check EVDB", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16))))
          ]
        ]),
      ),
    );
  }
}