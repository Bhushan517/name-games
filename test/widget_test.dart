import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/app/app.dart';
import 'package:name_twist_game/app/routes/app_router.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/level_data/default_levels.dart';
import 'package:name_twist_game/data/repositories/level_repository.dart';
import 'package:name_twist_game/features/game/presentation/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpTime(WidgetTester tester, int millis) async {
    final steps = (millis / 50).ceil();
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Spell & Shape Quest Refactored App Flow Tests', () {
    testWidgets(
        'First launch flow: Splash -> Onboarding -> Home -> Level Selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = await LocalStorageService.init();
      final repo = LevelRepository(storage);
      final router = AppRouter(storageService: storage, levelRepository: repo);

      await tester.pumpWidget(SpellShapeQuestApp(appRouter: router));

      // Splash
      expect(find.text('SPELL & SHAPE'), findsOneWidget);
      expect(find.text('Q U E S T'), findsOneWidget);

      // Transition to Onboarding
      await pumpTime(tester, 3600);
      expect(find.text('UNSCRAMBLE WORDS'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      // Slide 2
      await tester.tap(find.text('NEXT  →'));
      await pumpTime(tester, 700);
      expect(find.text('REVEAL PATTERNS'), findsOneWidget);

      // Slide 3
      await tester.tap(find.text('NEXT  →'));
      await pumpTime(tester, 700);
      expect(find.text('LEARN & WIN'), findsOneWidget);
      expect(find.text('START THE QUEST'), findsOneWidget);

      // Start Quest -> Home
      await tester.tap(find.text('START THE QUEST'));
      await pumpTime(tester, 700);

      expect(find.text('WORDS CREATE MAGIC'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);

      // Open Help dialog
      final helpBtn = find.byIcon(Icons.help_outline_rounded);
      await tester.tap(helpBtn);
      await pumpTime(tester, 400);
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      await tester.tap(find.text('GOT IT'));
      await pumpTime(tester, 400);

      // Open Level Selection
      await tester.tap(find.text('PLAY NOW'));
      await pumpTime(tester, 700);

      expect(find.text('CHOOSE A LEVEL'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('MYSTERY WORD'), findsWidgets);
    });

    testWidgets('Subsequent launch skips onboarding and goes straight to Home',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'seen': true,
        'unlocked_level': 2,
        'stars_0': 3,
      });

      final storage = await LocalStorageService.init();
      final repo = LevelRepository(storage);
      final router = AppRouter(storageService: storage, levelRepository: repo);

      await tester.pumpWidget(SpellShapeQuestApp(appRouter: router));
      await pumpTime(tester, 1800);

      expect(find.text('WORDS CREATE MAGIC'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
      expect(find.text('3/15'), findsOneWidget);
    });

    testWidgets(
        'Level 1 complete gameplay flow with answer validation and win dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = await LocalStorageService.init();
      final repo = LevelRepository(storage);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: defaultLevels[0],
            repository: repo,
          ),
        ),
      );
      await pumpTime(tester, 500);

      expect(find.text('LEVEL 1 / 5'), findsOneWidget);
      expect(find.text('STAR'), findsOneWidget);
      expect(find.text('FIRST LETTER HINT'), findsOneWidget);

      // Tap Hint
      await tester.tap(find.text('FIRST LETTER HINT'));
      await pumpTime(tester, 300);
      expect(find.text('STARTS WITH S'), findsOneWidget);

      // Tap S then H then Undo
      await tester.tap(find.widgetWithText(GestureDetector, 'S'));
      await pumpTime(tester, 250);
      await tester.tap(find.widgetWithText(GestureDetector, 'H'));
      await pumpTime(tester, 250);
      await tester.tap(find.text('UNDO'));
      await pumpTime(tester, 250);

      // Now spell SHINE
      const word = 'SHINE';
      for (var i = 0; i < word.length; i++) {
        await tester.tap(find.widgetWithText(GestureDetector, word[i]));
        await pumpTime(tester, 250);
      }

      // Check Word
      await tester.tap(find.text('CHECK WORD'));
      await pumpTime(tester, 1200);

      // Check Win dialog
      expect(find.text('BRILLIANT! 🎉'), findsOneWidget);
      expect(find.text('To produce or reflect bright light.'), findsOneWidget);
      expect(find.text('CONTINUE  →'), findsOneWidget);

      await tester.tap(find.text('CONTINUE  →'));
      await pumpTime(tester, 500);
    });

    testWidgets(
        'Responsive check on 360x800, 393x873, and 412x915 for all 5 levels',
        (WidgetTester tester) async {
      final storage = await LocalStorageService.init();
      final repo = LevelRepository(storage);

      final screenSizes = [
        const Size(360, 800),
        const Size(393, 873),
        const Size(412, 915),
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        for (var i = 0; i < 5; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: GameScreen(
                level: defaultLevels[i],
                repository: repo,
              ),
            ),
          );
          await pumpTime(tester, 300);
          expect(find.text('LEVEL ${i + 1} / 5'), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
