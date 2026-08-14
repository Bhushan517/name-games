import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/word_level.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.isLocked,
    required this.starsEarned,
    required this.onTap,
  });

  final WordLevel level;
  final bool isLocked;
  final int starsEarned;
  final VoidCallback onTap;

  bool get isCompleted => starsEarned > 0;

  @override
  Widget build(BuildContext context) {
    final cardColor = isLocked ? Colors.white12 : level.color;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardColor, width: isLocked ? 1.0 : 1.5),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: level.color.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Neutral mystery icon / lock icon (NO answer emoji!)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked
                    ? Colors.white.withValues(alpha: 0.04)
                    : level.color.withValues(alpha: 0.12),
                border: Border.all(
                  color: isLocked ? Colors.white24 : level.color,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_rounded
                    : (isCompleted
                        ? Icons.auto_awesome_rounded
                        : Icons.extension_rounded),
                color: isLocked ? Colors.white38 : level.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Level Info & Metadata (NO answer word / shape name!)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        'LEVEL ${level.index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: isLocked ? Colors.white38 : level.color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.white.withValues(alpha: 0.05)
                              : level.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          level.difficulty.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: isLocked ? Colors.white38 : level.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLocked
                        ? AppStrings.locked
                        : (isCompleted
                            ? AppStrings.completed
                            : AppStrings.mysteryWord),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: isLocked ? Colors.white38 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${level.category} • ${level.letterCount} LETTERS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          isLocked ? Colors.white24 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: List.generate(
                      3,
                      (starIndex) => Icon(
                        starIndex < starsEarned
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 15,
                        color: starIndex < starsEarned
                            ? AppColors.gold
                            : Colors.white24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Play / Locked Action Icon
            Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.play_circle_fill_rounded,
              color: isLocked ? Colors.white24 : level.color,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
