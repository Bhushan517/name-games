import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
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
  late ChallengeRepository challengeRepository;
  late List<GeneratedChallenge> allChallenges;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await LocalStorageService.init();

    final file = File('assets/data/word_levels.json');
    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    final words = decoded
        .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
        .toList();

    allChallenges = ChallengeGenerator.generateAllChallenges(words);
    final wordRepo = WordRepository(LocalWordDataSource());
    challengeRepository = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storageService,
    );
  });

  group('All 5 Game Modes Controller Unit Tests', () {
    test('Mode 1: Unscramble mode selects letters, validates, and awards stars',
        () async {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
      final controller = GameController(
        challenge: challenge,
        repository: challengeRepository,
      );

      expect(controller.mode, ChallengeMode.unscramble);
      expect(controller.lives, challenge.difficultyConfig.lives);

      // Select target spelling (handling duplicate letters)
      for (var i = 0; i < challenge.word.length; i++) {
        final char = challenge.word[i];
        final nodeIndex = controller.nodes.indexWhere(
          (n) => n.letter == char && !controller.isSelected(controller.nodes.indexOf(n)),
        );
        controller.selectLetter(nodeIndex);
      }

      final state = await controller.validateSpelling();
      expect(state, GameValidationState.correct);
      expect(controller.isCompleted, true);
      expect(controller.calculateStars(), 3);
    });

    test('Mode 2: Missing Letter mode fills blanks and validates', () async {
      final challenge = allChallenges
          .firstWhere((c) => c.mode == ChallengeMode.missingLetter);
      final controller = GameController(
        challenge: challenge,
        repository: challengeRepository,
      );

      expect(controller.mode, ChallengeMode.missingLetter);
      expect(controller.missingIndices.isNotEmpty, isTrue);
      expect(controller.missingLetterChoices.isNotEmpty, isTrue);

      // Fill in correct missing letters
      for (final missingIdx in controller.missingIndices) {
        final correctChar = challenge.word[missingIdx];
        controller.fillMissingLetter(correctChar);
      }

      final state = await controller.validateSpelling();
      expect(state, GameValidationState.correct);
      expect(controller.isCompleted, true);
    });

    test('Mode 3: Listen & Spell mode triggers speech and completes spelling',
        () async {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.listenSpell);
      final controller = GameController(
        challenge: challenge,
        repository: challengeRepository,
      );

      expect(controller.mode, ChallengeMode.listenSpell);
      await controller.speakWordOrClue();

      for (var i = 0; i < challenge.word.length; i++) {
        final char = challenge.word[i];
        final nodeIndex = controller.nodes.indexWhere(
          (n) => n.letter == char && !controller.isSelected(controller.nodes.indexOf(n)),
        );
        controller.selectLetter(nodeIndex);
      }

      final state = await controller.validateSpelling();
      expect(state, GameValidationState.correct);
    });

    test(
        'Mode 4: Memory Letters mode hides letters after preview and allows peek replay',
        () {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.memory);
      final controller = GameController(
        challenge: challenge,
        repository: challengeRepository,
      );

      expect(controller.mode, ChallengeMode.memory);
      expect(controller.isMemoryRevealed, isTrue);

      controller.replayMemoryPreview();
      expect(controller.hintUsed, isTrue);
    });

    test('Mode 5: Timed Challenge initializes timer and handles pause/resume',
        () {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
      final controller = GameController(
        challenge: challenge,
        repository: challengeRepository,
      );

      expect(controller.mode, ChallengeMode.timed);
      expect(controller.timeRemaining, challenge.difficultyConfig.timerSeconds);

      controller.pauseTimer();
      expect(controller.isTimerPaused, isTrue);

      controller.resumeTimer();
      expect(controller.isTimerPaused, isFalse);

      controller.dispose();
    });
  });
}
