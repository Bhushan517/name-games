import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/core/services/tts_service.dart';
import 'package:name_twist_game/core/services/audio_service.dart';
import 'package:name_twist_game/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class FakeTtsEngine implements TtsEngine {
  bool isPlaying = false;
  String? lastSpokenText;
  bool simulateError = false;

  // Track completer to simulate speech duration
  Completer<void>? currentSpeechCompleter;

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {}

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> speak(String text) async {
    if (simulateError) {
      throw Exception('Simulated TTS Error');
    }
    lastSpokenText = text;
    isPlaying = true;

    currentSpeechCompleter = Completer<void>();
    await currentSpeechCompleter!.future;

    isPlaying = false;
  }

  @override
  Future<void> stop() async {
    if (currentSpeechCompleter != null &&
        !currentSpeechCompleter!.isCompleted) {
      // Complete early due to stop
      currentSpeechCompleter!.complete();
    }
    isPlaying = false;
  }

  void simulateSpeechFinish() {
    if (currentSpeechCompleter != null &&
        !currentSpeechCompleter!.isCompleted) {
      currentSpeechCompleter!.complete();
    }
  }
}

void main() {
  group('TtsService Tests', () {
    late FakeTtsEngine fakeEngine;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(
          {'pref_sound': false, 'pref_music': false});
      final storage = await LocalStorageService.init();
      AudioService().enableTestMode();
      await AudioService().init(storage);

      TtsService.resetStateForTest();

      fakeEngine = FakeTtsEngine();
      TtsService.engineProvider = () => fakeEngine;
    });

    test('Actual English word is passed to TTS and music ducks correctly',
        () async {
      final speakFuture = TtsService.speak('APPLE');

      expect(AudioService().isDucking, true);
      expect(fakeEngine.lastSpokenText, 'APPLE');
      expect(TtsService.isPlaying, true);

      fakeEngine.simulateSpeechFinish();
      await speakFuture;

      expect(AudioService().isDucking, false);
      expect(TtsService.isPlaying, false);
    });

    test('Two rapid requests do not overlap, second request replaces first',
        () async {
      final firstSpeak = TtsService.speak('ONE');

      expect(fakeEngine.lastSpokenText, 'ONE');
      expect(AudioService().isDucking, true);

      // While first is speaking, trigger second
      final secondSpeak = TtsService.speak('TWO');

      // The first should be stopped (simulating stop completes its completer)
      await firstSpeak;

      // Music should STILL be ducking because the second one is active
      expect(AudioService().isDucking, true);
      expect(fakeEngine.lastSpokenText, 'TWO');
      expect(TtsService.isPlaying, true);

      fakeEngine.simulateSpeechFinish();
      await secondSpeak;

      // Now music should unduck
      expect(AudioService().isDucking, false);
      expect(TtsService.isPlaying, false);
    });

    test('Manual stop restores music exactly once', () async {
      final speakFuture = TtsService.speak('HELLO');
      
      // Wait for the async init() inside speak() to finish so the engine actually starts
      await Future.delayed(Duration.zero);
      
      expect(AudioService().isDucking, true);

      TtsService.stop();

      // Fake engine stop will complete the future
      await speakFuture;

      expect(AudioService().isDucking, false);
      expect(TtsService.isPlaying, false);
    });

    test('Error restores music exactly once', () async {
      fakeEngine.simulateError = true;
      await TtsService.speak('ERROR_WORD');

      expect(AudioService().isDucking, false);
      expect(TtsService.isPlaying, false);
    });

    test('Unsupported engine does not crash', () async {
      // Simulate engine provider throwing an error (unsupported)
      TtsService.engineProvider = () {
        throw Exception('Not supported on platform');
      };

      await TtsService.speak('TEST');
      expect(TtsService.isPlaying, false);
    });
  });
}
