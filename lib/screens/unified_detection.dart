import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum Phase {
  ocrInstructions,
  ocrCapturing,
  ocrProcessing,
  ocrComplete,
  lightScanning,
  decisionMade,
}

class UnifiedDetectionScreen extends StatefulWidget {
  const UnifiedDetectionScreen({super.key});

  @override
  State<UnifiedDetectionScreen> createState() => _UnifiedDetectionScreenState();
}

class _UnifiedDetectionScreenState extends State<UnifiedDetectionScreen> {
  Phase _phase = Phase.ocrInstructions;

  Map<String, String> _extractedData = {"model": "", "serial": ""};
  double _scanTime = 0;
  bool _redLightDetected = false;
  int? _branchDecided; // 1 or 2
  double _shakeLevel = 0;

  Timer? _shakeTimer;
  Timer? _scanTimer;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _shakeTimer?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) setState(fn);
  }

  // --- PHASE 1: OCR Capture ---
  void _handleStartOCR() {
    _safeSetState(() => _phase = Phase.ocrCapturing);

    // Simulate real-time camera shaking guidance
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _safeSetState(() {
        _shakeLevel = Random().nextDouble() * 100;
      });
    });

    // Auto-capture after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_phase == Phase.ocrCapturing && mounted) {
        _shakeTimer?.cancel();
        _startOcrProcessing();
      }
    });
  }

  // --- PHASE 2: OCR Processing & Completion ---
  void _startOcrProcessing() async {
    _safeSetState(() => _phase = Phase.ocrProcessing);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    _safeSetState(() {
      _extractedData = {
        "model": "Tesla Wall Connector Gen 3",
        "serial": "TWC-2024-A8F3E2",
      };
      _phase = Phase.ocrComplete;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    _startLightScanning();
  }

  // --- PHASE 3: Light Scanning & Branch Decision ---
  void _startLightScanning() {
    _safeSetState(() {
      _phase = Phase.lightScanning;
      _scanTime = 0;
      _redLightDetected = false;
    });

    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _safeSetState(() {
        _scanTime += 0.1;

        // Simulate red light detection (70% chance between 2s and 3s)
        if (!_redLightDetected &&
            _scanTime >= 2.0 &&
            _scanTime < 3.0 &&
            Random().nextDouble() > 0.3) {
          _redLightDetected = true;
          _branchDecided = 2;
          _phase = Phase.decisionMade;
          timer.cancel();

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted)
              Navigator.pushReplacementNamed(context, '/video-recording');
          });
        }

        // If 5 seconds pass and no light is found -> Branch 1
        if (_scanTime >= 5.0 && !_redLightDetected) {
          _branchDecided = 1;
          _phase = Phase.decisionMade;
          timer.cancel();

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted)
              Navigator.pushReplacementNamed(context, '/photo-isolator');
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1f35), Color(0xFF0f1423), Colors.black],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white10,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildCurrentPhaseContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPhaseContent() {
    switch (_phase) {
      case Phase.ocrInstructions:
        return _buildOcrInstructions();
      case Phase.ocrCapturing:
        return _buildOcrCapturing();
      case Phase.ocrProcessing:
        return _buildOcrProcessing();
      case Phase.ocrComplete:
        return _buildOcrComplete();
      case Phase.lightScanning:
        return _buildLightScanning();
      case Phase.decisionMade:
        return _buildDecisionMade();
    }
  }

  // --- UI RENDERERS FOR EACH PHASE ---

  Widget _buildOcrInstructions() => FadeInUp(
    key: const ValueKey("inst"),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pulse(
          infinite: true,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0066FF)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Capture Spec Plate",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Take a clear photo of the charger's technical specification label",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8B92A8)),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "For best results:",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              _buildBullet("Hold your phone steady with both hands"),
              _buildBullet("Ensure good lighting on the label"),
              _buildBullet("Keep the label in focus and centered"),
              _buildBullet("Avoid shadows and glare"),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleStartOCR,
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              "Start Camera",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildBullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "• ",
          style: TextStyle(color: Color(0xFF00D4FF), fontSize: 16),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF8B92A8), fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _buildOcrCapturing() {
    Color borderColor = _shakeLevel > 60
        ? Colors.orange
        : _shakeLevel > 30
        ? const Color(0xFF00D4FF)
        : const Color(0xFF00FF88);
    return ZoomIn(
      key: const ValueKey("cap"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF0A0E1A).withOpacity(0.5),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      "Camera preview",
                      style: TextStyle(color: Color(0xFF8B92A8)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildShakeWarningCard(borderColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Camera Stability",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      _shakeLevel > 60
                          ? "Shaky"
                          : _shakeLevel > 30
                          ? "Okay"
                          : "Excellent",
                      style: TextStyle(color: borderColor, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (100 - _shakeLevel) / 100,
                  backgroundColor: const Color(0xFF1E2436),
                  color: borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  _shakeLevel > 60
                      ? "Try holding with both hands for better stability"
                      : _shakeLevel > 30
                      ? "Almost there - keep steady..."
                      : "Perfect! Auto-capturing in 3s...",
                  style: const TextStyle(
                    color: Color(0xFF8B92A8),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeWarningCard(Color color) {
    String text = _shakeLevel > 60
        ? "Hold phone steadier"
        : _shakeLevel > 30
        ? "Position label in center"
        : "Good - capturing...";
    IconData icon = _shakeLevel > 60
        ? Icons.warning_amber_rounded
        : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_shakeLevel > 60 || _shakeLevel <= 30)
            Icon(icon, color: color, size: 16),
          if (_shakeLevel > 60 || _shakeLevel <= 30) const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOcrProcessing() => FadeIn(
    key: const ValueKey("proc"),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinPerfect(
          infinite: true,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00D4FF), width: 4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Processing OCR...",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 8),
        const Text(
          "Extracting model & serial number",
          style: TextStyle(color: Color(0xFF8B92A8)),
        ),
      ],
    ),
  );

  Widget _buildOcrComplete() => ZoomIn(
    key: const ValueKey("comp"),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF00FF88),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          "Data Extracted!",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Model",
                style: TextStyle(color: Color(0xFF8B92A8), fontSize: 12),
              ),
              Text(
                _extractedData["model"]!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                "Serial",
                style: TextStyle(color: Color(0xFF8B92A8), fontSize: 12),
              ),
              Text(
                _extractedData["serial"]!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00D4FF), size: 16),
            SizedBox(width: 8),
            Text(
              "Starting charger scan...",
              style: TextStyle(color: Color(0xFF00D4FF)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildLightScanning() => FadeIn(
    key: const ValueKey("scan"),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Scanning Charger",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        const Text(
          "Detecting red light indicator...",
          style: TextStyle(color: Color(0xFF8B92A8)),
        ),
        const SizedBox(height: 32),
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00D4FF), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SpinPerfect(
                infinite: true,
                duration: const Duration(seconds: 3),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00D4FF).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (_redLightDetected)
                ZoomIn(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2D55).withOpacity(0.6),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Scanning for red light",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    "${_scanTime.toStringAsFixed(1)}s / 5.0s",
                    style: const TextStyle(color: Color(0xFF00D4FF)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _scanTime / 5.0,
                backgroundColor: const Color(0xFF1E2436),
                color: const Color(0xFF00D4FF),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _redLightDetected ? Icons.bolt : Icons.autorenew,
                    color: _redLightDetected
                        ? const Color(0xFFFF2D55)
                        : const Color(0xFF00D4FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _redLightDetected
                        ? "Red light detected!"
                        : "Analyzing charger surface...",
                    style: TextStyle(
                      color: _redLightDetected
                          ? Colors.white
                          : const Color(0xFF8B92A8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildDecisionMade() {
    bool isRedLight = _branchDecided == 2;
    Color color = isRedLight ? const Color(0xFFFF2D55) : Colors.orange;

    return ZoomIn(
      key: const ValueKey("decide"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 30),
              ],
            ),
            child: Icon(
              isRedLight ? Icons.bolt : Icons.camera_alt,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isRedLight ? "Red Light Detected" : "No Light Detected",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRedLight
                ? "Preparing video recording mode..."
                : "Checking power supply...",
            style: const TextStyle(color: Color(0xFF8B92A8)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isRedLight
                  ? "Branch 2: Video Recording (15s)"
                  : "Branch 1: Photo Mode",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
