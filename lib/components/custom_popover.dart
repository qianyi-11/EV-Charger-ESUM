import 'package:flutter/material.dart';

class CustomPopover extends StatefulWidget {
  final Widget trigger;
  final Widget content;
  final double width;

  const CustomPopover({
    super.key,
    required this.trigger,
    required this.content,
    this.width = 288.0, // Matches Shadcn w-72 (72 * 4 pixels)
  });

  @override
  State<CustomPopover> createState() => _CustomPopoverState();
}

class _CustomPopoverState extends State<CustomPopover> {
  // Manages the visibility state of the floating portal
  final OverlayPortalController _overlayController = OverlayPortalController();
  
  // Anchors the floating content strictly to the trigger widget
  final LayerLink _link = LayerLink();

  void _togglePopover() {
    _overlayController.toggle();
  }

  void _closePopover() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              // 1. The Invisible Barrier Layer
              // Detects taps anywhere outside the popover and closes it
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePopover,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              
              // 2. The Popover Content Layer
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 8), // sideOffset spacing matching React specs
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: widget.width,
                      padding: const EdgeInsets.all(16.0), // p-4
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A), // bg-popover
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
              ),
            ],
          );
        },
        child: GestureDetector(
          onTap: _togglePopover,
          child: widget.trigger,
        ),
      ),
    );
  }
}