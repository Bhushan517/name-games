import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/player_progress.dart';

class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static const String keyUnlockedChallenge = 'unlocked_challenge_num';
  static const String keyChallengeStarsMap = 'challenge_stars_json';
  static const String keyCompletedWordIds = 'completed_word_ids';
  static const String keyDailyDate = 'daily_challenge_date';
  static const String keyDailyStars = 'daily_challenge_stars';
  static const String keySound = 'pref_sound';
  static const String keyMusic = 'pref_music';
  static const String keyHaptics = 'pref_haptics';
  static const String keyLang = 'pref_lang';

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    service._migrateLegacyProgressIfNeeded();
    return service;
  }

  void _migrateLegacyProgressIfNeeded() {
    if (!_prefs.containsKey(keyUnlockedChallenge)) {
      final legacyUnlocked = _prefs.getInt(AppConstants.keyUnlockedLevel) ?? 1;
      _prefs.setInt(keyUnlockedChallenge, legacyUnlocked);
    }
  }

  bool isFirstLaunch() {
    return !(_prefs.getBool(AppConstants.keySeenOnboarding) ?? false);
  }

  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(AppConstants.keySeenOnboarding, true);
  }

  PlayerProgress loadPlayerProgress() {
    final unlocked = _prefs.getInt(keyUnlockedChallenge) ?? 1;
    final starsJson = _prefs.getString(keyChallengeStarsMap);
    final starsMap = <String, int>{};
    if (starsJson != null && starsJson.isNotEmpty) {
      try {
        final decoded = json.decode(starsJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is num) {
            starsMap[key] = value.toInt();
          }
        });
      } catch (_) {}
    }

    final wordList = _prefs.getStringList(keyCompletedWordIds) ?? <String>[];
    final completedWords = wordList.toSet();

    final dailyDate = _prefs.getString(keyDailyDate) ?? '';
    final dailyStars = _prefs.getInt(keyDailyStars) ?? 0;

    final sound = _prefs.getBool(keySound) ?? true;
    final music = _prefs.getBool(keyMusic) ?? true;
    final haptics = _prefs.getBool(keyHaptics) ?? true;
    final lang = _prefs.getString(keyLang) ?? 'en';

    return PlayerProgress(
      unlockedChallengeNumber: unlocked,
      challengeStars: starsMap,
      completedWordIds: completedWords,
      lastDailyDate: dailyDate,
      lastDailyStars: dailyStars,
      soundEnabled: sound,
      musicEnabled: music,
      hapticsEnabled: haptics,
      selectedLanguage: lang,
    );
  }

  Future<void> saveChallengeResult({
    required int challengeNumber,
    required String challengeId,
    required String wordId,
    required int starsEarned,
  }) async {
    final currentProgress = loadPlayerProgress();

    // 1. Save stars (keep highest)
    final starsMap = Map<String, int>.from(currentProgress.challengeStars);
    final currentBest = starsMap[challengeId] ?? 0;
    if (starsEarned > currentBest) {
      starsMap[challengeId] = starsEarned;
      await _prefs.setString(keyChallengeStarsMap, json.encode(starsMap));
    }

    // 2. Mark word as completed in collection
    final completedWords = Set<String>.from(currentProgress.completedWordIds);
    if (!completedWords.contains(wordId)) {
      completedWords.add(wordId);
      await _prefs.setStringList(
        keyCompletedWordIds,
        completedWords.toList(),
      );
    }

    // 3. Unlock next challenge if completing current highest
    final nextChallenge = challengeNumber + 1;
    if (nextChallenge > currentProgress.unlockedChallengeNumber &&
        nextChallenge <= 500) {
      await _prefs.setInt(keyUnlockedChallenge, nextChallenge);
      await _prefs.setInt(AppConstants.keyUnlockedLevel, nextChallenge);
    }
  }

  Future<void> saveDailyChallengeResult({
    required String todayKey,
    required int starsEarned,
    String? wordId,
  }) async {
    await _prefs.setString(keyDailyDate, todayKey);
    await _prefs.setInt(keyDailyStars, starsEarned);
    if (wordId != null) {
      final currentProgress = loadPlayerProgress();
      final completedWords = Set<String>.from(currentProgress.completedWordIds);
      if (!completedWords.contains(wordId)) {
        completedWords.add(wordId);
        await _prefs.setStringList(
          keyCompletedWordIds,
          completedWords.toList(),
        );
      }
    }
  }

  int getUnlockedLevel() {
    return _prefs.getInt(keyUnlockedChallenge) ??
        _prefs.getInt(AppConstants.keyUnlockedLevel) ??
        1;
  }

  Future<void> setUnlockedLevel(int level) async {
    await _prefs.setInt(keyUnlockedChallenge, level);
    await _prefs.setInt(AppConstants.keyUnlockedLevel, level);
  }

  int getLevelStars(int levelIndex) {
    return _prefs.getInt('${AppConstants.keyLevelStarsPrefix}$levelIndex') ?? 0;
  }

  Future<void> setLevelStars(int levelIndex, int stars) async {
    final current = getLevelStars(levelIndex);
    if (stars > current) {
      await _prefs.setInt(
        '${AppConstants.keyLevelStarsPrefix}$levelIndex',
        stars,
      );
    }
  }

  int getTotalStars() {
    return loadPlayerProgress().totalStars;
  }
}
