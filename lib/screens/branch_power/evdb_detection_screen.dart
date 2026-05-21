import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/integration_controller.dart';

enum EvdbPhase { scanning, captured, analyzing, result }

class EvdbDetectionScreen extends StatefulWidget {
  const EvdbDetectionScreen({super.key});

  @override
  State<EvdbDetectionScreen> createState() => _EvdbDetectionScreenState();
}

class _EvdbDetectionScreenState extends State<EvdbDetectionScreen> {
  EvdbPhase _phase = EvdbPhase.scanning;
  bool _showInstruction = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showInstruction = true;
        });
      }
    });
  }

  void _captureAndAnalyze() async {
    setState(() {
      _phase = EvdbPhase.captured;
    });

    // Fake analyzing delay for UX
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _phase = EvdbPhase.analyzing;
    });

    // Run IntegrationController logic
    final state = DiagnosticState();
    final integration = IntegrationController();
    
    // Simulate finding a wrong MCB spec (Protection Issue) in EVDB
    state.setPowerBranchOutcomes(isolatorOn: true, evdbOk: false);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    
    // Process final diagnostics based on gathered data
    // Branch 1 (Dead Charger), Isolator ON, EVDB WRONG (false) -> Returns protection-issue
    final decision = await integration.processDiagnosticsAndRoute(
      isChargerDead: true,
      isIsolatorOff: false,
      isMcbMissingOrWrong: true, 
      isSolidRedLight: false,
      flashCount: 0,
      evidenceImage: null, // Simulated
    );

    setState(() {
      _phase = EvdbPhase.result;
    });

    // Route based on IntegrationController's decision
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    if (decision.routeToAfterSales) {
      state.addDiagnosticRecord(decision.errorCode);
      Navigator.pushReplacementNamed(context, "/diagnosis/${decision.errorCode}");
    } else {
      state.addDiagnosticRecord(decision.errorCode);
      Navigator.pushReplacementNamed(context, "/diagnosis/${decision.errorCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_phase == EvdbPhase.scanning)
            CameraViewfinder(
              fallbackBuilder: (context) => Container(color: Colors.black87),
              overlay: const SizedBox.shrink(),
            )
          else
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              child: Container(
                color: Colors.blueGrey.shade900,
                child: const Center(
                  child: Icon(Icons.electrical_services, color: Colors.white24, size: 100),
                ),
              ),
            ),

          // Slide-up Instruction
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            bottom: _showInstruction && _phase == EvdbPhase.scanning ? 120 : -200,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.electricBlue.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: AppColors.electricBlue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Please capture a clear photo of the EV Distribution Board (EVDB) internals.",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Capture Button
          if (_phase == EvdbPhase.scanning)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndAnalyze,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Analyzing Overlay
          if (_phase == EvdbPhase.analyzing || _phase == EvdbPhase.result)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_phase == EvdbPhase.analyzing)
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue))
                    else
                      const Icon(Icons.check_circle, color: AppColors.successGreen, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _phase == EvdbPhase.analyzing ? "Analyzing components..." : "Analysis Complete",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_phase == EvdbPhase.result) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Routing to diagnostic results...",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ]
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
