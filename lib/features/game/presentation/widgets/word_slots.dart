import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/letter_node.dart';

class WordSlots extends StatelessWidget {
  const WordSlots({
    super.key,
    required this.letterCount,
    required this.selectedIndices,
    required this.nodes,
    required this.themeColor,
    required this.revealedHintIndices,
  });

  final int letterCount;
  final List<int> selectedIndices;
  final List<LetterNode> nodes;
  final Color themeColor;
  final Set<int> revealedHintIndices;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(letterCount, (index) {
        final hasLetter = index < selectedIndices.length;
        final isHinted = hasLetter && revealedHintIndices.contains(index);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 36,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasLetter
                ? (isHinted
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : themeColor.withValues(alpha: 0.2))
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: hasLetter
                  ? (isHinted ? AppColors.gold : themeColor)
                  : Colors.white12,
            ),
          ),
          child: Text(
            hasLetter ? nodes[selectedIndices[index]].letter : '•',
            style: TextStyle(
              color: hasLetter
                  ? (isHinted ? AppColors.gold : themeColor)
                  : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        );
      }),
    );
  }
}
