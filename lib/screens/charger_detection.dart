import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum DetectionPhase { scanning, chargerFound, searchingLight, redLightFound, noLightFound }

class ChargerDetectionScreen extends StatefulWidget {
  const ChargerDetectionScreen({super.key});

  @override
  State<ChargerDetectionScreen> createState() => _ChargerDetectionScreenState();
}

class _ChargerDetectionScreenState extends State<ChargerDetectionScreen> {
  DetectionPhase _phase = DetectionPhase.scanning;
  
  @override
  void initState() {
    super.initState();
    _startDetectionTimeline();
  }

  void _startDetectionTimeline() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _phase = DetectionPhase.chargerFound);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _phase = DetectionPhase.searchingLight);
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _phase = DetectionPhase.redLightFound);
    
    // Redirect logic
    await Future.delayed(const Duration(seconds: 1));
    // Use your router to navigate
    // Navigator.pushNamed(context, '/recording');
  }

  Color getStatusColor() {
    switch (_phase) {
      case DetectionPhase.redLightFound: return Colors.redAccent;
      case DetectionPhase.noLightFound: return Colors.orange;
      default: return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background UI (Same as BlinkRecording)
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1a1f35), Colors.black]))),
          
          // Center Scanner UI
          Center(
            child: Pulse(
              infinite: true,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: getStatusColor(), width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: _phase == DetectionPhase.searchingLight 
                    ? SpinPerfect(infinite: true, child: const Icon(Icons.circle_outlined, color: Colors.cyan, size: 200))
                    : const Icon(Icons.qr_code_scanner, color: Colors.white24, size: 100),
                ),
              ),
            ),
          ),

          // Status Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Text("Phase: ${_phase.name.toUpperCase()}", style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(color: getStatusColor()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}