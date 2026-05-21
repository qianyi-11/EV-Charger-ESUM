import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_orbs.dart';
import '../widgets/glass_container.dart';
import '../widgets/pulsing_glow.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingOrbsBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),
              
              // Top Logo & Identity
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, val, child) {
                  return Transform.translate(
                    offset: Offset(0, -50 * (1 - val)),
                    child: Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing Logo Box
                          PulsingGlow(
                            glowColor: AppColors.electricBlue,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [AppColors.electricBlue, Color(0xFF007A99)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.flash_on,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Gradient Title
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [AppColors.electricBlue, AppColors.successGreen],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              "EVision AI",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          const Text(
                            "Smart EV Charger Diagnostic Assistant",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Animated divider
                          Container(
                            width: 100,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.electricBlue.withOpacity(0.0),
                                  AppColors.electricBlue,
                                  AppColors.electricBlue.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Bottom Actions
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, val, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - val)),
                    child: Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Button 1: Start Diagnosis
                            _buildGlassButton(
                              context,
                              title: "Start Diagnosis",
                              icon: Icons.camera_alt,
                              color: AppColors.electricBlue,
                              onTap: () => Navigator.pushNamed(context, "/unified-detection"),
                            ),
                            const SizedBox(height: 16),

                            // Rows for Report & AI Assistant
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGlassButton(
                                    context,
                                    title: "AI Assistant",
                                    icon: Icons.chat_bubble_outline,
                                    color: AppColors.successGreen,
                                    onTap: () => Navigator.pushNamed(context, "/assistant"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGlassButton(
                                    context,
                                    title: "View Reports",
                                    icon: Icons.file_present,
                                    color: AppColors.warningOrange,
                                    onTap: () => Navigator.pushNamed(context, "/report"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Skip Dashboard Link
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, "/home"),
                              child: const MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  "Skip to Dashboard →",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          borderColor: color.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
