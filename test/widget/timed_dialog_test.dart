import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/constants/app_strings.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/features/game/presentation/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<GeneratedChallenge> allChallenges;
  late ChallengeRepository challengeRepository;

  setUpAll(() {
    final file = File('assets/data/word_levels.json');
    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    final words = decoded
        .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
        .toList();

    allChallenges = ChallengeGenerator.generateAllChallenges(words);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();
    final wordRepo = WordRepository(LocalWordDataSource());
    challengeRepository = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storage,
    );
  });

  group('Timed Mode Out of Lives Dialog Tests', () {
    testWidgets(
        'Timed mode displays Out of Lives dialog on timeout with Retry and Exit actions',
        (WidgetTester tester) async {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
      final timerSecs = challenge.difficultyConfig.timerSeconds;
      final initialLives = challenge.difficultyConfig.lives;

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            challenge: challenge,
            repository: challengeRepository,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Advance time until all lives are exhausted
      for (var i = 0; i < initialLives; i++) {
        await tester.pump(Duration(seconds: timerSecs + 1));
      }

      // Dialog should be shown via post-frame callback
      await tester.pump(const Duration(milliseconds: 100));

      // Verify dialog is visible
      expect(find.text(AppStrings.outOfLives), findsOneWidget);
      expect(find.text(AppStrings.tryAgain), findsOneWidget);
      expect(find.text(AppStrings.exitLevel), findsOneWidget);

      // Tap TRY AGAIN to reset lives
      await tester.tap(find.text(AppStrings.tryAgain));
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog should be dismissed
      expect(find.text(AppStrings.outOfLives), findsNothing);
    });
  });
}
