import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/ml_model_service.dart';
import 'package:camera/camera.dart';

enum EvdbState { instruction, capturing, analyzing, resultFail, resultOk }

class EvdbCheckScreen extends StatefulWidget {
  const EvdbCheckScreen({super.key});

  @override
  State<EvdbCheckScreen> createState() => _EvdbCheckScreenState();
}

class _EvdbCheckScreenState extends State<EvdbCheckScreen> {
  EvdbState _state = EvdbState.instruction;
  final DiagnosticState _globalState = DiagnosticState();
  
  // Simulation states
  int _analysisStep = 0;
  Timer? _analysisTimer;

  CameraController? _cameraController;

  void _startDetection() {
    setState(() {
      _state = EvdbState.capturing;
    });
  }

  void _startAnalysis() async {
    setState(() {
      _state = EvdbState.analyzing;
      _analysisStep = 0;
    });

    XFile photoFile = XFile("mock_evdb_frame.jpg");
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        photoFile = await _cameraController!.takePicture();
      } catch (e) {
        debugPrint("Failed to take picture: $e");
      }
    }

    // Start the ML analysis in the background
    final mlService = MlModelService();
    final Future<EvdbResult> evdbFuture = mlService.processEvdbFrame(
      photoFile,
    );

    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      setState(() {
        _analysisStep++;
      });

      if (_analysisStep >= 5) {
        timer.cancel();
        // Wait for ML model service future to complete
        evdbFuture.then((result) {
          if (mounted) {
            setState(() {
              if (result.success) {
                // Update global state with the actual model outcome
                _globalState.setPowerBranchOutcomes(
                  isolatorOn: _globalState.isIsolatorOn,
                  evdbOk: result.isCompliant,
                );
                _state = result.isCompliant ? EvdbState.resultOk : EvdbState.resultFail;
              } else {
                // Fallback to local injected outcome if the model failed
                _state = _globalState.isEvdbOk ? EvdbState.resultOk : EvdbState.resultFail;
              }
            });
          }
        }).catchError((err) {
          if (mounted) {
            setState(() {
              _state = _globalState.isEvdbOk ? EvdbState.resultOk : EvdbState.resultFail;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("EVDB Board Inspection"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Outcome Selector
              if (_state == EvdbState.capturing || _state == EvdbState.instruction)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Inject Component Status:",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      _buildInjectionToggle(
                        label: "MCB Fault (Wrong)",
                        isActive: !_globalState.isEvdbOk,
                        onTap: () => setState(() => _globalState.setPowerBranchOutcomes(
                              isolatorOn: _globalState.isIsolatorOn,
                              evdbOk: false,
                            )),
                        color: AppColors.dangerRed,
                      ),
                      const SizedBox(width: 8),
                      _buildInjectionToggle(
                        label: "All OK (32A breaker)",
                        isActive: _globalState.isEvdbOk,
                        onTap: () => setState(() => _globalState.setPowerBranchOutcomes(
                              isolatorOn: _globalState.isIsolatorOn,
                              evdbOk: true,
                            )),
                        color: AppColors.successGreen,
                      ),
                    ],
                  ),
                ),

              // Viewfinder / HUD
              Expanded(
                flex: 4,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildCameraViewport(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action and status instructions
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: _buildBottomInstructionCard(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInjectionToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? color : AppColors.glassBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? color : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraViewport() {
    if (_state == EvdbState.instruction) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.electrical_services, color: AppColors.electricBlue, size: 48),
          SizedBox(height: 16),
          Text(
            "EVDB Board Inspection",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            "Checking breaker models (MCB / RCCB ratings).",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      );
    }

    if (_state == EvdbState.capturing) {
      return CameraViewfinder(
        aspectRatio: 4 / 3,
        onControllerCreated: (controller) => _cameraController = controller,
        fallbackBuilder: (context) {
          return Container(
            color: Colors.black.withOpacity(0.9),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanning Guides
                CustomPaint(
                  size: Size.infinite,
                  painter: _ScannerTargetPainter(),
                ),
                const _HScanPulseLine(),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.center_focus_strong, color: AppColors.electricBlue, size: 64),
                    SizedBox(height: 12),
                    Text(
                      "Aligning Board Rails...",
                      style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        overlay: Stack(
          alignment: Alignment.center,
          children: [
            // Scanning Guides
            CustomPaint(
              size: Size.infinite,
              painter: _ScannerTargetPainter(),
            ),
            const _HScanPulseLine(),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.center_focus_strong, color: AppColors.electricBlue, size: 64),
                SizedBox(height: 12),
                Text(
                  "Aligning Board Rails...",
                  style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_state == EvdbState.analyzing) {
      return Container(
        color: Colors.black.withOpacity(0.96),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Analyzing EVDB Components...",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildChecklistItem("EVDB housing detected", _analysisStep >= 1),
            const SizedBox(height: 8),
            _buildChecklistItem("MCB presence & rating check", _analysisStep >= 2, isError: _analysisStep >= 2 && !_globalState.isEvdbOk),
            const SizedBox(height: 8),
            _buildChecklistItem("RCCB type-A/B compliance check", _analysisStep >= 3),
            const SizedBox(height: 8),
            _buildChecklistItem("Specification verification", _analysisStep >= 4),
            const SizedBox(height: 8),
            _buildChecklistItem("Analysis complete", _analysisStep >= 5),
          ],
        ),
      );
    }

    // Results showing custom graphic blueprint cards
    final bool isOk = _state == EvdbState.resultOk;
    return Container(
      color: Colors.black87,
      child: CustomPaint(
        painter: _EvdbBoardPainter(passed: isOk),
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool isDone, {bool isError = false}) {
    IconData icon = Icons.circle_outlined;
    Color color = AppColors.textSecondary;
    
    if (isDone) {
      if (isError) {
        icon = Icons.cancel;
        color = AppColors.dangerRed;
      } else {
        icon = Icons.check_circle;
        color = AppColors.successGreen;
      }
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDone ? (isError ? AppColors.dangerRed : Colors.white) : AppColors.textSecondary,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInstructionCard() {
    if (_state == EvdbState.instruction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Verification Parameters:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 12),
                Text("• MCB Breaker (Current rating matching 32 Amps standard)", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Text("• RCCB Breaker (Earth leakage circuit safety compliance)", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Text("• Internal copper cable gauges & solid wiring contacts", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startDetection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Start EVDB Detection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          ),
        ],
      );
    }

    if (_state == EvdbState.capturing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            "Position the circuit breakers in the viewfinder and capture.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startAnalysis,
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
    }

    if (_state == EvdbState.analyzing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Extracting OCR breaker text markings & dimensions...",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (_state == EvdbState.resultFail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dangerRed.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.dangerRed, size: 20),
                    SizedBox(width: 8),
                    Text("MCB Component Anomaly", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "We detected a 16A breaker rating. Charger operations demand a 32A miniature circuit breaker. Safety loops are compromised.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _globalState.addDiagnosticRecord("protection-issue");
              Navigator.pushNamed(context, "/diagnosis/protection-issue");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("View Full Diagnosis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
        ],
      );
    }

    // resultOk
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 20),
                  SizedBox(width: 8),
                  Text("EVDB Compliance Verified", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                ],
              ),
              SizedBox(height: 10),
              Text(
                "Upstream circuit structures (MCB, RCCB, and wiring loads) conform entirely to 32A infrastructure standards. Power supply is structurally pristine.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/main", (route) => false),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Return to Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        ),
      ],
    );
  }
}

class _ScannerTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    
    // Horizontal alignment guidelines
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), paintGrid);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), paintGrid);
  }

  @override
  bool shouldRepaint(covariant _ScannerTargetPainter oldDelegate) => false;
}

