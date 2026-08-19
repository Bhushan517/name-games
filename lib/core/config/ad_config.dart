import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConfig {
  final bool isRelease;

  const AdConfig({this.isRelease = kReleaseMode});

  String get rewardedHintAdUnitId {
    if (isRelease) {
      return Platform.isAndroid
          ? 'ca-app-pub-4413496842954832/9352075514'
          : 'ca-app-pub-3940256099942544/1712485313'; // Keep iOS test ID since no prod ID provided
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  String get rewardedLifeAdUnitId {
    if (isRelease) {
      return Platform.isAndroid
          ? 'ca-app-pub-4413496842954832/2606703764'
          : 'ca-app-pub-3940256099942544/1712485313'; // Keep iOS test ID since no prod ID provided
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  String get interstitialAdUnitId {
    if (isRelease) {
      return Platform.isAndroid
          ? 'ca-app-pub-4413496842954832/1304551769'
          : 'ca-app-pub-3940256099942544/4411468910'; // Keep iOS test ID since no prod ID provided
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
  }
}
