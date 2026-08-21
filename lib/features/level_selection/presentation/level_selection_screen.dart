import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/generated_challenge.dart';
import '../../../data/models/player_progress.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../shared/widgets/space_background.dart';
import '../../../core/services/audio_service.dart';
import 'widgets/challenge_card.dart';
import 'widgets/pack_selector.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key, required this.repository});

  final ChallengeRepository repository;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _selectedPack = 0; // 0 to 9
  late PlayerProgress _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await widget.repository.getChallenges();
    final progress = widget.repository.getPlayerProgress();

    // Auto-select pack containing highest unlocked challenge
    final currentPack =
        ((progress.unlockedChallengeNumber - 1) ~/ 50).clamp(0, 9);

    if (mounted) {
      setState(() {
        _progress = progress;
        _selectedPack = currentPack;
        _isLoading = false;
      });
    }
  }

  Future<void> _openChallenge(GeneratedChallenge challenge) async {
    if (!_progress.isChallengeUnlocked(challenge.challengeNumber)) return;

    final earnedStars = await Navigator.pushNamed<int>(
      context,
      RouteNames.game,
      arguments: challenge,
    );

    if (earnedStars != null && mounted) {
      setState(() {
        _progress = widget.repository.getPlayerProgress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SpaceBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        ),
      );
    }

    final packChallenges = widget.repository.getPackChallenges(_selectedPack);
    final totalStars = _progress.totalStars;

    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 20, 10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        onPressed:
                            AudioService.withSound(() => Navigator.pop(context)),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.yourJourney,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            AppStrings.chooseLevel,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total Stars Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.25),
                            AppColors.gold.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '$totalStars',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pack Selector
              PackSelector(
                selectedPack: _selectedPack,
                onPackSelected: (packIndex) {
                  setState(() => _selectedPack = packIndex);
                },
              ),

              const SizedBox(height: 10),

              // Challenges List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: packChallenges.length,
                  itemBuilder: (_, index) {
                    final challenge = packChallenges[index];
                    final isLocked =
                        !_progress.isChallengeUnlocked(challenge.challengeNumber);
                    final starsEarned =
                        _progress.getStarsForChallenge(challenge.id);

                    return TweenAnimationBuilder<double>(
                      key: ValueKey(challenge.id),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 200 + (index % 8) * 35),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChallengeCard(
                          challenge: challenge,
                          isLocked: isLocked,
                          starsEarned: starsEarned,
                          onTap: isLocked
                              ? () => _openChallenge(challenge)
                              : AudioService.withSound(
                                  () => _openChallenge(challenge))!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
