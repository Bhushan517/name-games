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
  final List<int?> selectedIndices;
  final List<LetterNode> nodes;
  final Color themeColor;
  final Set<int> revealedHintIndices;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(letterCount, (index) {
          final nodeIndex = selectedIndices[index];
          final hasLetter = nodeIndex != null;
          final isHinted = hasLetter && revealedHintIndices.contains(index);

          final activeColor = isHinted ? AppColors.gold : themeColor;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            width: 42,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: hasLetter
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        activeColor.withValues(alpha: 0.35),
                        activeColor.withValues(alpha: 0.15),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasLetter ? activeColor : Colors.white24,
                width: hasLetter ? 1.8 : 1.0,
              ),
              boxShadow: hasLetter
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                hasLetter ? nodes[nodeIndex].letter : '_',
                key: ValueKey(hasLetter ? '${index}_${nodes[nodeIndex].letter}' : '${index}_empty'),
                style: TextStyle(
                  color: hasLetter ? Colors.white : Colors.white24,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  shadows: hasLetter
                      ? [
                          Shadow(
                            color: activeColor,
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
