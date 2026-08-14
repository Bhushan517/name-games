import '../../data/models/generated_challenge.dart';

/// Route arguments for the game screen.
///
/// [isDailyMode] prevents campaign-level unlock when the game is launched
/// from the Daily Challenge screen.
class GameScreenArgs {
  const GameScreenArgs({
    required this.challenge,
    this.isDailyMode = false,
  });

  final GeneratedChallenge challenge;

  /// When true the controller will NOT call [saveChallengeCompletion],
  /// so completing the daily quest never unlocks or skips campaign levels.
  final bool isDailyMode;
}
