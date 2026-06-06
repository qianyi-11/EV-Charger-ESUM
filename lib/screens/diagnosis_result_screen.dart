import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../models/detected_fault.dart';
import '../widgets/glass_container.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final String errorCode;

  const DiagnosisResultScreen({super.key, required this.errorCode});

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> with TickerProviderStateMixin {
  final DiagnosticState _globalState = DiagnosticState();

  double _animatedConfidence = 0.0;
  late final AnimationController _confidenceController;

  static const Color _cardBorderRed = Color(0x4DFF2D55);
  static const Color _subtitleCyan = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();

    final faults = _globalState.resolvedFaults(widget.errorCode);
    final rawConfidence = _globalState.scanConfidence > 0
        ? _globalState.scanConfidence
        : _defaultConfidenceForFaults(faults);
    final displayConfidence = DiagnosticState.normalizeDisplayConfidence(rawConfidence);

    _confidenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final Animation<double> curve =
        CurvedAnimation(parent: _confidenceController, curve: Curves.easeOutCubic);

    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confidenceController.forward();
      }
    });

    _confidenceController.addListener(() {
      setState(() {
        _animatedConfidence = curve.value * displayConfidence;
      });
    });
  }

  double _defaultConfidenceForFaults(List<DetectedFault> faults) {
    if (faults.isEmpty) return DiagnosticState.displayConfidenceDefault;
    final code = FaultCatalog.normalizeErrorCode(widget.errorCode);
    final info = _globalState.database[code] ?? _globalState.database[widget.errorCode];
    return info?.confidence ?? DiagnosticState.displayConfidenceDefault;
  }

  List<DetectedFault> get _faults => _globalState.resolvedFaults(widget.errorCode);

  int get _confidencePercent => (_animatedConfidence * 100).round();

  Color get _confidenceBarColor {
    final ratio = _animatedConfidence / DiagnosticState.displayConfidenceMax;
    if (ratio < 0.82) return AppColors.warningOrange;
    return const Color(0xFF00C853);
  }

  @override
  void dispose() {
    _confidenceController.dispose();
    super.dispose();
  }

  void _createTicket() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket request recorded. Support ticketing will be available in a future update.'),
        backgroundColor: AppColors.secondaryBg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faults = _faults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'AI Fault Diagnosis',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (faults.isEmpty)
                _buildEmptyCard()
              else
                ...faults.map(_buildFaultCard),
              const SizedBox(height: 16),
              _buildConfidenceCard(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _createTicket,
                icon: const Icon(Icons.confirmation_number_outlined, color: Colors.black),
                label: const Text(
                  'Create Ticket',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionGridButton(
                      title: 'Generate Report',
                      icon: Icons.file_copy_outlined,
                      onTap: () => Navigator.pushNamed(context, '/report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionGridButton(
                      title: 'Ask EVision AI',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => Navigator.pushNamed(context, '/assistant'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderColor: _cardBorderRed,
      child: const Text(
        'No fault details are available for this diagnosis yet.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFaultCard(DetectedFault fault) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderColor: _cardBorderRed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Confidence: $_confidencePercent%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              fault.faultType,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fault.faultDetail,
              style: const TextStyle(
                color: _subtitleCyan,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecommendedActionSection(fault.recommendedAction),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedActionSection(String action) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Action',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            action,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Inference Precision:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: _animatedConfidence,
                      backgroundColor: Colors.white12,
                      color: _confidenceBarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$_confidencePercent%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGridButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.electricBlue, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
