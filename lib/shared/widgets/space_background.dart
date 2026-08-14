import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'animated_star_field.dart';

class SpaceBackground extends StatelessWidget {
  const SpaceBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1, -1),
              radius: 1.35,
              colors: [
                AppColors.spaceGradientTop,
                AppColors.background,
                AppColors.spaceGradientBottom,
              ],
            ),
          ),
        ),
        const CustomPaint(painter: AnimatedStarField()),
        SafeArea(child: child),
      ],
    );
  }
}
