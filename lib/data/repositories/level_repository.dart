import '../../core/services/local_storage_service.dart';
import '../level_data/default_levels.dart';
import '../models/game_progress.dart';
import '../models/word_level.dart';

class LevelRepository {
  LevelRepository(this._storageService);

  final LocalStorageService _storageService;

  List<WordLevel> getLevels() {
    return defaultLevels;
  }

  WordLevel getLevel(int index) {
    return defaultLevels[index];
  }

  GameProgress getProgress() {
    final unlocked = _storageService.getUnlockedLevel();
    final starsMap = <int, int>{};
    for (var i = 0; i < defaultLevels.length; i++) {
      starsMap[i] = _storageService.getLevelStars(i);
    }
    return GameProgress(unlockedLevel: unlocked, starsMap: starsMap);
  }

  Future<void> saveLevelResult(int levelIndex, int starsEarned) async {
    await _storageService.setLevelStars(levelIndex, starsEarned);
    final currentUnlocked = _storageService.getUnlockedLevel();
    final nextLevel = levelIndex + 2;
    if (nextLevel > currentUnlocked && nextLevel <= defaultLevels.length) {
      await _storageService.setUnlockedLevel(nextLevel);
    }
  }
}
