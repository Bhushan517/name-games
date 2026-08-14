class PlayerProgress {
  const PlayerProgress({
    required this.unlockedChallengeNumber,
    required this.challengeStars,
    required this.completedWordIds,
    required this.lastDailyDate,
    required this.lastDailyStars,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.selectedLanguage = 'en',
  });

  final int unlockedChallengeNumber;
  final Map<String, int> challengeStars; // challengeId -> stars
  final Set<String> completedWordIds; // wordId -> completed
  final String lastDailyDate; // YYYY-MM-DD
  final int lastDailyStars;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final String selectedLanguage;

  int get totalStars =>
      challengeStars.values.fold(0, (sum, stars) => sum + stars);
  int get completedChallengeCount => challengeStars.length;
  int get unlockedWordCount => completedWordIds.length;

  bool isChallengeUnlocked(int challengeNumber) =>
      challengeNumber <= unlockedChallengeNumber;

  int getStarsForChallenge(String challengeId) =>
      challengeStars[challengeId] ?? 0;

  bool isWordUnlocked(String wordId) => completedWordIds.contains(wordId);

  bool isDailyChallengeCompletedFor(String todayKey) =>
      lastDailyDate == todayKey && lastDailyStars > 0;
}
