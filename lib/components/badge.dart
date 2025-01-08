import 'package:flutter/material.dart';

class badge extends StatelessWidget {
  final String text; // Text to display in the badge
  final Color color; // Background color of the badge
  final double fontSize; // Font size of the text
  final EdgeInsetsGeometry padding; // Padding around the text
  final BorderRadiusGeometry
      borderRadius; // Border radius for the badge corners
  final IconData? icon; // Optional icon to display
  final double iconSize; // Size of the icon
  final Color iconColor; // Color of the icon

  const badge({
    super.key,
    required this.text,
    this.color = Colors.red,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.icon,
    this.iconSize = 14.0,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 4), // Space between icon and text
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
