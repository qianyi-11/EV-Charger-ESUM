import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_orbs.dart';
import '../../widgets/glass_container.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final adminUrl = 'http://localhost:${ApiConfig.serverPort}/admin';

    return Scaffold(
      body: FloatingOrbsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AppColors.warningOrange),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Portal',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Manage customer support tickets',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dashboard_outlined, size: 48, color: AppColors.electricBlue),
                        const SizedBox(height: 16),
                        const Text(
                          'Open the admin dashboard in your browser',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'On your laptop:\n$adminUrl\n\n'
                          'Use the same admin email and password you registered with.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dangerRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
