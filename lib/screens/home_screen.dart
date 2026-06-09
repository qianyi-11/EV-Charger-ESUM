import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/floating_orbs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DiagnosticState _state = DiagnosticState();

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
                          "Dashboard",
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
                        child: _buildQuickActionCard(
                          context: context,
                          title: "Start Diagnosis",
                          subtitle: "AI-powered charger fault detection",
                          icon: Icons.camera_alt,
                          color: AppColors.electricBlue,
                          onTap: () => Navigator.pushNamed(context, "/unified-detection"),
                        ),
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

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final adaptive = context.adaptive;
    return _InteractiveCard(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        borderColor: color.withOpacity(0.2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: adaptive.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: adaptive.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: adaptive.textSecondary, size: 16),
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
