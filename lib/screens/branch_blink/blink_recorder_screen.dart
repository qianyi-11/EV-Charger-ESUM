import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/ml_model_service.dart';
import 'package:camera/camera.dart';

enum RecordPhase { recording, processing, complete }

class BlinkRecorderScreen extends StatefulWidget {
  const BlinkRecorderScreen({super.key});

  @override
  State<BlinkRecorderScreen> createState() => _BlinkRecorderScreenState();
}

class _BlinkRecorderScreenState extends State<BlinkRecorderScreen> with TickerProviderStateMixin {
  RecordPhase _phase = RecordPhase.recording;
  final DiagnosticState _globalState = DiagnosticState();

  // Telemetry clocks
  double _elapsedSeconds = 0.0;
  int _blinksDetected = 0;
  Timer? _timer;
  
  // LED blinking control states
  bool _isLedOn = false;
  
  // Waveform history plotting points
  final List<double> _signalHistory = [];
  final List<int> _blinkTimings = []; // Indexes in history when blink occurred

  // Interactive LED triggers
  final List<double> _programmedBlinkTimes = [1.2, 2.7, 4.2, 5.7, 7.2, 8.7, 10.2, 11.7];

  late final AnimationController _pulseController;
  late final AnimationController _processRotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _processRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _processRotationController.dispose();
    super.dispose();
  }

  void _startRecording() {
    _elapsedSeconds = 0.0;
    _blinksDetected = 0;
    _signalHistory.clear();
    _blinkTimings.clear();
    _phase = RecordPhase.recording;

    // Tick every 100 milliseconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 0.1;
        
        // Add to historical signal graph: 0 = low signal
        _signalHistory.add(0.0);

        // LED blinking injection simulation based on exact timing program
        bool matchFound = false;
        for (final double t in _programmedBlinkTimes) {
          // If current time is within [t, t + 0.6s] window, trigger a flash
          if (_elapsedSeconds >= t && _elapsedSeconds < t + 0.6) {
            matchFound = true;
            break;
          }
        }

        if (matchFound) {
          if (!_isLedOn) {
            // New flash start trigger
            _blinksDetected++;
            _globalState.blinksCounted = _blinksDetected;
            _signalHistory[_signalHistory.length - 1] = 1.0; // High signal
            _blinkTimings.add(_signalHistory.length - 1);
          } else {
            _signalHistory[_signalHistory.length - 1] = 1.0; // High signal
          }
          _isLedOn = true;
        } else {
          _isLedOn = false;
        }

        // Fills over 15 seconds
        if (_elapsedSeconds >= 15.0) {
          timer.cancel();
          _triggerProcessing();
        }
      });
    });
  }

  void _triggerProcessing() {
    _timer?.cancel();
    setState(() {
      _phase = RecordPhase.processing;
      _isLedOn = false;
    });
    _processRotationController.repeat();

    // Call OpenCV blink counting analyzer in our unified ML Service
    final mlService = MlModelService();
    mlService.processBlinkVideo(XFile("mock_pulse_recording.mp4")).then((result) {
      if (!mounted) return;
      _processRotationController.stop();
      
      if (result.success) {
        setState(() {
          _phase = RecordPhase.complete;
        });

        // Auto route to diagnosis screen after 1.5 seconds
        Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _globalState.addDiagnosticRecord(result.correlatedErrorCode);
            Navigator.pushReplacementNamed(context, "/diagnosis/${result.correlatedErrorCode}");
          }
        });
      } else {
        // Fallback or error state
        setState(() {
          _phase = RecordPhase.recording;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double recordingProgress = (_elapsedSeconds / 15.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dynamic Native Camera Viewfinder Background
          Positioned.fill(
            child: CameraViewfinder(
              aspectRatio: 9 / 16,
              fallbackBuilder: (context) {
                return Container(
                  color: Colors.black.withOpacity(0.95),
                  child: CustomPaint(
                    painter: _RecordingViewfinderPainter(),
                  ),
                );
              },
              overlay: const SizedBox.shrink(),
            ),
          ),

          // Central flashing red light simulated HUD
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing bracket outline target box
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.electricBlue.withOpacity(0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                
                // Outer target corner bracket markers
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: _TargetCornerBrackets(),
                ),

                // Flashing Red LED Light
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLedOn ? AppColors.dangerRed : const Color(0xFF301015),
                    boxShadow: _isLedOn 
                        ? [
                            BoxShadow(
                              color: AppColors.dangerRed.withOpacity(0.8),
                              blurRadius: 40,
                              spreadRadius: 4,
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Foreground Layout: Top Status bar and bottom telemetry panel
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top HUD Panel: REC blinking pill and clock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _phase == RecordPhase.recording ? _pulseController.value : 0.0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _phase == RecordPhase.recording ? "REC" : "PAUSE",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            "REC ${_elapsedSeconds.toStringAsFixed(1)}s / 15.0s",
                            style: const TextStyle(
                              color: AppColors.electricBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              fontFamily: "monospace",
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Analytics Panel
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Waveform chart
                        _buildWaveformGraphCard(),
                        const SizedBox(height: 12),
                        
                        // Action progress metrics
                        _buildRecordingProgressDetailsCard(recordingProgress),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformGraphCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.waves, color: AppColors.electricBlue, size: 16),
              SizedBox(width: 8),
              Text(
                "Oscilloscope Waveform Telemetry",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Waveform graph viewport
          SizedBox(
            height: 48,
            child: CustomPaint(
              size: Size.infinite,
              painter: _WaveformPainter(
                history: _signalHistory,
                blinkTimings: _blinkTimings,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingProgressDetailsCard(double progress) {
    String stateLabel = "RECORDING";
    Color statusColor = AppColors.dangerRed;
    String detailMessage = "Center the blinking red LED within the scanner target square.";
    
    if (_phase == RecordPhase.processing) {
      stateLabel = "PROCESSING";
      statusColor = AppColors.electricBlue;
      detailMessage = "Decoding frequency intervals and pulse gaps against standard error banks...";
    } else if (_phase == RecordPhase.complete) {
      stateLabel = "COMPLETE";
      statusColor = AppColors.successGreen;
      detailMessage = "8 blinks detected! Correlated with Error Code 8. Routing to details...";
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: statusColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Blink Detection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(detailMessage, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar and counters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recording Progress", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text("${(_elapsedSeconds).toStringAsFixed(1)}s / 15.0s", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.dangerRed, AppColors.electricBlue],
                            stops: [0.0, progress],
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Blink Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.electricBlue, size: 12),
                        SizedBox(width: 4),
                        Text("Blinks", style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _AnimatedCounterDisplay(count: _blinksDetected),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounterDisplay extends StatelessWidget {
  final int count;

  const _AnimatedCounterDisplay({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        "$count",
        key: ValueKey<int>(count),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.electricBlue,
        ),
      ),
    );
  }
}

class _TargetCornerBrackets extends StatelessWidget {
  const _TargetCornerBrackets();

  @override
  Widget build(BuildContext context) {
    const double length = 16.0;
    const double thickness = 2.0;
    const Color color = AppColors.electricBlue;

    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: Container(width: length, height: thickness, color: color)),
        Positioned(top: 0, left: 0, child: Container(width: thickness, height: length, color: color)),
        Positioned(top: 0, right: 0, child: Container(width: length, height: thickness, color: color)),
        Positioned(top: 0, right: 0, child: Container(width: thickness, height: length, color: color)),
        Positioned(bottom: 0, left: 0, child: Container(width: length, height: thickness, color: color)),
        Positioned(bottom: 0, left: 0, child: Container(width: thickness, height: length, color: color)),
        Positioned(bottom: 0, right: 0, child: Container(width: length, height: thickness, color: color)),
        Positioned(bottom: 0, right: 0, child: Container(width: thickness, height: length, color: color)),
      ],
    );
  }
}

class _RecordingViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    // Sub-grid plotting lines
    const int lines = 12;
    for (int i = 1; i < lines; i++) {
      final double x = size.width * (i / lines);
      final double y = size.height * (i / lines);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }
  }

  @override
  bool shouldRepaint(covariant _RecordingViewfinderPainter oldDelegate) => false;
}

class _WaveformPainter extends CustomPainter {
  final List<double> history;
  final List<int> blinkTimings;

  _WaveformPainter({required this.history, required this.blinkTimings});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = AppColors.electricBlue.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / 150.0; // Fit 15 seconds (150 steps)
    
    path.moveTo(0, size.height - 4);
    fillPath.moveTo(0, size.height - 4);

    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      // High signal = y near 4, Low signal = y near height-4
      final double y = history[i] == 1.0 ? 6.0 : size.height - 6.0;

      if (i > 0) {
        // Draw square wave transitions
        final double prevY = history[i - 1] == 1.0 ? 6.0 : size.height - 6.0;
        
        path.lineTo(x, prevY);
        path.lineTo(x, y);

        fillPath.lineTo(x, prevY);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(history.length * stepX, size.height - 4);
    fillPath.lineTo(0, size.height - 4);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Draw little blink index number markers
    final paintMarker = Paint()
      ..color = AppColors.dangerRed
      ..style = PaintingStyle.fill;

    for (int idx = 0; idx < blinkTimings.length; idx++) {
      final int pos = blinkTimings[idx];
      final double mx = pos * stepX;
      
      canvas.drawCircle(Offset(mx, 6.0), 3.0, paintMarker);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
