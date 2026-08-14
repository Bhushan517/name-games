import '../../core/services/local_storage_service.dart';
import '../generators/challenge_generator.dart';
import '../models/generated_challenge.dart';
import '../models/player_progress.dart';
import 'word_repository.dart';

class ChallengeRepository {
  ChallengeRepository({
    required this.wordRepository,
    required this.storageService,
  });

  final WordRepository wordRepository;
  final LocalStorageService storageService;

  List<GeneratedChallenge>? _cachedChallenges;

  Future<List<GeneratedChallenge>> getChallenges() async {
    if (_cachedChallenges != null && _cachedChallenges!.isNotEmpty) {
      return _cachedChallenges!;
    }

    final words = await wordRepository.getAllWords();
    _cachedChallenges = ChallengeGenerator.generateAllChallenges(words);
    return _cachedChallenges!;
  }

  List<GeneratedChallenge> getCachedChallenges() {
    return _cachedChallenges ?? <GeneratedChallenge>[];
  }

  GeneratedChallenge? getChallengeByNumber(int challengeNumber) {
    if (_cachedChallenges == null || _cachedChallenges!.isEmpty) return null;
    final index = challengeNumber - 1;
    if (index >= 0 && index < _cachedChallenges!.length) {
      return _cachedChallenges![index];
    }
    return null;
  }

  List<GeneratedChallenge> getPackChallenges(int packIndex) {
    if (_cachedChallenges == null || _cachedChallenges!.isEmpty) {
      return <GeneratedChallenge>[];
    }
    final start = (packIndex * 50).clamp(0, _cachedChallenges!.length);
    final end = ((packIndex + 1) * 50).clamp(0, _cachedChallenges!.length);
    return _cachedChallenges!.sublist(start, end);
  }

  GeneratedChallenge getDailyChallenge(DateTime date) {
    final challenges = getCachedChallenges();
    if (challenges.isEmpty) {
      throw StateError(
          'Challenges must be initialized before getting Daily Challenge.');
    }

    // Deterministic hash based on YYYY-MM-DD
    final dayHash = date.year * 10000 + date.month * 100 + date.day;
    final selectedIndex = dayHash % challenges.length;
    return challenges[selectedIndex];
  }

  String getTodayDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  PlayerProgress getPlayerProgress() {
    return storageService.loadPlayerProgress();
  }

  Future<void> saveChallengeCompletion({
    required GeneratedChallenge challenge,
    required int starsEarned,
  }) async {
    await storageService.saveChallengeResult(
      challengeNumber: challenge.challengeNumber,
      challengeId: challenge.id,
      wordId: challenge.wordContent.id,
      starsEarned: starsEarned,
    );
  }

  Future<void> saveDailyChallengeCompletion({
    required DateTime date,
    required int starsEarned,
    String? wordId,
  }) async {
    final todayKey = getTodayDateKey(date);
    await storageService.saveDailyChallengeResult(
      todayKey: todayKey,
      starsEarned: starsEarned,
      wordId: wordId,
    );
  }
}
