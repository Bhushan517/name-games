import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ListenSpellHeader extends StatelessWidget {
  const ListenSpellHeader({
    super.key,
    required this.onSpeak,
  });

  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Center(
        child: FilledButton.icon(
          onPressed: onSpeak,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
            foregroundColor: AppColors.cyan,
            side: const BorderSide(color: AppColors.cyan, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.volume_up_rounded, size: 22),
          label: const Text(
            'TAP TO LISTEN',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}
