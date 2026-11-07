import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  static String label(String p) {
    switch (p) {
      case 'high':
        return 'Ưu tiên cao';
      case 'low':
        return 'Ưu tiên thấp';
      default:
        return 'Ưu tiên trung bình';
    }
  }

  static Color color(String p) {
    switch (p) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.teal;
      default:
        return Colors.amber.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label(priority),
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}