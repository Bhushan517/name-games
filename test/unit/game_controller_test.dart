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
  void recordCampaignCompletionAndShowInterstitialIfNeeded(
      {required VoidCallback onContinue}) {
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

    test(
        'Wrong answer preserves every earned hint and clears only manual selections',
        () async {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      controller.grantHint();
      controller.grantHint();
      expect(controller.revealedHintIndices.length, 2);

      // Select manually some incorrect letters
      for (int i = 0; i < firstChallenge.letterCount; i++) {
        if (!controller.isSelected(i)) {
          controller.selectLetter(i);
        }
      }
      
      // Ensure it's the wrong answer by swapping the last two selections
      if (controller.currentAttempt == firstChallenge.word) {
        controller.undo();
        controller.undo();
        final remaining = List.generate(firstChallenge.letterCount, (i) => i).where((i) => !controller.isSelected(i)).toList();
        controller.selectLetter(remaining[1]);
        controller.selectLetter(remaining[0]);
      }

      await controller.validateSpelling();

      expect(controller.validationState, GameValidationState.wrong);
      expect(controller.revealedHintIndices.length, 2); // Hints preserved
      expect(controller.selectedIndices.length, 2); // Only hints remain active
      expect(controller.currentAttempt.length, 2);
    });

    test('Undo removes only a manual letter and cannot remove a hinted letter',
        () {
      final controller =
          GameController(challenge: firstChallenge, repository: repository);

      controller.grantHint();
      expect(controller.revealedHintIndices.length, 1);

      // Select a manual letter
      final firstUnselected = controller.nodes.indexWhere(
          (n) => !controller.isSelected(controller.nodes.indexOf(n)));
      controller.selectLetter(firstUnselected);
      expect(controller.selectedIndices.length, 2);

      // Undo should remove the manual letter
      controller.undo();
      expect(controller.selectedIndices.length, 1);

      // Undo should do nothing against the hint
      controller.undo();
      expect(controller.selectedIndices.length, 1);
      expect(controller.revealedHintIndices.length, 1);
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
      expect(controller.nodes[controller.selectedIndices[1]].letter, 'P');
      expect(controller.nodes[controller.selectedIndices[2]].letter, 'P');
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

    test('One-blank level allows one free hint and then disables Hint', () {
      final controller =
          GameController(challenge: oneBlankChallenge, repository: repository);
      // Easy mode has 1 blank
      expect(controller.missingIndices.length, 1);
      expect(controller.maxHints, 1);
      expect(controller.canUseHint, true);

      controller.grantHint(); // Free hint
      expect(controller.canUseHint, false);
      expect(controller.filledMissingLetters.length, 1);
    });

    test('No ad is shown after the final missing position is filled', () {
      final controller =
          GameController(challenge: oneBlankChallenge, repository: repository);

      // Manually fill the missing letter
      final missingIndex = controller.missingIndices.first;
      final expectedLetter = oneBlankChallenge.word[missingIndex];
      controller.fillMissingLetter(expectedLetter);

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
    testWidgets('Timed Extra Life after final timeout restarts exactly one timer', (WidgetTester tester) async {
      final timedChallenge = ChallengeGenerator.generateAllChallenges([
        WordContent(
          id: '1', word: 'TIME', category: 'Test', emoji: '⏱️',
          sentenceClue: 'Clue', meaningEnglish: '', meaningMarathi: '',
          meaningHindi: '', pronunciation: '', difficulty: 'easy',
          patternTemplate: 'star', minimumAge: 7,
        )
      ]).firstWhere((c) => c.mode == ChallengeMode.timed);

      final controller = GameController(challenge: timedChallenge, repository: repository);

      // Wait for timer to exhaust lives (3 lives * 60 seconds)
      while (controller.lives > 0) {
        await tester.pump(const Duration(seconds: 61));
      }

      expect(controller.validationState, GameValidationState.outOfLives);
      expect(controller.canUseRewardedLife, true);

      // Verify the timer was properly canceled and restarted without duplicates
      final currentTimerVal = controller.timeRemaining;
      controller.grantRewardedLife();
      expect(controller.timeRemaining, greaterThan(currentTimerVal));
      expect(controller.lives, 1);
      
      controller.dispose();
    });
  });
}
