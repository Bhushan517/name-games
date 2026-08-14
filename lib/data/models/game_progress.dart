class GameProgress {
  const GameProgress({
    required this.unlockedLevel,
    required this.starsMap,
  });

  final int unlockedLevel;
  final Map<int, int> starsMap;

  int get totalStars => starsMap.values.fold(0, (sum, stars) => sum + stars);
  bool isLevelUnlocked(int index) => (index + 1) <= unlockedLevel;
  int starsForLevel(int index) => starsMap[index] ?? 0;
}
