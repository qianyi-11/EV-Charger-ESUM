import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final Widget? footer;

  const CustomDrawer({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.footer,
  });

  /// A static helper method to display this bottom drawer panel overlay smoothly
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    required Widget child,
    Widget? footer,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true, // Allows content to occupy up to 80% screen height (max-h-[80vh])
      backgroundColor: const Color(0xFF020817), // bg-background
      barrierColor: Colors.black.withOpacity(0.5), // bg-black/50 backdrop
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)), // rounded-t-lg
        side: BorderSide(color: Colors.white12, width: 1.0), // border-t
      ),
      builder: (context) {
        return CustomDrawer(
          title: title,
          description: description,
          footer: footer,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Draggable bottom sheet container layout logic
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5, // Opens at half screen height by default
      minChildSize: 0.25,
      maxChildSize: 0.8, // Caps out at max-h-[80vh]
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The classic top drag pill indicator widget matching the vaul-direction style block
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  height: 4.0, // h-1
                  width: 48.0, // scaled down pull indicator width block
                  decoration: BoxDecoration(
                    color: Colors.white24, // bg-muted
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // DrawerHeader structural section layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // p-4
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // DrawerTitle font-semibold
                        color: Colors.white,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400], // DrawerDescription text-muted-foreground
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Dynamic scrollable body content area holding internal child listings
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: child,
                ),
              ),

              // DrawerFooter configuration container layout block alignment array
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.all(16.0), // p-4
                  child: footer!,
                ),
            ],
          ),
        );
      },
    );
  }
}