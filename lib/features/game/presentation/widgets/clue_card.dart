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
                  onPressed: canUseHint ? onHintTap : null,
                  icon: Icon(
                    isNextHintFree
                        ? Icons.lightbulb_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isNextHintFree
                        ? 'HINT ($totalHintsUsed/$maxHints)'
                        : 'WATCH AD FOR NEXT HINT ($totalHintsUsed/$maxHints)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
