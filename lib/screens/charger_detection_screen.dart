import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/pulsing_glow.dart';
import '../widgets/camera_viewfinder.dart';
import '../services/ml_model_service.dart';
import '../services/camera_session_manager.dart';
import 'package:camera/camera.dart';

enum DetectionPhase { scanning, chargerFound, searchingLight, branch1NoLight, branch2RedLight }

class ChargerDetectionScreen extends StatefulWidget {
  const ChargerDetectionScreen({super.key});

  @override
  State<ChargerDetectionScreen> createState() => _ChargerDetectionScreenState();
}

class _ChargerDetectionScreenState extends State<ChargerDetectionScreen> with TickerProviderStateMixin {
  DetectionPhase _phase = DetectionPhase.scanning;
  final DiagnosticState _state = DiagnosticState();
  
  // Timer & Progress states
  double _searchTimer = 0.0;
  double _progressPercent = 0.0;
  Timer? _tickTimer;
  int _elapsedMs = 0;
  bool _lightSampleInFlight = false;
  List<double>? _chargerBox;

  // Animation Controllers
  late final AnimationController _scannerPulseController;
  late final AnimationController _gearRotationController;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _scannerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _gearRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _scannerPulseController.dispose();
    _gearRotationController.dispose();
    _cameraController = null;
    super.dispose();
  }

  void _runDetectionSequence() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _phase = DetectionPhase.scanning;
    });

    try {
      final xfile = await _cameraController!.takePicture();
      final mlService = MlModelService();
      final result = await mlService.processChargerFrame(xfile);

      if (!mounted) return;
      
      if (kDebugMode) {
        debugPrint(
          "[ChargerDetect] gateway charger=${result.chargerDetected} "
          "light=${result.lightDetected} color=${result.lightColor} "
          "err=${result.errorMessage}",
        );
      }

      if (result.success && result.chargerDetected) {
        _chargerBox = result.chargerBox;

        if (result.lightDetected && _isRedOrFlicker(result.lightColor)) {
          setState(() => _phase = DetectionPhase.chargerFound);
          _completeBranch2(result.lightColor);
          return;
        }

        setState(() {
          _phase = DetectionPhase.chargerFound;
        });

        _startRedLightSearch();
      } else {
        // Retry if charger not found
        Timer(const Duration(milliseconds: 800), _runDetectionSequence);
      }
    } catch (e) {
      // Fallback or error handling
      Timer(const Duration(milliseconds: 800), _runDetectionSequence);
    }
  }

  bool _isRedOrFlicker(String color) {
    final normalized = color.toUpperCase();
    return normalized == "RED" || normalized == "FLICKER";
  }

  void _startRedLightSearch() {
    _tickTimer?.cancel();
    _lightSampleInFlight = false;
    setState(() {
      _phase = DetectionPhase.searchingLight;
      _searchTimer = 0.0;
      _progressPercent = 0.0;
      _elapsedMs = 0;
    });

    final mlService = MlModelService();

    // Sample first frame immediately, then every 900ms (rapid takePicture kills the camera on Xiaomi)
    _sampleRedLight(mlService);

    _tickTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      _elapsedMs += 900;
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _searchTimer = _elapsedMs / 1000;
        _progressPercent = (_searchTimer / 3.0).clamp(0.0, 1.0);
      });

      if (!_lightSampleInFlight) {
        _sampleRedLight(mlService, onRed: () => timer.cancel());
      }

      if (_searchTimer >= 3.0) {
        timer.cancel();
        if (mounted && _phase == DetectionPhase.searchingLight) {
          _completeBranch1();
        }
      }
    });
  }

  Future<void> _sampleRedLight(MlModelService mlService, {VoidCallback? onRed}) async {
    if (_lightSampleInFlight ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    _lightSampleInFlight = true;
    try {
      final frame = await _cameraController!.takePicture();
      final lightResult = await mlService.processChargerRedLight(
        frame,
        chargerBox: _chargerBox,
      );
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint(
          "[ChargerDetect] red poll light=${lightResult.lightDetected} "
          "color=${lightResult.lightColor}",
        );
      }

      if (lightResult.lightDetected && _isRedOrFlicker(lightResult.lightColor)) {
        onRed?.call();
        _completeBranch2(lightResult.lightColor);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("[ChargerDetect] red poll error: $e");
      }
    } finally {
      _lightSampleInFlight = false;
    }
  }

  void _completeBranch2(String lightColor) {
    _tickTimer?.cancel();
    _state.updateChargerInfo(true, true, lightColor);
    setState(() {
      _phase = DetectionPhase.branch2RedLight;
    });
    Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      _cameraController = null;
      await CameraSessionManager.instance.forceRelease();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/video-recording");
    });
  }

  void _completeBranch1() async {
    _tickTimer?.cancel();
    _state.updateChargerInfo(true, false, "OFF");
    setState(() {
      _phase = DetectionPhase.branch1NoLight;
    });
    _cameraController = null;
    await CameraSessionManager.instance.forceRelease();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/isolator-detection");
  }

  void _changeSimulatedBranch(int branchId) {
    setState(() {
      _state.setBranch(branchId.toString());
      // Restart sequence to let the user see the animation of the selected branch
      _runDetectionSequence();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Charger & LED Scanning"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Interactive Branch Selection Header
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Simulation Target Route:",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBranchSelectButton(
                            label: "Branch 1: No Light (5s timeout)",
                            branchId: 1,
                            isSelected: _state.selectedBranch == 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildBranchSelectButton(
                            label: "Branch 2: Red Light",
                            branchId: 2,
                            isSelected: _state.selectedBranch == 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildBranchSelectButton(
                            label: "Branch 2: Flicker",
                            branchId: 3,
                            isSelected: _state.selectedBranch == 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Camera Feed HUD Viewfinder
              Expanded(
                flex: 4,
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CameraViewfinder(
                      onControllerCreated: (controller) {
                        _cameraController = controller;
                        _runDetectionSequence();
                      },
                      fallbackBuilder: (context) {
                        return Container(
                          color: Colors.black.withOpacity(0.8),
                          child: CustomPaint(
                            painter: _MockChargerScanningPainter(
                              phase: _phase,
                              pulseVal: _scannerPulseController.value,
                              rotateVal: _gearRotationController.value,
                            ),
                          ),
                        );
                      },
                      overlay: _buildViewfinderOverlays(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom status checklist panel
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: _buildStatusTelemetryPanel(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchSelectButton({
    required String label,
    required int branchId,
    required bool isSelected,
  }) {
    final Color color = branchId == 1 ? AppColors.warningOrange : AppColors.dangerRed;
    return GestureDetector(
      onTap: () => _changeSimulatedBranch(branchId),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.glassBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinderOverlays() {
    // Guides always present
    final List<Widget> overlayWidgets = [
      const Positioned.fill(child: _ScanningGridOutline()),
    ];

    if (_phase == DetectionPhase.scanning) {
      overlayWidgets.add(
        Center(
          child: PulsingGlow(
            glowColor: AppColors.electricBlue,
            maxBlurRadius: 36,
            minBlurRadius: 12,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.electricBlue, width: 2.0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_scanner, color: AppColors.electricBlue, size: 40),
            ),
          ),
        ),
      );
    } else if (_phase == DetectionPhase.chargerFound) {
      overlayWidgets.add(
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successGreen),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.successGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  "Charger Found",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_phase == DetectionPhase.searchingLight) {
      overlayWidgets.add(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Scanning for LED indicator light...",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${_searchTimer.toStringAsFixed(1)}s",
                      style: const TextStyle(color: AppColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progressPercent,
                    color: AppColors.electricBlue,
                    backgroundColor: Colors.white12,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_phase == DetectionPhase.branch1NoLight) {
      overlayWidgets.add(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.90),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningOrange),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: AppColors.warningOrange, size: 24),
                SizedBox(width: 10),
                Text(
                  "NO LED LIGHT DETECTED",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_phase == DetectionPhase.branch2RedLight) {
      overlayWidgets.add(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.90),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dangerRed),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on, color: AppColors.dangerRed, size: 24),
                SizedBox(width: 10),
                Text(
                  "RED LED DETECTED!",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(children: overlayWidgets);
  }

  Widget _buildStatusTelemetryPanel() {
    String textGuidance = "Align the charger device inside the scanner overlay.";
    if (_phase == DetectionPhase.chargerFound) {
      textGuidance = "Charger body recognized! Hold your position steady.";
    } else if (_phase == DetectionPhase.searchingLight) {
      textGuidance = "Detecting high-frequency red/green color pixels on the panel...";
    } else if (_phase == DetectionPhase.branch1NoLight) {
      textGuidance = "Zero emission from indicators. Power source fault inferred.";
    } else if (_phase == DetectionPhase.branch2RedLight) {
      textGuidance = "Red flash sequence detected. Prepping blink recorder...";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Real-time status checklist
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Real-time Detection",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        _BlinkingGreenDot(),
                        SizedBox(width: 6),
                        Text(
                          "ACTIVE",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.electricBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Checklist items
              _buildChecklistItem(
                label: "Charger body detected",
                isCompleted: _phase != DetectionPhase.scanning,
                isLoading: _phase == DetectionPhase.scanning,
              ),
              const SizedBox(height: 12),
              _buildChecklistItem(
                label: "LED indicator detected",
                isCompleted: _phase == DetectionPhase.branch2RedLight,
                isFailed: _phase == DetectionPhase.branch1NoLight,
                isLoading: _phase == DetectionPhase.scanning || _phase == DetectionPhase.chargerFound || _phase == DetectionPhase.searchingLight,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Guidance Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Icon(
                _phase == DetectionPhase.branch1NoLight
                    ? Icons.warning_amber
                    : _phase == DetectionPhase.branch2RedLight
                        ? Icons.info_outline
                        : Icons.lightbulb_outline,
                color: _phase == DetectionPhase.branch1NoLight
                    ? AppColors.warningOrange
                    : _phase == DetectionPhase.branch2RedLight
                        ? AppColors.dangerRed
                        : AppColors.electricBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  textGuidance,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required bool isCompleted,
    bool isFailed = false,
    required bool isLoading,
  }) {
    Widget iconWidget;
    Color color = AppColors.textSecondary;

    if (isCompleted) {
      iconWidget = const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20);
      color = Colors.white;
    } else if (isFailed) {
      iconWidget = const Icon(Icons.warning, color: AppColors.warningOrange, size: 20);
      color = Colors.white;
    } else if (isLoading) {
      iconWidget = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
        ),
      );
      color = AppColors.electricBlue;
    } else {
      iconWidget = const Icon(Icons.circle_outlined, color: AppColors.textSecondary, size: 20);
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isCompleted || isLoading ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _BlinkingGreenDot extends StatefulWidget {
  const _BlinkingGreenDot();

  @override
  State<_BlinkingGreenDot> createState() => _BlinkingGreenDotState();
}

class _BlinkingGreenDotState extends State<_BlinkingGreenDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
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
        return Opacity(
          opacity: _ctrl.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.electricBlue,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _ScanningGridOutline extends StatelessWidget {
  const _ScanningGridOutline();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          // Mock crosshairs
          Align(
            alignment: Alignment.center,
            child: Container(width: 32, height: 1, color: Colors.white24),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 32, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

class _MockChargerScanningPainter extends CustomPainter {
  final DetectionPhase phase;
  final double pulseVal;
  final double rotateVal;

  _MockChargerScanningPainter({
    required this.phase,
    required this.pulseVal,
    required this.rotateVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Draw grid background lines
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1.0;
    
    for (int i = 1; i < 6; i++) {
      final double y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Draw main structural blueprint outlines for the EV charger
    final paintBody = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final chargerPath = Path()
      ..moveTo(centerX - 40, centerY - 80)
      ..lineTo(centerX + 40, centerY - 80)
      ..lineTo(centerX + 35, centerY + 80)
      ..lineTo(centerX - 35, centerY + 80)
      ..close();

    canvas.drawPath(chargerPath, paintBody);
    
    // Draw internal charger detailing
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY - 30), width: 30, height: 40),
      paintBody,
    );

    // Draw the LED indicator light region
    final double ledY = centerY - 30;
    
    if (phase == DetectionPhase.searchingLight) {
      // Rotating scan circle
      final paintRing = Paint()
        ..color = AppColors.electricBlue.withOpacity(0.3 + (pulseVal * 0.4))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawCircle(Offset(centerX, ledY), 16 + (pulseVal * 8), paintRing);
    } else if (phase == DetectionPhase.branch2RedLight) {
      // Draw simulated active blinking red LED
      final paintLedGlow = Paint()
        ..color = AppColors.dangerRed.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(centerX, ledY), 8, paintLedGlow);
      
      // Draw outer pulse rings
      final paintLedPulse = Paint()
        ..color = AppColors.dangerRed.withOpacity(0.3)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(centerX, ledY), 14 + (pulseVal * 6), paintLedPulse);
    }
  }

  @override
  bool shouldRepaint(covariant _MockChargerScanningPainter oldDelegate) => true;
}
