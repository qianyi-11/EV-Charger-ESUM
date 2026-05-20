import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? content;
  final List<Widget>? actions;

  const CustomDialog({
    super.key,
    required this.title,
    this.description,
    this.content,
    this.actions,
  });

  // A convenient static function to cleanly show this modal anywhere in your app context
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    Widget? content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5), // Matches fixed bg-black/50 overlay
      builder: (BuildContext context) {
        return CustomDialog(
          title: title,
          description: description,
          content: content,
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF020817), // Matches dark mode theme bg-background
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0), // max-w-[calc(100%-2rem)]
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // rounded-lg
        side: const BorderSide(color: Colors.white12, width: 1.0), // border
      ),
      contentPadding: const EdgeInsets.all(24.0), // p-6
      
      // DialogHeader section wrapper logic 
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18, // text-lg
                    fontWeight: FontWeight.w600, // FIXED: Changed to valid compile-time constant alias
                    color: Colors.white,
                    height: 1.1, // leading-none
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dynamic X close icon equivalent replacement matching top-4 right-4 position parameters
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 16, color: Colors.white70),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8), // gap-2 styling
            Text(
              description!,
              style: TextStyle(
                fontSize: 14, // text-sm
                color: Colors.grey[400], // text-muted-foreground
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      
      // DialogContent container rendering
      content: content != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16), // space break separating header and raw child logic blocks
                content!,
              ],
            )
          : null,
          
      // DialogFooter operational layout array handling map controls
      actions: actions != null
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 8.0), // bottom alignment gaps padding constraints
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0), // gap spacing handling row separations
                      child: action,
                    );
                  }).toList(),
                ),
              )
            ]
          : null,
    );
  }
}