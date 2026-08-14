import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../shared/widgets/space_background.dart';
import 'widgets/help_dialog.dart';
import 'widgets/stat_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storageService});

  final LocalStorageService storageService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  int _totalEarnedStars = 0;
  int _unlockedChallenges = 1;
  int _unlockedWords = 0;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    final progress = widget.storageService.loadPlayerProgress();
    setState(() {
      _totalEarnedStars = progress.totalStars;
      _unlockedChallenges = progress.unlockedChallengeNumber;
      _unlockedWords = progress.unlockedWordCount;
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              // Top Bar
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.cyan),
                    ),
                    child: const Icon(Icons.gesture_rounded,
                        color: AppColors.cyan),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          AppStrings.appSubtitle,
                          style: TextStyle(color: AppColors.cyan, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const HelpDialog(),
                    ),
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),

              // Main Body
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Floating Magic Badge
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, -8 + _floatController.value * 16),
                            child: child,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.purple.withValues(alpha: 0.28),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.cyan.withValues(alpha: 0.2),
                                      blurRadius: 60,
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                '✨',
                                style: TextStyle(fontSize: 92),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          AppStrings.heroTitle,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '500 Challenges • 100 Words • 5 Game Modes',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Live Stats Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatBadge(
                                icon: Icons.flag_rounded,
                                value: '$_unlockedChallenges/500',
                                label: 'LEVELS',
                              ),
                              const SizedBox(width: 18),
                              StatBadge(
                                icon: Icons.menu_book_rounded,
                                value: '$_unlockedWords/100',
                                label: 'WORDS',
                              ),
                              const SizedBox(width: 18),
                              StatBadge(
                                icon: Icons.star_rounded,
                                value: '$_totalEarnedStars',
                                label: 'STARS',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // PLAY NOW Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await Navigator.pushNamed(
                                context,
                                RouteNames.levelSelection,
                              );
                              if (mounted) {
                                _refreshStats();
                              }
                            },
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                            ),
                            label: const Text(
                              AppStrings.playNow,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Secondary Options: Daily Quest & Word Collection
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    RouteNames.dailyChallenge,
                                  );
                                  if (mounted) {
                                    _refreshStats();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.gold,
                                  size: 18,
                                ),
                                label: const Text(
                                  'DAILY QUEST',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    RouteNames.wordCollection,
                                  );
                                  if (mounted) {
                                    _refreshStats();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color:
                                        AppColors.purple.withValues(alpha: 0.5),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  color: AppColors.purple,
                                  size: 18,
                                ),
                                label: const Text(
                                  'MY WORDS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
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
