import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Animated Background Particles
          const _ParticleBackground(),

          // 2. Dark Overlay to ensure text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // --- HEADER SECTION ---
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      children: [
                        // Pulsing Logo
                        Pulse(
                          infinite: true,
                          duration: const Duration(seconds: 2),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF00D4FF), Color(0xFF0066FF)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00D4FF,
                                  ).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF00D4FF,
                                  ).withOpacity(0.6),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Gradient Title Text
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                          ).createShader(bounds),
                          child: const Text(
                            "EVision AI",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        const Text(
                          "Smart EV Charger Diagnostic Assistant",
                          style: TextStyle(
                            color: Color(0xFF8B92A8),
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Animated Underline
                        Pulse(
                          infinite: true,
                          duration: const Duration(seconds: 2),
                          child: Container(
                            height: 4,
                            width: 128,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFFFF2D55)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // --- ACTION BUTTONS ---
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      children: [
                        _buildMenuButton(
                          context: context,
                          title: "Start Diagnosis",
                          icon: Icons.bolt,
                          route: '/unified-detection',
                        ),
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          context: context,
                          title: "View Reports",
                          icon: Icons.description_outlined,
                          route: '/report',
                        ),
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          context: context,
                          title: "AI Assistant",
                          icon: Icons.chat_bubble_outline,
                          route: '/assistant',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // --- SKIP LINK ---
                  FadeIn(
                    delay: const Duration(seconds: 1),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text(
                        "Skip to Dashboard →",
                        style: TextStyle(
                          color: Color(0xFF8B92A8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00D4FF), size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom widget that generates random glowing orbs in the background
/// to replicate the framer-motion particle effect.
class _ParticleBackground extends StatelessWidget {
  const _ParticleBackground();

  @override
  Widget build(BuildContext context) {
    final Random random = Random();

    return Stack(
      children: List.generate(20, (index) {
        // Generate random properties for each particle
        final double size = random.nextDouble() * 300 + 50;
        final double top =
            random.nextDouble() * MediaQuery.of(context).size.height;
        final double left =
            random.nextDouble() * MediaQuery.of(context).size.width;
        final int duration = random.nextInt(10) + 10;
        final bool isBlue = index % 2 == 0;

        final Color particleColor = isBlue
            ? const Color(0xFF00D4FF).withOpacity(0.1)
            : const Color(0xFFFF2D55).withOpacity(0.1);

        return Positioned(
          top: top - (size / 2),
          left: left - (size / 2),
          child: Pulse(
            infinite: true,
            duration: Duration(seconds: duration),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [particleColor, Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
