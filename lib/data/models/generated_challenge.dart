import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/difficulty_config.dart';
import 'challenge_mode.dart';
import 'pattern_template.dart';
import 'word_content.dart';

class GeneratedChallenge {
  const GeneratedChallenge({
    required this.challengeNumber,
    required this.id,
    required this.wordContent,
    required this.mode,
    required this.difficultyConfig,
    required this.patternTemplate,
    required this.themeColor,
  });

  final int challengeNumber; // 1 to 500
  final String id;
  final WordContent wordContent;
  final ChallengeMode mode;
  final DifficultyConfig difficultyConfig;
  final PatternTemplate patternTemplate;
  final Color themeColor;

  String get word => wordContent.word;
  String get category => wordContent.category;
  String get difficulty => difficultyConfig.difficulty;
  int get letterCount => wordContent.letterCount;

  static Color getColorForCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'animals':
        return AppColors.cyan;
      case 'nature':
        return AppColors.emeraldGreen;
      case 'home':
        return AppColors.purple;
      case 'school':
        return AppColors.gold;
      case 'food':
        return const Color(0xFFFF9500);
      case 'body and health':
        return AppColors.pink;
      case 'space and science':
        return const Color(0xFF5AC8FA);
      case 'action words':
        return const Color(0xFFFF2D55);
      case 'places and transport':
        return const Color(0xFF34C759);
      case 'feelings and values':
      default:
        return const Color(0xFFAF52DE);
    }
  }
}
