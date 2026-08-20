import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/ad_startup_service.dart';

void main() {
  group('Production initializeAdsSafely Tests', () {
    test(
        'MobileAds initialization throws -> completes safely without calling initializeAdService',
        () async {
      int mobileAdsCalls = 0;
      int adServiceCalls = 0;

      await initializeAdsSafely(
        initializeMobileAds: () async {
          mobileAdsCalls++;
          throw Exception('Simulated MobileAds Failure');
        },
        initializeAdService: () async {
          adServiceCalls++;
        },
      );

      expect(mobileAdsCalls, 1);
      expect(adServiceCalls, 0,
          reason: 'initializeAdService must not be called if MobileAds throws');
    });

    test('AdService initialization throws -> completes safely without throwing',
        () async {
      int mobileAdsCalls = 0;
      int adServiceCalls = 0;

      await initializeAdsSafely(
        initializeMobileAds: () async {
          mobileAdsCalls++;
        },
        initializeAdService: () async {
          adServiceCalls++;
          throw Exception('Simulated AdService Failure');
        },
      );

      expect(mobileAdsCalls, 1);
      expect(adServiceCalls, 1);
    });

    test(
        'Successful initialization calls MobileAds and AdService once each in order',
        () async {
      final order = <String>[];

      await initializeAdsSafely(
        initializeMobileAds: () async {
          order.add('MobileAds');
        },
        initializeAdService: () async {
          order.add('AdService');
        },
      );

      expect(order, ['MobileAds', 'AdService']);
    });
  });
}
