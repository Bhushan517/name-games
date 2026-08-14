import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/game_progress.dart';
import '../../../data/models/word_level.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../shared/widgets/space_background.dart';
import 'widgets/level_card.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key, required this.repository});

  final LevelRepository repository;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late List<WordLevel> _levels;
  late GameProgress _progress;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  void _loadLevels() {
    _levels = widget.repository.getLevels();
    _progress = widget.repository.getProgress();
  }

  Future<void> _openLevel(int index) async {
    if (!_progress.isLevelUnlocked(index)) return;

    final earnedStars = await Navigator.pushNamed<int>(
      context,
      RouteNames.game,
      arguments: index,
    );

    if (earnedStars != null && mounted) {
      setState(() {
        _loadLevels();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                itemCount: _levels.length,
                itemBuilder: (_, index) {
                  final level = _levels[index];
                  final isLocked = !_progress.isLevelUnlocked(index);
                  final starsEarned = _progress.starsForLevel(index);

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + index * 80),
                    curve: Curves.easeOutBack,
                    builder: (_, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index.isOdd ? 28 : 0,
                        right: index.isEven ? 28 : 0,
                        bottom: 14,
                      ),
                      child: LevelCard(
                        level: level,
                        isLocked: isLocked,
                        starsEarned: starsEarned,
                        onTap: () => _openLevel(index),
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
