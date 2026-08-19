import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/features/home/presentation/widgets/settings_dialog.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorageService storageService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'pref_sound': true,
      'pref_music': true,
    });
    storageService = await LocalStorageService.init();

    AudioService().enableTestMode();
    await AudioService().init(storageService);
    AudioService().testPlayedSfx.clear();
  });

  testWidgets('Tapping Close in SettingsDialog plays exactly one button_tap sound', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsDialog(storageService: storageService),
      ),
    ));

    expect(find.text('CLOSE'), findsOneWidget);

    // Tap the CLOSE button
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    final taps = AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length;
    expect(taps, 1, reason: 'Expected exactly one button_tap.wav to play');
  });

  testWidgets('Tapping Close in SettingsDialog does NOT play sound when Sound is OFF', (WidgetTester tester) async {
    await AudioService().setSoundEnabled(false);
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsDialog(storageService: storageService),
      ),
    ));

    expect(find.text('CLOSE'), findsOneWidget);

    // Tap the CLOSE button
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    final taps = AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length;
    expect(taps, 0, reason: 'Expected zero button_tap.wav to play when sound is disabled');
  });
}
