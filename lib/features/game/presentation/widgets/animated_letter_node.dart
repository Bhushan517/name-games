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
        duration: const Duration(milliseconds: 200),
        scale: isSelected ? 1.2 : 1.0,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: radius * 2,
          height: radius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeColor,
                      Color.lerp(themeColor, Colors.white, 0.3)!,
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E2B4B),
                      Color(0xFF10172A),
                    ],
                  ),
            border: Border.all(
              color: isSelected ? Colors.white : themeColor.withValues(alpha: 0.8),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(
                  alpha: isSelected ? 0.75 : 0.2,
                ),
                blurRadius: isSelected ? 28 : 12,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: isSelected ? const Color(0xFF090D18) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              shadows: isSelected
                  ? null
                  : [
                      Shadow(
                        color: themeColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
