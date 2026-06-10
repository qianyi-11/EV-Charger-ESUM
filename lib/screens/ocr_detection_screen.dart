import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/pulsing_glow.dart';
import '../widgets/camera_viewfinder.dart';
import '../services/integration_controller.dart';
import '../services/sharp_capture.dart';
import 'package:camera/camera.dart';

enum OcrState { instruction, capturing, retakeRequired, processing, success }

class OcrDetectionScreen extends StatefulWidget {
  const OcrDetectionScreen({super.key});

  @override
  State<OcrDetectionScreen> createState() => _OcrDetectionScreenState();
}

class _OcrDetectionScreenState extends State<OcrDetectionScreen> with TickerProviderStateMixin {
  AdaptiveTheme get _t => context.adaptive;

  OcrState _currentState = OcrState.instruction;
  
  // Capturing telemetry simulation
  double _stability = 85.0;
  Timer? _stabilityTimer;
  Timer? _autoCaptureTimer;
  
  // Animation controllers
  late final AnimationController _rotationController;
  late final AnimationController _checkmarkController;
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _captureInFlight = false;
  
  // Store extracted OCR data
  String _extractedModel = 'Unknown';
  String _extractedSerialNumber = 'Unknown';
  // Add these state variables:
  String _extractedBrand = 'Unknown';
  String _extractedInputVoltage = 'Unknown';
  String _extractedOutputCurrent = 'Unknown';
  String _retakeMessage = '';

  bool _isValidInputVoltage(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final lower = value.trim().toLowerCase();
    if (lower == 'unknown' || lower == 'n/a') return false;
    return RegExp(r'\d+\s*v', caseSensitive: false).hasMatch(value);
  }

