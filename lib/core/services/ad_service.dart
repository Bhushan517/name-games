import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'audio_service.dart';
import '../constants/app_constants.dart';

class AdService {
  static AdService? _mockInstance;
  static final AdService _instance = AdService._internal();

  factory AdService() => _mockInstance ?? _instance;

  @visibleForTesting
  static set mockInstance(AdService? mock) => _mockInstance = mock;

  AdService._internal();

  RewardedAd? _rewardedHintAd;
  RewardedAd? _rewardedLifeAd;
  InterstitialAd? _interstitialAd;

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

  // --- Configuration ---
  String get _rewardedHintAdUnitId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // TODO: Replace
          : 'ca-app-pub-3940256099942544/1712485313'; // TODO: Replace
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  String get _rewardedLifeAdUnitId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // TODO: Replace
          : 'ca-app-pub-3940256099942544/1712485313'; // TODO: Replace
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  String get _interstitialAdUnitId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // TODO: Replace
          : 'ca-app-pub-3940256099942544/4411468910'; // TODO: Replace
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
  }

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

    RewardedAd.load(
      adUnitId: _rewardedHintAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedHintAd = ad;
          _isRewardedHintLoading = false;
          _hintRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedHintAd failed to load: $error');
          _rewardedHintAd = null;
          _isRewardedHintLoading = false;
          _scheduleHintRetry();
        },
      ),
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

    AudioService().onAdShow();
    _rewardedHintAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Hint ad showed.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Hint ad dismissed.');
        ad.dispose();
        _rewardedHintAd = null;
        _isRewardedHintShowing = false;
        AudioService().onAdDismiss();
        onAdClosed();
        loadRewardedHintAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Hint ad failed to show: $error');
        ad.dispose();
        _rewardedHintAd = null;
        _isRewardedHintShowing = false;
        AudioService().onAdDismiss();
        onAdClosed();
        loadRewardedHintAd(); // Preload next
      },
    );

    _rewardedHintAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (!rewardGranted) {
        rewardGranted = true;
        onRewardEarned();
      }
    });
  }

  // --- Rewarded Extra Life Ad ---
  void loadRewardedLifeAd() {
    if (_rewardedLifeAd != null || _isRewardedLifeLoading) return;
    _isRewardedLifeLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedLifeAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLifeAd = ad;
          _isRewardedLifeLoading = false;
          _lifeRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedLifeAd failed to load: $error');
          _rewardedLifeAd = null;
          _isRewardedLifeLoading = false;
          _scheduleLifeRetry();
        },
      ),
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

    AudioService().onAdShow();
    _rewardedLifeAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Life ad showed.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Life ad dismissed.');
        ad.dispose();
        _rewardedLifeAd = null;
        _isRewardedLifeShowing = false;
        AudioService().onAdDismiss();
        onAdClosed();
        loadRewardedLifeAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Life ad failed to show: $error');
        ad.dispose();
        _rewardedLifeAd = null;
        _isRewardedLifeShowing = false;
        AudioService().onAdDismiss();
        onAdClosed();
        loadRewardedLifeAd(); // Preload next
      },
    );

    _rewardedLifeAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (!rewardGranted) {
        rewardGranted = true;
        onRewardEarned();
      }
    });
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd() {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _scheduleInterstitialRetry();
        },
      ),
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

    if (_campaignCompletionsThisSession >=
            AppConstants.adFrequencyCampaignLevels &&
        _interstitialAd != null) {
      AudioService().onAdShow();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _campaignCompletionsThisSession = 0;
          loadInterstitialAd();
          AudioService().onAdDismiss();
          onContinue();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          AudioService().onAdDismiss();
          onContinue();
        },
      );
      await _interstitialAd!.show();
    } else {
      onContinue();
    }
  }

  void _showInterstitialAd({required VoidCallback onAdClosed}) {
    if (_interstitialAd == null ||
        _isInterstitialShowing ||
        _isRewardedHintShowing ||
        _isRewardedLifeShowing) {
      debugPrint('Warning: attempt to show interstitial ad blocked.');
      onAdClosed();
      return;
    }

    _isInterstitialShowing = true;
    _lastInterstitialTime = DateTime.now();

    AudioService().onAdShow();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) =>
          debugPrint('Interstitial ad showed.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed.');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialShowing = false;
        AudioService().onAdDismiss();
        onAdClosed();
        loadInterstitialAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialShowing = false;
        AudioService().onAdDismiss();
        onAdClosed();
        loadInterstitialAd(); // Preload next
      },
    );

    _interstitialAd!.show();
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
