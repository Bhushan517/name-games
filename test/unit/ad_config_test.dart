import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/config/ad_config.dart';

void main() {
  group('AdConfig Tests', () {
    test('Debug mode returns test IDs for Android', () {
      const config = AdConfig(isRelease: false);
      if (Platform.isAndroid) {
        expect(config.rewardedHintAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
        expect(config.rewardedLifeAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
        expect(config.interstitialAdUnitId, 'ca-app-pub-3940256099942544/1033173712');
      } else if (Platform.isIOS) {
        expect(config.rewardedHintAdUnitId, 'ca-app-pub-3940256099942544/1712485313');
        expect(config.rewardedLifeAdUnitId, 'ca-app-pub-3940256099942544/1712485313');
        expect(config.interstitialAdUnitId, 'ca-app-pub-3940256099942544/4411468910');
      }
    });

    test('Release mode returns production IDs for Android', () {
      const config = AdConfig(isRelease: true);
      if (Platform.isAndroid) {
        expect(config.rewardedHintAdUnitId, 'ca-app-pub-4413496842954832/9352075514');
        expect(config.rewardedLifeAdUnitId, 'ca-app-pub-4413496842954832/2606703764');
        expect(config.interstitialAdUnitId, 'ca-app-pub-4413496842954832/1304551769');
      } else if (Platform.isIOS) {
        // iOS retains test IDs as per requirements
        expect(config.rewardedHintAdUnitId, 'ca-app-pub-3940256099942544/1712485313');
        expect(config.rewardedLifeAdUnitId, 'ca-app-pub-3940256099942544/1712485313');
        expect(config.interstitialAdUnitId, 'ca-app-pub-3940256099942544/4411468910');
      }
    });
  });
}
