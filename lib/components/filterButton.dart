import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String text;
  final bool isActive;

  const FilterButton({Key? key, required this.text, required this.isActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : myColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isActive ? myColor : Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          Icon(
            isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isActive ? myColor : Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}
