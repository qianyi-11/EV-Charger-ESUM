import 'package:flutter/material.dart';

class CustomResizableGroup extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;

  const CustomResizableGroup({
    super.key,
    required this.leftChild,
    required this.rightChild,
  });

  @override
  State<CustomResizableGroup> createState() => _CustomResizableGroupState();
}

class _CustomResizableGroupState extends State<CustomResizableGroup> {
  // We control the width of the left panel manually
  double _leftPanelWidth = 300.0; 

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Panel
        SizedBox(width: _leftPanelWidth, child: widget.leftChild),
        
        // Custom Draggable Divider
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _leftPanelWidth += details.delta.dx;
              // Prevent the panel from becoming too small
              if (_leftPanelWidth < 100) _leftPanelWidth = 100;
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Container(
              width: 8, // Invisible buffer zone for easier grabbing
              color: Colors.transparent, 
              child: Center(
                child: Container(
                  width: 1, // Visible line
                  color: Colors.white12, // bg-border
                  child: const Icon(Icons.drag_handle, size: 12, color: Colors.white38),
                ),
              ),
            ),
          ),
        ),
        
        // Right Panel
        Expanded(child: widget.rightChild),
      ],
    );
  }
}