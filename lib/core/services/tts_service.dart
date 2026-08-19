import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'audio_service.dart';

/// Production TTS service backed by [FlutterTts].
///
/// Usage:
///   await TtsService.init();
///   await TtsService.speak('EAGLE');
///   TtsService.stop();
///   TtsService.dispose();
abstract class TtsEngine {
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  Future<void> awaitSpeakCompletion(bool awaitCompletion);
  Future<void> speak(String text);
  Future<void> stop();
}

class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> setLanguage(String language) => _tts.setLanguage(language);
  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);
  @override
  Future<void> setVolume(double volume) => _tts.setVolume(volume);
  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);
  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) =>
      _tts.awaitSpeakCompletion(awaitCompletion);
  @override
  Future<void> speak(String text) => _tts.speak(text);
  @override
  Future<void> stop() => _tts.stop();
}

class TtsService {
  TtsService._();

  static TtsEngine? _tts;
  static bool _isPlaying = false;
  static bool _initialized = false;
  static int _speechToken = 0;

  @visibleForTesting
  static TtsEngine Function() engineProvider = () => FlutterTtsEngine();

  static bool get isPlaying => _isPlaying;

  /// Initialise the TTS engine. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      _tts = engineProvider();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.45); // slightly slower for children
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);
      await _tts!.awaitSpeakCompletion(true);

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

      stop();
      _speechToken++;
      final currentToken = _speechToken;

      _isPlaying = true;
      AudioService().duckBgmForTts();

      await _tts!.speak(word);

      if (currentToken == _speechToken) {
        _isPlaying = false;
        AudioService().unduckBgmFromTts();
      }
    } catch (e) {
      _isPlaying = false;
      AudioService().unduckBgmFromTts();
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
    _speechToken++;
    _isPlaying = false;
    AudioService().unduckBgmFromTts();
  }

  /// Release the TTS engine. Call from app lifecycle dispose.
  static void dispose() {
    stop();
    _tts = null;
    _initialized = false;
  }

  @visibleForTesting
  static void resetStateForTest() {
    _tts = null;
    _isPlaying = false;
    _initialized = false;
    _speechToken = 0;
    engineProvider = () => FlutterTtsEngine();
  }
}
