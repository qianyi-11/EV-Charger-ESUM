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
    return Scaffold(
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
                        const Text(
                          "Welcome to EVision AI",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    _buildIconButton(
                      icon: Icons.settings,
                      onTap: () => Navigator.pushNamed(context, "/settings"),
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

                      // Quick Action Cards (3-column grid)
                      _buildAnimatedEntrance(
                        delayIndex: 0,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                title: "Start Diagnosis",
                                subtitle: "AI Detection",
                                icon: Icons.camera_alt,
                                color: AppColors.electricBlue,
                                onTap: () => Navigator.pushNamed(context, "/unified-detection"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickActionCard(
                                title: "AI Assistant",
                                subtitle: "Expert Guide",
                                icon: Icons.chat_bubble,
                                color: AppColors.successGreen,
                                onTap: () => Navigator.pushNamed(context, "/assistant"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickActionCard(
                                title: "Reports",
                                subtitle: "Past History",
                                icon: Icons.file_copy,
                                color: AppColors.warningOrange,
                                onTap: () => Navigator.pushNamed(context, "/report"),
                              ),
                            ),
                          ],
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
                                title: "AI Model",
                                value: "v2.4.1",
                                indicatorColor: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                title: "Accuracy",
                                value: "98.5%",
                                indicatorColor: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                title: "Latency",
                                value: "45ms",
                                indicatorColor: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Recent Activity Section
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off, color: AppColors.electricBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Recent Activity",
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
                        child: _state.recentActivity.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    "No diagnoses performed yet.",
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _state.recentActivity.length,
                                itemBuilder: (context, index) {
                                  final item = _state.recentActivity[index];
                                  return _buildActivityItem(
                                    description: item["description"],
                                    timestamp: item["timestamp"],
                                    status: item["status"],
                                    code: item["code"],
                                  );
                                },
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

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _InteractiveCard(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        borderColor: color.withOpacity(0.2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required Color indicatorColor,
  }) {
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String description,
    required String timestamp,
    required String status,
    required String code,
  }) {
    Color badgeColor = AppColors.successGreen;
    if (status == "critical") badgeColor = AppColors.dangerRed;
    if (status == "warning") badgeColor = AppColors.warningOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _InteractiveCard(
        onTap: () => Navigator.pushNamed(context, "/diagnosis/$code"),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Activity Status Pill
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withOpacity(0.2)),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
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