class _HScanPulseLine extends StatefulWidget {
  const _HScanPulseLine();

  @override
  State<_HScanPulseLine> createState() => _HScanPulseLineState();
}

class _HScanPulseLineState extends State<_HScanPulseLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
          top: _ctrl.value * 180 + 30,
          left: 16,
          right: 16,
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              boxShadow: [
                BoxShadow(color: AppColors.electricBlue.withOpacity(0.8), blurRadius: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EvdbBoardPainter extends CustomPainter {
  final bool passed;

  _EvdbBoardPainter({required this.passed});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Draw rails background
    final paintRail = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromCenter(center: Offset(centerX, centerY), width: size.width * 0.9, height: 60), paintRail);

    // Draw Breaker Block 1 (MCB)
    final paintMcb = Paint()
      ..color = passed ? AppColors.secondaryBg : AppColors.dangerRed.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final paintMcbBorder = Paint()
      ..color = passed ? AppColors.successGreen : AppColors.dangerRed
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final mcbRect = Rect.fromCenter(center: Offset(centerX - 40, centerY), width: 50, height: 80);
    canvas.drawRect(mcbRect, paintMcb);
    canvas.drawRect(mcbRect, paintMcbBorder);

    // MCB toggle switch toggle
    final paintToggle = Paint()
      ..color = passed ? AppColors.successGreen : AppColors.dangerRed
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX - 40, passed ? centerY - 15 : centerY + 15), width: 14, height: 20),
      paintToggle,
    );

    // Text labels inside MCB box
    
    // Label "32A" or "16A"
    final textSpan = TextSpan(
      text: passed ? "32A" : "16A",
      style: TextStyle(
        color: passed ? AppColors.successGreen : AppColors.dangerRed,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
    
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(centerX - 52, centerY - 5));

    // Draw Breaker Block 2 (RCCB)
    final paintRccb = Paint()
      ..color = AppColors.secondaryBg
      ..style = PaintingStyle.fill;
    
    final paintRccbBorder = Paint()
      ..color = AppColors.successGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rccbRect = Rect.fromCenter(center: Offset(centerX + 40, centerY), width: 64, height: 80);
    canvas.drawRect(rccbRect, paintRccb);
    canvas.drawRect(rccbRect, paintRccbBorder);

    // RCCB trip switch knob
    canvas.drawCircle(Offset(centerX + 40, centerY - 10), 8, paintToggle);
    
    final rccbTextSpan = const TextSpan(
      text: "RCCB\n30mA",
      style: TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 8,
      ),
    );
    final tpRccb = TextPainter(text: rccbTextSpan, textDirection: TextDirection.ltr)..layout();
    tpRccb.paint(canvas, Offset(centerX + 24, centerY + 8));
  }

  @override
  bool shouldRepaint(covariant _EvdbBoardPainter oldDelegate) => true;
}
