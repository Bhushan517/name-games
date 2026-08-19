import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';
import 'package:name_twist_game/features/game/controller/game_controller.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';

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

    final wordRepo = WordRepository(LocalWordDataSource());
    challengeRepository = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storageService,
    );
  });

  test('Menu music starts correctly', () async {
    await AudioService().playBgm('menu_music.wav');
    expect(AudioService().currentBgmTrack, 'menu_music.wav');
  });

  test('Gameplay music starts correctly and replaces menu music', () async {
    await AudioService().playBgm('menu_music.wav');
    await AudioService().playBgm('gameplay_music.wav');
    expect(AudioService().currentBgmTrack, 'gameplay_music.wav');
  });

  test('Music OFF prevents background music state from resuming', () async {
    await AudioService().setMusicEnabled(false);
    expect(AudioService().isMusicEnabled, false);
    await AudioService().playBgm('gameplay_music.wav');
    expect(AudioService().currentBgmTrack, 'gameplay_music.wav');
  });

  test('Sound OFF prevents sound effects', () async {
    await AudioService().setSoundEnabled(false);
    await AudioService().playSfx('button_tap.wav');
    expect(AudioService().testPlayedSfx, isEmpty);
  });

  test('Correct answer plays one success sound', () async {
    final challenge =
        allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
    final controller = GameController(
      challenge: challenge,
      repository: challengeRepository,
    );

    final word = challenge.word;
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      final nodeIndex = controller.nodes.indexWhere((n) =>
          n.letter == char &&
          !controller.isSelected(controller.nodes.indexOf(n)));
      if (nodeIndex != -1) {
        controller.selectLetter(nodeIndex);
      }
    }

    AudioService().testPlayedSfx.clear();
    await controller.validateSpelling();
    expect(AudioService().testPlayedSfx, contains('correct_answer.wav'));
  });

  test('Wrong answer plays one error sound', () async {
    final challenge =
        allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
    final controller = GameController(
      challenge: challenge,
      repository: challengeRepository,
    );

    final word = challenge.word;
    for (int i = 0; i < word.length; i++) {
      // Pick deliberately wrong letter, or just a different node
      final nodeIndex = controller.nodes.indexWhere((n) =>
          n.letter != word[i] &&
          !controller.isSelected(controller.nodes.indexOf(n)));
      if (nodeIndex != -1) {
        controller.selectLetter(nodeIndex);
      } else {
        // Fallback if not enough wrong letters
        final fallback = controller.nodes.indexWhere(
            (n) => !controller.isSelected(controller.nodes.indexOf(n)));
        if (fallback != -1) controller.selectLetter(fallback);
      }
    }

    AudioService().testPlayedSfx.clear();
    await controller.validateSpelling();
    expect(AudioService().testPlayedSfx, contains('wrong_answer.wav'));
  });

  test('TTS ducks/pauses music and restores it afterward', () async {
    await AudioService().playBgm('gameplay_music.wav');
    await AudioService().duckBgmForTts();
    expect(AudioService().isDucking, true);
    await AudioService().unduckBgmFromTts();
    expect(AudioService().isDucking, false);
  });

  test('Ad display pauses music and dismissal restores the correct track', () {
    AudioService().onAdShow();
    expect(AudioService().isAdShowing, true);
    AudioService().onAdDismiss();
    expect(AudioService().isAdShowing, false);
  });

  test('App pause/resume toggles pause state', () {
    AudioService().onAppPaused();
    expect(AudioService().isAppPaused, true);
    AudioService().onAppResumed();
    expect(AudioService().isAppPaused, false);
  });

  test('Hint sound plays only when a hint is actually granted', () {
    final challenge =
        allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
    final controller = GameController(
      challenge: challenge,
      repository: challengeRepository,
    );

    AudioService().testPlayedSfx.clear();
    controller.grantHint();
    expect(AudioService().testPlayedSfx, contains('hint_reveal.wav'));

    // Grant until no more hints
    for (int i = 0; i < challenge.word.length; i++) {
      controller.grantHint();
    }

    AudioService().testPlayedSfx.clear();
    controller.grantHint(); // Cannot use hint
    expect(AudioService().testPlayedSfx, isEmpty);
  });

  test('Extra Life sound plays exactly once after reward', () {
    final challenge =
        allChallenges.firstWhere((c) => c.mode == ChallengeMode.unscramble);
    final controller = GameController(
      challenge: challenge,
      repository: challengeRepository,
    );

    AudioService().testPlayedSfx.clear();
    controller.grantRewardedLife();
    expect(AudioService().testPlayedSfx, contains('extra_life.wav'));
  });

  group('Deterministic Timer Audio Tests', () {
    test(
        'Timer tick sequence fires exactly at 5,4,3,2,1 and respects app pause/resume without duplicates',
        () {
      fakeAsync((async) {
        final challenge =
            allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
        final controller = GameController(
            challenge: challenge, repository: challengeRepository);

        final totalTime = challenge.difficultyConfig.timerSeconds;
        AudioService().testPlayedSfx.clear();

        // Fast forward to just before 5 seconds remaining
        async.elapse(Duration(seconds: totalTime - 6));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .isEmpty,
            true);

        // Elapse 3 seconds (ticks at 5, 4, 3)
        async.elapse(const Duration(seconds: 3));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            3);

        // Pause timer
        controller.pauseTimer();
        async.elapse(const Duration(seconds: 2));

        // Still 3 ticks because it was paused
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            3);

        // Resume timer
        controller.resumeTimer();

        // Elapse remaining time (ticks at 2, 1)
        async.elapse(const Duration(seconds: 3));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            5);

        // Beyond 0 (no more ticks)
        async.elapse(const Duration(seconds: 5));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            5);

        controller.dispose();
      });
    });

    test(
        'Correct completion cancels future ticks and disposal leaves no pending timer',
        () {
      fakeAsync((async) {
        final challenge =
            allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
        final controller = GameController(
            challenge: challenge, repository: challengeRepository);
        final totalTime = challenge.difficultyConfig.timerSeconds;

        AudioService().testPlayedSfx.clear();

        // Enter the tick zone
        async.elapse(Duration(seconds: totalTime - 4));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            2);

        // Complete the word correctly
        for (int i = 0; i < challenge.word.length; i++) {
          final char = challenge.word[i];
          final nodeIndex = controller.nodes.indexWhere((n) =>
              n.letter == char &&
              !controller.isSelected(controller.nodes.indexOf(n)));
          if (nodeIndex != -1) {
            controller.selectLetter(nodeIndex);
          }
        }
        controller
            .validateSpelling(); // This completes the challenge and cancels timer

        // Elapse remaining time
        async.elapse(const Duration(seconds: 5));

        // Still 2 ticks because completion cancelled the timer
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            2);

        controller.dispose();
        // fakeAsync automatically verifies there are no pending timers at the end of the block
      });
    });

    test('Try Again (resetLives) restarts one tick sequence cleanly', () {
      fakeAsync((async) {
        final challenge =
            allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
        final controller = GameController(
            challenge: challenge, repository: challengeRepository);
        final totalTime = challenge.difficultyConfig.timerSeconds;

        for (int i = 0; i < challenge.difficultyConfig.lives; i++) {
          async.elapse(Duration(seconds: totalTime + 1));
        }

        AudioService().testPlayedSfx.clear();
        controller.resetLives(); // Player taps Try Again

        async.elapse(Duration(seconds: totalTime - 6));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .isEmpty,
            true);

        async.elapse(const Duration(seconds: 6));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            5);

        controller.dispose();
      });
    });

    test('Rewarded Extra Life restarts one tick sequence cleanly', () {
      fakeAsync((async) {
        final challenge =
            allChallenges.firstWhere((c) => c.mode == ChallengeMode.timed);
        final controller = GameController(
            challenge: challenge, repository: challengeRepository);
        final totalTime = challenge.difficultyConfig.timerSeconds;

        for (int i = 0; i < challenge.difficultyConfig.lives; i++) {
          async.elapse(Duration(seconds: totalTime + 1));
        }

        AudioService().testPlayedSfx.clear();
        controller.grantRewardedLife(); // Player uses rewarded life

        async.elapse(Duration(seconds: totalTime - 6));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .isEmpty,
            true);

        async.elapse(const Duration(seconds: 6));
        expect(
            AudioService()
                .testPlayedSfx
                .where((s) => s == 'timer_tick.wav')
                .length,
            5);

        controller.dispose();
      });
    });
  });

  test('Missing letter undo plays exactly once on success', () async {
    final challenge =
        allChallenges.firstWhere((c) => c.mode == ChallengeMode.missingLetter);
    final controller = GameController(
      challenge: challenge,
      repository: challengeRepository,
    );

    AudioService().testPlayedSfx.clear();

    // Try undoing when nothing is filled
    controller.undo();
    expect(AudioService().testPlayedSfx, isEmpty);

    // Fill a letter manually
    final missingIndex = controller.missingIndices.first;
    final wrongLetter = controller.missingLetterChoices
        .firstWhere((c) => c != challenge.word[missingIndex]);
    controller.fillMissingLetter(wrongLetter);

    // Undo successfully
    AudioService().testPlayedSfx.clear();
    controller.undo();
    expect(AudioService().testPlayedSfx, contains('letter_undo.wav'));
    expect(
        AudioService()
            .testPlayedSfx
            .where((s) => s == 'letter_undo.wav')
            .length,
        1);
  });

  test('Button tap helper plays sound', () {
    AudioService().testPlayedSfx.clear();
    bool tapped = false;
    final callback = AudioService.withSound(() {
      tapped = true;
    });
    callback!();
    expect(tapped, true);
    expect(AudioService().testPlayedSfx, contains('button_tap.wav'));
  });

  test('Audio Service safely handles disposeAll', () async {
    await AudioService().disposeAll();
    expect(AudioService().currentBgmTrack, isNull);
  });
}
