import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/features/home/presentation/widgets/settings_dialog.dart';
import 'package:name_twist_game/features/home/presentation/widgets/help_dialog.dart';
import 'package:name_twist_game/features/level_selection/presentation/widgets/level_card.dart';
import 'package:name_twist_game/features/level_selection/presentation/widgets/pack_selector.dart';
import 'package:name_twist_game/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:name_twist_game/features/word_collection/presentation/word_collection_screen.dart';
import 'package:name_twist_game/features/word_collection/presentation/widgets/word_card.dart';
import 'package:name_twist_game/features/game/presentation/widgets/game_action_buttons.dart';
import 'package:name_twist_game/features/game/presentation/widgets/level_complete_dialog.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:name_twist_game/features/game/controller/game_controller.dart';
import 'package:name_twist_game/core/services/tts_service.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/models/word_level.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/data/models/player_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorageService storageService;
  late ChallengeRepository challengeRepository;
  late List<GeneratedChallenge> allChallenges;

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
    SharedPreferences.setMockInitialValues({
      'pref_sound': true,
      'pref_music': true,
    });
    storageService = await LocalStorageService.init();

    AudioService().enableTestMode();
    await AudioService().init(storageService);
    AudioService().testPlayedSfx.clear();
    
    TtsService.resetStateForTest();

    final wordRepo = WordRepository(LocalWordDataSource());
    challengeRepository = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storageService,
    );
  });

  group('Widget Button Sound Tests', () {
    testWidgets('Tapping Close in SettingsDialog plays exactly one button_tap sound', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SettingsDialog(storageService: storageService),
        ),
      ));

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Tapping Close in HelpDialog plays exactly one button_tap sound', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: HelpDialog(),
        ),
      ));

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Unlocked Level card -> one Button Tap', (WidgetTester tester) async {
      final challenge = allChallenges.first;
      final wordLevel = WordLevel(
        index: challenge.challengeNumber,
        word: challenge.wordContent.word,
        emoji: challenge.wordContent.emoji,
        clue: challenge.wordContent.sentenceClue,
        meaning: challenge.wordContent.meaningEnglish,
        shape: challenge.wordContent.patternTemplate,
        color: challenge.themeColor,
        points: const [],
        category: 'test',
        difficulty: 'easy',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LevelCard(
            level: wordLevel,
            isLocked: false,
            starsEarned: 0,
            onTap: AudioService.withSound(() {})!,
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Locked Level card -> zero', (WidgetTester tester) async {
      final challenge = allChallenges.first;
      final wordLevel = WordLevel(
        index: challenge.challengeNumber,
        word: challenge.wordContent.word,
        emoji: challenge.wordContent.emoji,
        clue: challenge.wordContent.sentenceClue,
        meaning: challenge.wordContent.meaningEnglish,
        shape: challenge.wordContent.patternTemplate,
        color: challenge.themeColor,
        points: const [],
        category: 'test',
        difficulty: 'easy',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LevelCard(
            level: wordLevel,
            isLocked: true,
            starsEarned: 0,
            onTap: () {}, // Simulated locked tap not wrapped in withSound
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
    });

    testWidgets('Pack selection -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PackSelector(
            selectedPack: 0,
            onPackSelected: (m) {},
          ),
        ),
      ));

      await tester.tap(find.text('Missing Letter'));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Daily Challenge Screen Back/Play -> one each', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DailyChallengeScreen(
          challengeRepository: challengeRepository,
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Word Collection Back -> one', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WordCollectionScreen(
          wordRepository: WordRepository(LocalWordDataSource()),
          progress: PlayerProgress(
            challengeStars: const {},
            completedWordIds: const {},
            lastDailyDate: '',
            lastDailyStars: 0,
            unlockedChallengeNumber: 1,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Game Close (from Out of Lives) -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            actions: [
              TextButton(
                onPressed: AudioService.withSound(() {}),
                child: const Text('EXIT LEVEL'),
              ),
              FilledButton(
                onPressed: AudioService.withSound(() {}),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text('EXIT LEVEL'));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });
    
    testWidgets('Retry (from Out of Lives) -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            actions: [
              TextButton(
                onPressed: AudioService.withSound(() {}),
                child: const Text('EXIT LEVEL'),
              ),
              FilledButton(
                onPressed: AudioService.withSound(() {}),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text('TRY AGAIN'));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Check Word -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GameActionButtons(
            onUndo: () {},
            onCheckWord: () {},
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.check_circle_rounded));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Level Complete Continue -> one', (WidgetTester tester) async {
      final challenge = allChallenges.first;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LevelCompleteDialog(
            challenge: challenge,
            stars: 3,
            onContinue: () {},
          ),
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Letter selection -> Letter Select only, no Button Tap', (WidgetTester tester) async {
      final challenge = allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
      final controller = GameController(challenge: challenge, repository: challengeRepository);
      
      AudioService().testPlayedSfx.clear();
      controller.selectLetter(0);
      
      expect(AudioService().testPlayedSfx.where((s) => s == 'letter_select.wav').length, 1);
      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
      controller.dispose();
    });

    testWidgets('Undo -> Letter Undo only', (WidgetTester tester) async {
      final challenge = allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
      final controller = GameController(challenge: challenge, repository: challengeRepository);
      
      controller.selectLetter(0); // select a letter
      
      AudioService().testPlayedSfx.clear();
      controller.undo(); // undo it
      
      expect(AudioService().testPlayedSfx.where((s) => s == 'letter_undo.wav').length, 1);
      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
      controller.dispose();
    });

    testWidgets('TTS Speak -> no Button Tap', (WidgetTester tester) async {
      final wordContent = allChallenges.first.wordContent;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WordCard(word: wordContent, isUnlocked: true),
        ),
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
    });

    testWidgets('Sound OFF -> zero Button Tap globally', (WidgetTester tester) async {
      await AudioService().setSoundEnabled(false);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SettingsDialog(storageService: storageService),
        ),
      ));

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
    });
  });
}
