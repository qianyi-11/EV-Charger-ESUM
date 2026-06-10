import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'floating_orbs.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool centerContent;
  final Widget? topRightAction;

  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.centerContent = false,
    this.topRightAction,
  });

  Widget _buildContent(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!centerContent) const SizedBox(height: 12),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.electricBlue, Color(0xFF007A99)],
              ),
            ),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
        const SizedBox(height: 28),
        child,
        if (footer != null) ...[
          const SizedBox(height: 20),
          footer!,
        ],
      ],
    );

    if (!centerContent) return content;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [content],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingOrbsBackground(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: _buildContent(context),
                    ),
                  );
                },
              ),
              if (topRightAction != null)
                Positioned(
                  top: 8,
                  right: 16,
                  child: topRightAction!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
