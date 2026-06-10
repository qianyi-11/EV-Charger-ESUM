import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/floating_orbs.dart';
import '../widgets/pulsing_glow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _CommonIssue {
  final String title;
  final String description;
  final String date;
  final bool isNew;

  const _CommonIssue({
    required this.title,
    required this.description,
    required this.date,
    this.isNew = false,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  final DiagnosticState _state = DiagnosticState();
  final Set<int> _expandedIssues = {};

  static const List<_CommonIssue> _commonIssues = [
    _CommonIssue(
      title: 'Low Charging Speed',
      description:
          'Charging speed may be lower than expected due to battery temperature, vehicle charging limitations, grid power restrictions, or charger settings. In some cases, the vehicle intentionally reduces charging power to protect battery health. Lower charging speeds are not always indicative of a charger malfunction.',
      date: '2026-02-18',
      isNew: true,
    ),
    _CommonIssue(
      title: 'Charging Cable Damaged',
      description:
          'Charging cables are exposed to frequent handling and environmental conditions. Physical damage such as cuts, cracks, bent pins, or worn insulation can affect charging performance and create safety risks. Damaged cables should be inspected and replaced as necessary.',
      date: '2026-02-17',
      isNew: true,
    ),
    _CommonIssue(
      title: 'Connector Not Detected',
      description:
          'The charging connector must be securely inserted before a charging session can begin. Dirt, debris, damaged contacts, or incomplete insertion may prevent the charger from detecting the connector. Regular inspection and proper handling of charging equipment can reduce connection issues.',
      date: '2026-02-16',
      isNew: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;

    return Scaffold(
      backgroundColor: adaptive.background,
      body: FloatingOrbsBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Home",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Welcome, ${_state.username}",
                          style: TextStyle(color: adaptive.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Dashboard Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      _buildAnimatedEntrance(
                        delayIndex: 0,
                        child: _buildStartDiagnosisHero(context),
                      ),

                      const SizedBox(height: 28),

                      // System Status Section
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: AppColors.electricBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "System Status",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      _buildAnimatedEntrance(
                        delayIndex: 1,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatusCard(
                                context: context,
                                title: "AI Model",
                                value: "v2.4.1",
                                indicatorColor: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                context: context,
                                title: "Accuracy",
                                value: "98.5%",
                                indicatorColor: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                context: context,
                                title: "Latency",
                                value: "45ms",
                                indicatorColor: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Icon(Icons.report_problem_outlined, color: AppColors.dangerRed, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Common Issues',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildAnimatedEntrance(
                        delayIndex: 2,
                        child: Column(
                          children: [
                            for (var i = 0; i < _commonIssues.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _buildCommonIssueCard(context, _commonIssues[i], i),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartDiagnosisHero(BuildContext context) {
    final adaptive = context.adaptive;

    return _InteractiveCard(
      onTap: () => Navigator.pushNamed(context, '/unified-detection'),
      child: PulsingGlow(
        glowColor: AppColors.electricBlue,
        maxBlurRadius: 36,
        minBlurRadius: 14,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.electricBlue.withValues(alpha: adaptive.isDark ? 0.28 : 0.18),
                adaptive.isDark
                    ? const Color(0xFF0C1A2E)
                    : AppColors.electricBlue.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: AppColors.electricBlue.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.22),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.electricBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Diagnosis',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: adaptive.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered charger fault detection',
                      style: TextStyle(
                        fontSize: 13,
                        color: adaptive.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: adaptive.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleIssueExpanded(int index) {
    setState(() {
      if (_expandedIssues.contains(index)) {
        _expandedIssues.remove(index);
      } else {
        _expandedIssues.add(index);
      }
    });
  }

  Widget _buildCommonIssueCard(BuildContext context, _CommonIssue issue, int index) {
    final adaptive = context.adaptive;
    final expanded = _expandedIssues.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: adaptive.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: adaptive.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.dangerRed),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.dangerRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  issue.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: adaptive.textPrimary,
                                  ),
                                ),
                              ),
                              if (issue.isNew) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _toggleIssueExpanded(index),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    issue.description,
                                    maxLines: expanded ? null : 3,
                                    overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.45,
                                      color: adaptive.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  expanded ? 'Tap to show less' : 'Tap to read more',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.electricBlue.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            issue.date,
                            style: TextStyle(
                              fontSize: 11,
                              color: adaptive.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color indicatorColor,
  }) {
    final adaptive = context.adaptive;
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: adaptive.textSecondary,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withOpacity(0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: adaptive.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedEntrance({required int delayIndex, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delayIndex * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, val, childWidget) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - val)),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveCard({required this.child, required this.onTap});

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _scale = 1.02),
      onExit: (_) => setState(() => _scale = 1.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.98),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: AnimatedTransformScale(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedTransformScale extends StatelessWidget {
  final double scale;
  final Widget child;

  const AnimatedTransformScale({
    super.key,
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      transform: Matrix4.identity()..scale(scale),
      transformAlignment: Alignment.center,
      child: child,
    );
  }
}
