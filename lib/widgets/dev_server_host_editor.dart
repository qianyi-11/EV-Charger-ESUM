import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/server_connectivity_service.dart';
import '../theme/app_theme.dart';

/// IP host editor shared between Settings and the login-screen tester shortcut.
class DevServerHostEditor extends StatefulWidget {
  final bool compact;

  const DevServerHostEditor({super.key, this.compact = false});

  static Future<void> showHostDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBg,
        title: const Text(
          'Dev Server PC IP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SizedBox(
          width: double.maxFinite,
          child: DevServerHostEditor(compact: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.electricBlue)),
          ),
        ],
      ),
    );
  }

  @override
  State<DevServerHostEditor> createState() => _DevServerHostEditorState();
}

class _DevServerHostEditorState extends State<DevServerHostEditor> {
  final TextEditingController _serverHostController = TextEditingController();
  bool _serverTesting = false;
  String? _serverStatusMessage;

  @override
  void initState() {
    super.initState();
    _loadServerHost();
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

  @override
  void dispose() {
    _serverHostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compact) ...[
          Text(
            'Dev Server PC IP (same Wi‑Fi)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: adaptive.textPrimary),
          ),
          const SizedBox(height: 4),
        ],
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
            foregroundColor: Colors.white,
          ),
          child: _serverTesting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Save & Test Connection',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ],
    );
  }
}
