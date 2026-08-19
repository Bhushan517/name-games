import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/ad_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/generated_challenge.dart';
import 'package:name_twist_game/data/models/word_content.dart';
import 'package:name_twist_game/data/repositories/challenge_repository.dart';
import 'package:name_twist_game/data/repositories/word_repository.dart';
import 'package:name_twist_game/data/sources/local_word_data_source.dart';
import 'package:name_twist_game/features/game/controller/game_controller.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAdService implements AdService {
  bool shouldGrantReward = true;
  int hintsEarned = 0;
  int livesEarned = 0;
  int rewardedHintCount = 0;
  int rewardedLifeCount = 0;
  int interstitialCount = 0;
  bool isInterstitialReady = true;

  @override
  DateTime Function() clock = () => DateTime.now();

  @override
  void Function(
    String adUnitId,
    void Function(InterstitialAdWrapper) onAdLoaded,
    void Function(dynamic error) onAdFailedToLoad,
  ) interstitialLoadProvider = (a, b, c) {};

  @override
  Future<void> init() async {}
  @override
  void loadRewardedHintAd() {}
  @override
  bool get isRewardedHintAdReady => true;
  @override
  void showRewardedHintAd(
      {required VoidCallback onRewardEarned,
      required VoidCallback onAdClosed}) {
    if (shouldGrantReward) {
      hintsEarned++;
      onRewardEarned();
    }
    onAdClosed();
  }

  @override
  void loadRewardedLifeAd() {}
  @override
  bool get isRewardedLifeAdReady => true;
  @override
  void showRewardedLifeAd(
      {required VoidCallback onRewardEarned,
      required VoidCallback onAdClosed}) {
    if (shouldGrantReward) {
      livesEarned++;
      onRewardEarned();
    }
    onAdClosed();
  }

  @override
  void loadInterstitialAd() {}
  @override
  void resetStateForTest() {}

  @override
  Future<void> recordCampaignCompletionAndShowInterstitialIfNeeded(
      {required VoidCallback onContinue}) async {
    onContinue();
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late ChallengeRepository repository;
  late GeneratedChallenge firstChallenge;
  late FakeAdService fakeAdService;

  setUpAll(() {
    final file = File('assets/data/word_levels.json');
    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    final words = decoded
        .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
        .toList();
    final challenges = ChallengeGenerator.generateAllChallenges(words);
    firstChallenge = challenges.first;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await LocalStorageService.init();
    final wordRepo = WordRepository(LocalWordDataSource());
    repository = ChallengeRepository(
      wordRepository: wordRepo,
      storageService: storageService,
    );

    fakeAdService = FakeAdService();
    AdService.mockInstance = fakeAdService;
  });

  group('Normal Spelling Modes Tests', () {
    test('First hint is free, second requires rewarded ad', () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);
      expect(controller.isNextHintFree, true);

      controller.grantHint();
      expect(controller.totalHintsUsed, 1);
      expect(controller.isNextHintFree, false);
      expect(controller.revealedHintIndices.length, 1);
    });

    test('Each rewarded hint reveals a different new position', () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      controller.grantHint();
      final firstHint = controller.revealedHintIndices.first;

      controller.grantHint();
      expect(controller.revealedHintIndices.length, 2);
      expect(controller.revealedHintIndices.contains(firstHint), true);
    });

    test('Sparse hints stay visible after wrong answers and undo', () async {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      // 1. Manually fill positions 0 and 1 correctly.
      final char0 = firstChallenge.word[0];
      final node0 = controller.nodes.indexWhere((n) => n.letter == char0);
      controller.selectLetter(node0);

      final char1 = firstChallenge.word[1];
      final node1 = controller.nodes.indexWhere((n) =>
          n.letter == char1 &&
          !controller.isSelected(controller.nodes.indexOf(n)));
      controller.selectLetter(node1);

      // 2. Request the first hint so it appears at position 2.
      controller.grantHint();
      expect(controller.revealedHintIndices.contains(2), true);

      // 3. Fill the rest incorrectly and submit.
      for (int i = 0; i < firstChallenge.letterCount; i++) {
        if (!controller.isSelected(i)) {
          controller.selectLetter(i);
        }
      }

      // Ensure wrong answer by swapping last two
      if (controller.currentAttempt == firstChallenge.word) {
        controller.undo();
        controller.undo();
        final remaining = List.generate(firstChallenge.letterCount, (i) => i)
            .where((i) => !controller.isSelected(i))
            .toList();
        controller.selectLetter(remaining[1]);
        controller.selectLetter(remaining[0]);
      }

      await controller.validateSpelling();
      expect(controller.validationState, GameValidationState.wrong);

      // 4. Confirm manual positions are cleared.
      // 5. Confirm the position-2 hint is still visible and fixed.
      expect(controller.selectedIndices[2] != null, true);
      expect(controller.selectedIndices[0], isNull);

      // 6. Confirm currentAttempt represents gaps correctly
      final attempt = controller.currentAttempt;
      expect(attempt[0], '_');
      expect(attempt[1], '_');
      expect(attempt[2], firstChallenge.word[2]);

      // 7. Confirm Undo cannot remove that hint.
      controller.undo();
      expect(controller.selectedIndices[2] != null, true);

      // 8. Confirm completing the remaining positions validates the correct word.
      for (int i = 0; i < firstChallenge.word.length; i++) {
        if (i == 2) continue; // skip hinted
        final expected = firstChallenge.word[i];
        final n = controller.nodes.indexWhere((n) =>
            n.letter == expected &&
            !controller.isSelected(controller.nodes.indexOf(n)));
        controller.selectLetter(n);
      }
      expect(controller.currentAttempt, firstChallenge.word);
      final result = await controller.validateSpelling();
      expect(result, GameValidationState.correct);
    });

    test('Duplicate-letter words use different correct nodes', () {
      final duplicateChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '1',
          word: 'APPLE',
          category: 'Test',
          emoji: '🍎',
          sentenceClue: 'A fruit',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'easy',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.unscramble);

      final controller =
          GameController(challenge: duplicateChallenge, repository: repository);

      // A (0), P (1), P (2), L (3), E (4)
      controller.grantHint(); // A
      controller.grantHint(); // P1
      controller.grantHint(); // P2

      expect(controller.selectedIndices[1],
          isNot(equals(controller.selectedIndices[2])));
      expect(controller.nodes[controller.selectedIndices[1]!].letter, 'P');
      expect(controller.nodes[controller.selectedIndices[2]!].letter, 'P');
    });

    test('Hints and manual selections assemble the correct final word',
        () async {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);
      controller.grantHint(); // First letter hinted

      // Select the rest manually
      for (int i = 1; i < firstChallenge.word.length; i++) {
        final expectedLetter = firstChallenge.word[i];
        final nodeIndex = controller.nodes.indexWhere((n) =>
            n.letter == expectedLetter &&
            !controller.isSelected(controller.nodes.indexOf(n)));
        controller.selectLetter(nodeIndex);
      }

      expect(controller.currentAttempt, firstChallenge.word);
      final result = await controller.validateSpelling();
      expect(result, GameValidationState.correct);
    });

    test('No hint can reveal the complete answer', () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      int maxHints = firstChallenge.word.length - 1;
      expect(controller.maxHints, maxHints);

      for (int i = 0; i < maxHints; i++) {
        expect(controller.canUseHint, true);
        controller.grantHint();
      }

      expect(controller.canUseHint, false);
      expect(controller.totalHintsUsed, maxHints);
    });
  });

  group('Missing Letter Mode Tests', () {
    late GeneratedChallenge oneBlankChallenge;
    late GeneratedChallenge twoBlankChallenge;

    setUpAll(() {
      oneBlankChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '2',
          word: 'CAT',
          category: 'Test',
          emoji: '🐱',
          sentenceClue: 'Pet',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'easy',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.missingLetter);

      twoBlankChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '3',
          word: 'ELEPHANT',
          category: 'Test',
          emoji: '🐘',
          sentenceClue: 'Big animal',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'hard',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.missingLetter);
    });

    test('Maximum hints equal actual unresolved missing positions', () {
      final controller =
          GameController(challenge: twoBlankChallenge, repository: repository);
      final blanks = controller
          .missingIndices.length; // Hard mode has 2 blanks for ELEPHANT
      expect(controller.maxHints, blanks);
    });

    test(
        'One blank manually filled incorrectly -> Hint remains enabled and fixes it',
        () {
      final controller =
          GameController(challenge: oneBlankChallenge, repository: repository);
      final missingIndex = controller.missingIndices.first;

      final wrongLetter = controller.missingLetterChoices
          .firstWhere((c) => c != oneBlankChallenge.word[missingIndex]);
      controller.fillMissingLetter(wrongLetter);

      // Hint is still enabled because it's incorrect
      expect(controller.canUseHint, true);

      // Granting hint fixes it
      controller.grantHint();
      expect(controller.filledMissingLetters[missingIndex],
          oneBlankChallenge.word[missingIndex]);
      expect(controller.revealedHintIndices.contains(missingIndex), true);
      expect(controller.canUseHint, false);

      // Undo does not remove the hinted letter
      controller.undo();
      expect(controller.filledMissingLetters[missingIndex],
          oneBlankChallenge.word[missingIndex]);
    });

    test('One blank manually filled correctly -> Hint is disabled', () {
      final controller =
          GameController(challenge: oneBlankChallenge, repository: repository);
      final missingIndex = controller.missingIndices.first;

      final correctLetter = oneBlankChallenge.word[missingIndex];
      controller.fillMissingLetter(correctLetter);

      expect(controller.canUseHint, false);
    });

    test(
        'Two blanks with one correct and one wrong -> Hint fixes only the wrong position',
        () {
      final controller =
          GameController(challenge: twoBlankChallenge, repository: repository);
      final missingIndex1 = controller.missingIndices[0];
      final missingIndex2 = controller.missingIndices[1];

      final correctLetter = twoBlankChallenge.word[missingIndex1];
      final wrongLetter = controller.missingLetterChoices
          .firstWhere((c) => c != twoBlankChallenge.word[missingIndex2]);

      // First fill correctly, second wrong
      controller.fillMissingLetter(correctLetter);
      controller.fillMissingLetter(wrongLetter);

      // Hint is enabled because there's a wrong one
      expect(controller.canUseHint, true);

      controller.grantHint();

      // It should fix the wrong one (missingIndex2)
      expect(controller.filledMissingLetters[missingIndex2],
          twoBlankChallenge.word[missingIndex2]);
      expect(controller.revealedHintIndices.contains(missingIndex2), true);

      // The correctly filled one remains unhinted (so it can be undone)
      expect(controller.revealedHintIndices.contains(missingIndex1), false);
      expect(controller.canUseHint, false);
    });

    test('Two-blank level reveals two different positions', () {
      final controller =
          GameController(challenge: twoBlankChallenge, repository: repository);
      expect(controller.missingIndices.length, 2);

      controller.grantHint(); // Free
      controller.grantHint(); // Ad

      expect(controller.filledMissingLetters.length, 2);
      expect(controller.revealedHintIndices.length, 2);
    });

    test(
        'Wrong answer preserves hinted positions but clears wrong manual entries',
        () async {
      final controller =
          GameController(challenge: twoBlankChallenge, repository: repository);

      controller.grantHint();
      final hintedIndex = controller.filledMissingLetters.keys.first;

      final otherMissingIndex =
          controller.missingIndices.firstWhere((i) => i != hintedIndex);
      // Provide a wrong letter
      final wrongLetter = controller.missingLetterChoices
          .firstWhere((c) => c != twoBlankChallenge.word[otherMissingIndex]);
      controller.fillMissingLetter(wrongLetter);

      await controller.validateSpelling();

      expect(controller.validationState, GameValidationState.wrong);
      expect(controller.filledMissingLetters.containsKey(hintedIndex),
          true); // Hint kept
      expect(controller.filledMissingLetters.containsKey(otherMissingIndex),
          false); // Manual cleared
    });

    test('Undo does not remove a hinted missing letter', () {
      final controller =
          GameController(challenge: twoBlankChallenge, repository: repository);
      controller.grantHint();

      final hintedIndex = controller.filledMissingLetters.keys.first;
      controller.undo(); // Does nothing

      expect(controller.filledMissingLetters.containsKey(hintedIndex), true);
    });
  });

  group('AdService Mock Testing', () {
    test('Early dismissal grants nothing', () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      controller.grantHint(); // First free
      expect(controller.totalHintsUsed, 1);

      // Simulate ad dismissal
      fakeAdService.shouldGrantReward = false;
      AdService().showRewardedHintAd(
        onRewardEarned: () => controller.grantHint(),
        onAdClosed: () {},
      );

      expect(fakeAdService.hintsEarned, 0);
      expect(controller.totalHintsUsed, 1); // No new hint granted
    });

    test('Reward callback grants exactly one hint/life', () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      controller.grantHint(); // First free

      // Simulate successful ad
      fakeAdService.shouldGrantReward = true;
      AdService().showRewardedHintAd(
        onRewardEarned: () => controller.grantHint(),
        onAdClosed: () {},
      );

      expect(fakeAdService.hintsEarned, 1);
      expect(controller.totalHintsUsed, 2);
    });

    test('No successful ad can result in zero reward', () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      controller.grantHint(); // Free

      fakeAdService.shouldGrantReward = true;
      AdService().showRewardedHintAd(
        onRewardEarned: () => controller.grantHint(),
        onAdClosed: () {},
      );

      expect(controller.totalHintsUsed, 2);
    });
  });

  group('Timed Mode Tests', () {
    testWidgets(
        'Timed Extra Life after final timeout restarts exactly one timer',
        (WidgetTester tester) async {
      final timedChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '1',
          word: 'TIME',
          category: 'Test',
          emoji: '⏱️',
          sentenceClue: 'Clue',
          meaningEnglish: '',
          meaningMarathi: '',
          meaningHindi: '',
          pronunciation: '',
          difficulty: 'easy',
          patternTemplate: 'star',
          minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.timed);

      final controller =
          GameController(challenge: timedChallenge, repository: repository);

      // Wait for timer to exhaust lives sequentially
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 60; j++) {
          await tester.pump(const Duration(seconds: 1));
        }
      }

      expect(controller.validationState, GameValidationState.outOfLives);
      expect(controller.canUseRewardedLife, true);

      // Verify the timer was properly canceled
      final currentTimerVal = controller.timeRemaining;
      await tester.pump(const Duration(seconds: 1));
      expect(controller.timeRemaining, currentTimerVal);

      controller.grantRewardedLife();

      final expectedTimer = timedChallenge.difficultyConfig.timerSeconds;
      expect(controller.timeRemaining, expectedTimer);
      expect(controller.lives, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(controller.timeRemaining, expectedTimer - 1);

      controller.dispose();

      // Attempting to pump after dispose should not throw pending timer exceptions
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
