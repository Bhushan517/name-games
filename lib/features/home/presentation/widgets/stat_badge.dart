import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
      ],
    );
  }
}
