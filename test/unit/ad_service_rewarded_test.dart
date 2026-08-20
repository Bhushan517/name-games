import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:name_twist_game/core/services/ad_service.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRewardedAdWrapper implements RewardedAdWrapper {
  bool isDisposed = false;
  bool simulateFailure = false;
  bool simulateException = false;
  bool autoRewardOnShow = true;
  void Function(RewardItem reward)? _onRewardEarnedCallback;
  void Function()? _onAdShowed;
  void Function()? _onAdDismissed;
  void Function(dynamic error)? _onAdFailed;

  @override
  void setFullScreenContentCallback({
    required void Function() onAdShowedFullScreenContent,
    required void Function() onAdDismissedFullScreenContent,
    required void Function(dynamic error) onAdFailedToShowFullScreenContent,
  }) {
    _onAdShowed = onAdShowedFullScreenContent;
    _onAdDismissed = onAdDismissedFullScreenContent;
    _onAdFailed = onAdFailedToShowFullScreenContent;
  }

  @override
  Future<void> show(
      {required void Function(RewardItem reward) onUserEarnedReward}) async {
    if (simulateException) {
      throw Exception('Simulated exception during show()');
    }
    _onRewardEarnedCallback = onUserEarnedReward;
    if (simulateFailure) {
      _onAdFailed?.call('Simulated failure');
    } else {
      _onAdShowed?.call();
      if (autoRewardOnShow) {
        triggerReward();
      }
    }
  }

  void triggerReward() {
    _onRewardEarnedCallback?.call(RewardItem(1, 'reward'));
  }

  void simulateDismiss() {
    _onAdDismissed?.call();
  }

  void simulateFailAfterShow() {
    _onAdFailed?.call('Delayed failure');
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}

void main() {
  group('AdService Production Rewarded Tests', () {
    FakeRewardedAdWrapper? currentFakeHintAd;
    FakeRewardedAdWrapper? currentFakeLifeAd;
    late AdService adService;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(
          {'pref_sound': false, 'pref_music': false});
      final storage = await LocalStorageService.init();
      AudioService().enableTestMode();
      await AudioService().init(storage);

      AdService.mockInstance = null; // Reset factory
      adService = AdService();
      adService.resetStateForTest();

      adService.rewardedHintLoadProvider = (adUnitId, onLoaded, onFailed) {
        currentFakeHintAd = FakeRewardedAdWrapper();
        onLoaded(currentFakeHintAd!);
      };

      adService.rewardedLifeLoadProvider = (adUnitId, onLoaded, onFailed) {
        currentFakeLifeAd = FakeRewardedAdWrapper();
        onLoaded(currentFakeLifeAd!);
      };

      // Preload ads
      adService.loadRewardedHintAd();
      adService.loadRewardedLifeAd();
    });

    tearDown(() {
      adService.dispose();
      AdService.mockInstance = null;
      AudioService().disposeAll();
    });

    test(
        'Exactly-once terminal guard protects against duplicate dismiss callbacks for Hint Ad',
        () async {
      expect(adService.isRewardedHintAdReady, isTrue);

      int closedCalls = 0;
      int rewardEarnedCalls = 0;

      adService.showRewardedHintAd(
        onRewardEarned: () => rewardEarnedCalls++,
        onAdClosed: () => closedCalls++,
      );

      final oldAd = currentFakeHintAd!;

      // Attempt dismiss multiple times
      oldAd.simulateDismiss();
      oldAd.simulateDismiss();
      oldAd.simulateFailAfterShow();

      // Only ONE closed call, ONE reward call, and ONE dispose
      expect(closedCalls, 1);
      expect(rewardEarnedCalls, 1);
      expect(oldAd.isDisposed, isTrue);

      // Ensure the NEW ad (preloaded inside safeContinue) is not disposed
      expect(currentFakeHintAd, isNot(equals(oldAd)));
      expect(currentFakeHintAd!.isDisposed, isFalse);
    });

    test(
        'Exactly-once terminal guard protects against duplicate dismiss callbacks for Life Ad',
        () async {
      expect(adService.isRewardedLifeAdReady, isTrue);

      int closedCalls = 0;
      int rewardEarnedCalls = 0;

      adService.showRewardedLifeAd(
        onRewardEarned: () => rewardEarnedCalls++,
        onAdClosed: () => closedCalls++,
      );

      final oldAd = currentFakeLifeAd!;

      oldAd.simulateFailAfterShow();
      oldAd.simulateDismiss();

      expect(closedCalls, 1);
      expect(rewardEarnedCalls, 1);
      expect(oldAd.isDisposed, isTrue);

      expect(currentFakeLifeAd, isNot(equals(oldAd)));
      expect(currentFakeLifeAd!.isDisposed, isFalse);
    });

    test('Exception on show() triggers safeContinue exactly once', () {
      fakeAsync((async) {
        final oldAd = currentFakeHintAd!;
        oldAd.simulateException = true;

        int closedCalls = 0;
        int rewardEarnedCalls = 0;

        adService.showRewardedHintAd(
          onRewardEarned: () => rewardEarnedCalls++,
          onAdClosed: () => closedCalls++,
        );

        async.flushMicrotasks();

        expect(closedCalls, 1);
        expect(rewardEarnedCalls, 0); // Reward not earned due to exception
        expect(currentFakeHintAd, isNot(equals(oldAd)));
        expect(currentFakeHintAd!.isDisposed, isFalse);
      });
    });

    test('Failed/skipped ad grants no reward', () async {
      currentFakeLifeAd!.simulateFailure = true;

      int closedCalls = 0;
      int rewardEarnedCalls = 0;

      adService.showRewardedLifeAd(
        onRewardEarned: () => rewardEarnedCalls++,
        onAdClosed: () => closedCalls++,
      );

      expect(closedCalls, 1);
      expect(rewardEarnedCalls, 0);
    });

    test('Dismiss then late reward callback yields zero reward', () {
      final oldAd = currentFakeHintAd!;
      oldAd.autoRewardOnShow = false; // Do not auto-reward on show

      int rewardEarnedCalls = 0;
      int closedCalls = 0;

      adService.showRewardedHintAd(
        onRewardEarned: () => rewardEarnedCalls++,
        onAdClosed: () => closedCalls++,
      );

      // Ad dismissed before user earns reward
      oldAd.simulateDismiss();
      expect(closedCalls, 1);
      expect(rewardEarnedCalls, 0);

      // Late reward callback arrives after dismiss
      oldAd.triggerReward();
      expect(rewardEarnedCalls, 0,
          reason: 'Late reward callback after dismiss must be ignored');
    });

    test('Failure then late reward callback yields zero reward', () {
      final oldAd = currentFakeLifeAd!;
      oldAd.simulateFailure = true;
      oldAd.autoRewardOnShow = false;

      int rewardEarnedCalls = 0;
      int closedCalls = 0;

      adService.showRewardedLifeAd(
        onRewardEarned: () => rewardEarnedCalls++,
        onAdClosed: () => closedCalls++,
      );

      expect(closedCalls, 1);
      expect(rewardEarnedCalls, 0);

      // Late reward callback arrives after failure
      oldAd.triggerReward();
      expect(rewardEarnedCalls, 0,
          reason: 'Late reward callback after failure must be ignored');
    });

    test('Show exception then late reward callback yields zero reward', () {
      fakeAsync((async) {
        final oldAd = currentFakeHintAd!;
        oldAd.simulateException = true;
        oldAd.autoRewardOnShow = false;

        int rewardEarnedCalls = 0;
        int closedCalls = 0;

        adService.showRewardedHintAd(
          onRewardEarned: () => rewardEarnedCalls++,
          onAdClosed: () => closedCalls++,
        );

        async.flushMicrotasks();

        expect(closedCalls, 1);
        expect(rewardEarnedCalls, 0);

        // Late reward callback arrives after show exception
        oldAd.triggerReward();
        expect(rewardEarnedCalls, 0,
            reason: 'Late reward callback after exception must be ignored');
      });
    });

    test('Duplicate reward callback before dismiss yields exactly one reward',
        () {
      final oldAd = currentFakeHintAd!;
      oldAd.autoRewardOnShow = false;

      int rewardEarnedCalls = 0;
      int closedCalls = 0;

      adService.showRewardedHintAd(
        onRewardEarned: () => rewardEarnedCalls++,
        onAdClosed: () => closedCalls++,
      );

      // Duplicate reward callbacks
      oldAd.triggerReward();
      oldAd.triggerReward();
      oldAd.triggerReward();

      expect(rewardEarnedCalls, 1,
          reason:
              'Duplicate reward callbacks before dismiss must grant exactly one reward');

      oldAd.simulateDismiss();
      expect(closedCalls, 1);
    });

    test(
        'Multiple setUp/tearDown cycles prove resetStateForTest leaves no state leaks',
        () {
      // Run reset and verify clean slate
      adService.resetStateForTest();

      expect(adService.isRewardedHintAdReady, isFalse);
      expect(adService.isRewardedLifeAdReady, isFalse);

      // Re-load and verify independent operation
      adService.loadRewardedHintAd();
      expect(adService.isRewardedHintAdReady, isTrue);

      adService.dispose();
      expect(adService.isRewardedHintAdReady, isFalse);

      // Idempotent dispose check
      adService.dispose();
      adService.dispose();
      expect(adService.isRewardedHintAdReady, isFalse);
    });
  });
}
