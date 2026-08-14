class DifficultyConfig {
  const DifficultyConfig({
    required this.difficulty,
    required this.lives,
    required this.timerSeconds,
    required this.memoryPreviewSeconds,
    required this.missingLetterCount,
    required this.allowFirstLetterHint,
    required this.maximumStars,
  });

  final String difficulty;
  final int lives;
  final int timerSeconds;
  final int memoryPreviewSeconds;
  final int missingLetterCount;
  final bool allowFirstLetterHint;
  final int maximumStars;

  static DifficultyConfig fromDifficulty(String difficulty) {
    switch (difficulty.toLowerCase().trim()) {
      case 'hard':
        return const DifficultyConfig(
          difficulty: 'hard',
          lives: 2,
          timerSeconds: 15,
          memoryPreviewSeconds: 3,
          missingLetterCount: 2,
          allowFirstLetterHint: false,
          maximumStars: 3,
        );
      case 'medium':
        return const DifficultyConfig(
          difficulty: 'medium',
          lives: 3,
          timerSeconds: 20,
          memoryPreviewSeconds: 4,
          missingLetterCount: 2,
          allowFirstLetterHint: true,
          maximumStars: 3,
        );
      case 'easy':
      default:
        return const DifficultyConfig(
          difficulty: 'easy',
          lives: 3,
          timerSeconds: 30,
          memoryPreviewSeconds: 5,
          missingLetterCount: 1,
          allowFirstLetterHint: true,
          maximumStars: 3,
        );
    }
  }
}
