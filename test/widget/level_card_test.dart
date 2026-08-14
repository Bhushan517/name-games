import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/features/level_selection/presentation/widgets/challenge_card.dart';

void main() {
  group('ChallengeCard Spoiler-Free Verification Tests', () {
    late List<GeneratedChallenge> challenges;

    setUpAll(() {
      final file = File('assets/data/word_levels.json');
      final jsonString = file.readAsStringSync();
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final words = decoded
          .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
          .toList();
      challenges = ChallengeGenerator.generateAllChallenges(words);
    });

    testWidgets(
        'Incomplete ChallengeCard does NOT display answer word, pattern name, or emoji clue',
        (WidgetTester tester) async {
      // Test first 10 challenges from various modes
      for (var i = 0; i < 10; i++) {
        final challenge = challenges[i];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChallengeCard(
                challenge: challenge,
                isLocked: false,
                starsEarned: 0,
                onTap: () {},
              ),
            ),
          ),
        );

        // Verify Level number, MYSTERY WORD and metadata are shown
        expect(find.text('LEVEL ${challenge.challengeNumber}'), findsOneWidget);
        expect(find.text('MYSTERY WORD'), findsOneWidget);
        expect(
          find.text('${challenge.category} • ${challenge.letterCount} LETTERS'),
          findsOneWidget,
        );

        // MUST NOT display the answer word
        expect(find.text(challenge.word), findsNothing);

        // MUST NOT display the pattern/shape name
        expect(find.text(challenge.patternTemplate.name.toUpperCase()),
            findsNothing);

        // MUST NOT display the clue emoji
        expect(find.text(challenge.wordContent.emoji), findsNothing);
      }
    });

    testWidgets(
        'Completed ChallengeCard displays COMPLETED and stars without revealing the answer',
        (WidgetTester tester) async {
      final challenge = challenges[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChallengeCard(
              challenge: challenge,
              isLocked: false,
              starsEarned: 3,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify COMPLETED is displayed
      expect(find.text('COMPLETED'), findsOneWidget);

      // Answer word remains hidden
      expect(find.text(challenge.word), findsNothing);
      expect(find.text(challenge.wordContent.emoji), findsNothing);
    });

    testWidgets('Locked ChallengeCard displays LOCKED without answer spoilers',
        (WidgetTester tester) async {
      final challenge = challenges[499];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChallengeCard(
              challenge: challenge,
              isLocked: true,
              starsEarned: 0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text(challenge.word), findsNothing);
      expect(find.text(challenge.wordContent.emoji), findsNothing);
    });
  });
}
