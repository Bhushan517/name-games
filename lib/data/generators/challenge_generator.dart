import '../../core/utils/difficulty_config.dart';
import '../models/challenge_mode.dart';
import '../models/generated_challenge.dart';
import '../models/word_content.dart';
import 'pattern_generator.dart';

class ChallengeGenerator {
  ChallengeGenerator._();

  static List<GeneratedChallenge> generateAllChallenges(
      List<WordContent> words) {
    if (words.isEmpty) return <GeneratedChallenge>[];

    final allChallenges = <GeneratedChallenge>[];
    const modes = ChallengeMode.values; // 5 modes

    // 100 words * 5 modes = 500 challenges
    final rawGenerated = <_RawChallenge>[];

    for (final word in words) {
      for (final mode in modes) {
        final challengeId = '${word.id}_${mode.idSuffix}';
        // Effective difficulty based on word difficulty and mode complexity
        final effectiveDiff =
            _computeEffectiveDifficulty(word.difficulty, mode);
        rawGenerated.add(
          _RawChallenge(
            id: challengeId,
            word: word,
            mode: mode,
            effectiveDifficulty: effectiveDiff,
          ),
        );
      }
    }

    // Sort by effective difficulty weight, then interleave categories and modes
    rawGenerated.sort((a, b) {
      final diffScoreA = _difficultyScore(a.effectiveDifficulty);
      final diffScoreB = _difficultyScore(b.effectiveDifficulty);
      if (diffScoreA != diffScoreB) return diffScoreA.compareTo(diffScoreB);
      // Secondary sort by category and mode index for variety
      final catCompare = a.word.category.compareTo(b.word.category);
      if (catCompare != 0) return catCompare;
      return a.mode.index.compareTo(b.mode.index);
    });

    // Interleave to avoid repeating same category/mode consecutively
    final interleaved = _interleaveForVariety(rawGenerated);

    // Build the final 500 GeneratedChallenge instances with 1-based challenge numbers
    for (var i = 0; i < interleaved.length; i++) {
      final item = interleaved[i];
      final template = PatternGenerator.getTemplate(
        item.word.patternTemplate,
        item.word.letterCount,
      );
      final diffConfig =
          DifficultyConfig.fromDifficulty(item.effectiveDifficulty);
      final color = GeneratedChallenge.getColorForCategory(item.word.category);

      allChallenges.add(
        GeneratedChallenge(
          challengeNumber: i + 1,
          id: item.id,
          wordContent: item.word,
          mode: item.mode,
          difficultyConfig: diffConfig,
          patternTemplate: template,
          themeColor: color,
        ),
      );
    }

    return allChallenges;
  }

  static String _computeEffectiveDifficulty(
    String wordDifficulty,
    ChallengeMode mode,
  ) {
    if (wordDifficulty == 'hard' || mode == ChallengeMode.timed) {
      if (wordDifficulty == 'hard') return 'hard';
      return 'medium';
    }
    if (wordDifficulty == 'medium') {
      if (mode == ChallengeMode.memory || mode == ChallengeMode.timed) {
        return 'hard';
      }
      return 'medium';
    }
    // word is easy
    if (mode == ChallengeMode.memory || mode == ChallengeMode.missingLetter) {
      return 'easy';
    }
    return 'easy';
  }

  static int _difficultyScore(String diff) {
    switch (diff) {
      case 'hard':
        return 3;
      case 'medium':
        return 2;
      case 'easy':
      default:
        return 1;
    }
  }

  static List<_RawChallenge> _interleaveForVariety(List<_RawChallenge> list) {
    final result = <_RawChallenge>[];
    final remaining = List<_RawChallenge>.from(list);

    while (remaining.isNotEmpty) {
      _RawChallenge? selected;
      if (result.isEmpty) {
        selected = remaining.removeAt(0);
      } else {
        final last = result.last;
        // Find best match with different category and mode
        int matchIndex = remaining.indexWhere(
          (c) => c.word.category != last.word.category && c.mode != last.mode,
        );
        if (matchIndex == -1) {
          // Fallback: different category
          matchIndex = remaining.indexWhere(
            (c) => c.word.category != last.word.category,
          );
        }
        if (matchIndex == -1) {
          matchIndex = 0;
        }
        selected = remaining.removeAt(matchIndex);
      }
      result.add(selected);
    }

    return result;
  }
}

class _RawChallenge {
  const _RawChallenge({
    required this.id,
    required this.word,
    required this.mode,
    required this.effectiveDifficulty,
  });

  final String id;
  final WordContent word;
  final ChallengeMode mode;
  final String effectiveDifficulty;
}
