import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/generated_challenge.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.isLocked,
    required this.starsEarned,
    required this.onTap,
  });

  final GeneratedChallenge challenge;
  final bool isLocked;
  final int starsEarned;
  final VoidCallback onTap;

  bool get isCompleted => starsEarned > 0;

  @override
  Widget build(BuildContext context) {
    final cardColor = isLocked ? Colors.white12 : challenge.themeColor;

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
                    color: challenge.themeColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Neutral mystery icon / lock icon (NO answer emoji!)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked
                    ? Colors.white.withValues(alpha: 0.04)
                    : challenge.themeColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: isLocked ? Colors.white24 : challenge.themeColor,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_rounded
                    : (isCompleted
                        ? Icons.auto_awesome_rounded
                        : Icons.extension_rounded),
                color: isLocked ? Colors.white38 : challenge.themeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Challenge Metadata (NO answer word / shape name!)
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
                        'LEVEL ${challenge.challengeNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color:
                              isLocked ? Colors.white38 : challenge.themeColor,
                        ),
                      ),
                      // Mode tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.white.withValues(alpha: 0.05)
                              : challenge.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          challenge.mode.shortName,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isLocked
                                ? Colors.white38
                                : challenge.themeColor,
                          ),
                        ),
                      ),
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          challenge.difficulty.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isLocked ? Colors.white38 : Colors.white70,
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
                    '${challenge.category} • ${challenge.letterCount} LETTERS',
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
              color: isLocked ? Colors.white24 : challenge.themeColor,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
