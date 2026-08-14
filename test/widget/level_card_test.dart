import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/data/level_data/default_levels.dart';
import 'package:name_twist_game/features/level_selection/presentation/widgets/level_card.dart';

void main() {
  group('LevelCard Spoiler-Free Verification Tests', () {
    testWidgets(
        'Incomplete LevelCard does NOT display answer word, shape name, or emoji clue',
        (WidgetTester tester) async {
      for (final level in defaultLevels) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LevelCard(
                level: level,
                isLocked: false,
                starsEarned: 0,
                onTap: () {},
              ),
            ),
          ),
        );

        // Verify Level Header and Mystery Word are shown
        expect(find.text('LEVEL ${level.index + 1}'), findsOneWidget);
        expect(find.text('MYSTERY WORD'), findsOneWidget);
        expect(
          find.text('${level.category} • ${level.letterCount} LETTERS'),
          findsOneWidget,
        );

        // MUST NOT display the answer word
        expect(find.text(level.word), findsNothing);

        // MUST NOT display the pattern/shape name
        expect(find.text(level.shape), findsNothing);

        // MUST NOT display the clue emoji
        expect(find.text(level.emoji), findsNothing);
      }
    });

    testWidgets(
        'Completed LevelCard displays COMPLETED and stars without spoiling the answer word',
        (WidgetTester tester) async {
      final level = defaultLevels[0]; // SHINE / STAR

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelCard(
              level: level,
              isLocked: false,
              starsEarned: 3,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify COMPLETED tag
      expect(find.text('COMPLETED'), findsOneWidget);

      // Answer word, shape name, and emoji remain hidden
      expect(find.text('SHINE'), findsNothing);
      expect(find.text('STAR'), findsNothing);
      expect(find.text('✨'), findsNothing);
    });

    testWidgets('Locked LevelCard displays LOCKED without answer spoilers',
        (WidgetTester tester) async {
      final level = defaultLevels[4]; // PLANT / TREE

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelCard(
              level: level,
              isLocked: true,
              starsEarned: 0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('PLANT'), findsNothing);
      expect(find.text('TREE'), findsNothing);
      expect(find.text('🌱'), findsNothing);
    });
  });
}
