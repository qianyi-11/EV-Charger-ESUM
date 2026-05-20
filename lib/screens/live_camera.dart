import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum DetectionState { initializing, scanning, chargerDetected, ledDetected, counting, complete }

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  DetectionState _state = DetectionState.initializing;
  int _flashCount = 0;
  double _confidence = 0;
  Timer? _flashTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startDetectionSequence();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _flashTimer?.cancel();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) setState(fn);
  }

  void _startDetectionSequence() async {
    await Future.delayed(const Duration(seconds: 1));
    _safeSetState(() => _state = DetectionState.scanning);

    await Future.delayed(const Duration(seconds: 2));
    _safeSetState(() => _state = DetectionState.chargerDetected);

    await Future.delayed(const Duration(seconds: 2));
    _safeSetState(() => _state = DetectionState.ledDetected);

    await Future.delayed(const Duration(seconds: 2));
    _safeSetState(() => _state = DetectionState.counting);

    _flashTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_flashCount >= 8) {
        timer.cancel();
        _safeSetState(() => _state = DetectionState.complete);
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // Navigator.pushNamed(context, '/diagnosis/8');
          }
        });
        return;
      }
      
      _safeSetState(() {
        _flashCount++;
        _confidence = (_flashCount * 12).clamp(0, 96).toDouble();
      });
    });
  }

  String _getGuidanceText() {
    switch (_state) {
      case DetectionState.initializing: return "Initializing camera...";
      case DetectionState.scanning: return "Point camera at EV charger";
      case DetectionState.chargerDetected: return "Charger detected - Hold steady";
      case DetectionState.ledDetected: return "LED indicator found";
      case DetectionState.counting: return "Counting flashes... $_flashCount";
      case DetectionState.complete: return "Analysis complete!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1a1f35), Colors.black]))),
          
          // Back Button
          Positioned(
            top: 50, left: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white10),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Top Guidance Pill
          Positioned(
            top: 100, left: 0, right: 0,
            child: FadeInDown(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.8), borderRadius: BorderRadius.circular(30)),
                  child: Text(_getGuidanceText(), style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),

          // Center Scanner Box
          Center(
            child: Pulse(
              infinite: true,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyan, width: 2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 30)],
                ),
                child: Center(
                  child: SpinPerfect(
                    infinite: true,
                    duration: const Duration(seconds: 3),
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2, style: BorderStyle.solid), // Note: Flutter doesn't have native dashed borders without custom paint, so using solid with opacity
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Status Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("AI Detection Status", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(children: [
                          Icon(Icons.circle, color: Color(0xFF00FF88), size: 10),
                          SizedBox(width: 6),
                          Text("ACTIVE", style: TextStyle(color: Color(0xFF00FF88), fontSize: 12)),
                        ])
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    _buildStatusRow("Charger detected", _state.index >= DetectionState.chargerDetected.index),
                    _buildStatusRow("LED indicator detected", _state.index >= DetectionState.ledDetected.index),
                    _buildStatusRow("Counting flashes...", _state.index >= DetectionState.counting.index, isSpinning: _state == DetectionState.counting),
                    
                    if (_state == DetectionState.complete)
                      FadeIn(
                        child: const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Row(children: [
                            Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
                            SizedBox(width: 12),
                            Text("8 flashes identified - Error Code 8", style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                      ),

                    if (_confidence > 0) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Confidence", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Text("${_confidence.toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _confidence / 100, backgroundColor: Colors.white10, color: Colors.cyan),
                    ],

                    const SizedBox(height: 20),
                    
                    // Flash Visualizer (Replaces the SVG)
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF1E2436), borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _state.index >= DetectionState.counting.index 
                        ? Row(
                            children: List.generate(_flashCount, (index) => FadeIn(
                                child: Container(
                                  width: 30, height: 20,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(color: const Color(0xFFFF2D55), borderRadius: BorderRadius.circular(4)),
                                ),
                              )),
                          )
                        : const Center(child: LinearProgressIndicator(color: Colors.cyan)),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusRow(String text, bool isActive, {bool isSpinning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (isActive && !isSpinning)
            const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20)
          else if (isSpinning)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.cyan, strokeWidth: 2))
          else
            const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white54)),
        ],
      ),
    );
  }
}