  void _showRetakeRequired(String message) {
    _rotationController.stop();
    setState(() {
      _captureInFlight = false;
      _currentState = OcrState.retakeRequired;
      _retakeMessage = message;
    });
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _t.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _t.textPrimary)),
      ],
    );
  }

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
    _stabilityTimer?.cancel();
    setState(() {
      _currentState = OcrState.capturing;
      _stability = 85.0;
      _cameraReady = false;
      _captureInFlight = false;
      _retakeMessage = '';
    });

    final rand = math.Random();
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_currentState == OcrState.capturing) {
        setState(() {
          _stability = 75.0 + rand.nextDouble() * 23.0;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _triggerProcessing() async {
    if (_captureInFlight) return;
    if (!_cameraReady ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is still starting — please wait a moment.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _stabilityTimer?.cancel();
    setState(() {
      _captureInFlight = true;
      _currentState = OcrState.processing;
    });
    _rotationController.repeat();

    final integrationController = IntegrationController();

    try {
      final xfile = await SharpCapture.takePicture(_cameraController!);
      final file = File(xfile.path);
      final result = await integrationController.executeOcrScan(file);

      if (!mounted) return;
      _rotationController.stop();

      if (result.success) {
        if (!_isValidInputVoltage(result.inputVoltage)) {
          _showRetakeRequired(
            'Could not read input voltage from the spec plate. '
            'Retake a clearer photo showing the voltage rating (e.g. 230V AC).',
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Charger label read successfully.'),
          duration: Duration(seconds: 2),
        ));
        setState(() {
          _currentState = OcrState.success;
          _extractedBrand = result.brand ?? 'Unknown';
          _extractedModel = result.modelName.isNotEmpty ? result.modelName : 'Unknown';
          _extractedSerialNumber =
              result.serialNumber.isNotEmpty ? result.serialNumber : 'Unknown';
          _extractedInputVoltage = result.inputVoltage ?? 'Unknown';
          _extractedOutputCurrent = result.outputCurrent ?? 'Unknown';
        });
        _checkmarkController.forward();

        final state = DiagnosticState();
        state.updateOcr(
          result.modelName,
          result.serialNumber,
          brandVal: result.brand,
          voltage: result.inputVoltage,
          current: result.outputCurrent,
        );
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/charger-detection");
          }
        });
      } else {
        final String errorMsg;
        if (result.quotaExceeded) {
          errorMsg = result.reason ??
              "The scan service is busy. Wait about a minute, then try again.";
        } else if (result.reason != null && result.reason!.isNotEmpty) {
          errorMsg = result.reason!;
        } else if (result.extractedText.startsWith('Scan failed:') ||
            result.extractedText.startsWith('OCR failed:') ||
            result.extractedText.startsWith('Server error:')) {
          errorMsg = result.extractedText.contains('Connection') ||
                  result.extractedText.contains('SocketException')
              ? "Cannot reach the server. Check Wi‑Fi and that the backend is running on your PC."
              : result.extractedText;
        } else if (result.isBlurry) {
          errorMsg =
              "Image is too blurry. Please ensure the plate is clearly in focus.";
        } else if (result.partialExtraction) {
          errorMsg =
              "Could not read the model or serial number. Move closer and improve lighting.";
        } else {
          errorMsg = "Could not read the plate. Please try again.";
        }

        _showRetakeRequired(errorMsg);
      }
    } catch (e, stack) {
      print("====== OCR ERROR: $e");
      print(stack);
      if (mounted) {
        _showRetakeRequired("Error: $e. Please try again.");
      }
    } finally {
      if (mounted && _currentState != OcrState.retakeRequired) {
        setState(() => _captureInFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.adaptive;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Step 1: Scan Charger Label", style: TextStyle(color: t.textPrimary)),
        iconTheme: IconThemeData(color: t.textPrimary),
      ),
      body: SafeArea(
        child: _currentState == OcrState.instruction
            ? Align(
                alignment: const Alignment(0, -0.18),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: _buildStateViewfinder(),
                      ),
                      const SizedBox(height: 16),
                      _buildBottomPanel(),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 4,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: _buildStateViewfinder(),
                      ),
                    ),
                    const SizedBox(height: 24),
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

  Widget _buildStateViewfinder() {
    switch (_currentState) {
      case OcrState.instruction:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingGlow(
              glowColor: AppColors.electricBlue,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.electricBlue, Color(0xFF005F80)],
                  ),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Capture your charger label",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _t.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "Find the sticker on your charger.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _t.textSecondary, fontSize: 13, height: 1.35),
            ),
          ],
        );

      case OcrState.capturing:
        final bool isStable = _stability >= 80;
        final Color stabilityColor = isStable ? AppColors.successGreen : AppColors.warningOrange;
        
        return CameraViewfinder(
          aspectRatio: 4 / 3,
          highQualityCapture: true,
          onControllerCreated: (controller) {
            _cameraController = controller;
          },
          onReady: () {
            if (mounted) setState(() => _cameraReady = true);
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

      case OcrState.retakeRequired:
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
                Icons.refresh,
                color: AppColors.warningOrange,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Retake Required",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _t.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              _retakeMessage.isNotEmpty
                  ? _retakeMessage
                  : 'Please retake a clearer photo of the spec plate.',
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
            Text(
              "Reading your charger label...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _t.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please hold still while we read the model, serial number, and voltage from your photo.",
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
          width: 56, height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successGreen,
          ),
          child: const Icon(Icons.check, color: Colors.black, size: 32),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        "Label captured successfully",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _t.textPrimary),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _t.emptyFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _t.glassBorder),
        ),
        child: Column(
          children: [
            _buildResultRow("Charger Brand", _extractedBrand),
            const SizedBox(height: 8),
            _buildResultRow("Model",          _extractedModel),
            const SizedBox(height: 8),
            _buildResultRow("Serial Number",  _extractedSerialNumber),
            const SizedBox(height: 8),
            _buildResultRow("Input Voltage",  _extractedInputVoltage),
            const SizedBox(height: 8),
            _buildResultRow("Output Current", _extractedOutputCurrent),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _t.emptyFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _t.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tips",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _t.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem("Hold steady, avoid glare"),
                  const SizedBox(height: 6),
                  _buildTipItem("Keep the whole label in frame"),
                  const SizedBox(height: 6),
                  _buildTipItem("Use good lighting"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Open Camera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ),
          ],
        );

      case OcrState.capturing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              "Line up the charger label inside the frame, then tap Capture Photo.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: (_captureInFlight || !_cameraReady) ? null : _triggerProcessing,
              icon: _captureInFlight
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.black),
              label: Text(
                _captureInFlight
                    ? "Capturing..."
                    : _cameraReady
                        ? "Capture Photo"
                        : "Starting camera...",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
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

      case OcrState.retakeRequired:
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
                  Text("Before you retake:", style: TextStyle(fontWeight: FontWeight.bold, color: _t.textPrimary)),
                  const SizedBox(height: 12),
                  _buildTipItem("Hold the phone steady and ensure good lighting"),
                  const SizedBox(height: 8),
                  _buildTipItem("Make sure the voltage rating (e.g. 230V) is visible"),
                  const SizedBox(height: 8),
                  _buildTipItem("Wipe the camera lens and tap to focus on the label"),
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
            "This usually takes a few seconds...",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );

      case OcrState.success:
        return const Center(
          child: Text(
            "Great — moving to the next step...",
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
            style: TextStyle(fontSize: 13, color: _t.textSecondary),
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
