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
    final themeColor = challenge.themeColor;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isLocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.03),
                    Colors.white.withValues(alpha: 0.01),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B2646),
                    themeColor.withValues(alpha: 0.15),
                  ],
                ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLocked
                ? Colors.white10
                : (isCompleted ? AppColors.gold : themeColor),
            width: isLocked ? 1.0 : (isCompleted ? 1.8 : 1.4),
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Level badge / lock icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isLocked
                    ? null
                    : LinearGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.25),
                          themeColor.withValues(alpha: 0.1),
                        ],
                      ),
                color: isLocked ? Colors.white.withValues(alpha: 0.04) : null,
                border: Border.all(
                  color: isLocked ? Colors.white24 : themeColor,
                  width: 1.8,
                ),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_rounded
                    : (isCompleted
                        ? Icons.workspace_premium_rounded
                        : Icons.play_arrow_rounded),
                color: isLocked ? Colors.white38 : (isCompleted ? AppColors.gold : themeColor),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'LEVEL ${challenge.challengeNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isLocked ? Colors.white38 : themeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mode pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.white.withValues(alpha: 0.05)
                              : themeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          challenge.mode.shortName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: isLocked ? Colors.white38 : themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLocked
                        ? AppStrings.locked
                        : (isCompleted
                            ? AppStrings.completed
                            : AppStrings.mysteryWord),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isLocked ? Colors.white38 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${challenge.category} • ${challenge.letterCount} LETTERS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLocked ? Colors.white24 : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // Stars
                      Row(
                        children: List.generate(
                          3,
                          (starIndex) => Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              starIndex < starsEarned
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: starIndex < starsEarned
                                  ? AppColors.gold
                                  : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Play Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked
                    ? Colors.transparent
                    : themeColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                color: isLocked ? Colors.white24 : themeColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
