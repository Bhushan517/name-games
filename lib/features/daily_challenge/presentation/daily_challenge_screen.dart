import 'package:flutter/material.dart';
import '../../../app/routes/game_screen_args.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/generated_challenge.dart';
import '../../../data/models/player_progress.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../shared/widgets/space_background.dart';
import '../../../core/services/audio_service.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    super.key,
    required this.challengeRepository,
  });

  final ChallengeRepository challengeRepository;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  GeneratedChallenge? _dailyChallenge;
  late PlayerProgress _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    await widget.challengeRepository.getChallenges();
    final now = DateTime.now();
    final challenge = widget.challengeRepository.getDailyChallenge(now);
    final progress = widget.challengeRepository.getPlayerProgress();

    if (mounted) {
      setState(() {
        _dailyChallenge = challenge;
        _progress = progress;
        _isLoading = false;
      });
    }
  }

  Future<void> _playDaily() async {
    if (_dailyChallenge == null) return;

    final earnedStars = await Navigator.pushNamed<int>(
      context,
      RouteNames.game,
      arguments: GameScreenArgs(
        challenge: _dailyChallenge!,
        isDailyMode: true, // must NOT unlock campaign challenge numbers
      ),
    );

    if (earnedStars != null && mounted) {
      await widget.challengeRepository.saveDailyChallengeCompletion(
        date: DateTime.now(),
        starsEarned: earnedStars,
        wordId: _dailyChallenge!.wordContent.id,
      );
      setState(() {
        _progress = widget.challengeRepository.getPlayerProgress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _dailyChallenge == null) {
      return const Scaffold(
        body: SpaceBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final todayKey = widget.challengeRepository.getTodayDateKey(now);
    final isCompletedToday = _progress.isDailyChallengeCompletedFor(todayKey);

    return Scaffold(
      body: SpaceBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: AudioService.withSound(() => Navigator.pop(context)),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPECIAL EVENT',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'DAILY QUEST',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.gold),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.25),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.gold,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isCompletedToday
                              ? 'DAILY QUEST COMPLETED! 🎉'
                              : 'TODAY\'S MYSTERY CHALLENGE',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date: $todayKey',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_dailyChallenge!.category} • ${_dailyChallenge!.letterCount} LETTERS',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mode: ${_dailyChallenge!.mode.displayName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _dailyChallenge!.themeColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Difficulty: ${_dailyChallenge!.difficulty.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: AudioService.withSound(_playDaily),
                            style: FilledButton.styleFrom(
                              backgroundColor: isCompletedToday
                                  ? AppColors.purple
                                  : AppColors.gold,
                              foregroundColor: AppColors.background,
                            ),
                            icon: Icon(
                              isCompletedToday
                                  ? Icons.replay_rounded
                                  : Icons.play_arrow_rounded,
                              size: 26,
                            ),
                            label: Text(
                              isCompletedToday
                                  ? 'PLAY AGAIN (PRACTICE)'
                                  : 'START DAILY QUEST',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
