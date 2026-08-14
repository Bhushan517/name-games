import 'package:flutter/services.dart';

class HapticService {
  HapticService._();

  static void tap() {
    HapticFeedback.selectionClick();
  }

  static void success() {
    HapticFeedback.heavyImpact();
  }

  static void error() {
    HapticFeedback.vibrate();
  }
}
