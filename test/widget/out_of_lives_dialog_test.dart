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
import 'package:name_twist_game/features/game/presentation/widgets/missing_letter_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<GeneratedChallenge> allChallenges;
  late ChallengeRepository challengeRepository;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();

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
      storageService: storage,
    );
  });

  group('Out of Lives Dialog Tests (Centralized & No Duplicates)', () {
    testWidgets(
        'Final life lost by wrong spelling triggers exactly ONE Out of Lives dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final challenge = allChallenges
          .firstWhere((c) => c.mode == ChallengeMode.missingLetter);
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

      // Exhaust lives with guaranteed wrong choices
      for (var attempt = 0; attempt < initialLives; attempt++) {
        final choiceButtons = find.descendant(
          of: find.byType(MissingLetterBoard),
          matching: find.byType(InkWell),
        );
        expect(choiceButtons, findsWidgets);

        // Tap choice button to fill slot
        for (var slot = 0;
            slot < challenge.difficultyConfig.missingLetterCount;
            slot++) {
          await tester.tap(choiceButtons.last, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 20));
        }

        await tester.tap(find.text(AppStrings.checkWord), warnIfMissed: false);
        // Wait for 420ms shake animation to finish
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Allow dialog route transition animation to render into view
      await tester.pump(const Duration(milliseconds: 300));

      // Crucial: exactly ONE dialog must be present
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(AppStrings.outOfLives), findsOneWidget);
      expect(find.text(AppStrings.tryAgain), findsOneWidget);
      expect(find.text(AppStrings.exitLevel), findsOneWidget);
    });

    testWidgets(
        'Final life lost by timeout triggers exactly ONE Out of Lives dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Settle frame
      await tester.pump(const Duration(milliseconds: 300));

      // Crucial: exactly ONE dialog must be present
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(AppStrings.outOfLives), findsOneWidget);
    });

    testWidgets('Retry closes Out of Lives dialog and resets the game state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Advance time until out of lives
      for (var i = 0; i < initialLives; i++) {
        await tester.pump(Duration(seconds: timerSecs + 1));
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.outOfLives), findsOneWidget);

      // Tap TRY AGAIN
      await tester.tap(find.text(AppStrings.tryAgain));
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog is dismissed and game is active again
      expect(find.text(AppStrings.outOfLives), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
        'Exit closes Out of Lives dialog and returns to previous screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
      final timerSecs = challenge.difficultyConfig.timerSeconds;
      final initialLives = challenge.difficultyConfig.lives;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          challenge: challenge,
                          repository: challengeRepository,
                        ),
                      ),
                    );
                  },
                  child: const Text('OPEN_GAME'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Open game screen
      await tester.tap(find.text('OPEN_GAME'));
      await tester.pump(const Duration(milliseconds: 500));

      // Advance time until all lives are exhausted
      for (var i = 0; i < initialLives; i++) {
        await tester.pump(Duration(seconds: timerSecs + 1));
      }

      // Allow dialog route transition animation to render into view
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.outOfLives), findsOneWidget);

      // Tap EXIT
      await tester.tap(find.text(AppStrings.exitLevel));
      await tester.pumpAndSettle();

      // Should be back on the initial screen
      expect(find.text('OPEN_GAME'), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    });
  });
}
