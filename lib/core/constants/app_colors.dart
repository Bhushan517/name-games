import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF060916);
  static const Color cardBg = Color(0xFF121A31);
  static const Color nodeBg = Color(0xFF17223B);
  static const Color spaceGradientTop = Color(0xFF321360);
  static const Color spaceGradientBottom = Color(0xFF02040B);

  static const Color cyan = Color(0xFF25F1DF);
  static const Color purple = Color(0xFF9A60FF);
  static const Color pink = Color(0xFFFF5D9E);
  static const Color gold = Color(0xFFFFD45C);
  static const Color emeraldGreen = Color(0xFF58E68A);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x61FFFFFF);
  static const Color borderSubtle = Colors.white12;

  // Glass & Gradient Helpers
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassCardBg = Color(0x1F16223D);
  static const Color neonGlowCyan = Color(0x4025F1DF);
  static const Color neonGlowGold = Color(0x40FFD45C);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B2646),
      Color(0xFF121A31),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [
      Color(0xFF25F1DF),
      Color(0xFF9A60FF),
    ],
  );
}

