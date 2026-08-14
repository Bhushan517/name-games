import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedStarField extends CustomPainter {
  const AnimatedStarField();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (var i = 0; i < 95; i++) {
      final offset = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 0.5 + random.nextDouble() * 1.2;
      final starColor = (i % 9 == 0 ? AppColors.cyan : Colors.white).withValues(
        alpha: 0.15 + random.nextDouble() * 0.45,
      );
      canvas.drawCircle(offset, radius, Paint()..color = starColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
