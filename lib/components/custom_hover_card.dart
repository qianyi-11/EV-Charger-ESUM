import 'package:flutter/material.dart';

class CustomHoverCard extends StatefulWidget {
  final Widget trigger;
  final Widget content;
  final double width;

  const CustomHoverCard({
    super.key,
    required this.trigger,
    required this.content,
    this.width = 256.0, // Matches Shadcn w-64
  });

  @override
  State<CustomHoverCard> createState() => _CustomHoverCardState();
}

class _CustomHoverCardState extends State<CustomHoverCard> {
  // OverlayPortalController manages showing/hiding the floating UI
  final OverlayPortalController _overlayController = OverlayPortalController();
  
  // LayerLink magically ties the floating card's position to the trigger's position
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Desktop/Web hover interactions
      onEnter: (_) => _overlayController.show(),
      onExit: (_) => _overlayController.hide(),
      child: GestureDetector(
        // Mobile touch interaction
        onTap: _overlayController.toggle,
        child: CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (context) {
              return CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 8), // sideOffset gap matching Shadcn
                child: Align(
                  alignment: Alignment.topCenter, // Prevents the follower from expanding full screen
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: widget.width,
                      padding: const EdgeInsets.all(16.0), // p-4 padding
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A), // bg-popover dark slate
                        borderRadius: BorderRadius.circular(6.0), // rounded-md
                        border: Border.all(color: Colors.white12), // border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: widget.content,
                    ),
                  ),
                ),
              );
            },
            child: widget.trigger,
          ),
        ),
      ),
    );
  }
}