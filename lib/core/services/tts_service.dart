import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Production TTS service backed by [FlutterTts].
///
/// Usage:
///   await TtsService.init();
///   await TtsService.speak('EAGLE');
///   TtsService.stop();
///   TtsService.dispose();
class TtsService {
  TtsService._();

  static FlutterTts? _tts;
  static bool _isPlaying = false;
  static bool _initialized = false;

  static bool get isPlaying => _isPlaying;

  /// Initialise the TTS engine. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.45); // slightly slower for children
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);

      _tts!.setStartHandler(() => _isPlaying = true);
      _tts!.setCompletionHandler(() => _isPlaying = false);
      _tts!.setCancelHandler(() => _isPlaying = false);
      _tts!.setErrorHandler((_) => _isPlaying = false);

      _initialized = true;
    } catch (e) {
      // Unsupported device or platform — silently degrade
      if (kDebugMode) debugPrint('[TtsService] init failed: $e');
      _tts =
          null; // ensure stop() is a no-op in test / unsupported environments
    }
  }

  /// Speak [word] aloud. Initialises engine lazily if needed.
  /// [word] should be the plain English word (e.g. "EAGLE"), NOT a phonetic string.
  static Future<void> speak(String word) async {
    if (word.trim().isEmpty) return;
    try {
      await init();
      if (_tts == null) return;
      _isPlaying = true;
      await _tts!.speak(word);
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) debugPrint('[TtsService] speak failed: $e');
    }
  }

  /// Stop any in-progress speech immediately.
  static void stop() {
    try {
      // Use .ignore() so the async MissingPluginException in test VMs
      // (where the flutter_tts channel is not registered) is swallowed.
      _tts?.stop().ignore();
    } catch (_) {}
    _isPlaying = false;
  }

  /// Release the TTS engine. Call from app lifecycle dispose.
  static void dispose() {
    stop();
    _tts = null;
    _initialized = false;
  }
}
