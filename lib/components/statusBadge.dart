import 'package:flutter/material.dart';

class StatusBadge {
  static Widget getBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = const Color.fromARGB(255, 117, 103, 127);
        break;
      case 'shipped' || 'Expired':
        badgeColor = Colors.red.withOpacity(.6);
        break;
      case 'delivered' || 'Active':
        badgeColor = Colors.green;
        break;
      case 'partially shipped':
        badgeColor = Colors.orangeAccent;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
