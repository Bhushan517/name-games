import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class LivesIndicator extends StatelessWidget {
  const LivesIndicator({super.key, required this.currentLives});

  final int currentLives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        AppConstants.maxLives,
        (index) => AnimatedScale(
          duration: const Duration(milliseconds: 220),
          scale: index < currentLives ? 1.0 : 0.0,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.favorite_rounded,
              color: AppColors.pink,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
