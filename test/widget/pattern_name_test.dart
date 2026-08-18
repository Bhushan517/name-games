import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/features/game/presentation/game_screen.dart';
import 'package:name_twist_game/features/game/presentation/widgets/animated_letter_node.dart';
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

  group('Pattern Name Visibility Tests', () {
    testWidgets(
        'Pattern name is NOT visible before completion; shows MYSTERY PATTERN',
        (WidgetTester tester) async {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
      final patternName = challenge.patternTemplate.name.toUpperCase();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            challenge: challenge,
            repository: challengeRepository,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Must show MYSTERY PATTERN in the header
      expect(find.text('MYSTERY PATTERN'), findsOneWidget);

      // Must NOT show the real pattern name before completion
      expect(find.text(patternName), findsNothing);
    });

    testWidgets('Pattern name is revealed only AFTER correct word completion',
        (WidgetTester tester) async {
      final challenge =
          allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
      final patternName = challenge.patternTemplate.name.toUpperCase();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            challenge: challenge,
            repository: challengeRepository,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('MYSTERY PATTERN'), findsOneWidget);
      expect(find.text(patternName), findsNothing);

      // Tap all letter nodes in target word sequence to complete, handling duplicates
      for (var i = 0; i < challenge.word.length; i++) {
        final char = challenge.word[i];
        final nodeFinder = find.byWidgetPredicate(
          (w) => w is AnimatedLetterNode && w.letter == char && !w.isSelected,
        );
        expect(nodeFinder, findsWidgets);

        await tester.tap(nodeFinder.first);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Tap CHECK WORD unconditionally
      expect(find.text('CHECK WORD'), findsOneWidget);
      await tester.tap(find.text('CHECK WORD'));
      // Wait for the 650ms completion delay and dialog
      await tester.pumpAndSettle();

      // Verify pattern name is now revealed in GameScreen / LevelCompleteDialog
      expect(find.text(patternName), findsWidgets);
    });
  });
}
