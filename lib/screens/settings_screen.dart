import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("App Settings"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Language Selection Section
              _buildSectionHeader(Icons.public, "Language Selection"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLanguageCard("English", "English", _state.language == "English"),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLanguageCard("Bahasa Melayu", "Melayu", _state.language == "Bahasa Melayu"),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLanguageCard("中文", "Chinese", _state.language == "Chinese"),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 2. Appearance Section
              _buildSectionHeader(Icons.dark_mode_outlined, "Appearance"),
              const SizedBox(height: 12),
              _buildToggleSettingsCard(
                title: "Dark Mode",
                subtitle: "System default theme active",
                value: _state.darkTheme,
                onChanged: _state.toggleDarkTheme,
                iconColor: AppColors.electricBlue,
              ),
              const SizedBox(height: 28),

              // 3. Notifications Section
              _buildSectionHeader(Icons.notifications_none_outlined, "Notifications"),
              const SizedBox(height: 12),
              _buildToggleSettingsCard(
                title: "Push Notifications",
                subtitle: "Get alerts for critical errors",
                value: _state.pushNotifications,
                onChanged: _state.toggleNotifications,
                iconColor: AppColors.electricBlue,
              ),
              const SizedBox(height: 28),

              // 4. System Information Section
              _buildSectionHeader(Icons.memory, "System Information"),
              const SizedBox(height: 12),
              _buildSystemInfoCard(
                icon: Icons.developer_board,
                iconColor: AppColors.successGreen,
                title: "AI Model Version",
                subtitle: "EVision AI v2.4.1",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Latest", style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              _buildSystemInfoCard(
                icon: Icons.wifi,
                iconColor: AppColors.successGreen,
                title: "Offline Sync",
                subtitle: "Enabled for diagnostics",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text("Active", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 5. App Information Section
              _buildSectionHeader(Icons.info_outline, "App Information"),
              const SizedBox(height: 12),
              _buildNavigationLinkCard("About EVision AI"),
              const SizedBox(height: 8),
              _buildNavigationLinkCard("Privacy Policy"),
              const SizedBox(height: 8),
              _buildNavigationLinkCard("Terms of Service"),
              const SizedBox(height: 36),

              // 6. Footer Info
              const Center(
                child: Column(
                  children: [
                    Text(
                      "Version: EVision AI Mobile v1.0.0",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "© 2026 Smart EV Infrastructure",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.electricBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(String display, String code, bool isSelected) {
    return GestureDetector(
      onTap: () => _state.changeLanguage(display),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          borderColor: isSelected ? AppColors.electricBlue : AppColors.glassBorder,
          bgColor: isSelected ? AppColors.electricBlue.withOpacity(0.08) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                display,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.electricBlue, size: 16)
              else
                Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.08), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSettingsCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.electricBlue,
            activeTrackColor: AppColors.electricBlue.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildNavigationLinkCard(String title) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loading $title document... secure connection established.")),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
