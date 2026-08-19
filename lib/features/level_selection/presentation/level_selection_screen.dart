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

    return Scaffold(
      body: SpaceBackground(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        AudioService.withSound(() => Navigator.pop(context)),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.yourJourney,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppStrings.chooseLevel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.map_rounded, color: AppColors.gold),
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

            const SizedBox(height: 8),

            // Challenges List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                    duration: Duration(milliseconds: 250 + (index % 10) * 40),
                    curve: Curves.easeOutBack,
                    builder: (_, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index.isOdd ? 28 : 0,
                        right: index.isEven ? 28 : 0,
                        bottom: 14,
                      ),
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
    );
  }
}
