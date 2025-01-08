import 'package:flutter/material.dart';
import '../configuration/config.dart';

class AddressWidget extends StatelessWidget {
  final String firstLineText; // Text for the first line
  final String? secondLineText; // Optional text for the second line
  final Color backgroundColor; // Background color for the widget
  final Color textColor; // Text color for both lines
  final IconData icon; // Icon for the widget
  final VoidCallback? onTap; // Optional tap callback

  const AddressWidget({
    Key? key,
    required this.firstLineText,
    this.secondLineText,
    this.backgroundColor = Colors.white70, // Default background color
    this.textColor = myColor, // Default text color
    this.icon = Icons.location_on, // Default icon
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Execute the callback when tapped
      child: Container(
        width: MediaQuery.of(context).size.width * .52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor, // Customizable background color
          borderRadius: BorderRadius.circular(30), // Oval shape
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor), // Customizable icon

            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstLineText, // First line text
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor, // Customizable text color
                  ),
                ),
                if (secondLineText != null) // Conditionally render second line
                  Text(
                    secondLineText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor, // Customizable text color
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 5),
            Icon(Icons.arrow_drop_down, color: textColor), // Dropdown arrow
          ],
        ),
      ),
    );
  }
}
