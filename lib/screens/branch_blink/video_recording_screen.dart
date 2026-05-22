import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/integration_controller.dart';
import '../../services/ml_model_service.dart';

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
  CameraController? _cameraController;
  XFile? _recordedVideo;
  String? _cameraError;

  late AnimationController _pulseController;

  int _peakCount = 0;
  String _detectedPattern = "";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  void _onCameraReady(CameraController controller) {
    _cameraController = controller;
    if (!mounted) return;
    setState(() => _cameraError = null);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startRecording();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      setState(() => _cameraError = 'Camera not ready for recording.');
      return;
    }

    try {
      if (!controller.value.isRecordingVideo) {
        await controller.startVideoRecording();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = 'Could not start video recording: $e');
      return;
    }

    setState(() {
      _phase = RecordingPhase.recording;
      _progress = 0.0;
    });

    const totalMs = 15000;
    const intervalMs = 100;
    var elapsed = 0;

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      elapsed += intervalMs;

      if (mounted) {
        setState(() {
          _progress = elapsed / totalMs;
        });
      }

      if (elapsed >= totalMs) {
        timer.cancel();
        await _stopRecordingAndProcess();
      }
    });
  }

  Future<void> _stopRecordingAndProcess() async {
    final controller = _cameraController;
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        _recordedVideo = await controller.stopVideoRecording();
      } catch (e) {
        if (mounted) {
          setState(() => _cameraError = 'Failed to stop recording: $e');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _phase = RecordingPhase.processing;
    });

    final mlService = MlModelService();
    BlinkDetectionResult blinkResult;

    if (_recordedVideo != null) {
      blinkResult = await mlService.processBlinkVideo(_recordedVideo!);
    } else {
      blinkResult = BlinkDetectionResult(
        success: false,
        blinkCount: 0,
        correlatedErrorCode: 'unknown',
        confidence: 0.0,
        errorMessage: _cameraError ?? 'No video captured',
      );
    }

    for (var i = 0; i <= 7; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _peakCount = blinkResult.success ? blinkResult.blinkCount : i;
        if (i == 7 && blinkResult.success) {
          _detectedPattern = '${blinkResult.blinkCount} blinks detected';
        }
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final state = DiagnosticState();
    final integration = IntegrationController();

    final isRedLight = state.selectedBranch == 2;
    final flashCount = state.selectedBranch == 3 ? blinkResult.blinkCount : 0;

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

    state.addDiagnosticRecord(decision.errorCode);
    Navigator.pushReplacementNamed(context, "/diagnosis/${decision.errorCode}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraViewfinder(
            fillScreen: true,
            forVideo: true,
            onControllerCreated: _onCameraReady,
            fallbackBuilder: (context) => _buildCameraError(),
          ),

          if (_phase == RecordingPhase.processing || _phase == RecordingPhase.complete)
            Container(color: Colors.black87),

          if (_phase == RecordingPhase.preparing || _phase == RecordingPhase.recording)
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: _phase == RecordingPhase.recording
                            ? AppColors.dangerRed.withOpacity(0.5 + (_pulseController.value * 0.5))
                            : AppColors.electricBlue,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white.withOpacity(0.25),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),

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
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _phase == RecordingPhase.preparing
                      ? "Preparing camera..."
                      : "Center the blinking light inside the box and hold still.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          if (_phase == RecordingPhase.recording)
            Positioned(
              bottom: 80,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: AppColors.dangerRed, size: 16),
                          SizedBox(width: 8),
                          Text("REC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        "15s",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dangerRed),
                    minHeight: 8,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ],
              ),
            ),

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
                    BoxShadow(color: AppColors.electricBlue.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_phase == RecordingPhase.processing)
                      const SizedBox(
                        width: 50,
                        height: 50,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Peaks Counted:", style: TextStyle(color: Colors.white70)),
                        Text(
                          "$_peakCount",
                          style: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pattern:", style: TextStyle(color: Colors.white70)),
                        Text(
                          _detectedPattern.isEmpty ? "Analyzing..." : _detectedPattern,
                          style: TextStyle(
                            color: _detectedPattern.isEmpty ? Colors.white54 : AppColors.warningOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: AppColors.dangerRed, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Camera unavailable",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _cameraError ?? "Grant camera permission and restart the recording step.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
