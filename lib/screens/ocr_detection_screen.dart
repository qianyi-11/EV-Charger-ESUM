import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/pulsing_glow.dart';
import '../widgets/camera_viewfinder.dart';
import '../services/ml_model_service.dart';
import '../services/integration_controller.dart';
import 'package:camera/camera.dart';

enum OcrState { instruction, capturing, shakeDetected, blurDetected, processing, success }

class OcrDetectionScreen extends StatefulWidget {
  const OcrDetectionScreen({super.key});

  @override
  State<OcrDetectionScreen> createState() => _OcrDetectionScreenState();
}

class _OcrDetectionScreenState extends State<OcrDetectionScreen> with TickerProviderStateMixin {
  OcrState _currentState = OcrState.instruction;
  
  // Capturing telemetry simulation
  double _stability = 85.0;
  Timer? _stabilityTimer;
  Timer? _autoCaptureTimer;
  
  // Animation controllers
  late final AnimationController _rotationController;
  late final AnimationController _checkmarkController;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    _autoCaptureTimer?.cancel();
    _rotationController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  void _startCamera() {
    setState(() {
      _currentState = OcrState.capturing;
      _stability = 85.0;
    });

    // Simulate fluctuating camera stability
    _stabilityTimer?.cancel();
    final rand = math.Random();
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_currentState == OcrState.capturing) {
        setState(() {
          // Fluctuate stability between 75 and 98
          _stability = 75.0 + rand.nextDouble() * 23.0;
        });
        
        // Manual capture mode - stability metrics still tracked in real-time
      }
    });
  }

  void _triggerShake() {
    _stabilityTimer?.cancel();
    setState(() {
      _currentState = OcrState.shakeDetected;
      _stability = 25.0;
    });
  }

  void _triggerBlur() {
    _stabilityTimer?.cancel();
    setState(() {
      _currentState = OcrState.blurDetected;
    });
  }

  Future<void> _triggerProcessing() async {
    _stabilityTimer?.cancel();
    
    final integrationController = IntegrationController();
    
    // Take real picture
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xfile = await _cameraController!.takePicture();
        final file = File(xfile.path);
        
        setState(() {
          _currentState = OcrState.processing;
        });
        _rotationController.repeat();
        
        final result = await integrationController.executeOcrScan(file);
        
        if (mounted) {
          _rotationController.stop();
          if (result.success) { // BYPASSED FOR TESTING
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("OCR extracted: '${result.extractedText}'"),
              duration: const Duration(seconds: 2),
            ));
            setState(() {
              _currentState = OcrState.success;
            });
            _checkmarkController.forward();
            
            final state = DiagnosticState();
            state.updateOcr(result.modelName, result.serialNumber);

            Timer(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, "/charger-detection");
              }
            });
          } else {
            // Failed to read OCR
            setState(() {
              _currentState = OcrState.blurDetected; // or show some error state
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _startCamera();
              }
            });
          }
        }
      } catch (e, stack) {
        print("====== OCR ERROR: $e");
        print(stack);
        if (mounted) {
          _rotationController.stop();
          setState(() {
            _currentState = OcrState.blurDetected;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _startCamera();
            }
          });
        }
      }
    } else {
      // Fallback for emulator without camera
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _rotationController.stop();
          setState(() {
            _currentState = OcrState.success;
          });
          _checkmarkController.forward();
          
          final state = DiagnosticState();
          state.updateOcr("Tesla Wall Connector Gen 3", "TWC-2024-A8F3E2");

          Timer(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, "/charger-detection");
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Charger OCR Diagnosis"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // Dynamic Simulator Control Bar
              if (_currentState == OcrState.capturing)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text(
                        "Simulator Tools:",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      _buildMiniButton("Simulate Shake", AppColors.warningOrange, _triggerShake),
                      _buildMiniButton("Simulate Blur", AppColors.dangerRed, _triggerBlur),
                    ],
                  ),
                ),

              // Main interactive viewfinder / container
              Expanded(
                flex: 4,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: _buildStateViewfinder(),
                ),
              ),
              const SizedBox(height: 24),

              // Description and status card
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: _buildBottomPanel(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStateViewfinder() {
    switch (_currentState) {
      case OcrState.instruction:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingGlow(
              glowColor: AppColors.electricBlue,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.electricBlue, Color(0xFF005F80)],
                  ),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Capture Spec Plate",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              "Position the camera directly in front of the technical specification label to extract model and warranty tags.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        );

      case OcrState.capturing:
        final bool isStable = _stability >= 80;
        final Color stabilityColor = isStable ? AppColors.successGreen : AppColors.warningOrange;
        
        return CameraViewfinder(
          aspectRatio: 4 / 3,
          onControllerCreated: (controller) {
            _cameraController = controller;
          },
          fallbackBuilder: (context) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: CustomPaint(
                      painter: _SpecLabelMockPainter(),
                    ),
                  ),
                ),
              ],
            );
          },
          overlay: Stack(
            clipBehavior: Clip.none,
            children: [
              // Animated grid scan line
              const _ScanLineAnimation(),

              // Corner guides
              const Positioned.fill(child: _ViewfinderGuides()),

              // Stability overlay telemetries
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isStable ? "STABLE" : "UNSTABLE",
                        style: TextStyle(
                          color: stabilityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _stability / 100,
                            backgroundColor: Colors.white12,
                            color: stabilityColor,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${_stability.toInt()}%",
                        style: TextStyle(color: stabilityColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case OcrState.shakeDetected:
      case OcrState.blurDetected:
        final isShake = _currentState == OcrState.shakeDetected;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warningOrange.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningOrange,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isShake ? "Camera Movement Detected" : "Image Too Blurry",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              isShake 
                ? "We detected significant phone shake. Please keep your hands steady."
                : "The captured image fails clarity tests. Clean your lens and improve lighting.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        );

      case OcrState.processing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.electricBlue.withOpacity(0.2), width: 3),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Processing OCR...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              "Extracting charger model details and serial telemetry metrics...",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case OcrState.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _checkmarkController,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successGreen,
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Data Extracted Successfully!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Charger Model:", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text("Tesla Wall Connector Gen 3", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Serial Number:", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text("TWC-2024-A8F3E2", style: TextStyle(fontFamily: "monospace", fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBottomPanel() {
    switch (_currentState) {
      case OcrState.instruction:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tips Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("OCR Scanning Tips:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildTipItem("Hold phone extremely steady"),
                  const SizedBox(height: 8),
                  _buildTipItem("Ensure high contrast and lighting"),
                  const SizedBox(height: 8),
                  _buildTipItem("Keep barcode or spec values in focus"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Start Camera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ),
          ],
        );

      case OcrState.capturing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              "Aim at the spec plate label and tap capture to extract serials.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _triggerProcessing,
              icon: const Icon(Icons.camera_alt, color: Colors.black),
              label: const Text(
                "Capture Photo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: AppColors.electricBlue.withValues(alpha: 0.4),
              ),
            ),
          ],
        );

      case OcrState.shakeDetected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningOrange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quick Stabilization Tips:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildTipItem("Rest hands or elbows on a stable platform"),
                  const SizedBox(height: 8),
                  _buildTipItem("Hold device firmly with both hands"),
                  const SizedBox(height: 8),
                  _buildTipItem("Slowly approach the plate target label"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ),
          ],
        );

      case OcrState.blurDetected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningOrange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Lighting & Lens Adjustments:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildTipItem("Wipe your smartphone camera lens"),
                  const SizedBox(height: 8),
                  _buildTipItem("Tap on-screen spec boxes to force autofocus"),
                  const SizedBox(height: 8),
                  _buildTipItem("Avoid reflective light glare blocks"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Retake Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ),
          ],
        );

      case OcrState.processing:
        return const Center(
          child: Text(
            "Verifying data against internal server databases...",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );

      case OcrState.success:
        return const Center(
          child: Text(
            "Loading diagnostic model parameters. Please wait...",
            style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderGuides extends StatelessWidget {
  const _ViewfinderGuides();

  @override
  Widget build(BuildContext context) {
    const double length = 24.0;
    const double thickness = 3.0;
    const Color color = AppColors.electricBlue;

    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: length,
            height: thickness,
            color: color,
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: thickness,
            height: length,
            color: color,
          ),
        ),

        // Top Right
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: length,
            height: thickness,
            color: color,
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: thickness,
            height: length,
            color: color,
          ),
        ),

        // Bottom Left
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            width: length,
            height: thickness,
            color: color,
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            width: thickness,
            height: length,
            color: color,
          ),
        ),

        // Bottom Right
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: length,
            height: thickness,
            color: color,
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: thickness,
            height: length,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation();

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          top: 20 + (_ctrl.value * (180)),
          left: 24,
          right: 24,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpecLabelMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Draw tech background grid lines
    const int lines = 8;
    for (int i = 1; i < lines; i++) {
      final double x = size.width * (i / lines);
      final double y = size.height * (i / lines);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Mock technical label schematic text blocks
    final paintText = Paint()..color = Colors.white.withOpacity(0.12);
    
    // Draw rectangles to simulate label fields
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.7, 16), paintText);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.28, size.width * 0.4, 10), paintText);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.38, size.width * 0.5, 10), paintText);
    
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.52, size.width * 0.3, 10), paintText);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.5, size.height * 0.52, size.width * 0.35, 10), paintText);

    // Mock barcode lines
    final double barcodeY = size.height * 0.68;
    final double barcodeHeight = size.height * 0.16;
    for (double x = size.width * 0.2; x < size.width * 0.8; x += 6) {
      final double width = (x.toInt() % 4 == 0) ? 3.0 : 1.0;
      canvas.drawRect(Rect.fromLTWH(x, barcodeY, width, barcodeHeight), paintText);
    }
  }

  @override
  bool shouldRepaint(covariant _SpecLabelMockPainter oldDelegate) => false;
}
