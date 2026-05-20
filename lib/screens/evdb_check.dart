import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum CheckPhase { instruction, detecting, analyzing, resultOk, resultMissing, resultWrongSpec }

class EVDBCheckScreen extends StatefulWidget {
  const EVDBCheckScreen({super.key});

  @override
  State<EVDBCheckScreen> createState() => _EVDBCheckScreenState();
}

class _EVDBCheckScreenState extends State<EVDBCheckScreen> {
  CheckPhase _phase = CheckPhase.instruction;
  
  // Progress tracker for analysis steps
  Map<String, bool> steps = {
    "evdb_detected": false,
    "mcb_check": false,
    "rccb_check": false,
    "specs_check": false,
    "complete": false,
  };

  void _startDetection() {
    setState(() => _phase = CheckPhase.detecting);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _phase = CheckPhase.analyzing);
      _runAnalysis();
    });
  }

  void _runAnalysis() async {
    for (var key in steps.keys) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => steps[key] = true);
    }
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _phase = CheckPhase.resultMissing); // Simulate a result
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_phase == CheckPhase.instruction) _buildInstructionView(),
            if (_phase == CheckPhase.detecting) _buildDetectingView(),
            if (_phase == CheckPhase.analyzing) _buildAnalyzingView(),
            if (_phase == CheckPhase.resultMissing) _buildResultView(isMissing: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionView() => FadeIn(
    child: Column(children: [
      const Text("EVDB Inspection", style: TextStyle(color: Colors.white, fontSize: 24)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _startDetection,
        child: const Text("Start EVDB Detection"),
      )
    ]),
  );

  Widget _buildAnalyzingView() => Expanded(
    child: Column(
      children: steps.entries.map((e) => FadeInLeft(
        child: ListTile(
          leading: Icon(e.value ? Icons.check_circle : Icons.circle_outlined, color: e.value ? Colors.green : Colors.grey),
          title: Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.white)),
        ),
      )).toList(),
    ),
  );

  Widget _buildResultView({required bool isMissing}) => FadeInUp(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 64),
        Text(isMissing ? "Missing Component" : "Wrong Specification", style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {}, child: const Text("View Full Diagnosis"))
      ]),
    ),
  );

  Widget _buildDetectingView() => const Center(
    child: CircularProgressIndicator(color: Colors.cyan),
  );
}