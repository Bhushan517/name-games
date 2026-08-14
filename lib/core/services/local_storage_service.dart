import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  bool isFirstLaunch() {
    return !(_prefs.getBool(AppConstants.keySeenOnboarding) ?? false);
  }

  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(AppConstants.keySeenOnboarding, true);
  }

  int getUnlockedLevel() {
    return _prefs.getInt(AppConstants.keyUnlockedLevel) ?? 1;
  }

  Future<void> setUnlockedLevel(int level) async {
    await _prefs.setInt(AppConstants.keyUnlockedLevel, level);
  }

  int getLevelStars(int levelIndex) {
    return _prefs.getInt('${AppConstants.keyStarsPrefix}$levelIndex') ?? 0;
  }

  Future<void> setLevelStars(int levelIndex, int stars) async {
    final current = getLevelStars(levelIndex);
    if (stars > current) {
      await _prefs.setInt('${AppConstants.keyStarsPrefix}$levelIndex', stars);
    }
  }

  int getTotalStars() {
    int sum = 0;
    for (var i = 0; i < AppConstants.totalLevels; i++) {
      sum += getLevelStars(i);
    }
    return sum;
  }
}
