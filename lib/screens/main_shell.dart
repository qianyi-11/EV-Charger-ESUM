import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import 'home_screen.dart';
import 'my_ticket_screen.dart';
import 'assistant_chat_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';
import '../services/ticket_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final DiagnosticState _appState = DiagnosticState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      TicketService.instance.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;

    return Scaffold(
      backgroundColor: adaptive.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          MyTicketScreen(),
          AssistantChatScreen(embeddedInShell: true),
          ActivityScreen(),
          SettingsScreen(embeddedInShell: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        backgroundColor: adaptive.surface,
        indicatorColor: AppColors.electricBlue.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: adaptive.textSecondary),
            selectedIcon: const Icon(Icons.home, color: AppColors.electricBlue),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined, color: adaptive.textSecondary),
            selectedIcon: const Icon(Icons.confirmation_number, color: AppColors.electricBlue),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, color: adaptive.textSecondary),
            selectedIcon: const Icon(Icons.smart_toy, color: AppColors.electricBlue),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: adaptive.textSecondary),
            selectedIcon: const Icon(Icons.history, color: AppColors.electricBlue),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: adaptive.textSecondary),
            selectedIcon: const Icon(Icons.settings, color: AppColors.electricBlue),
            label: '',
          ),
        ],
      ),
    );
  }
}
