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
  late final PageController _commonIssuesController;
  int _commonIssuePage = 0;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _commonIssuesController = PageController(viewportFraction: 0.88);
  }

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
  void dispose() {
    _state.removeListener(_onStateChanged);
    _commonIssuesController.dispose();
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

                      Text(
                        'System Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
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
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                context: context,
                                title: "Accuracy",
                                value: "98.5%",
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                context: context,
                                title: "Latency",
                                value: "45ms",
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        'Common Issues',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildAnimatedEntrance(
                        delayIndex: 2,
                        child: _buildCommonIssuesCarousel(context),
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

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: adaptive.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.electricBlue.withValues(alpha: 0.32),
                  const Color(0xFF0C1A2E),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF6FF),
                  Color(0xFFDBEAFE),
                ],
              ),
        border: Border.all(
          color: adaptive.isDark
              ? AppColors.electricBlue.withValues(alpha: 0.55)
              : AppColors.electricBlue.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: adaptive.isDark
            ? adaptive.cardShadow
            : [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricBlue,
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Diagnosis',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: adaptive.isDark ? adaptive.textPrimary : AppColors.electricBlue,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-powered charger fault detection',
                  style: TextStyle(
                    fontSize: 15,
                    color: adaptive.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap to begin scan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricBlue.withValues(alpha: adaptive.isDark ? 0.9 : 1),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.electricBlue,
            size: 22,
          ),
        ],
      ),
    );

    return _InteractiveCard(
      onTap: () => Navigator.pushNamed(context, '/unified-detection'),
      child: adaptive.isDark
          ? PulsingGlow(
              glowColor: AppColors.electricBlue,
              maxBlurRadius: 36,
              minBlurRadius: 14,
              child: content,
            )
          : content,
    );
  }

  double _measureCommonIssuesCarouselHeight(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const scrollPadding = 40.0;
    final cardInnerWidth = (screenWidth - scrollPadding) * 0.88 - 4 - 28;

    double maxHeight = 0;
    for (final issue in _commonIssues) {
      var height = 28.0;

      final titlePainter = TextPainter(
        text: TextSpan(
          text: issue.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: issue.isNew ? cardInnerWidth - 48 : cardInnerWidth);
      height += titlePainter.height + 8;

      final bodyPainter = TextPainter(
        text: TextSpan(
          text: issue.description,
          style: const TextStyle(fontSize: 12, height: 1.45),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: cardInnerWidth);
      height += bodyPainter.height + 10 + 14;

      if (height > maxHeight) maxHeight = height;
    }

    return maxHeight.ceilToDouble() + 16;
  }

  Widget _buildCommonIssuesCarousel(BuildContext context) {
    final carouselHeight = _measureCommonIssuesCarouselHeight(context);

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _commonIssuesController,
            itemCount: _commonIssues.length,
            onPageChanged: (index) => setState(() => _commonIssuePage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == _commonIssues.length - 1 ? 0 : 6,
                ),
                child: _buildCommonIssueCard(context, _commonIssues[index], index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_commonIssues.length, (index) {
            final active = index == _commonIssuePage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.electricBlue : AppTheme.lightCardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommonIssueCard(BuildContext context, _CommonIssue issue, int index) {
    final adaptive = context.adaptive;

    return Container(
      decoration: BoxDecoration(
        color: adaptive.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adaptive.subtleBorder),
        boxShadow: adaptive.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, color: AppColors.dangerRed),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: adaptive.textSecondary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required String title,
    required String value,
  }) {
    final adaptive = context.adaptive;
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: adaptive.textSecondary,
            ),
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
