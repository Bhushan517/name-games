import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/word_content.dart';

class ClueCard extends StatelessWidget {
  const ClueCard({
    super.key,
    required this.level,
    required this.isNextHintFree,
    required this.canUseHint,
    required this.totalHintsUsed,
    required this.maxHints,
    required this.onHintTap,
  });

  final WordContent level;
  final bool isNextHintFree;
  final bool canUseHint;
  final int totalHintsUsed;
  final int maxHints;
  final VoidCallback onHintTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x1F16223D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(level.emoji, style: const TextStyle(fontSize: 30)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              level.sentenceClue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: canUseHint ? onHintTap : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: canUseHint
                      ? (isNextHintFree
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : AppColors.purple.withValues(alpha: 0.2))
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canUseHint
                        ? (isNextHintFree ? AppColors.gold : AppColors.purple)
                        : Colors.white12,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNextHintFree
                          ? Icons.lightbulb_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 16,
                      color: canUseHint
                          ? (isNextHintFree ? AppColors.gold : AppColors.cyan)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isNextHintFree
                          ? 'FREE HINT ($totalHintsUsed/$maxHints)'
                          : 'WATCH AD FOR HINT ($totalHintsUsed/$maxHints)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: canUseHint
                            ? (isNextHintFree ? AppColors.gold : Colors.white)
                            : Colors.white38,
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
