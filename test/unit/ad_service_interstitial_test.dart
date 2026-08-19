import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:name_twist_game/core/services/ad_service.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeInterstitialAdWrapper implements InterstitialAdWrapper {
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
  Future<void> show() async {
    if (simulateException) {
      throw Exception('Simulated exception during show()');
    }
    if (simulateFailure) {
      _onAdFailed?.call('Simulated failure');
    } else {
      _onAdShowed?.call();
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
  group('AdService Production Interstitial Tests', () {
    FakeInterstitialAdWrapper? currentFakeAd;
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

      adService.interstitialLoadProvider = (adUnitId, onLoaded, onFailed) {
        currentFakeAd = FakeInterstitialAdWrapper();
        onLoaded(currentFakeAd!);
      };

      // Load first ad
      adService.loadInterstitialAd();
    });

    tearDown(() {
      adService.dispose();
      AdService.mockInstance = null;
      AudioService().disposeAll();
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

        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
          onContinue: () => continueCount++,
        );

        expect(continueCount, 3); // 4th deferred until dismiss
        currentFakeAd!.simulateDismiss();
        expect(continueCount, 4);
      });
    });

    test('Cooldown enforces 2-minute gap between ads', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        // Trigger first ad
        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
          if (i == 3) currentFakeAd!.simulateDismiss();
        }
        expect(continueCount, 4);

        // Complete 4 more levels immediately (cooldown active)
        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }
        expect(continueCount, 8); // Bypassed

        // Advance time by 1m 59s, still blocked
        async.elapse(const Duration(minutes: 1, seconds: 59));
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);
        expect(continueCount, 9);

        // Advance past 2 minutes
        async.elapse(const Duration(seconds: 1));
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);

        expect(continueCount, 9); // Deferred
        currentFakeAd!.simulateDismiss();
        expect(continueCount, 10);
      });
    });

    test(
        'Dismiss calls navigation exactly once and duplicate callbacks run cleanup exactly once',
        () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        final displayedAd = currentFakeAd!;

        displayedAd.simulateDismiss();
        displayedAd.simulateDismiss();
        displayedAd.simulateDismiss();

        expect(continueCount, 4);
        expect(displayedAd.isDisposed, true);
      });
    });

    test(
        'Failure calls navigation exactly once, starts no cooldown, does not reset counter',
        () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        currentFakeAd!.simulateFailure = true;
        final failedAd = currentFakeAd!;

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        expect(continueCount, 4); // Immediate callback on failure
        expect(failedAd.isDisposed, true);

        // Try again immediately (no cooldown started, counter not reset)
        currentFakeAd!.simulateFailure = false;
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);

        expect(continueCount, 4);
        currentFakeAd!.simulateDismiss();
        expect(continueCount, 5);
      });
    });

    test('Directly thrown show() exception calls navigation exactly once', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        currentFakeAd!.simulateException = true;
        final excAd = currentFakeAd!;

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        async.flushMicrotasks();

        expect(continueCount, 4); // Cleaned up immediately
        expect(excAd.isDisposed, true);
      });
    });

    test('Dismiss followed by failure still runs terminal cleanup exactly once',
        () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        final ad = currentFakeAd!;
        ad.simulateDismiss();
        ad.simulateFailAfterShow();

        expect(continueCount, 4);
      });
    });

    test('Newly preloaded ad is not disposed by an old duplicate callback', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () {});
        }

        final firstAd = currentFakeAd!;
        firstAd.simulateDismiss(); // This preloads the second ad

        final secondAd = currentFakeAd!;
        expect(firstAd == secondAd, false);

        firstAd.simulateDismiss(); // Duplicate callback from first ad

        expect(secondAd.isDisposed, false); // Second ad must remain loaded
      });
    });

    test('Unavailable ad defers and does not reset the completion counter', () {
      fakeAsync((async) {
        adService.clock = () => async.getClock(DateTime.now()).now();
        int continueCount = 0;

        // Force interstitialAd to be null by clearing it directly
        // (in production this happens if load fails or hasn't finished)
        adService.resetStateForTest(); // Clears it

        for (int i = 0; i < 4; i++) {
          adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
              onContinue: () => continueCount++);
        }

        expect(continueCount, 4); // Deferred immediately

        // Now load a real ad
        adService.loadInterstitialAd();

        // Counter was not reset, so 5th level should trigger it
        adService.recordCampaignCompletionAndShowInterstitialIfNeeded(
            onContinue: () => continueCount++);

        expect(continueCount, 4); // Waiting for dismiss
        currentFakeAd!.simulateDismiss();
        expect(continueCount, 5);
      });
    });
  });
}
