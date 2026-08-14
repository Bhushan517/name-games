import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/main.dart';
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

  group('Spell & Shape Quest Game Flow Tests', () {
    testWidgets('First launch shows Splash and transitions to Onboarding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const App(first: true));

      // Check Splash elements
      expect(find.text('SPELL & SHAPE'), findsOneWidget);
      expect(find.text('Q U E S T'), findsOneWidget);

      // Advance time for splash transition (2700ms delay + 650ms transition)
      await pumpTime(tester, 3600);

      // Should now be on Onboarding
      expect(find.text('UNSCRAMBLE WORDS'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.text('NEXT  →'), findsOneWidget);

      // Tap NEXT to slide 2
      await tester.tap(find.text('NEXT  →'));
      await pumpTime(tester, 700);
      expect(find.text('REVEAL PATTERNS'), findsOneWidget);

      // Tap NEXT to slide 3
      await tester.tap(find.text('NEXT  →'));
      await pumpTime(tester, 700);
      expect(find.text('LEARN & WIN'), findsOneWidget);
      expect(find.text('START THE QUEST'), findsOneWidget);

      // Tap START THE QUEST to navigate to Home
      await tester.tap(find.text('START THE QUEST'));
      await pumpTime(tester, 700);

      expect(find.text('WORDS CREATE MAGIC'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);
    });

    testWidgets('Home screen opens Help dialog and Level Map at 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const App(first: false));
      await pumpTime(tester, 500);

      // Open Help dialog
      final helpButton = find.byIcon(Icons.help_outline_rounded);
      expect(helpButton, findsOneWidget);
      await tester.tap(helpButton);
      await pumpTime(tester, 500);

      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('GOT IT'), findsOneWidget);

      // Close Help dialog
      await tester.tap(find.text('GOT IT'));
      await pumpTime(tester, 500);

      // Tap PLAY NOW to go to Level Map
      await tester.tap(find.text('PLAY NOW'));
      await pumpTime(tester, 700);

      expect(find.text('CHOOSE A LEVEL'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('Game level 1 play flow: Hint, letters, undo, and win at 412x915',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Game(0)));
      await pumpTime(tester, 500);

      // Check level 1 UI
      expect(find.text('LEVEL 1 / 5'), findsOneWidget);
      expect(find.text('STAR'), findsOneWidget);
      expect(find.text('The sun can _____ brightly.'), findsOneWidget);
      expect(find.text('FIRST LETTER HINT'), findsOneWidget);

      // Tap Hint
      await tester.tap(find.text('FIRST LETTER HINT'));
      await pumpTime(tester, 300);
      expect(find.text('STARTS WITH S'), findsOneWidget);

      // S H I N E letters
      // Tap S
      await tester.tap(find.widgetWithText(GestureDetector, 'S'));
      await pumpTime(tester, 300);

      // Tap H
      await tester.tap(find.widgetWithText(GestureDetector, 'H'));
      await pumpTime(tester, 300);

      // Tap UNDO
      await tester.tap(find.text('UNDO'));
      await pumpTime(tester, 300);

      // Now enter SHINE in order
      const word = 'SHINE';
      for (var i = 0; i < word.length; i++) {
        final letter = word[i];
        await tester.tap(find.widgetWithText(GestureDetector, letter));
        await pumpTime(tester, 250);
      }

      // Tap CHECK WORD
      await tester.tap(find.text('CHECK WORD'));
      await pumpTime(tester, 1200);

      // Verify Win dialog appeared
      expect(find.text('BRILLIANT! 🎉'), findsOneWidget);
      expect(find.text('To produce or reflect bright light.'), findsOneWidget);
      expect(find.text('CONTINUE  →'), findsOneWidget);

      await tester.tap(find.text('CONTINUE  →'));
      await pumpTime(tester, 500);
    });

    testWidgets('All 5 levels render without overflow on 360x800 and 412x915',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(360, 800),
        const Size(412, 915),
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        for (var i = 0; i < 5; i++) {
          await tester.pumpWidget(MaterialApp(home: Game(i)));
          await pumpTime(tester, 300);
          expect(find.text('LEVEL ${i + 1} / 5'), findsOneWidget);
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
