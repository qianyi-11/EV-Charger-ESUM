import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class SpecPlateCaptureScreen extends StatefulWidget {
  const SpecPlateCaptureScreen({super.key});

  @override
  State<SpecPlateCaptureScreen> createState() => _SpecPlateCaptureScreenState();
}

class _SpecPlateCaptureScreenState extends State<SpecPlateCaptureScreen> {
  bool _isProcessing = false;
  bool _ocrComplete = false;
  
  String _model = "";
  String _serialNumber = "";

  void _handleCapture() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate OCR processing latency
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _ocrComplete = true;
      _model = "Tesla Wall Connector Gen 3";
      _serialNumber = "TWC-2024-A8F3E2";
    });

    // Auto-proceed to charger detection screen after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // Navigator.pushNamed(context, '/charger-detection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient Animation Canvas
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1F35), Color(0xFF0F1423), Colors.black],
              ),
            ),
          ),

          // Close / Exit Button
          Positioned(
            top: 50,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Core Interactive Content Layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Indicator Header Text
                FadeInDown(
                  child: Column(
                    children: [
                      _buildAnimatedHeaderIcon(),
                      const SizedBox(height: 16),
                      const Text(
                        "Step 1: Spec Plate",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Please take a clear photo of the charger's technical specification label",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: const Color(0xFF8B92A8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Viewfinder Outer Box Frame
                ZoomIn(
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.4), width: 2),
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFF0A0E1A).withOpacity(0.5),
                      ),
                      child: Stack(
                        children: [
                          // Interior Scanning Window Viewport
                          Center(child: _buildViewportStateContent()),

                          // Aesthetic Camera Corner Framing Markers
                          _buildCornerBracket(top: 12, left: 12, isTop: true, isLeft: true),
                          _buildCornerBracket(top: 12, right: 12, isTop: true, isLeft: false),
                          _buildCornerBracket(bottom: 12, left: 12, isTop: false, isLeft: true),
                          _buildCornerBracket(bottom: 12, right: 12, isTop: false, isLeft: false),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer Actions / Processing Text Fields
                _buildBottomControlWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeaderIcon() {
    return Pulse(
      infinite: true,
      duration: const Duration(seconds: 2),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF0066FF)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildViewportStateContent() {
    if (!_isProcessing && !_ocrComplete) {
      return FadeIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_back_outlined, color: const Color(0xFF00D4FF).withOpacity(0.5), size: 48),
            const SizedBox(height: 12),
            const Text("Camera preview placeholder", style: TextStyle(color: Color(0xFF8B92A8), fontSize: 14)),
          ],
        ),
      );
    }

    if (_isProcessing) {
      return FadeIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinPerfect(
              infinite: true,
              duration: const Duration(seconds: 2),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 4),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Processing OCR...", style: TextStyle(color: Colors.white, fontSize: 16)),
            const Text("Extracting model & serial number", style: TextStyle(color: Color(0xFF8B92A8), fontSize: 12)),
          ],
        ),
      );
    }

    // Success Extraction Completed Card Window Layout
    return ZoomIn(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            const Text("Data Extracted!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MODEL", style: TextStyle(color: Color(0xFF8B92A8), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(_model, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 10),
                  const Text("SERIAL NUMBER", style: TextStyle(color: Color(0xFF8B92A8), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(_serialNumber, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlWidget() {
    if (!_isProcessing && !_ocrComplete) {
      return FadeInUp(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleCapture,
            icon: const Icon(Icons.camera),
            label: const Text("Capture Spec Plate", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: const Color(0xFF00D4FF).withOpacity(0.4),
            ),
          ),
        ),
      );
    }

    if (_ocrComplete) {
      return FadeIn(
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00D4FF), size: 16),
            SizedBox(width: 8),
            Text("Proceeding to charger detection...", style: TextStyle(color: Color(0xFF00D4FF), fontSize: 14)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCornerBracket({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF00D4FF), width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF00D4FF), width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF00D4FF), width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF00D4FF), width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}