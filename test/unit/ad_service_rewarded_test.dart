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
    if (simulateFailure) {
      _onAdFailed?.call('Simulated failure');
    } else {
      _onAdShowed?.call();
      // Simulate user earning reward
      onUserEarnedReward(RewardItem(1, 'reward'));
    }
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
      expect(rewardEarnedCalls, 1); // Reward earned before fail/dismiss in fake
      expect(oldAd.isDisposed, isTrue);

      expect(currentFakeLifeAd, isNot(equals(oldAd)));
      expect(currentFakeLifeAd!.isDisposed, isFalse);
    });

    test('Exception on show() triggers safeContinue exactly once', () {
      // The FakeRewardedAdWrapper.show() is async, so throwing inside it produces
      // a rejected Future (not a synchronous exception). The .catchError() handler
      // runs as a microtask. Use fakeAsync + flushMicrotasks to drive it.
      fakeAsync((async) {
        final oldAd = currentFakeHintAd!;
        oldAd.simulateException = true;

        int closedCalls = 0;
        int rewardEarnedCalls = 0;

        adService.showRewardedHintAd(
          onRewardEarned: () => rewardEarnedCalls++,
          onAdClosed: () => closedCalls++,
        );

        // Drive the rejected-Future microtask to completion
        async.flushMicrotasks();

        expect(closedCalls, 1);
        expect(rewardEarnedCalls, 0); // Reward not earned due to exception
        // currentFakeHintAd is now the newly preloaded ad (not the old one)
        expect(currentFakeHintAd, isNot(equals(oldAd)));
        expect(currentFakeHintAd!.isDisposed,
            isFalse); // New ad must not be disposed
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
  });
}
