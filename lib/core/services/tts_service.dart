import 'package:flutter/foundation.dart';

class TtsService {
  TtsService._();

  static bool _isPlaying = false;
  static bool get isPlaying => _isPlaying;

  static Future<void> speak(String text) async {
    if (kDebugMode) {
      print('[TtsService] Speaking text: $text');
    }
    _isPlaying = true;
    // Safe duration delay simulating speech completion
    await Future.delayed(const Duration(milliseconds: 800));
    _isPlaying = false;
  }

  static void stop() {
    _isPlaying = false;
  }
}
