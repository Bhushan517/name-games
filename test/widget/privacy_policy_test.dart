import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/constants/app_constants.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/core/services/url_launcher_service.dart';
import 'package:name_twist_game/features/home/presentation/widgets/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'pref_sound': true});
    storage = await LocalStorageService.init();
    AudioService().enableTestMode();
    await AudioService().init(storage);
    AudioService().testPlayedSfx.clear();
  });

  tearDown(() {
    UrlLauncherService.mockLauncher = null;
    AudioService().disposeAll();
  });

  group('Privacy Policy Settings & Launcher Tests', () {
    testWidgets(
        'SettingsDialog renders Privacy Policy option with correct icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(storageService: storage),
          ),
        ),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets(
        'Tapping Privacy Policy plays button_tap sound and opens external URL in LaunchMode.externalApplication',
        (WidgetTester tester) async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      UrlLauncherService.mockLauncher =
          (url, {mode = LaunchMode.platformDefault}) async {
        launchedUri = url;
        launchedMode = mode;
        return true;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(storageService: storage),
          ),
        ),
      );

      AudioService().testPlayedSfx.clear();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(launchedUri, isNotNull);
      expect(launchedUri.toString(), equals(AppConstants.privacyPolicyUrl));
      expect(launchedUri.toString(), contains('/view'));
      expect(launchedMode, equals(LaunchMode.externalApplication));

      // Verify button_tap sound played exactly once
      final taps =
          AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav');
      expect(taps.length, equals(1));
    });

    testWidgets(
        'Launcher failure shows error SnackBar and handles error safely',
        (WidgetTester tester) async {
      UrlLauncherService.mockLauncher =
          (url, {mode = LaunchMode.platformDefault}) async {
        return false; // simulate failure
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(storageService: storage),
          ),
        ),
      );

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Unable to open Privacy Policy. Please check your internet connection.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Launcher exception shows error SnackBar without crashing',
        (WidgetTester tester) async {
      UrlLauncherService.mockLauncher =
          (url, {mode = LaunchMode.platformDefault}) async {
        throw Exception('Simulated launcher error');
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(storageService: storage),
          ),
        ),
      );

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Unable to open Privacy Policy. Please check your internet connection.',
        ),
        findsOneWidget,
      );
    });
  });
}
