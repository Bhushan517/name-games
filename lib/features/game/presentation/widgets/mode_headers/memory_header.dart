import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class MemoryHeader extends StatelessWidget {
  const MemoryHeader({
    super.key,
    required this.isRevealed,
    required this.secondsLeft,
    required this.onReplay,
  });

  final bool isRevealed;
  final int secondsLeft;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isRevealed
              ? AppColors.purple.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRevealed ? AppColors.purple : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isRevealed
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: isRevealed ? AppColors.purple : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isRevealed
                      ? 'MEMORIZE LETTERS ($secondsLeft s)'
                      : 'RECALL & SPELL FROM MEMORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isRevealed ? AppColors.purple : Colors.white70,
                  ),
                ),
              ],
            ),
            if (!isRevealed)
              InkWell(
                onTap: onReplay,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.replay_rounded,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        'PEEK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
