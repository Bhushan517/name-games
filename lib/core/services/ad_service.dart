import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
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

  // --- Configuration ---
  // Using official test Ad Unit IDs.
  // Replace these with production IDs from AdMob console when releasing.
  String get _rewardedHintAdUnitId {
    if (kReleaseMode) {
      // TODO: Replace with your actual production Rewarded Ad Unit ID for hints
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  String get _rewardedLifeAdUnitId {
    if (kReleaseMode) {
      // TODO: Replace with your actual production Rewarded Ad Unit ID for lives
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  String get _interstitialAdUnitId {
    if (kReleaseMode) {
      // TODO: Replace with your actual production Interstitial Ad Unit ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
  }

  Future<void> init() async {
    // Set child-safe configuration
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
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedHintAd failed to load: $error');
          _rewardedHintAd = null;
          _isRewardedHintLoading = false;
        },
      ),
    );
  }

  bool get isRewardedHintAdReady =>
      _rewardedHintAd != null && !_isRewardedHintShowing;

  void showRewardedHintAd({required VoidCallback onRewardEarned}) {
    if (_rewardedHintAd == null || _isRewardedHintShowing) {
      debugPrint('Warning: attempt to show rewarded hint ad before loaded.');
      return;
    }

    _isRewardedHintShowing = true;
    bool rewardGranted = false;

    _rewardedHintAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('\$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _rewardedHintAd = null;
        _isRewardedHintShowing = false;
        loadRewardedHintAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('\$ad onAdFailedToShowFullScreenContent: \$error');
        ad.dispose();
        _rewardedHintAd = null;
        _isRewardedHintShowing = false;
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
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedLifeAd failed to load: \$error');
          _rewardedLifeAd = null;
          _isRewardedLifeLoading = false;
        },
      ),
    );
  }

  bool get isRewardedLifeAdReady =>
      _rewardedLifeAd != null && !_isRewardedLifeShowing;

  void showRewardedLifeAd({required VoidCallback onRewardEarned}) {
    if (_rewardedLifeAd == null || _isRewardedLifeShowing) {
      debugPrint('Warning: attempt to show rewarded life ad before loaded.');
      return;
    }

    _isRewardedLifeShowing = true;
    bool rewardGranted = false;

    _rewardedLifeAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('\$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _rewardedLifeAd = null;
        _isRewardedLifeShowing = false;
        loadRewardedLifeAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('\$ad onAdFailedToShowFullScreenContent: \$error');
        ad.dispose();
        _rewardedLifeAd = null;
        _isRewardedLifeShowing = false;
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
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: \$error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void recordCampaignCompletionAndShowInterstitialIfNeeded() {
    _campaignCompletionsThisSession++;
    if (_campaignCompletionsThisSession % 4 == 0) {
      _showInterstitialAd();
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null || _isInterstitialShowing) {
      debugPrint('Warning: attempt to show interstitial ad before loaded.');
      return;
    }

    _isInterstitialShowing = true;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('\$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialShowing = false;
        loadInterstitialAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('\$ad onAdFailedToShowFullScreenContent: \$error');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialShowing = false;
        loadInterstitialAd(); // Preload next
      },
    );

    _interstitialAd!.show();
  }
}
