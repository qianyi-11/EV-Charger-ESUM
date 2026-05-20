import 'package:flutter/material.dart';

class CustomSeparator extends StatelessWidget {
  final Axis orientation;
  final double thickness;
  final Color color;

  const CustomSeparator({
    super.key,
    this.orientation = Axis.horizontal,
    this.thickness = 1.0,
    this.color = const Color(0x1FFFFFFF), // Equivalent to border/white12
  });

  @override
  Widget build(BuildContext context) {
    return orientation == Axis.horizontal
        ? Divider(
            height: thickness,
            thickness: thickness,
            color: color,
          )
        : VerticalDivider(
            width: thickness,
            thickness: thickness,
            color: color,
          );
  }
}