import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/integration_controller.dart';

enum RecordingPhase { preparing, recording, processing, complete }

class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> with SingleTickerProviderStateMixin {
  RecordingPhase _phase = RecordingPhase.preparing;
  double _progress = 0.0;
  Timer? _recordingTimer;
  
  late AnimationController _pulseController;
  
  // Local processing metrics
  int _peakCount = 0;
  String _detectedPattern = "";
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    
    // Automatically start recording after brief instruction period
    Timer(const Duration(seconds: 2), () {
      if (mounted) _startRecording();
    });
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _phase = RecordingPhase.recording;
    });

    // 15-second timer
    const totalMs = 15000;
    const intervalMs = 100;
    int elapsed = 0;

    _recordingTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsed += intervalMs;
      
      if (mounted) {
        setState(() {
          _progress = elapsed / totalMs;
        });
      }

      if (elapsed >= totalMs) {
        timer.cancel();
        _processVideo();
      }
    });
  }

  void _processVideo() async {
    setState(() {
      _phase = RecordingPhase.processing;
    });
    
    // Simulate "Difference Map" peak counting process
    for (int i = 0; i <= 7; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _peakCount = i;
        if (i == 7) _detectedPattern = "7 blinks \u2192 pause \u2192 7 blinks";
      });
    }
    
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // Use IntegrationController to finalize the diagnostic
    final state = DiagnosticState();
    final integration = IntegrationController();
    
    // Mock the state values based on simulated outcome
    bool isRedLight = state.selectedBranch == 2;
    int flashCount = state.selectedBranch == 3 ? 7 : 0; // If flicker branch, 7 flashes
    
    final decision = await integration.processDiagnosticsAndRoute(
      isChargerDead: false,
      isIsolatorOff: false,
      isMcbMissingOrWrong: false,
      isSolidRedLight: isRedLight,
      flashCount: flashCount,
      evidenceImage: null, 
    );
    
    setState(() {
      _phase = RecordingPhase.complete;
    });

    await Future.delayed(const Duration(seconds: 1));
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
          // Background Feed
          CameraViewfinder(
            fallbackBuilder: (context) => Container(color: Colors.black87),
            overlay: const SizedBox.shrink(),
          ),
          
          // Darken background if processing
          if (_phase == RecordingPhase.processing || _phase == RecordingPhase.complete)
            Container(color: Colors.black87),
            
          // Target Box Overlay
          if (_phase == RecordingPhase.preparing || _phase == RecordingPhase.recording)
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _phase == RecordingPhase.recording 
                            ? AppColors.dangerRed.withOpacity(0.5 + (_pulseController.value * 0.5))
                            : AppColors.electricBlue, 
                        width: 3
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (_phase == RecordingPhase.recording)
                          BoxShadow(
                            color: AppColors.dangerRed.withOpacity(0.3),
                            blurRadius: 20 * _pulseController.value,
                            spreadRadius: 5,
                          )
                      ]
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add, 
                        color: Colors.white.withOpacity(0.3),
                        size: 40,
                      ),
                    ),
                  );
                }
              ),
            ),
            
          // Instruction Text
          if (_phase == RecordingPhase.preparing || _phase == RecordingPhase.recording)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24)
                ),
                child: Text(
                  _phase == RecordingPhase.preparing 
                      ? "Preparing to record..."
                      : "Center the blinking light inside the box and hold still.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
          // Recording Progress Bar
          if (_phase == RecordingPhase.recording)
            Positioned(
              bottom: 80,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, color: AppColors.dangerRed, size: 16),
                          const SizedBox(width: 8),
                          const Text("REC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        "15s",
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dangerRed),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            
          // Processing Overlay
          if (_phase == RecordingPhase.processing || _phase == RecordingPhase.complete)
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: [
                    BoxShadow(color: AppColors.electricBlue.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_phase == RecordingPhase.processing)
                      const SizedBox(
                        width: 50, height: 50,
                        child: CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 3),
                      )
                    else
                      const Icon(Icons.check_circle, color: AppColors.successGreen, size: 50),
                      
                    const SizedBox(height: 24),
                    const Text(
                      "Local Processing",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Difference Map Extraction",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    
                    // Metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Peaks Counted:", style: TextStyle(color: Colors.white70)),
                        Text("$_peakCount", style: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pattern:", style: TextStyle(color: Colors.white70)),
                        Text(_detectedPattern.isEmpty ? "Analyzing..." : _detectedPattern, 
                            style: TextStyle(
                              color: _detectedPattern.isEmpty ? Colors.white54 : AppColors.warningOrange, 
                              fontWeight: FontWeight.bold,
                              fontSize: 12
                            )
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
