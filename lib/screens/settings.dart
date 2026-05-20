import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  bool _darkMode = true;
  bool _notifications = true;

  final List<Map<String, String>> _languages = [
    {"code": "en", "name": "English", "nativeName": "English"},
    {"code": "ms", "name": "Malay", "nativeName": "Bahasa Melayu"},
    {"code": "zh", "name": "Chinese", "nativeName": "中文"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = AppLocalizations.getLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Back to Dashboard",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          FadeInDown(
            child: const Text(
              "Settings",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // --- LANGUAGE SECTION ---
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Language", Icons.language, Colors.cyan),
                const SizedBox(height: 16),
                ..._languages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lang = entry.value;
                  return FadeInLeft(
                    delay: Duration(milliseconds: 200 + (index * 100)),
                    child: _buildLanguageOption(lang),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- APPEARANCE SECTION ---
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Appearance", Icons.dark_mode, Colors.cyan),
                const SizedBox(height: 16),
                _buildToggleCard(
                  title: "Dark Mode",
                  subtitle: "System default theme",
                  icon: Icons.dark_mode,
                  iconColor: Colors.cyan,
                  value: _darkMode,
                  onChanged: () => setState(() => _darkMode = !_darkMode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- NOTIFICATIONS SECTION ---
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  "Notifications",
                  Icons.notifications,
                  Colors.cyan,
                ),
                const SizedBox(height: 16),
                _buildToggleCard(
                  title: "Push Notifications",
                  subtitle: "Get alerts for critical errors",
                  icon: Icons.notifications,
                  iconColor: Colors.cyan,
                  value: _notifications,
                  onChanged: () =>
                      setState(() => _notifications = !_notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- SYSTEM INFORMATION SECTION ---
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  "System Information",
                  Icons.memory,
                  Colors.cyan,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: "AI Model Version",
                  subtitle: "EVision AI v2.4.1",
                  icon: Icons.memory,
                  iconColor: const Color(0xFF00FF88),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Latest",
                      style: TextStyle(color: Color(0xFF00FF88), fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: "Offline Sync",
                  subtitle: "Enabled for diagnostics",
                  icon: Icons.wifi,
                  iconColor: const Color(0xFF00FF88),
                  trailing: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF88),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Active",
                        style: TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- LINKS SECTION ---
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Column(
              children: [
                _buildLinkButton("About EVision AI"),
                const SizedBox(height: 12),
                _buildLinkButton("Privacy Policy"),
                const SizedBox(height: 12),
                _buildLinkButton("Terms of Service"),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // --- FOOTER ---
          FadeIn(
            delay: const Duration(milliseconds: 800),
            child: const Column(
              children: [
                Text(
                  "EVision AI Mobile v1.0.0",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  "© 2026 Smart EV Infrastructure",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(Map<String, String> lang) {
    bool isSelected = _selectedLanguage == lang["code"];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() => _selectedLanguage = lang["code"]!);
          AppLocalizations.setLanguage(lang["code"]!);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.cyan.withOpacity(0.1)
                : const Color(0xFF0F172A),
            border: Border.all(
              color: isSelected
                  ? Colors.cyan.withOpacity(0.3)
                  : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang["nativeName"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        lang["name"]!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isSelected)
                FadeIn(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          // Custom Animated Toggle Switch
          GestureDetector(
            onTap: onChanged,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: 56,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value ? Colors.cyan : const Color(0xFF1E2436),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildLinkButton(String title) {
    return InkWell(
      onTap: () => _openLink(title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _openLink(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF07101B),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This is placeholder content. Replace with the real content or webview for the selected document.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  'Document: $title',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
