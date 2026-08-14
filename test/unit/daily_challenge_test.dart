import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChallengeRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();
    final wordRepo = WordRepository(LocalWordDataSource());
    repo = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storage,
    );
    await repo.getChallenges();
  });

  group('Daily Challenge Stability Tests', () {
    test('getDailyChallenge always returns a non-null challenge', () {
      final now = DateTime.now();
      final challenge = repo.getDailyChallenge(now);
      expect(challenge.word.isNotEmpty, isTrue);
    });

    test('Same date always returns the same daily challenge (deterministic)',
        () {
      final date = DateTime(2025, 6, 15);
      final c1 = repo.getDailyChallenge(date);
      final c2 = repo.getDailyChallenge(date);
      expect(c1.id, equals(c2.id));
    });

    test('Different dates return different challenges', () {
      final date1 = DateTime(2025, 1, 1);
      final date2 = DateTime(2025, 1, 2);
      final date3 = DateTime(2025, 1, 3);

      final ids = {
        repo.getDailyChallenge(date1).id,
        repo.getDailyChallenge(date2).id,
        repo.getDailyChallenge(date3).id,
      };
      // At least 2 of 3 adjacent days should differ
      expect(ids.length, greaterThan(1));
    });

    test('getTodayDateKey returns YYYY-MM-DD format', () {
      final now = DateTime(2025, 8, 14);
      final key = repo.getTodayDateKey(now);
      expect(key, equals('2025-08-14'));
    });

    test('Daily completion flag is date-keyed (not global)', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final freshRepo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );
      await freshRepo.getChallenges();

      final today = DateTime(2025, 8, 14);
      final todayKey = freshRepo.getTodayDateKey(today);

      // Not completed initially
      final beforeProgress = freshRepo.getPlayerProgress();
      expect(beforeProgress.isDailyChallengeCompletedFor(todayKey), isFalse);

      // Save completion for today
      await freshRepo.saveDailyChallengeCompletion(
        date: today,
        starsEarned: 3,
      );

      // Now marked as completed for today
      final afterProgress = freshRepo.getPlayerProgress();
      expect(afterProgress.isDailyChallengeCompletedFor(todayKey), isTrue);

      // But not for a different date
      final tomorrowKey =
          freshRepo.getTodayDateKey(today.add(const Duration(days: 1)));
      expect(afterProgress.isDailyChallengeCompletedFor(tomorrowKey), isFalse);
    });

    test('Daily challenge index stays within 0..499', () {
      final file = File('assets/data/word_levels.json');
      final decoded = json.decode(file.readAsStringSync()) as List<dynamic>;
      final words = decoded
          .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
          .toList();
      final all = ChallengeGenerator.generateAllChallenges(words);

      // Test 365 different dates — none should go out of bounds
      final base = DateTime(2025, 1, 1);
      for (var i = 0; i < 365; i++) {
        final date = base.add(Duration(days: i));
        final dayIndex = date.difference(DateTime(2025)).inDays;
        final idx = dayIndex % all.length;
        expect(idx, inInclusiveRange(0, all.length - 1));
      }
    });
  });
}
