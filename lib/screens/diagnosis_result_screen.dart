import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../models/detected_fault.dart';
import '../models/support_ticket.dart';
import 'new_ticket_screen.dart';

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

  static const Color _pageBackground = Color(0xFF050A18);
  static const Color _accentCyan = Color(0xFF00D1FF);
  static const Color _mutedText = Color(0xFF94A3B8);
  static const Color _sectionDivider = Color(0xFF1A2238);
  static const Color _cardSurface = Color(0xFF0C1224);

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

  @override
  void dispose() {
    _confidenceController.dispose();
    super.dispose();
  }

  void _createTicket() {
    final state = DiagnosticState();
    final prefill = TicketPrefill.fromDiagnosis(
      widget.errorCode,
      scanFindings: state.scanFindings,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewTicketScreen(
          prefill: TicketPrefill(
            faultyComponent: prefill.faultyComponent,
            describeIssue: prefill.describeIssue,
            chargerSerialNumber: state.serialNumber.isNotEmpty ? state.serialNumber : null,
            sourceErrorCode: widget.errorCode,
            details: prefill.details,
          ),
        ),
      ),
    );
  }

  String _headlineTitle(DetectedFault fault) {
    final detail = fault.faultDetail;
    final indicating = RegExp(r'indicating an? (.+?)\.?$', caseSensitive: false).firstMatch(detail);
    if (indicating != null) return indicating.group(1)!.trim();
    if (detail.length <= 48) return detail;
    final dot = detail.indexOf('. ');
    if (dot > 0) return detail.substring(0, dot);
    return fault.faultType;
  }

  String? _headlineSubtitle(DetectedFault fault) {
    if (fault.faultDetail.toLowerCase().startsWith('wrong component specifications')) {
      return null;
    }
    final title = _headlineTitle(fault);
    if (fault.faultDetail.trim() == title.trim()) return null;
    return fault.faultDetail;
  }

  List<String> _splitIntoBullets(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final faults = _faults;
    final primaryFault = faults.isNotEmpty ? faults.first : null;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Result',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (primaryFault == null)
                _buildEmptyState()
              else ...[
                _buildHeaderSection(primaryFault),
                const SizedBox(height: 20),
                _buildConfidenceCard(),
                const SizedBox(height: 24),
                _buildDiagnosticExplanationSection(faults),
                const SizedBox(height: 24),
                _buildRecommendedActionsSection(faults),
              ],
              const SizedBox(height: 28),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'No fault details are available for this diagnosis yet.',
        style: TextStyle(
          color: _mutedText,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeaderSection(DetectedFault fault) {
    final subtitle = _headlineSubtitle(fault);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _accentCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentCyan.withValues(alpha: 0.35)),
          ),
          child: Text(
            fault.faultType,
            style: const TextStyle(
              color: _accentCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _headlineTitle(fault),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfidenceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Confidence Score',
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_confidencePercent%',
                style: const TextStyle(
                  color: _accentCyan,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GradientConfidenceBar(progress: _animatedConfidence),
        ],
      ),
    );
  }

  Widget _buildDiagnosticExplanationSection(List<DetectedFault> faults) {
    final List<String> bullets;
    if (widget.errorCode.toLowerCase() == 'protection-issue' &&
        _globalState.scanFindings.isNotEmpty) {
      bullets = _globalState.scanFindings
          .map(FaultCatalog.simplifySpecFinding)
          .toSet()
          .toList();
    } else {
      bullets = faults
          .expand((fault) => _splitIntoBullets(fault.faultDetail))
          .toSet()
          .toList();
    }

    return _buildSectionCard(
      icon: Icons.bolt_rounded,
      iconColor: _accentCyan,
      title: 'Diagnostic Explanation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis findings:',
            style: TextStyle(
              color: _accentCyan,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...bullets.map((item) => _buildBulletItem(item)),
        ],
      ),
    );
  }

  Widget _buildRecommendedActionsSection(List<DetectedFault> faults) {
    final bullets = faults
        .expand((fault) => _splitIntoBullets(fault.recommendedAction))
        .toSet()
        .toList();

    return _buildSectionCard(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.warningOrange,
      title: 'Recommended Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bullets.map((item) => _buildBulletItem(item)).toList(),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _sectionDivider),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: const BoxDecoration(
              color: _accentCyan,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
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
    );
  }
}

class _GradientConfidenceBar extends StatelessWidget {
  final double progress;

  const _GradientConfidenceBar({required this.progress});

  static const _gradient = LinearGradient(
    colors: [
      Color(0xFFFF3B30),
      Color(0xFFFF9500),
      Color(0xFFFFCC00),
      Color(0xFF34C759),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white.withValues(alpha: 0.08)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(gradient: _gradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
