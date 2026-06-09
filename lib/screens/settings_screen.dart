import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../services/server_connectivity_service.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool embeddedInShell;

  const SettingsScreen({super.key, this.embeddedInShell = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DiagnosticState _state = DiagnosticState();
  final TextEditingController _serverHostController = TextEditingController();
  bool _serverTesting = false;
  String? _serverStatusMessage;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    AuthService.instance.addListener(_onAuthChanged);
    _refreshUsername();
    _loadServerHost();
  }

  Future<void> _refreshUsername() async {
    final profile = AuthService.instance.profile;
    if (profile != null) {
      await _state.setUsername(profile.displayName);
    } else {
      await _state.loadUserProfile();
    }
    if (mounted) setState(() {});
  }

  void _onAuthChanged() {
    _refreshUsername();
  }

  Future<void> _loadServerHost() async {
    final host = await ServerConnectivityService.instance.getSavedHost() ??
        (ApiConfig.buildTimeHost.isNotEmpty
            ? ApiConfig.buildTimeHost
            : ApiConfig.defaultDevServerHost);
    if (!mounted) return;
    _serverHostController.text = host;
    setState(() {});
  }

  Future<void> _saveAndTestServer() async {
    final host = _serverHostController.text.trim();
    if (host.isEmpty) {
      setState(() => _serverStatusMessage = 'Enter your PC\'s Wi‑Fi IP address.');
      return;
    }

    setState(() {
      _serverTesting = true;
      _serverStatusMessage = 'Testing connection...';
    });

    final ok = await ServerConnectivityService.instance.testHost(host);
    if (ok) {
      await ServerConnectivityService.instance.saveHost(host);
      if (!mounted) return;
      setState(() {
        _serverStatusMessage = 'Connected to $host:${ApiConfig.serverPort}';
      });
    } else if (mounted) {
      setState(() {
        _serverStatusMessage =
            'Cannot reach server at $host:${ApiConfig.serverPort}. Start `npm start` in /server on your PC.';
      });
    }

    if (mounted) {
      setState(() => _serverTesting = false);
    }
  }

  Future<void> _logout() async {
    _state.logout();
    await AuthService.instance.signOut();
    await TicketService.instance.load();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    AuthService.instance.removeListener(_onAuthChanged);
    _serverHostController.dispose();
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
      appBar: widget.embeddedInShell
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text('Settings', style: TextStyle(color: adaptive.textPrimary)),
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Settings', style: TextStyle(color: adaptive.textPrimary)),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.dns_outlined, 'Dev Server'),
              const SizedBox(height: 12),
              _buildDevServerCard(),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.notifications_none_outlined, 'Notifications'),
              const SizedBox(height: 12),
              _buildToggleCard(
                title: 'Push Notifications',
                subtitle: 'Alerts for critical diagnosis results',
                value: _state.pushNotifications,
                onChanged: (v) => _state.toggleNotifications(newValue: v),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.dark_mode_outlined, 'Appearance'),
              const SizedBox(height: 12),
              _buildToggleCard(
                title: 'Dark Mode',
                subtitle: _state.darkTheme ? 'Dark theme enabled' : 'Light theme enabled',
                value: _state.darkTheme,
                onChanged: (v) => _state.toggleDarkTheme(newValue: v),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.info_outline, 'About'),
              const SizedBox(height: 12),
              _buildLinkCard('About EVision', () => _showInfoDialog(
                'About EVision',
                'EVision AI is a smart EV charger diagnostic assistant. '
                'It uses machine vision and AI to identify charger faults, '
                'guide safe troubleshooting, and route issues to support.',
              )),
              const SizedBox(height: 8),
              _buildLinkCard('Terms & Conditions', () => _showInfoDialog(
                'Terms & Conditions',
                'By using EVision AI you agree to follow safe electrical practices. '
                'Do not open distribution boards or modify wiring without qualified personnel. '
                'Diagnostic results are advisory and require professional verification for repairs.',
              )),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _logout,
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
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'EVision AI Mobile v1.0.0',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final adaptive = context.adaptive;
    final initial = _state.username.isNotEmpty ? _state.username[0].toUpperCase() : 'E';

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.electricBlue.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.electricBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Text(
              _state.username,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: adaptive.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevServerCard() {
    final adaptive = context.adaptive;
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dev Server PC IP (same Wi‑Fi)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: adaptive.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Used for AI chat and vision APIs on your development PC.',
            style: TextStyle(fontSize: 11, color: adaptive.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverHostController,
            style: TextStyle(color: adaptive.textPrimary),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: ApiConfig.defaultDevServerHost,
              hintStyle: TextStyle(color: adaptive.textSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: adaptive.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (_serverStatusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _serverStatusMessage!,
              style: TextStyle(
                fontSize: 11,
                color: _serverStatusMessage!.startsWith('Connected')
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _serverTesting ? null : _saveAndTestServer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.black,
            ),
            child: _serverTesting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Save & Test Connection'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBg,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.electricBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final adaptive = context.adaptive;
    return Row(
      children: [
        Icon(icon, color: AppColors.electricBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: adaptive.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final adaptive = context.adaptive;
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: adaptive.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, color: adaptive.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.electricBlue,
            activeTrackColor: AppColors.electricBlue.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(String title, VoidCallback onTap) {
    final adaptive = context.adaptive;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 13, color: adaptive.textPrimary, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.chevron_right, color: adaptive.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
