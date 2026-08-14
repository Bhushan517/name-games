import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MissingLetterBoard extends StatelessWidget {
  const MissingLetterBoard({
    super.key,
    required this.word,
    required this.missingIndices,
    required this.filledLetters,
    required this.choices,
    required this.themeColor,
    required this.onLetterSelected,
  });

  final String word;
  final List<int> missingIndices;
  final Map<int, String> filledLetters;
  final List<String> choices;
  final Color themeColor;
  final ValueChanged<String> onLetterSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display word with blanks
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: List.generate(word.length, (index) {
            final isMissing = missingIndices.contains(index);
            final filled = filledLetters[index];

            return Container(
              width: 42,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMissing
                    ? (filled != null
                        ? themeColor.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05))
                    : const Color(0xFF17223B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMissing
                      ? (filled != null ? themeColor : AppColors.gold)
                      : Colors.white24,
                  width: isMissing ? 2.0 : 1.0,
                ),
              ),
              child: Text(
                isMissing ? (filled ?? '?') : word[index],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isMissing
                      ? (filled != null ? themeColor : AppColors.gold)
                      : Colors.white,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 36),

        const Text(
          'CHOOSE THE MISSING LETTER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 14),

        // Letter Choices
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: choices.map((letter) {
            return InkWell(
              onTap: () => onLetterSelected(letter),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.nodeBg,
                  border: Border.all(color: themeColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
