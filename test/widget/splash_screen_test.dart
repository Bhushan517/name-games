import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:name_twist_game/features/splash/presentation/splash_screen.dart';
import 'package:name_twist_game/core/constants/app_strings.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';

void main() {
  testWidgets('Splash Screen Branding Test', (WidgetTester tester) async {
    // Verify the AppStrings constant is correctly set
    expect(AppStrings.appName, 'WordSpark');

    // Initialize SharedPreferences and LocalStorageService
    SharedPreferences.setMockInitialValues({});
    final storageService = await LocalStorageService.init();

    // Build the splash screen
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(storageService: storageService),
    ));

    // Verify the visual text on the splash screen
    expect(find.text('WORDSPARK'), findsOneWidget);

    // Ensure the old names are nowhere to be found
    expect(find.text('SPELL & SHAPE'), findsNothing);
    expect(find.text('Spell & Shape Quest'), findsNothing);
    expect(find.text('Name Twist'), findsNothing);
  });
}
