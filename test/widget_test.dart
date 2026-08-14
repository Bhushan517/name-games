import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/features/game/presentation/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Spell & Shape Quest 500-Level Engine Flow Tests', () {
    late List<WordContent> testWords;
    late List<GeneratedChallenge> testChallenges;

    setUpAll(() {
      final file = File('assets/data/word_levels.json');
      final jsonString = file.readAsStringSync();
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      testWords = decoded
          .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
          .toList();
      testChallenges = ChallengeGenerator.generateAllChallenges(testWords);
    });

    testWidgets('GameScreen renders LEVEL header for each of 5 modes',
        (WidgetTester tester) async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final challengeRepo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      // One challenge per mode (indices 0-4 cover modes 1-5)
      final modeChallenges = testChallenges.take(5).toList();

      for (final challenge in modeChallenges) {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              challenge: challenge,
              repository: challengeRepo,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text('LEVEL ${challenge.challengeNumber} / 500'),
          findsOneWidget,
          reason: 'Mode ${challenge.mode} header not found',
        );
      }
    });

    testWidgets('Responsive layout: no overflow on 360x800, 393x873, 412x915',
        (WidgetTester tester) async {
      final storage = await LocalStorageService.init();
      final wordRepo = WordRepository(LocalWordDataSource());
      final challengeRepo = ChallengeRepository(
        wordRepository: wordRepo,
        storageService: storage,
      );

      final screenSizes = [
        const Size(360, 800),
        const Size(393, 873),
        const Size(412, 915),
      ];

      // Test mode 1 (Unscramble) across all screen sizes — fastest check
      final challenge = testChallenges[0];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              challenge: challenge,
              repository: challengeRepo,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text('LEVEL ${challenge.challengeNumber} / 500'),
          findsOneWidget,
          reason: 'Overflow or missing header on $size',
        );
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
