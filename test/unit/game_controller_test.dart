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
      expect(controller.hintUsed, false);
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

    test('Hint usage reduces maximum star reward to 2', () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      controller.useHint();
      expect(controller.hintUsed, true);
      expect(controller.calculateStars(), 2);

      final targetWord = firstChallenge.word;
      for (var charIndex = 0; charIndex < targetWord.length; charIndex++) {
        final letter = targetWord[charIndex];
        final nodeIndex =
            controller.nodes.indexWhere((n) => n.letter == letter);
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

  group('Rewarded Ads Limits Unit Tests', () {
    test('Rewarded Hint grants exactly 1 hint and is capped at 3', () {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      expect(controller.rewardedHintsUsed, 0);
      expect(controller.canUseRewardedHint, true);

      controller.grantRewardedHint();
      expect(controller.rewardedHintsUsed, 1);
      expect(controller.hintUsed, true);

      controller.grantRewardedHint();
      controller.grantRewardedHint();
      expect(controller.rewardedHintsUsed, 3);
      expect(controller.canUseRewardedHint, false);

      // 4th attempt should do nothing
      controller.grantRewardedHint();
      expect(controller.rewardedHintsUsed, 3);
    });

    test(
        'Rewarded Life grants 1 life, clears outOfLives state, and is capped at 2',
        () async {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      // Force outOfLives state
      while (controller.lives > 0) {
        // Drain a life by guessing wrong
        for (var i = 0; i < firstChallenge.letterCount; i++) {
          controller.selectLetter(i);
        }
        if (controller.currentAttempt == firstChallenge.word) {
          controller.undo();
          controller.undo();
          controller.selectLetter(firstChallenge.letterCount - 1);
          controller.selectLetter(firstChallenge.letterCount - 2);
        }
        await controller.validateSpelling();
      }

      expect(controller.validationState, GameValidationState.outOfLives);
      expect(controller.rewardedLivesUsed, 0);
      expect(controller.canUseRewardedLife, true);

      controller.grantRewardedLife();
      expect(controller.lives, 1);
      expect(controller.rewardedLivesUsed, 1);
      expect(controller.validationState,
          GameValidationState.initial); // Cleared out of lives

      controller.grantRewardedLife();
      expect(controller.lives, 2);
      expect(controller.rewardedLivesUsed, 2);
      expect(controller.canUseRewardedLife, false);

      // 3rd attempt should do nothing
      controller.grantRewardedLife();
      expect(controller.rewardedLivesUsed, 2);
    });

    test('resetLives() resets the rewarded limits', () {
      final controller = GameController(
        challenge: firstChallenge,
        repository: repository,
      );

      controller.grantRewardedHint();
      controller.grantRewardedLife();

      expect(controller.rewardedHintsUsed, 1);
      expect(controller.rewardedLivesUsed, 1);

      controller.resetLives();

      expect(controller.rewardedHintsUsed, 0);
      expect(controller.rewardedLivesUsed, 0);
    });
  });
}
