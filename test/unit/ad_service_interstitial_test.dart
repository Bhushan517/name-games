import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:name_twist_game/core/services/ad_service.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeInterstitialAdWrapper implements InterstitialAdWrapper {
  bool isDisposed = false;
  bool simulateFailure = false;
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
  Future<void> show() async {
    if (simulateFailure) {
      _onAdFailed?.call('Simulated failure');
    } else {
      _onAdShowed?.call();
      // Test must manually dismiss
    }
  }

  void simulateDismiss() {
    _onAdDismissed?.call();
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}

void main() {
  group('AdService Production Interstitial Tests', () {
    late FakeInterstitialAdWrapper currentFakeAd;
    late AdService adService;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(
          {'pref_sound': false, 'pref_music': false});
      final storage = await LocalStorageService.init();
      AudioService().enableTestMode();
      await AudioService().init(storage);

      // Clean singleton state before each test if possible
      AdService.mockInstance = null; // Reset factory

      adService = AdService();
      adService.resetStateForTest();

      adService.interstitialLoadProvider = (adUnitId, onLoaded, onFailed) {
        currentFakeAd = FakeInterstitialAdWrapper();
        onLoaded(currentFakeAd);
      };

      // Load first ad
      adService.loadInterstitialAd();
    });

    test('1, 2, 3 completions show nothing, 4th shows ad', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        for (int i = 1; i <= 3; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++,
          );
        }

        expect(continueCount, 3);
        // Ensure no ad was shown, and the time is still null

        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
          onContinue: () => continueCount++,
        );
        // Before we call simulateDismiss, onContinue shouldn't be called yet for the 4th
        expect(continueCount, 3);

        currentFakeAd.simulateDismiss();
        expect(continueCount, 4);
      });
    });

    test('Cooldown enforces 2-minute gap between ads', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        // Trigger first ad (4 levels)
        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
          if (i == 3) currentFakeAd.simulateDismiss();
        }
        expect(continueCount, 4);

        // Complete 4 more levels immediately (cooldown active)
        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        // Should have continued immediately 4 times because of cooldown bypass
        expect(continueCount, 8);

        // Advance time by 1 minute, still blocked
        async.elapse(const Duration(minutes: 1));
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);
        expect(continueCount, 9);

        // Advance time past 2 minutes
        async.elapse(const Duration(minutes: 1, seconds: 1));
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);

        // Ad should show now, meaning onContinue is deferred until dismiss
        expect(continueCount, 9);
        currentFakeAd.simulateDismiss();
        expect(continueCount, 10);
      });
    });

    test(
        'Failure to show does not start cooldown or reset counter, allows exactly once continue',
        () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        currentFakeAd.simulateFailure = true;

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        // It failed to show, so onContinue was called immediately inside failure callback
        expect(continueCount, 4);

        // Try again immediately (5th completion).
        // We load a new fake ad in failure callback, ensure it doesn't fail this time
        currentFakeAd.simulateFailure = false;
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);

        expect(continueCount, 4); // Deferred until dismiss
        currentFakeAd.simulateDismiss();
        expect(continueCount, 5);
      });
    });

    test('Exactly once callback protection handles duplicate SDK callbacks',
        () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        expect(continueCount, 3); // 4th is waiting for ad dismiss

        // Simulate aggressive bad SDK firing dismiss multiple times
        currentFakeAd.simulateDismiss();
        currentFakeAd.simulateDismiss();
        currentFakeAd.simulateDismiss();

        expect(continueCount, 4); // Handled exactly once!
      });
    });

    test('Unavailable ad starts no cooldown and does not reset counter', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        // Make ad unavailable by simulating a failed load
        adService.interstitialLoadProvider = (a, onL, onF) {
          onF('Simulated Load Error');
        };
        adService.loadInterstitialAd(); // Force failure load

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        // It defers immediately because ad is null
        expect(continueCount, 4);

        // Now make ad available
        adService.interstitialLoadProvider = (a, onL, onF) {
          currentFakeAd = FakeInterstitialAdWrapper();
          onL(currentFakeAd);
        };
        adService.loadInterstitialAd();

        // 5th level, it should show ad because counter was never reset
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);
        expect(continueCount, 4);
        currentFakeAd.simulateDismiss();
        expect(continueCount, 5);
      });
    });
  });
}
