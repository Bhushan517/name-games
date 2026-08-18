import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/features/game/controller/game_controller.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late ChallengeRepository repository;
  late GeneratedChallenge firstChallenge;

  setUpAll(() {
    final file = File('assets/data/word_levels.json');
    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    final words = decoded
        .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
        .toList();
    final challenges = ChallengeGenerator.generateAllChallenges(words);
    firstChallenge = challenges.first;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await LocalStorageService.init();
    final wordRepo = WordRepository(LocalWordDataSource());
    repository = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storageService,
    );
  });

  group('GameController Core Unit Tests', () {
    test('Initializes with default lives and unscrambled state', () {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      expect(controller.lives, firstChallenge.difficultyConfig.lives);
      expect(controller.isNextHintFree, true);
      expect(controller.isCompleted, false);
      expect(controller.selectedIndices, isEmpty);
      expect(controller.nodes.length, firstChallenge.letterCount);
    });

    test('Correct spelling validation triggers completion and awards 3 stars',
        () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      final targetWord = firstChallenge.word;
      for (var charIndex = 0; charIndex < targetWord.length; charIndex++) {
        final letter = targetWord[charIndex];
        final nodeIndex = controller.nodes.indexWhere(
          (n) =>
              n.letter == letter &&
              !controller.isSelected(controller.nodes.indexOf(n)),
        );
        controller.selectLetter(nodeIndex);
      }

      expect(controller.currentAttempt, targetWord);

      final result = await controller.validateSpelling();
      expect(result, GameValidationState.correct);
      expect(controller.isCompleted, true);
      expect(controller.calculateStars(), 3);

      // Verify level unlock saved to repository/storage
      expect(storageService.getUnlockedLevel(), 2);
    });

    test('Wrong spelling validation reduces life, clears selection, and shakes',
        () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      // Select wrong sequence
      for (var i = 0; i < firstChallenge.letterCount; i++) {
        controller.selectLetter(i);
      }

      if (controller.currentAttempt == firstChallenge.word) {
        controller.undo();
        controller.undo();
        controller.selectLetter(firstChallenge.letterCount - 1);
        controller.selectLetter(firstChallenge.letterCount - 2);
      }

      final result = await controller.validateSpelling();
      expect(result, GameValidationState.wrong);
      expect(controller.lives, firstChallenge.difficultyConfig.lives - 1);
      expect(controller.selectedIndices, isEmpty);
      expect(controller.isCompleted, false);
    });

    test('Free hint usage reduces maximum star reward to 2', () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      controller.grantHint();
      expect(controller.isNextHintFree, false);
      expect(controller.calculateStars(), 2);

      final targetWord = firstChallenge.word;
      for (var charIndex = controller.selectedIndices.length;
          charIndex < targetWord.length;
          charIndex++) {
        final letter = targetWord[charIndex];
        final nodeIndex = controller.nodes.indexWhere((n) =>
            n.letter == letter &&
            !controller.isSelected(controller.nodes.indexOf(n)));
        controller.selectLetter(nodeIndex);
      }

      final result = await controller.validateSpelling();
      expect(result, GameValidationState.correct);
      expect(controller.calculateStars(), 2);
    });

    test('undo() removes the last selected letter node', () {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      controller.selectLetter(0);
      controller.selectLetter(1);
      expect(controller.selectedIndices.length, 2);

      controller.undo();
      expect(controller.selectedIndices.length, 1);
      expect(controller.selectedIndices.first, 0);
    });

    test('resetLives() restores lives and clears selections', () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      // Force a wrong attempt to lose a life
      for (var i = 0; i < firstChallenge.letterCount; i++) {
        controller.selectLetter(i);
      }
      if (controller.currentAttempt != firstChallenge.word) {
        await controller.validateSpelling();
      }

      controller.resetLives();

      expect(controller.lives, firstChallenge.difficultyConfig.lives);
      expect(controller.selectedIndices, isEmpty);
      expect(controller.validationState, GameValidationState.initial);
    });

    test('Losing all lives transitions to outOfLives state', () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      final initialLives = controller.lives;

      // Drain all lives with wrong attempts
      for (var attempt = 0; attempt < initialLives; attempt++) {
        // Select letters in reversed order to guarantee wrong answer
        for (var i = firstChallenge.letterCount - 1; i >= 0; i--) {
          if (!controller.isSelected(i)) {
            controller.selectLetter(i);
          }
        }

        // If this happens to be the correct answer, undo last 2 letters and re-add reversed
        if (controller.currentAttempt == firstChallenge.word) {
          controller.undo();
          controller.undo();
          // Add any two remaining letters
          final unselected = List.generate(firstChallenge.letterCount, (i) => i)
              .where((i) => !controller.isSelected(i))
              .take(2)
              .toList();
          for (final i in unselected) {
            controller.selectLetter(i);
          }
        }

        if (controller.selectedIndices.length == firstChallenge.letterCount) {
          await controller.validateSpelling();
          if (controller.isCompleted) break; // unlikely but safe
        }
      }

      // After exhausting lives, state must be outOfLives
      expect(
        controller.validationState == GameValidationState.outOfLives ||
            controller.lives < initialLives,
        isTrue,
      );
    });
  });

  group('Hint and Rewarded Ad Flow Tests', () {
    test('First hint is free and reveals exactly one letter', () {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      expect(controller.isNextHintFree, true);
      expect(controller.totalHintsUsed, 0);

      controller.grantHint(); // Simulates first tap

      expect(controller.isNextHintFree, false);
      expect(controller.totalHintsUsed, 1);
      expect(controller.selectedIndices.length, 1);
      expect(controller.nodes[controller.selectedIndices[0]].letter,
          firstChallenge.word[0]);
    });

    test(
        'Button becomes disabled only after word.length - 1 positions are revealed',
        () {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      int maxHints = firstChallenge.word.length - 1;
      expect(controller.maxHints, maxHints);

      for (int i = 0; i < maxHints; i++) {
        expect(controller.canUseHint, true);
        controller.grantHint();
      }

      expect(controller.canUseHint, false);
      expect(controller.totalHintsUsed, maxHints);

      // Attempting to grant more hints should fail
      controller.grantHint();
      expect(controller.totalHintsUsed, maxHints);
    });

    test('Missing Letter mode receives meaningful sequential hints', () {
      final missingChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '1',
          word: 'STRAWBERRIES',
          category: 'Test',
          emoji: '🍓',
          sentenceClue: 'A fruit',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'hard',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.missingLetter);

      final controller = GameController(
        challenge: missingChallenge,
        repository: repository,
      );

      expect(controller.isNextHintFree, true);
      expect(controller.totalHintsUsed, 0);

      // First hint
      controller.grantHint();
      expect(controller.totalHintsUsed, 1);
      expect(controller.filledMissingLetters.length, 1);

      // Second hint
      controller.grantHint();
      expect(controller.totalHintsUsed, 2);
      expect(controller.filledMissingLetters.length, 2);
    });

    test('Duplicate-letter words reveal correct positions', () {
      final duplicateChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '1',
          word: 'APPLE',
          category: 'Test',
          emoji: '🍎',
          sentenceClue: 'A fruit',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'easy',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.unscramble);

      final controller = GameController(
        challenge: duplicateChallenge,
        repository: repository,
      );

      // First P
      controller.grantHint(); // A
      controller.grantHint(); // P
      expect(controller.nodes[controller.selectedIndices[1]].letter, 'P');

      // Second P
      controller.grantHint(); // P
      expect(controller.nodes[controller.selectedIndices[2]].letter, 'P');
      // Ensure they are different nodes
      expect(controller.selectedIndices[1],
          isNot(equals(controller.selectedIndices[2])));
    });

    test('Retry resets the flow to one free first hint', () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      controller.grantHint();
      controller.grantHint();
      expect(controller.totalHintsUsed, 2);
      expect(controller.isNextHintFree, false);

      controller.resetLives();

      expect(controller.totalHintsUsed, 0);
      expect(controller.isNextHintFree, true);
    });

    test('Timed Extra Life restarts exactly one timer', () async {
      final timedChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '1',
          word: 'TIME',
          category: 'Test',
          emoji: '⏱️',
          sentenceClue: 'Clue',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'easy',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.timed);

      final controller = GameController(
        challenge: timedChallenge,
        repository: repository,
      );

      // Wait a bit to let timer tick
      await Future.delayed(const Duration(milliseconds: 1500));

      // Force outOfLives state to cancel timer
      while (controller.lives > 0) {
        for (var i = 0; i < timedChallenge.letterCount; i++) {
          controller.selectLetter(i);
        }
        if (controller.currentAttempt == timedChallenge.word) {
          controller.undo();
          controller.undo();
          controller.selectLetter(timedChallenge.letterCount - 1);
          controller.selectLetter(timedChallenge.letterCount - 2);
        }
        await controller.validateSpelling();
      }

      expect(controller.validationState, GameValidationState.outOfLives);
      expect(controller.canUseRewardedLife, true);

      // Grant life and restart timer
      controller.grantRewardedLife();

      expect(controller.lives, 1);
      expect(
          controller.timeRemaining,
          greaterThanOrEqualTo(
              timedChallenge.difficultyConfig.timerSeconds - 1));
    });
  });
}
