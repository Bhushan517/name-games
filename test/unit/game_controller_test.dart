import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/level_data/default_levels.dart';
import 'package:name_twist_game/data/repositories/level_repository.dart';
import 'package:name_twist_game/features/game/controller/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late LevelRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await LocalStorageService.init();
    repository = LevelRepository(storageService);
  });

  group('GameController Unit Tests', () {
    test('Initializes with 3 lives and unscrambled state', () {
      final controller = GameController(
        level: defaultLevels[0],
        repository: repository,
      );

      expect(controller.lives, 3);
      expect(controller.hintUsed, false);
      expect(controller.isCompleted, false);
      expect(controller.selectedIndices, isEmpty);
      expect(controller.nodes.length, 5);
    });

    test('Correct spelling validation triggers completion and awards 3 stars',
        () async {
      final controller = GameController(
        level: defaultLevels[0], // SHINE
        repository: repository,
      );

      // Select letters matching "SHINE"
      const targetWord = 'SHINE';
      for (var charIndex = 0; charIndex < targetWord.length; charIndex++) {
        final letter = targetWord[charIndex];
        final nodeIndex =
            controller.nodes.indexWhere((n) => n.letter == letter);
        controller.selectLetter(nodeIndex);
      }

      expect(controller.currentAttempt, 'SHINE');

      final result = await controller.validateSpelling();
      expect(result, GameValidationState.correct);
      expect(controller.isCompleted, true);
      expect(controller.calculateStars(), 3);

      // Verify level unlock saved to repository/storage
      expect(storageService.getUnlockedLevel(), 2);
      expect(storageService.getLevelStars(0), 3);
    });

    test('Wrong spelling validation reduces life, clears selection, and shakes',
        () async {
      final controller = GameController(
        level: defaultLevels[0], // SHINE
        repository: repository,
      );

      // Select wrong sequence
      controller.selectLetter(0);
      controller.selectLetter(1);
      controller.selectLetter(2);
      controller.selectLetter(3);
      controller.selectLetter(4);

      if (controller.currentAttempt == 'SHINE') {
        // Swap last two to ensure it's wrong
        controller.undo();
        controller.undo();
        controller.selectLetter(4);
        controller.selectLetter(3);
      }

      final result = await controller.validateSpelling();
      expect(result, GameValidationState.wrong);
      expect(controller.lives, 2);
      expect(controller.selectedIndices, isEmpty);
      expect(controller.isCompleted, false);
    });

    test('Hint usage reduces maximum star reward to 2', () async {
      final controller = GameController(
        level: defaultLevels[0], // SHINE
        repository: repository,
      );

      controller.useHint();
      expect(controller.hintUsed, true);
      expect(controller.calculateStars(), 2);

      // Now complete with all 3 lives intact
      const targetWord = 'SHINE';
      for (var charIndex = 0; charIndex < targetWord.length; charIndex++) {
        final letter = targetWord[charIndex];
        final nodeIndex =
            controller.nodes.indexWhere((n) => n.letter == letter);
        controller.selectLetter(nodeIndex);
      }

      final result = await controller.validateSpelling();
      expect(result, GameValidationState.correct);
      expect(controller.calculateStars(), 2);
      expect(storageService.getLevelStars(0), 2);
    });

    test('Out of lives state triggers when all 3 lives are lost', () async {
      final controller = GameController(
        level: defaultLevels[0],
        repository: repository,
      );

      for (var attempt = 0; attempt < 3; attempt++) {
        // Form wrong word
        for (var i = 0; i < 5; i++) {
          controller.selectLetter(i);
        }
        if (controller.currentAttempt == 'SHINE') {
          controller.undo();
          controller.undo();
          controller.selectLetter(4);
          controller.selectLetter(3);
        }
        await controller.validateSpelling();
      }

      expect(controller.lives, 0);
      expect(controller.validationState, GameValidationState.outOfLives);

      // Reset lives
      controller.resetLives();
      expect(controller.lives, 3);
      expect(controller.validationState, GameValidationState.initial);
    });
  });
}
