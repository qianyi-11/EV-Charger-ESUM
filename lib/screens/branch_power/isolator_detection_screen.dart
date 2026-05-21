import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';

enum IsolatorPhase { scanning, captured, analyzing, resultOff, resultOn }

class IsolatorDetectionScreen extends StatefulWidget {
  const IsolatorDetectionScreen({super.key});

  @override
  State<IsolatorDetectionScreen> createState() => _IsolatorDetectionScreenState();
}

class _IsolatorDetectionScreenState extends State<IsolatorDetectionScreen> {
  IsolatorPhase _phase = IsolatorPhase.scanning;
  bool _showInstruction = false;
  
  // Checklist animations
  bool _step1Done = false;
  bool _step2Done = false;

  @override
  void initState() {
    super.initState();
    
    // Slide up instruction after a tiny delay
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showInstruction = true;
        });
      }
    });

    _startSimulatedYoloScan();
  }

  void _startSimulatedYoloScan() {
    // Simulate YOLO detecting the isolator after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _phase = IsolatorPhase.captured;
        });
        _runFakeAnalysis();
      }
    });
  }

  void _runFakeAnalysis() {
    // 1.5s fake delay for "Analyzing..."
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _step1Done = true; // [✓] Isolator detected
      });
      
      // 1.0s delay for second step
      Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _step2Done = true; // [✓] Switch position
        });
        
        // Final result transition based on mock global state
        Timer(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          final state = DiagnosticState();
          
          if (state.isIsolatorOn) {
            setState(() {
              _phase = IsolatorPhase.resultOn;
            });
            // Proceed to EVDB
            Timer(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, "/evdb-detection");
              }
            });
          } else {
            setState(() {
              _phase = IsolatorPhase.resultOff;
            });
          }
        });
      });
    });
  }

  void _showIsolatorExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text("Isolator Switch Example", style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          height: 200,
          color: Colors.white10,
          child: const Center(
            child: Icon(Icons.power, color: AppColors.electricBlue, size: 80),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it", style: TextStyle(color: AppColors.electricBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Camera or Static Photo
          if (_phase == IsolatorPhase.scanning)
            CameraViewfinder(
              fallbackBuilder: (context) => Container(color: Colors.black87),
              overlay: const SizedBox.shrink(),
            )
          else
            // Simulated Static Photo (dimmed)
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              child: Container(
                color: Colors.blueGrey.shade900, // Mock photo background
                child: const Center(
                  child: Icon(Icons.power, color: Colors.white24, size: 100),
                ),
              ),
            ),

          // Slide-up Instruction (Semi-transparent)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            bottom: _showInstruction && _phase == IsolatorPhase.scanning ? 40 : -200,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warningOrange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warningOrange, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Charger is not powered.\nPlease point your camera at the Isolator switch.",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.electricBlue),
                    onPressed: () => _showIsolatorExample(context),
                  ),
                ],
              ),
            ),
          ),

          // Analyzing Overlay
          if (_phase == IsolatorPhase.captured || _phase == IsolatorPhase.resultOn || _phase == IsolatorPhase.resultOff)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_phase == IsolatorPhase.captured)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
                            ),
                          )
                        else if (_phase == IsolatorPhase.resultOn)
                          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20)
                        else
                          const Icon(Icons.error, color: AppColors.dangerRed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _phase == IsolatorPhase.captured
                              ? "Analyzing Isolator..."
                              : _phase == IsolatorPhase.resultOn
                                  ? "Analysis Complete"
                                  : "Error Found",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildChecklistItem("Isolator detected", _step1Done, null),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      "Switch position: ${!_step2Done ? '...' : (DiagnosticState().isIsolatorOn ? 'ON' : 'OFF')}",
                      _step2Done,
                      _step2Done ? (DiagnosticState().isIsolatorOn ? AppColors.successGreen : AppColors.dangerRed) : null,
                    ),
                    
                    if (_phase == IsolatorPhase.resultOff) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text(
                        "Please flip the Isolator switch back to the ON position.",
                        style: TextStyle(color: AppColors.warningOrange, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Mock animation of flipping switch
                      const Center(
                        child: Icon(Icons.swipe_up, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // User flipped it, simulate success
                            DiagnosticState().setPowerBranchOutcomes(isolatorOn: true, evdbOk: false);
                            Navigator.pushReplacementNamed(context, "/evdb-detection");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                          ),
                          child: const Text("I have turned it ON", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],

                    if (_phase == IsolatorPhase.resultOn) ...[
                      const SizedBox(height: 24),
                      const Text(
                        "Power confirmed at Isolator.\nProceeding to EVDB check...",
                        style: TextStyle(color: AppColors.successGreen, fontSize: 14),
                        textAlign: TextAlign.center,
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

  Widget _buildChecklistItem(String label, bool isDone, Color? overrideColor) {
    return Row(
      children: [
        if (isDone)
          Icon(Icons.check_box, color: overrideColor ?? AppColors.successGreen, size: 20)
        else
          const Icon(Icons.check_box_outline_blank, color: Colors.white24, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDone ? (overrideColor ?? Colors.white) : Colors.white54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
