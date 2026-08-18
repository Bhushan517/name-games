import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/word_content.dart';

class ClueCard extends StatelessWidget {
  const ClueCard({
    super.key,
    required this.level,
    required this.hintUsed,
    required this.hasSelectedLetters,
    required this.onHintTap,
    this.onRewardedHintTap,
    this.canUseRewardedHint = false,
  });

  final WordContent level;
  final bool hintUsed;
  final bool hasSelectedLetters;
  final VoidCallback onHintTap;
  final VoidCallback? onRewardedHintTap;
  final bool canUseRewardedHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 2),
            Text(
              level.sentenceClue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: hintUsed || hasSelectedLetters ? null : onHintTap,
                  icon: const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    hintUsed
                        ? 'STARTS WITH ${level.word[0]}'
                        : AppStrings.hintPrompt,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!hintUsed &&
                    onRewardedHintTap != null &&
                    canUseRewardedHint) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: hasSelectedLetters ? null : onRewardedHintTap,
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 16,
                    ),
                    label: const Text(
                      'WATCH AD FOR HINT',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
