import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/ml_model_service.dart';
import 'package:camera/camera.dart';

enum IsolatorState { instruction, capturing, analyzing, resultOff, resultOn }

class IsolatorCheckScreen extends StatefulWidget {
  const IsolatorCheckScreen({super.key});

  @override
  State<IsolatorCheckScreen> createState() => _IsolatorCheckScreenState();
}

class _IsolatorCheckScreenState extends State<IsolatorCheckScreen> {
  IsolatorState _state = IsolatorState.instruction;
  final DiagnosticState _globalState = DiagnosticState();
  
  // Timing parameters
  int _analysisStep = 0;
  Timer? _analysisTimer;
  bool _showMockImage = false;

  CameraController? _cameraController;

  void _startDetection() {
    setState(() {
      _state = IsolatorState.capturing;
    });
  }

  void _startAnalysis() async {
    setState(() {
      _state = IsolatorState.analyzing;
      _analysisStep = 0;
    });

    XFile photoFile = XFile("mock_isolator_frame.jpg");
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        photoFile = await _cameraController!.takePicture();
      } catch (e) {
        debugPrint("Failed to take picture: $e");
      }
    }

    // Start the ML analysis in the background
    final mlService = MlModelService();
    final Future<IsolatorResult> isolatorFuture = mlService.processIsolatorFrame(
      photoFile,
    );

    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) return;
      setState(() {
        _analysisStep++;
      });

      if (_analysisStep >= 3) {
        timer.cancel();
        // Wait for ML model service future to complete
        isolatorFuture.then((result) {
          if (mounted) {
            setState(() {
              if (result.success) {
                // Update global state with the actual model outcome
                _globalState.setPowerBranchOutcomes(
                  isolatorOn: result.isSwitchOn,
                  evdbOk: _globalState.isEvdbOk,
                );
                _state = result.isSwitchOn ? IsolatorState.resultOn : IsolatorState.resultOff;
              } else {
                // Fallback to local injected outcome if the model failed
                _state = _globalState.isIsolatorOn ? IsolatorState.resultOn : IsolatorState.resultOff;
              }
            });
          }
        }).catchError((err) {
          if (mounted) {
            setState(() {
              _state = _globalState.isIsolatorOn ? IsolatorState.resultOn : IsolatorState.resultOff;
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
        title: const Text("Isolator Switch Check"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Injection outcome bar
              if (_state == IsolatorState.capturing || _state == IsolatorState.instruction)
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
                        "Inject Switch Position:",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      _buildInjectionToggle(
                        label: "OFF (Fault)",
                        isActive: !_globalState.isIsolatorOn,
                        onTap: () => setState(() => _globalState.setPowerBranchOutcomes(
                              isolatorOn: false,
                              evdbOk: _globalState.isEvdbOk,
                            )),
                        color: AppColors.dangerRed,
                      ),
                      const SizedBox(width: 8),
                      _buildInjectionToggle(
                        label: "ON (Healthy)",
                        isActive: _globalState.isIsolatorOn,
                        onTap: () => setState(() => _globalState.setPowerBranchOutcomes(
                              isolatorOn: true,
                              evdbOk: _globalState.isEvdbOk,
                            )),
                        color: AppColors.successGreen,
                      ),
                    ],
                  ),
                ),

              // Viewfinder Scanner Box
              Expanded(
                flex: 4,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildCameraViewport(),
                        ),
                      ),
                      
                      // Diagram Help Box overlay
                      if (_showMockImage)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => setState(() => _showMockImage = false),
                            child: Container(
                              color: Colors.black.withOpacity(0.95),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.help_outline, color: AppColors.electricBlue, size: 32),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Isolator Switch Diagram",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  // Mock custom rotary switch outline
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 3),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 12,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.dangerRed,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "This rotary switch is situated upstream adjacent to the charging holster box. Click anywhere to return.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom status actions
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: _buildBottomActionsCard(),
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
    if (_state == IsolatorState.instruction) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_off, color: AppColors.warningOrange, size: 48),
          const SizedBox(height: 16),
          Text(
            "Power Issue Detected",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Let's check the Isolator Switch position.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      );
    }

    if (_state == IsolatorState.capturing) {
      return CameraViewfinder(
        aspectRatio: 4 / 3,
        onControllerCreated: (controller) => _cameraController = controller,
        fallbackBuilder: (context) {
          return Container(
            color: Colors.black.withOpacity(0.9),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanning guides
                CustomPaint(
                  size: Size.infinite,
                  painter: _ScannerGuidePainter(),
                ),
                // Floating scan line
                const _LineScannerOverlay(),
                
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crop_free, color: AppColors.electricBlue, size: 64),
                    SizedBox(height: 12),
                    Text(
                      "Detecting isolator switch...",
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
            // Scanning guides
            CustomPaint(
              size: Size.infinite,
              painter: _ScannerGuidePainter(),
            ),
            // Floating scan line
            const _LineScannerOverlay(),
            
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.crop_free, color: AppColors.electricBlue, size: 64),
                SizedBox(height: 12),
                Text(
                  "Detecting isolator switch...",
                  style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_state == IsolatorState.analyzing) {
      return Container(
        color: Colors.black.withOpacity(0.95),
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
                Text(
                  "Analyzing Isolator...",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Staggered checkmarks
            _buildCheckmarkItem("Isolator housing detected", _analysisStep >= 1),
            const SizedBox(height: 10),
            _buildCheckmarkItem("Switch position identified", _analysisStep >= 2),
            const SizedBox(height: 10),
            _buildCheckmarkItem("Analysis complete", _analysisStep >= 3),
          ],
        ),
      );
    }

    // Success or Error results show beautiful static custom dials representation
    final bool isOn = _state == IsolatorState.resultOn;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOn ? AppColors.successGreen : AppColors.dangerRed,
                  width: 4,
                ),
              ),
              child: Transform.rotate(
                angle: isOn ? 0 : -math.pi / 2, // OFF = flat left, ON = straight up
                child: Center(
                  child: Container(
                    width: 12,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isOn ? AppColors.successGreen : AppColors.dangerRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOn ? "SWITCH STATUS: ON" : "SWITCH STATUS: OFF",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isOn ? AppColors.successGreen : AppColors.dangerRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckmarkItem(String label, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.circle_outlined,
          color: isDone ? AppColors.successGreen : AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDone ? Colors.white : AppColors.textSecondary,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionsCard() {
    if (_state == IsolatorState.instruction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Step 1: Locate Isolator", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    GestureDetector(
                      onTap: () => setState(() => _showMockImage = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("Info Diagram", style: TextStyle(color: AppColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Point the phone's camera at the primary isolator rotary switch box adjacent to the EV charger holster and capture the photo.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
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
            child: const Text("Start Isolator Detection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
        ],
      );
    }

    if (_state == IsolatorState.capturing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            "Position the isolator switch in the viewfinder and capture.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startAnalysis,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              "Capture Photo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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

    if (_state == IsolatorState.analyzing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Evaluating switch blade orientation relative to labels...",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (_state == IsolatorState.resultOff) {
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
                    Text("Isolator Switch is OFF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "Power supply is completely disconnected at the isolator box. No upstream line voltages can enter the charger terminals.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Add record to state & push result
              _globalState.addDiagnosticRecord("power-cut");
              Navigator.pushNamed(context, "/diagnosis/power-cut");
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

    // resultOn
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
                  Text("Isolator is ON", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                ],
              ),
              SizedBox(height: 10),
              Text(
                "Power lines successfully verified at isolator contacts. Let's proceed downstream to inspect breakers at the distribution board.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, "/photo-evdb"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Check EVDB →", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}

class _ScannerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    
    // Draw technical cross hairs
    canvas.drawLine(Offset(size.width * 0.1, size.height / 2), Offset(size.width * 0.9, size.height / 2), paintGrid);
    canvas.drawLine(Offset(size.width / 2, size.height * 0.1), Offset(size.width / 2, size.height * 0.9), paintGrid);
  }

  @override
  bool shouldRepaint(covariant _ScannerGuidePainter oldDelegate) => false;
}

class _LineScannerOverlay extends StatefulWidget {
  const _LineScannerOverlay();

  @override
  State<_LineScannerOverlay> createState() => _LineScannerOverlayState();
}

class _LineScannerOverlayState extends State<_LineScannerOverlay> with SingleTickerProviderStateMixin {
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
          top: _ctrl.value * 200 + 20,
          left: 10,
          right: 10,
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
