import 'package:flutter/material.dart';

// 1. The Global State Manager
class SidebarProvider extends ChangeNotifier {
  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  void toggle() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }
}

// 2. The Sidebar Layout Wrapper
class CustomSidebar extends StatelessWidget {
  final Widget child;
  final SidebarProvider provider;

  const CustomSidebar({super.key, required this.child, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: provider.isExpanded ? 256 : 64, // Width transitions
          color: const Color(0xFF020817),
          child: Column(
            children: [
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

// 3. Reusable Menu Item (The 'SidebarMenuButton' equivalent)
class CustomSidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isExpanded;

  const CustomSidebarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}