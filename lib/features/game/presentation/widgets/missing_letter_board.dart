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
          spacing: 8,
          runSpacing: 10,
          children: List.generate(word.length, (index) {
            final isMissing = missingIndices.contains(index);
            final filled = filledLetters[index];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isMissing
                    ? (filled != null
                        ? LinearGradient(
                            colors: [
                              themeColor.withValues(alpha: 0.35),
                              themeColor.withValues(alpha: 0.15),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.15),
                              AppColors.gold.withValues(alpha: 0.05),
                            ],
                          ))
                    : const LinearGradient(
                        colors: [
                          Color(0xFF1B2646),
                          Color(0xFF121A31),
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMissing
                      ? (filled != null ? themeColor : AppColors.gold)
                      : Colors.white24,
                  width: isMissing ? 2.0 : 1.2,
                ),
                boxShadow: isMissing && filled != null
                    ? [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
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

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'CHOOSE THE MISSING LETTER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Letter Choices
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: choices.map((letter) {
            return InkWell(
              onTap: () => onLetterSelected(letter),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      themeColor.withValues(alpha: 0.25),
                      const Color(0xFF17223B),
                    ],
                  ),
                  border: Border.all(color: themeColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 21,
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
