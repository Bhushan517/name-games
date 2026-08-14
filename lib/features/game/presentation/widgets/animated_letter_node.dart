import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AnimatedLetterNode extends StatelessWidget {
  const AnimatedLetterNode({
    super.key,
    required this.letter,
    required this.isSelected,
    required this.themeColor,
    required this.radius,
    required this.onTap,
  });

  final String letter;
  final bool isSelected;
  final Color themeColor;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        scale: isSelected ? 1.15 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: radius * 2,
          height: radius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? themeColor : AppColors.nodeBg,
            border: Border.all(
              color: isSelected ? Colors.white : themeColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(
                  alpha: isSelected ? 0.65 : 0.25,
                ),
                blurRadius: isSelected ? 25 : 10,
              ),
            ],
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: isSelected ? AppColors.background : Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
