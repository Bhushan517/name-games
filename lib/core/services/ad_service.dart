import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'audio_service.dart';
import '../constants/app_constants.dart';
import '../config/ad_config.dart';

abstract class InterstitialAdWrapper {
  Future<void> show();
  void dispose();
  void setFullScreenContentCallback({
    required void Function() onAdShowedFullScreenContent,
    required void Function() onAdDismissedFullScreenContent,
    required void Function(dynamic error) onAdFailedToShowFullScreenContent,
  });
}

class GoogleMobileAdsInterstitialWrapper implements InterstitialAdWrapper {
  final InterstitialAd _ad;
  GoogleMobileAdsInterstitialWrapper(this._ad);

  @override
  Future<void> show() => _ad.show();

  @override
  void dispose() => _ad.dispose();

  @override
  void setFullScreenContentCallback({
    required void Function() onAdShowedFullScreenContent,
    required void Function() onAdDismissedFullScreenContent,
    required void Function(dynamic error) onAdFailedToShowFullScreenContent,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => onAdShowedFullScreenContent(),
      onAdDismissedFullScreenContent: (ad) => onAdDismissedFullScreenContent(),
      onAdFailedToShowFullScreenContent: (ad, error) =>
          onAdFailedToShowFullScreenContent(error),
    );
  }
}

abstract class RewardedAdWrapper {
  Future<void> show(
      {required void Function(RewardItem reward) onUserEarnedReward});
  void dispose();
  void setFullScreenContentCallback({
    required void Function() onAdShowedFullScreenContent,
    required void Function() onAdDismissedFullScreenContent,
    required void Function(dynamic error) onAdFailedToShowFullScreenContent,
  });
}

class GoogleMobileAdsRewardedWrapper implements RewardedAdWrapper {
  final RewardedAd _ad;
  GoogleMobileAdsRewardedWrapper(this._ad);

  @override
  Future<void> show(
          {required void Function(RewardItem reward) onUserEarnedReward}) =>
      _ad.show(onUserEarnedReward: (ad, reward) => onUserEarnedReward(reward));

  @override
  void dispose() => _ad.dispose();

  @override
  void setFullScreenContentCallback({
    required void Function() onAdShowedFullScreenContent,
    required void Function() onAdDismissedFullScreenContent,
    required void Function(dynamic error) onAdFailedToShowFullScreenContent,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => onAdShowedFullScreenContent(),
      onAdDismissedFullScreenContent: (ad) => onAdDismissedFullScreenContent(),
      onAdFailedToShowFullScreenContent: (ad, error) =>
          onAdFailedToShowFullScreenContent(error),
    );
  }
}

class AdService {
  static AdService? _mockInstance;
  static final AdService _instance = AdService._internal();

  factory AdService() => _mockInstance ?? _instance;

  @visibleForTesting
  static set mockInstance(AdService? mock) => _mockInstance = mock;

  AdService._internal();

  // Test hooks
  @visibleForTesting
  DateTime Function() clock = () => DateTime.now();

