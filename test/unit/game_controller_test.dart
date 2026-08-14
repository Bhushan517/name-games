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
  });
}
