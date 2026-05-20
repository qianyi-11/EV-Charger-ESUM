import 'package:flutter/material.dart';

/// The main shell of the Card
class CustomCard extends StatelessWidget {
  final Widget child;

  const CustomCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Matches Tailwind bg-card
        borderRadius: BorderRadius.circular(12.0), // rounded-xl
        border: Border.all(color: Colors.white12), // border
      ),
      child: child,
    );
  }
}

/// The Header, which handles Titles, Descriptions, and top-right Actions
class CustomCardHeader extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? action;

  const CustomCardHeader({
    super.key,
    this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8), // px-6 pt-6
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      height: 1.1, // leading-none
                    ),
                  ),
                if (title != null && description != null) const SizedBox(height: 6),
                if (description != null)
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400], // text-muted-foreground
                    ),
                  ),
              ],
            ),
          ),
          // Top-right action (like a button or a badge)
          if (action != null) ...[
            const SizedBox(width: 16),
            action!,
          ]
        ],
      ),
    );
  }
}

/// The main body content area
class CustomCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CustomCardContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 24), // px-6 pb-6
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// The footer area (for submit buttons, last updated text, etc.)
class CustomCardFooter extends StatelessWidget {
  final Widget child;

  const CustomCardFooter({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // px-6 pb-6
      child: child,
    );
  }
}