import 'package:flutter/material.dart';

enum AlertVariant { standard, destructive }

class CustomAlert extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final AlertVariant variant;

  const CustomAlert({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.variant = AlertVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Define colors based on the selected variant
    final bool isDestructive = variant == AlertVariant.destructive;
    
    final Color borderColor = isDestructive 
        ? Colors.red.withOpacity(0.5) 
        : Colors.white12;
        
    final Color iconAndTitleColor = isDestructive 
        ? Colors.redAccent 
        : Colors.white;
        
    final Color descriptionColor = isDestructive 
        ? Colors.red[200]! 
        : Colors.grey[400]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // px-4 py-3
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // bg-card (Dark Slate)
        borderRadius: BorderRadius.circular(8.0), // rounded-lg
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. The Icon (if provided)
          if (icon != null) ...[
            Icon(
              icon,
              size: 16, // [&>svg]:size-4
              color: iconAndTitleColor,
            ),
            const SizedBox(width: 12), // gap-x-3
          ],
          
          // 3. The Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AlertTitle
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: iconAndTitleColor,
                    letterSpacing: -0.2, // tracking-tight
                  ),
                  maxLines: 1, // line-clamp-1
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // gap-y-0.5
                
                // AlertDescription
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14, // text-sm
                    color: descriptionColor,
                    height: 1.5, // leading-relaxed
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}