import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum Phase { preparing, waitingForClarity, recording, processing, complete }

class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  Phase _phase = Phase.preparing;
  double _recordingTime = 0.0;
  int _blinkCount = 0;
  bool _isDisposed = false;

  Map<String, String> clarity = {
    "brightness": "dark",
    "stability": "shaking",
    "focus": "blurry",
  };

  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _startClarityCheck();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) setState(fn);
  }

  void _startClarityCheck() async {
    await Future.delayed(const Duration(seconds: 1));
    _safeSetState(() => _phase = Phase.waitingForClarity);

    await Future.delayed(const Duration(milliseconds: 1500));
    _safeSetState(() => clarity["brightness"] = "good");

    await Future.delayed(const Duration(milliseconds: 1500));
    _safeSetState(() => clarity["stability"] = "steady");

    await Future.delayed(const Duration(milliseconds: 1500));
    _safeSetState(() => clarity["focus"] = "sharp");

    // Start recording automatically when clarity is good
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _startRecording();
  }

  void _startRecording() {
    _safeSetState(() => _phase = Phase.recording);

    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      _safeSetState(() {
        _recordingTime += 0.1;

        if (_recordingTime >= 15.0) {
          timer.cancel();
          _startProcessing();
        }
      });
    });
  }

  void _startProcessing() async {
    _safeSetState(() {
      _phase = Phase.processing;
      _recordingTime = 15.0;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    _safeSetState(() {
      _blinkCount = 8;
      _phase = Phase.complete;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _safeSetState(() {
      _blinkCount = 8;
      _phase = Phase.complete;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/diagnosis/blink-8');
  }

  bool get _isReadyToRecord =>
      clarity["brightness"] == "good" &&
      clarity["stability"] == "steady" &&
      clarity["focus"] == "sharp";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1f35), Colors.black],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white10,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Top Right Recording Indicator
          if (_phase == Phase.recording)
            Positioned(
              top: 50,
              right: 24,
              child: FadeIn(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Pulse(
                        infinite: true,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF2D55),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "REC ${_recordingTime.toStringAsFixed(1)}s",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main Center Scanner
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScannerBox(),
                const SizedBox(height: 32),

                // Guidance Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _phase == Phase.preparing
                        ? "Preparing video mode..."
                        : _phase == Phase.waitingForClarity && !_isReadyToRecord
                        ? "Adjust camera for better clarity"
                        : _phase == Phase.waitingForClarity && _isReadyToRecord
                        ? "Ready - Auto-starting..."
                        : _phase == Phase.recording
                        ? "Hold steady - Recording blink pattern"
                        : _phase == Phase.processing
                        ? "Processing video..."
                        : "Analysis complete!",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _phase == Phase.recording
                              ? "Recording Blinks"
                              : _phase == Phase.processing ||
                                    _phase == Phase.complete
                              ? "Analysis"
                              : "Video Clarity",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusTag(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBottomPanelContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBox() {
    Color borderColor = _phase == Phase.recording
        ? const Color(0xFFFF2D55)
        : const Color(0xFF00D4FF);

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: 30),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.my_location, color: borderColor, size: 64),

          if (_phase == Phase.waitingForClarity && !_isReadyToRecord)
            const Text(
              "Center the red light\nin the box",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF00D4FF)),
            ),

          if (_phase == Phase.waitingForClarity && _isReadyToRecord)
            ZoomIn(
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 48),
                  SizedBox(height: 8),
                  Text(
                    "Starting in 1s...",
                    style: TextStyle(color: Color(0xFF00FF88)),
                  ),
                ],
              ),
            ),

          if (_phase == Phase.recording)
            Pulse(
              infinite: true,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D55),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.8),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTag() {
    if (_phase == Phase.waitingForClarity) {
      return Row(
        children: [
          Pulse(
            infinite: true,
            child: const Icon(Icons.circle, color: Color(0xFF00D4FF), size: 10),
          ),
          const SizedBox(width: 6),
          const Text(
            "PREPARING",
            style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12),
          ),
        ],
      );
    } else if (_phase == Phase.recording) {
      return const Row(
        children: [
          Icon(Icons.videocam, color: Color(0xFFFF2D55), size: 16),
          SizedBox(width: 6),
          Text(
            "RECORDING",
            style: TextStyle(color: Color(0xFFFF2D55), fontSize: 12),
          ),
        ],
      );
    } else {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 16),
          SizedBox(width: 6),
          Text(
            "COMPLETE",
            style: TextStyle(color: Color(0xFF00FF88), fontSize: 12),
          ),
        ],
      );
    }
  }

  Widget _buildBottomPanelContent() {
    if (_phase == Phase.waitingForClarity || _phase == Phase.preparing) {
      return Column(
        children: [
          _buildClarityIndicator("Brightness", clarity["brightness"]!),
          _buildClarityIndicator("Stability", clarity["stability"]!),
          _buildClarityIndicator("Focus", clarity["focus"]!),
        ],
      );
    }

    if (_phase == Phase.recording) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recording Progress",
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                "${_recordingTime.toStringAsFixed(1)}s / 15.0s",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _recordingTime / 15.0,
            backgroundColor: const Color(0xFF1E2436),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2D55).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFFFF2D55).withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFFFF2D55), size: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Capturing blink pattern...\nAI will count flashes after recording",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_phase == Phase.processing) {
      return ZoomIn(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.1),
            border: Border.all(color: Colors.cyan.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.cyan,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Analyzing Video\nAI processing blink pattern...",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Complete Phase
    return ZoomIn(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withOpacity(0.1),
          border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Pattern Identified\n$_blinkCount blinks detected - Error Code $_blinkCount",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClarityIndicator(String label, String value) {
    bool isGood = value == "good" || value == "steady" || value == "sharp";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isGood ? const Color(0xFF00FF88) : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: isGood ? Colors.white : Colors.white54),
              ),
            ],
          ),
          Text(
            value.toUpperCase(),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
