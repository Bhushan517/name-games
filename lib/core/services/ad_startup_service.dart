import 'dart:async';
import 'package:flutter/foundation.dart';

/// Production ad startup initializer.
/// Safely runs MobileAds and AdService initializations without blocking
/// main UI boot / runApp().
Future<void> initializeAdsSafely({
  required Future<void> Function() initializeMobileAds,
  required Future<void> Function() initializeAdService,
}) async {
  try {
    await initializeMobileAds();
    try {
      await initializeAdService();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdService initialization failed: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('MobileAds initialization failed: $e');
    }
  }
}
