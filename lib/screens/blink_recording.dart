import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class BlinkRecordingScreen extends StatefulWidget {
  const BlinkRecordingScreen({super.key});

  @override
  State<BlinkRecordingScreen> createState() => _BlinkRecordingScreenState();
}

class _BlinkRecordingScreenState extends State<BlinkRecordingScreen> with SingleTickerProviderStateMixin {
  double recordingTime = 0.0;
  int blinkCount = 0;
  String status = "Preparing...";
  
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15));
    _startRecordingSequence();
  }

  void _startRecordingSequence() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => status = "Hold steady - Recording blink pattern");
    _controller.forward();
    
    // Simulate blink logic
    _controller.addListener(() {
      setState(() {
        recordingTime = _controller.value * 15;
        // Logic to trigger blink increments
        if (recordingTime > (blinkCount + 1) * 1.5) {
          blinkCount++;
        }
      });
      if (_controller.isCompleted) _finishRecording();
    });
  }

  void _finishRecording() {
    setState(() => status = "Processing...");
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => status = "Analysis complete!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient Animation
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1a1f35), Colors.black]))),
          
          // Camera Frame & Blink Visualization
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.cyan, width: 4), borderRadius: BorderRadius.circular(24)),
              child: Center(
                child: FadeIn(child: const Icon(Icons.center_focus_weak, color: Colors.cyan, size: 48)),
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: (recordingTime / 15).clamp(0, 1),
                    progressColor: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  // Blink Count Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Blinks Detected", style: TextStyle(color: Colors.white)),
                        Text("$blinkCount", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}