  @visibleForTesting
  void Function(
    String adUnitId,
    void Function(InterstitialAdWrapper) onAdLoaded,
    void Function(dynamic error) onAdFailedToLoad,
  ) interstitialLoadProvider = (adUnitId, onLoaded, onFailed) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(GoogleMobileAdsInterstitialWrapper(ad)),
        onAdFailedToLoad: (error) => onFailed(error),
      ),
    );
  };

  @visibleForTesting
  void Function(
    String adUnitId,
    void Function(RewardedAdWrapper) onAdLoaded,
    void Function(dynamic error) onAdFailedToLoad,
  ) rewardedHintLoadProvider = (adUnitId, onLoaded, onFailed) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(GoogleMobileAdsRewardedWrapper(ad)),
        onAdFailedToLoad: (error) => onFailed(error),
      ),
    );
  };

  @visibleForTesting
  void Function(
    String adUnitId,
    void Function(RewardedAdWrapper) onAdLoaded,
    void Function(dynamic error) onAdFailedToLoad,
  ) rewardedLifeLoadProvider = (adUnitId, onLoaded, onFailed) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(GoogleMobileAdsRewardedWrapper(ad)),
        onAdFailedToLoad: (error) => onFailed(error),
      ),
    );
  };

  RewardedAdWrapper? _rewardedHintAd;
  RewardedAdWrapper? _rewardedLifeAd;
  InterstitialAdWrapper? _interstitialAd;

  bool _isRewardedHintLoading = false;
  bool _isRewardedLifeLoading = false;
  bool _isInterstitialLoading = false;

  bool _isRewardedHintShowing = false;
  bool _isRewardedLifeShowing = false;
  bool _isInterstitialShowing = false;

  int _campaignCompletionsThisSession = 0;
  DateTime? _lastInterstitialTime;
  static const Duration _interstitialCooldown = Duration(minutes: 2);

  // Retry Timers
  Timer? _hintRetryTimer;
  Timer? _lifeRetryTimer;
  Timer? _interstitialRetryTimer;

  int _hintRetryAttempt = 0;
  int _lifeRetryAttempt = 0;
  int _interstitialRetryAttempt = 0;

  static const int _maxRetryAttempts = 5;

  @visibleForTesting
  void resetStateForTest() {
    _campaignCompletionsThisSession = 0;
    _lastInterstitialTime = null;
    _isInterstitialLoading = false;
    _isInterstitialShowing = false;
    _interstitialRetryAttempt = 0;
    _interstitialAd = null;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    clock = () => DateTime.now();
  }

  final AdConfig _adConfig = const AdConfig();

  // --- Configuration ---
  String get _rewardedHintAdUnitId => _adConfig.rewardedHintAdUnitId;
  String get _rewardedLifeAdUnitId => _adConfig.rewardedLifeAdUnitId;
  String get _interstitialAdUnitId => _adConfig.interstitialAdUnitId;

  Future<void> init() async {
    final RequestConfiguration requestConfiguration = RequestConfiguration(
      ageRestrictedTreatment: AgeRestrictedTreatment.child,
      maxAdContentRating: MaxAdContentRating.g,
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    _preloadAllAds();
  }

  void _preloadAllAds() {
    loadRewardedHintAd();
    loadRewardedLifeAd();
    loadInterstitialAd();
  }

  int _calculateRetryDelay(int attempt) {
    return min(60, pow(2, attempt).toInt()); // Exponential backoff up to 60s
  }

  // --- Rewarded Hint Ad ---
  void loadRewardedHintAd() {
    if (_rewardedHintAd != null || _isRewardedHintLoading) return;
    _isRewardedHintLoading = true;

    rewardedHintLoadProvider(
      _rewardedHintAdUnitId,
      (ad) {
        _rewardedHintAd = ad;
        _isRewardedHintLoading = false;
        _hintRetryAttempt = 0;
      },
      (error) {
        debugPrint('RewardedHintAd failed to load: $error');
        _rewardedHintAd = null;
        _isRewardedHintLoading = false;
        _scheduleHintRetry();
      },
    );
  }

  void _scheduleHintRetry() {
    if (_hintRetryAttempt >= _maxRetryAttempts) return;
    _hintRetryAttempt++;
    final delaySeconds = _calculateRetryDelay(_hintRetryAttempt);
    _hintRetryTimer?.cancel();
    _hintRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      loadRewardedHintAd();
    });
  }

  bool get isRewardedHintAdReady =>
      _rewardedHintAd != null && !_isRewardedHintShowing;

  void showRewardedHintAd(
      {required VoidCallback onRewardEarned,
      required VoidCallback onAdClosed}) {
    if (_rewardedHintAd == null ||
        _isRewardedHintShowing ||
        _isRewardedLifeShowing ||
        _isInterstitialShowing) {
      debugPrint('Warning: attempt to show rewarded hint ad blocked.');
      onAdClosed();
      return;
    }

    _isRewardedHintShowing = true;
    bool rewardGranted = false;
    bool hasCompleted = false;
    final adToDisplay = _rewardedHintAd!;

    void safeContinue() {
      if (hasCompleted) return;
      hasCompleted = true;

      adToDisplay.dispose();
      if (_rewardedHintAd == adToDisplay) {
        _rewardedHintAd = null;
      }
      _isRewardedHintShowing = false;
      AudioService().onAdDismiss();
      onAdClosed();
      loadRewardedHintAd();
    }

    AudioService().onAdShow();
    adToDisplay.setFullScreenContentCallback(
      onAdShowedFullScreenContent: () => debugPrint('Hint ad showed.'),
      onAdDismissedFullScreenContent: () {
        debugPrint('Hint ad dismissed.');
        safeContinue();
      },
      onAdFailedToShowFullScreenContent: (error) {
        debugPrint('Hint ad failed to show: $error');
        safeContinue();
      },
    );

    try {
      adToDisplay.show(
        onUserEarnedReward: (reward) {
          if (!rewardGranted) {
            rewardGranted = true;
            onRewardEarned();
          }
        },
      ).catchError((e) {
        debugPrint('Hint ad threw exception on show Future: $e');
        safeContinue();
      });
    } catch (e) {
      debugPrint('Hint ad threw exception on show: $e');
      safeContinue();
    }
  }

  // --- Rewarded Extra Life Ad ---
  void loadRewardedLifeAd() {
    if (_rewardedLifeAd != null || _isRewardedLifeLoading) return;
    _isRewardedLifeLoading = true;

    rewardedLifeLoadProvider(
      _rewardedLifeAdUnitId,
      (ad) {
        _rewardedLifeAd = ad;
        _isRewardedLifeLoading = false;
        _lifeRetryAttempt = 0;
      },
      (error) {
        debugPrint('RewardedLifeAd failed to load: $error');
        _rewardedLifeAd = null;
        _isRewardedLifeLoading = false;
        _scheduleLifeRetry();
      },
    );
  }

  void _scheduleLifeRetry() {
    if (_lifeRetryAttempt >= _maxRetryAttempts) return;
    _lifeRetryAttempt++;
    final delaySeconds = _calculateRetryDelay(_lifeRetryAttempt);
    _lifeRetryTimer?.cancel();
    _lifeRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      loadRewardedLifeAd();
    });
  }

  bool get isRewardedLifeAdReady =>
      _rewardedLifeAd != null && !_isRewardedLifeShowing;

  void showRewardedLifeAd(
      {required VoidCallback onRewardEarned,
      required VoidCallback onAdClosed}) {
    if (_rewardedLifeAd == null ||
        _isRewardedLifeShowing ||
        _isRewardedHintShowing ||
        _isInterstitialShowing) {
      debugPrint('Warning: attempt to show rewarded life ad blocked.');
      onAdClosed();
      return;
    }

    _isRewardedLifeShowing = true;
    bool rewardGranted = false;
    bool hasCompleted = false;
    final adToDisplay = _rewardedLifeAd!;

    void safeContinue() {
      if (hasCompleted) return;
      hasCompleted = true;

      adToDisplay.dispose();
      if (_rewardedLifeAd == adToDisplay) {
        _rewardedLifeAd = null;
      }
      _isRewardedLifeShowing = false;
      AudioService().onAdDismiss();
      onAdClosed();
      loadRewardedLifeAd();
    }

    AudioService().onAdShow();
    adToDisplay.setFullScreenContentCallback(
      onAdShowedFullScreenContent: () => debugPrint('Life ad showed.'),
      onAdDismissedFullScreenContent: () {
        debugPrint('Life ad dismissed.');
        safeContinue();
      },
      onAdFailedToShowFullScreenContent: (error) {
        debugPrint('Life ad failed to show: $error');
        safeContinue();
      },
    );

    try {
      adToDisplay.show(
        onUserEarnedReward: (reward) {
          if (!rewardGranted) {
            rewardGranted = true;
            onRewardEarned();
          }
        },
      ).catchError((e) {
        debugPrint('Life ad threw exception on show Future: $e');
        safeContinue();
      });
    } catch (e) {
      debugPrint('Life ad threw exception on show: $e');
      safeContinue();
    }
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd() {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    interstitialLoadProvider(
      _interstitialAdUnitId,
      (ad) {
        _interstitialAd = ad;
        _isInterstitialLoading = false;
        _interstitialRetryAttempt = 0;
      },
      (error) {
        debugPrint('InterstitialAd failed to load: $error');
        _interstitialAd = null;
        _isInterstitialLoading = false;
        _scheduleInterstitialRetry();
      },
    );
  }

  void _scheduleInterstitialRetry() {
    if (_interstitialRetryAttempt >= _maxRetryAttempts) return;
    _interstitialRetryAttempt++;
    final delaySeconds = _calculateRetryDelay(_interstitialRetryAttempt);
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      loadInterstitialAd();
    });
  }

  Future<void> recordCampaignCompletionAndShowInterstitialIfNeeded({
    required VoidCallback onContinue,
  }) async {
    _campaignCompletionsThisSession++;

    if (_campaignCompletionsThisSession <
        AppConstants.adFrequencyCampaignLevels) {
      onContinue();
      return;
    }

    if (_lastInterstitialTime != null &&
        clock().difference(_lastInterstitialTime!) < _interstitialCooldown) {
      onContinue();
      return;
    }

    if (_interstitialAd == null ||
        _isInterstitialShowing ||
        _isRewardedHintShowing ||
        _isRewardedLifeShowing) {
      debugPrint('Interstitial not ready or blocked, deferring.');
      onContinue();
      return; // Do not reset completion counter; try again next level
    }

    _isInterstitialShowing = true;
    bool terminalHandled = false;
    final displayedAd = _interstitialAd!;

    void terminalCleanup(bool success) {
      if (terminalHandled) return;
      terminalHandled = true;

      displayedAd.dispose();

      // Only clear if the global reference hasn't been replaced by a newly preloaded ad
      if (_interstitialAd == displayedAd) {
        _interstitialAd = null;
      }

      _isInterstitialShowing = false;
      AudioService().onAdDismiss();

      if (success) {
        _campaignCompletionsThisSession = 0;
      }

      onContinue();
      loadInterstitialAd(); // Preload next exactly once
    }

    AudioService().onAdShow();
    displayedAd.setFullScreenContentCallback(
      onAdShowedFullScreenContent: () {
        debugPrint('Interstitial ad showed.');
        _lastInterstitialTime = clock();
      },
      onAdDismissedFullScreenContent: () {
        debugPrint('Interstitial ad dismissed.');
        terminalCleanup(true);
      },
      onAdFailedToShowFullScreenContent: (error) {
        debugPrint('Interstitial ad failed to show: $error');
        terminalCleanup(false);
      },
    );

    try {
      await displayedAd.show();
    } catch (e) {
      debugPrint('Interstitial ad show exception: $e');
      terminalCleanup(false);
    }
  }

  void dispose() {
    _hintRetryTimer?.cancel();
    _lifeRetryTimer?.cancel();
    _interstitialRetryTimer?.cancel();
    _rewardedHintAd?.dispose();
    _rewardedLifeAd?.dispose();
    _interstitialAd?.dispose();
  }
}
