import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'local_storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _bgmPlayer;
  List<AudioPlayer>? _sfxPlayers;
  int _sfxIndex = 0;

  bool _musicEnabled = true;
  bool _soundEnabled = true;
  String? _currentBgmTrack;
  bool _isAppPaused = false;
  bool _isDucking = false;
  bool _isAdShowing = false;
  bool _isTestMode = false;

  final List<String> testPlayedSfx = [];

  void enableTestMode() {
    _isTestMode = true;
  }

  String? get currentBgmTrack => _currentBgmTrack;
  bool get isAppPaused => _isAppPaused;
  bool get isDucking => _isDucking;
  bool get isAdShowing => _isAdShowing;

  late LocalStorageService _storageService;

  Future<void> init(LocalStorageService storageService) async {
    _storageService = storageService;
    final progress = storageService.loadPlayerProgress();
    _musicEnabled = progress.musicEnabled;
    _soundEnabled = progress.soundEnabled;

    if (_isTestMode) return;

    _bgmPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    _sfxPlayers = List.generate(
        4, (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _storageService.setMusicEnabled(enabled);
    if (!enabled) {
      await _bgmPlayer?.pause();
    } else if (_currentBgmTrack != null && !_isAppPaused && !_isAdShowing) {
      await _bgmPlayer?.resume();
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _storageService.setSoundEnabled(enabled);
  }

  bool get isMusicEnabled => _musicEnabled;
  bool get isSoundEnabled => _soundEnabled;

  Future<void> playBgm(String assetName, {double volume = 0.25}) async {
    if (_isTestMode) {
      _currentBgmTrack = assetName;
      return;
    }
    if (_currentBgmTrack == assetName) {
      if (_bgmPlayer?.state != PlayerState.playing &&
          _musicEnabled &&
          !_isAppPaused &&
          !_isAdShowing) {
        await _bgmPlayer?.resume();
      }
      return;
    }

    _currentBgmTrack = assetName;
    await _bgmPlayer?.setVolume(_isDucking ? volume * 0.3 : volume);
    await _bgmPlayer?.setSource(AssetSource('audio/music/$assetName'));

    if (_musicEnabled && !_isAppPaused && !_isAdShowing) {
      await _bgmPlayer?.resume();
    }
  }

  Future<void> playSfx(String assetName, {double volume = 0.5}) async {
    if (!_soundEnabled || _isAppPaused) return;
    if (_isTestMode) {
      testPlayedSfx.add(assetName);
      return;
    }

    if (_sfxPlayers == null || _sfxPlayers!.isEmpty) return;

    final player = _sfxPlayers![_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPlayers!.length;

    await player.setVolume(volume);
    await player.play(AssetSource('audio/sfx/$assetName'));
  }

  Future<void> pauseBgm() async {
    if (_isTestMode) return;
    if (_bgmPlayer?.state == PlayerState.playing) {
      await _bgmPlayer?.pause();
    }
  }

  Future<void> resumeBgm() async {
    if (_isTestMode) return;
    if (_musicEnabled &&
        _currentBgmTrack != null &&
        !_isAppPaused &&
        !_isAdShowing) {
      await _bgmPlayer?.resume();
    }
  }

  Future<void> onAppPaused() async {
    _isAppPaused = true;
    await pauseBgm();
  }

  Future<void> onAppResumed() async {
    _isAppPaused = false;
    await resumeBgm();
  }

  Future<void> duckBgmForTts() async {
    _isDucking = true;
    if (_isTestMode) return;
    if (_bgmPlayer?.state == PlayerState.playing) {
      await _bgmPlayer?.setVolume(0.05);
    }
  }

  Future<void> unduckBgmFromTts() async {
    if (!_isDucking) return;
    _isDucking = false;
    if (_isTestMode) return;
    if (_currentBgmTrack == 'gameplay_music.wav') {
      await _bgmPlayer?.setVolume(0.20);
    } else {
      await _bgmPlayer?.setVolume(0.25);
    }
  }

  void onAdShow() {
    _isAdShowing = true;
    pauseBgm();
  }

  void onAdDismiss() {
    _isAdShowing = false;
    resumeBgm();
  }

  Future<void> disposeAll() async {
    if (_isTestMode) {
      _bgmPlayer = null;
      _sfxPlayers = null;
      _currentBgmTrack = null;
      _isAppPaused = false;
      _isDucking = false;
      _isAdShowing = false;
      return;
    }
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
    if (_sfxPlayers != null) {
      for (var player in _sfxPlayers!) {
        await player.dispose();
      }
      _sfxPlayers = null;
    }
    _currentBgmTrack = null;
    _isAppPaused = false;
    _isDucking = false;
    _isAdShowing = false;
  }

  /// Helper to wrap UI callbacks with the standard button tap sound
  static VoidCallback? withSound(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      AudioService().playSfx('button_tap.wav');
      callback();
    };
  }
}
