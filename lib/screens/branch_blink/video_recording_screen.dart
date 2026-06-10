import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/ml_model_service.dart';
import '../../services/camera_session_manager.dart';

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
  Timer? _stuckDetectionTimer;
  CameraController? _cameraController;
  XFile? _recordedVideo;
  String? _cameraError;
  bool _isProcessing = false;
  bool _isStuck = false;
  bool _cameraReady = false;
  bool _recordingStarted = false;

  late AnimationController _pulseController;

  int _peakCount = 0;
  String _detectedPattern = "";
  bool _resultIsSolidRed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    
    // Fix 4: Safety net - if stuck for more than 30 seconds, auto-reset
    _stuckDetectionTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isProcessing) {
        _handleDetectionFailure('Detection timed out after 30 seconds');
      }
    });
  }

  void _onCameraReady(CameraController controller) {
    _cameraController = controller;
    if (!mounted) return;
    setState(() {
      _cameraError = null;
      _cameraReady = true;
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _stuckDetectionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_recordingStarted) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      setState(() => _cameraError = 'Camera not ready for recording.');
      return;
    }

    _recordingStarted = true;

    try {
      if (!controller.value.isRecordingVideo) {
        print("[Video Recording] 🔴 Starting 15-second video recording...");
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
    
    print("[Video Recording] ⏱️  Recording started. Will stop after 15 seconds...");

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

  // Fix 2: Handle detection failure gracefully
  void _handleDetectionFailure(String reason) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isStuck = true;
      _cameraError = reason;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $reason. Please retry.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper method to reset detection state
  void _resetDetection() {
    if (!mounted) return;
    setState(() {
      _phase = RecordingPhase.preparing;
      _progress = 0.0;
      _isProcessing = false;
      _isStuck = false;
      _cameraError = null;
      _peakCount = 0;
      _detectedPattern = '';
      _resultIsSolidRed = false;
      _recordingStarted = false;
    });
    _stuckDetectionTimer?.cancel();
    _stuckDetectionTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isProcessing) {
        _handleDetectionFailure('Detection timed out after 30 seconds');
      }
    });
  }

  /// Maps server codes like blink-7-very-rapid → blink-7 for diagnosis lookup.
  String _normalizeBlinkErrorCode(String code) {
    if (code == 'solid-red') return 'solid-red';
    final match = RegExp(r'^blink-(\d+)').firstMatch(code);
    if (match != null) return 'blink-${match.group(1)}';
    return code;
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
    print("[Video Recording] ✅ Recording stopped. File: ${_recordedVideo?.path}");
    
    setState(() {
      _phase = RecordingPhase.processing;
      _isProcessing = true;
    });

    final mlService = MlModelService();
    BlinkDetectionResult blinkResult;

    if (_recordedVideo != null) {
      print("[Video Recording] 📤 Starting video upload and analysis...");
      try {
        // Fix 1: Add timeout to the API call
        // Video analysis often takes 15–25s; 15s timeout caused UI to show 0
        // while the server still returned the real count in the background.
        blinkResult = await mlService.processBlinkVideo(_recordedVideo!).timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            _handleDetectionFailure(
              'Server timeout - no response within 45 seconds',
            );
            return BlinkDetectionResult(
              success: false,
              blinkCount: 0,
              correlatedErrorCode: 'timeout',
              confidence: 0.0,
              errorMessage: 'Server timeout',
            );
          },
        );
      } on SocketException catch (e) {
        _handleDetectionFailure('No network connection: $e');
        blinkResult = BlinkDetectionResult(
          success: false,
          blinkCount: 0,
          correlatedErrorCode: 'network_error',
          confidence: 0.0,
          errorMessage: 'Network connection failed',
        );
      } on TimeoutException catch (e) {
        _handleDetectionFailure('Server timeout: $e');
        blinkResult = BlinkDetectionResult(
          success: false,
          blinkCount: 0,
          correlatedErrorCode: 'timeout',
          confidence: 0.0,
          errorMessage: 'Server timeout',
        );
      } catch (e) {
        _handleDetectionFailure('Detection failed: $e');
        blinkResult = BlinkDetectionResult(
          success: false,
          blinkCount: 0,
          correlatedErrorCode: 'unknown',
          confidence: 0.0,
          errorMessage: e.toString(),
        );
      }
    } else {
      print("[Video Recording] ❌ No video was recorded!");
      _handleDetectionFailure('No video was recorded');
      blinkResult = BlinkDetectionResult(
        success: false,
        blinkCount: 0,
        correlatedErrorCode: 'unknown',
        confidence: 0.0,
        errorMessage: _cameraError ?? 'No video captured',
      );
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    print("[Video Recording] 📊 Result received: blinkCount=${blinkResult.blinkCount}, success=${blinkResult.success}, pattern=${blinkResult.pattern}");

    final isSolidRed = blinkResult.isSolidRed;

    if (!blinkResult.success && !isSolidRed) {
      _handleDetectionFailure(
        blinkResult.errorMessage ?? 'Blink detection failed',
      );
      return;
    }

    if (isSolidRed) {
      setState(() {
        _resultIsSolidRed = true;
        _peakCount = 0;
        _detectedPattern = 'Solid red light detected';
        _phase = RecordingPhase.complete;
      });
    } else {
      _resultIsSolidRed = false;
      for (var i = 0; i <= blinkResult.blinkCount; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          _peakCount = i;
          if (i == blinkResult.blinkCount) {
            _detectedPattern = '${blinkResult.blinkCount} blinks detected';
          }
        });
      }

      setState(() {
        _phase = RecordingPhase.complete;
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await _navigateToDiagnosis(blinkResult);
  }

  Future<void> _navigateToDiagnosis(BlinkDetectionResult blinkResult) async {
    final isSolidRed = blinkResult.isSolidRed;
    final errorCode = isSolidRed
        ? 'solid-red'
        : _normalizeBlinkErrorCode(blinkResult.correlatedErrorCode);

    final state = DiagnosticState();
    state.setFaultsFromBlinkResult(
      blinkCount: isSolidRed ? 0 : blinkResult.blinkCount,
      correlatedErrorCode: isSolidRed ? 'solid-red' : blinkResult.correlatedErrorCode,
      confidence: blinkResult.confidence > 0 ? blinkResult.confidence : 0.88,
      pattern: isSolidRed ? 'solid_red' : blinkResult.pattern,
    );
    state.addDiagnosticRecord(errorCode);

    _stuckDetectionTimer?.cancel();
    _cameraController = null;
    await CameraSessionManager.instance.forceRelease();

    if (!mounted) return;

    try {
      await Navigator.pushReplacementNamed(context, '/diagnosis/$errorCode');
    } catch (e) {
      if (!mounted) return;
      _handleDetectionFailure('Could not open diagnosis screen: $e');
    }
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
          
          // Fix 3: Show retry button when stuck
          if (_isStuck && _phase == RecordingPhase.processing)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _cameraError ?? 'Detection failed',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _resetDetection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

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
                      ? (_cameraReady
                          ? 'Step 3: Point at the red status light, then tap Start Recording for 15 seconds.'
                          : 'Preparing camera...')
                      : 'Keep the blinking red light inside the box and hold your phone steady.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          if (_phase == RecordingPhase.preparing && _cameraReady)
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.fiber_manual_record, color: Colors.white),
                label: const Text(
                  'Start Recording',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Text(
                          _resultIsSolidRed ? 'Light Status:' : 'Peaks Counted:',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _resultIsSolidRed ? 'Solid Red' : '$_peakCount',
                          style: const TextStyle(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
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
