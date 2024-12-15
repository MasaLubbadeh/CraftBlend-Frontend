import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon; // Made icon optional (nullable)
  final Color color;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final BorderRadiusGeometry borderRadius;
  final double elevation;

  const CustomButton({
    required this.onPressed,
    required this.label,
    this.icon, // Optional icon
    required this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
    this.textStyle = const TextStyle(fontSize: 18, color: myColor),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.7),
              blurRadius: 3,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Check if the icon is provided, if not just show the label
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}
