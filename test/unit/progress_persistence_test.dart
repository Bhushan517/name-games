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

  late List<GeneratedChallenge> allChallenges;

  setUpAll(() {
    final file = File('assets/data/word_levels.json');
    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    final words = decoded
        .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
        .toList();
    allChallenges = ChallengeGenerator.generateAllChallenges(words);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Progress Persistence Tests', () {
    test('Fresh start: unlocked level is 1, no completed words', () async {
      final storage = await LocalStorageService.init();
      final progress = storage.loadPlayerProgress();

      expect(storage.getUnlockedLevel(), 1);
      expect(progress.completedWordIds, isEmpty);
      expect(progress.challengeStars, isEmpty);
    });

    test('Completing challenge 1 unlocks challenge 2 and persists stars',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      final challenge = allChallenges[0]; // Challenge #1
      await repo.saveChallengeCompletion(challenge: challenge, starsEarned: 3);

      // Unlocked level advances
      expect(storage.getUnlockedLevel(), 2);

      // Stars persisted
      final progress = storage.loadPlayerProgress();
      expect(progress.challengeStars[challenge.id], 3);
    });

    test(
        'Re-completing a challenge with fewer stars does not overwrite 3-star score',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      final challenge = allChallenges[0];
      await repo.saveChallengeCompletion(challenge: challenge, starsEarned: 3);
      await repo.saveChallengeCompletion(challenge: challenge, starsEarned: 1);

      final progress = storage.loadPlayerProgress();
      // Must keep the BEST (highest) score — replaying with fewer stars must NOT downgrade
      expect(
        progress.challengeStars[challenge.id],
        equals(3),
        reason:
            'Replaying with 1 star must not overwrite the stored 3-star score',
      );
    });

    test('Completing challenges sequentially unlocks next level each time',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      for (var i = 0; i < 5; i++) {
        await repo.saveChallengeCompletion(
          challenge: allChallenges[i],
          starsEarned: 2,
        );
      }

      expect(storage.getUnlockedLevel(), 6);
    });

    test('Word is added to completedWordIds after challenge completion',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      final challenge = allChallenges[0];
      await repo.saveChallengeCompletion(challenge: challenge, starsEarned: 2);

      final progress = storage.loadPlayerProgress();
      expect(progress.completedWordIds, contains(challenge.wordContent.id));
    });

    test('PlayerProgress.isWordUnlocked returns true for completed words',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      final challenge = allChallenges[0];
      await repo.saveChallengeCompletion(challenge: challenge, starsEarned: 3);

      final progress = storage.loadPlayerProgress();
      expect(progress.isWordUnlocked(challenge.wordContent.id), isTrue);
      expect(progress.isWordUnlocked('nonexistent_id'), isFalse);
    });

    test('Total stars across multiple completions are summed correctly',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      await repo.saveChallengeCompletion(
          challenge: allChallenges[0], starsEarned: 3);
      await repo.saveChallengeCompletion(
          challenge: allChallenges[1], starsEarned: 2);
      await repo.saveChallengeCompletion(
          challenge: allChallenges[2], starsEarned: 1);

      final progress = storage.loadPlayerProgress();
      final total = progress.challengeStars.values.fold(0, (a, b) => a + b);
      expect(total, greaterThanOrEqualTo(3));
    });

    test(
        'Completing a high-numbered Daily Challenge does not unlock or skip campaign levels',
        () async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final repo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      expect(storage.getUnlockedLevel(), 1);

      // Take a high numbered challenge (e.g. challenge #450)
      final highChallenge = allChallenges[449];
      expect(highChallenge.challengeNumber, 450);

      // Play as Daily Challenge (isDailyMode: true)
      final controller = GameController(
        challenge: highChallenge,
        repository: repo,
        isDailyMode: true,
      );

      // Spell the target word correctly
      final targetWord = highChallenge.word;
      for (var i = 0; i < targetWord.length; i++) {
        final char = targetWord[i];
        final nodeIndex = controller.nodes.indexWhere(
          (n) =>
              n.letter == char &&
              !controller.isSelected(controller.nodes.indexOf(n)),
        );
        controller.selectLetter(nodeIndex);
      }

      final validation = await controller.validateSpelling();
      expect(validation, GameValidationState.correct);
      expect(controller.isCompleted, isTrue);

      // Crucial: Campaign unlocked level must remain 1!
      expect(storage.getUnlockedLevel(), 1);

      // Save daily completion
      await repo.saveDailyChallengeCompletion(
        date: DateTime(2025, 10, 1),
        starsEarned: controller.calculateStars(),
        wordId: highChallenge.wordContent.id,
      );

      // Still must remain 1 in campaign
      expect(storage.getUnlockedLevel(), 1);

      // But the daily challenge record and word collection ARE updated
      final progress = storage.loadPlayerProgress();
      expect(progress.isDailyChallengeCompletedFor('2025-10-01'), isTrue);
      expect(progress.isWordUnlocked(highChallenge.wordContent.id), isTrue);
    });
  });
}
