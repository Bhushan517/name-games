import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/features/home/presentation/home_screen.dart';
import 'package:name_twist_game/features/level_selection/presentation/level_selection_screen.dart';
import 'package:name_twist_game/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:name_twist_game/features/word_collection/presentation/word_collection_screen.dart';
import 'package:name_twist_game/features/game/presentation/widgets/game_action_buttons.dart';
import 'package:name_twist_game/features/game/presentation/widgets/level_complete_dialog.dart';
import 'package:name_twist_game/features/game/presentation/game_screen.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:name_twist_game/features/game/controller/game_controller.dart';
import 'package:name_twist_game/core/services/tts_service.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/app/routes/app_router.dart';
import 'package:name_twist_game/features/word_collection/presentation/widgets/word_card.dart';
import 'package:name_twist_game/core/utils/difficulty_config.dart';
import 'package:name_twist_game/features/level_selection/presentation/widgets/challenge_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorageService storageService;
  late ChallengeRepository challengeRepository;
  late WordRepository wordRepository;
  late AppRouter appRouter;
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
      'unlocked_challenge_num': 10,
    });
    storageService = await LocalStorageService.init();

    AudioService().enableTestMode();
    await AudioService().init(storageService);
    AudioService().testPlayedSfx.clear();

    TtsService.resetStateForTest();

    wordRepository = WordRepository(LocalWordDataSource());
    challengeRepository = ChallengeRepository(
      wordRepository: wordRepository,
      storageService: storageService,
    );

    await challengeRepository.getChallenges();

    appRouter = AppRouter(
      storageService: storageService,
      wordRepository: wordRepository,
      challengeRepository: challengeRepository,
    );
  });

  Widget buildApp(Widget home) {
    return MaterialApp(
      home: home,
      onGenerateRoute: appRouter.generateRoute,
    );
  }

  group('Widget Button Sound Tests', () {
    // --- HOME SCREEN ---

    testWidgets('Home Settings Close -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(HomeScreen(storageService: storageService)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      AudioService().testPlayedSfx.clear(); 

      await tester.tap(find.text('CLOSE'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Home Help Close -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(HomeScreen(storageService: storageService)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      AudioService().testPlayedSfx.clear();

      await tester.tap(find.text('GOT IT'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Home Play Now -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(HomeScreen(storageService: storageService)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('PLAY NOW'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Home Daily Quest -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(HomeScreen(storageService: storageService)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('DAILY QUEST'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Home My Words -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(HomeScreen(storageService: storageService)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('MY WORDS'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    // --- LEVEL SELECTION SCREEN ---

    testWidgets('Level Selection Back -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(LevelSelectionScreen(repository: challengeRepository)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Pack Selection -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(LevelSelectionScreen(repository: challengeRepository)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Pack 2 (51–100)'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Unlocked Level Card -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(LevelSelectionScreen(repository: challengeRepository)));
      await tester.pump(const Duration(seconds: 1));
      
      // Level 1 is unlocked (progress unlockedChallengeNumber is 10)
      final level1Card = find.byType(ChallengeCard).first;
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: level1Card, matching: find.byType(InkWell)).first
      );
      inkWell.onTap?.call();
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Locked Level Card -> zero sound', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(LevelSelectionScreen(repository: challengeRepository)));
      await tester.pump(const Duration(seconds: 1));
      
      // Level 11 is locked. Scroll to it.
      final level11Card = find.widgetWithText(ChallengeCard, 'LEVEL 11');
      await tester.scrollUntilVisible(
        level11Card, 
        100, 
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump(const Duration(seconds: 1));
      final inkWell11 = tester.widget<InkWell>(
        find.descendant(of: level11Card, matching: find.byType(InkWell)).first
      );
      
      // Tap it directly
      if (inkWell11.onTap != null) inkWell11.onTap!();
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
    });

    // --- DAILY CHALLENGE SCREEN ---

    testWidgets('Daily Challenge Back -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(DailyChallengeScreen(challengeRepository: challengeRepository)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Daily Challenge Play -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(DailyChallengeScreen(challengeRepository: challengeRepository)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('START DAILY QUEST'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    // --- WORD COLLECTION SCREEN ---

    testWidgets('Word Collection Back -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(WordCollectionScreen(
        wordRepository: wordRepository,
        progress: challengeRepository.getPlayerProgress(),
      )));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    // --- GAME SCREEN & DIALOGS ---

    testWidgets('Game Screen Close -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(GameScreen(
        challenge: allChallenges.first,
        repository: challengeRepository,
      )));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Check Word -> one button_tap', (WidgetTester tester) async {
      // Testing the production GameActionButtons widget
      await tester.pumpWidget(buildApp(Scaffold(
        body: GameActionButtons(
          onUndo: () {},
          onCheckWord: () {}, // Test does not wrap in withSound
        ),
      )));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.check_circle_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Out-of-Lives Exit Level -> one button_tap', (WidgetTester tester) async {
      final baseChallenge = allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
      final timedChallenge = GeneratedChallenge(
        id: baseChallenge.id,
        mode: baseChallenge.mode,
        challengeNumber: baseChallenge.challengeNumber,
        wordContent: baseChallenge.wordContent,
        themeColor: baseChallenge.themeColor,
        patternTemplate: baseChallenge.patternTemplate,
        difficultyConfig: const DifficultyConfig(
          difficulty: 'custom',
          timerSeconds: 1, // Only 1 second
          lives: 1,        // Only 1 life
          memoryPreviewSeconds: 0,
          missingLetterCount: 1,
          allowFirstLetterHint: false,
          maximumStars: 3,
        ),
      );
      
      await tester.pumpWidget(buildApp(GameScreen(
        challenge: timedChallenge,
        repository: challengeRepository,
      )));
      await tester.pump(const Duration(seconds: 1));
      
      // Let time run out to trigger Out of Lives
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      
      AudioService().testPlayedSfx.clear();
      await tester.tap(find.text('EXIT'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Out-of-Lives Try Again -> one button_tap', (WidgetTester tester) async {
      final baseChallenge = allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
      final timedChallenge = GeneratedChallenge(
        id: baseChallenge.id,
        mode: baseChallenge.mode,
        challengeNumber: baseChallenge.challengeNumber,
        wordContent: baseChallenge.wordContent,
        themeColor: baseChallenge.themeColor,
        patternTemplate: baseChallenge.patternTemplate,
        difficultyConfig: const DifficultyConfig(
          difficulty: 'custom',
          timerSeconds: 1,
          lives: 1,
          memoryPreviewSeconds: 0,
          missingLetterCount: 1,
          allowFirstLetterHint: false,
          maximumStars: 3,
        ),
      );
      
      await tester.pumpWidget(buildApp(GameScreen(
        challenge: timedChallenge,
        repository: challengeRepository,
      )));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      
      AudioService().testPlayedSfx.clear();
      await tester.tap(find.text('TRY AGAIN'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    testWidgets('Level Complete Continue -> one button_tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(Scaffold(
        body: LevelCompleteDialog(
          challenge: allChallenges.first,
          stars: 3,
          onContinue: () {}, // Not wrapped by test
        ),
      )));
      
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 1);
    });

    // --- SPECIFIC INTENTIONAL SOUNDS ---

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
      
      controller.selectLetter(0); 
      
      AudioService().testPlayedSfx.clear();
      controller.undo(); 
      
      expect(AudioService().testPlayedSfx.where((s) => s == 'letter_undo.wav').length, 1);
      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
      controller.dispose();
    });

    testWidgets('TTS Speak -> no Button Tap', (WidgetTester tester) async {
      final wordContent = allChallenges.first.wordContent;

      await tester.pumpWidget(buildApp(Scaffold(
        body: WordCard(word: wordContent, isUnlocked: true),
      )));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(InkWell));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
    });

    testWidgets('Sound OFF -> zero Button Tap globally', (WidgetTester tester) async {
      await AudioService().setSoundEnabled(false);
      
      await tester.pumpWidget(buildApp(HomeScreen(storageService: storageService)));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('CLOSE'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(AudioService().testPlayedSfx.where((s) => s == 'button_tap.wav').length, 0);
    });
  });
}
