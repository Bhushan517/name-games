import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../shared/widgets/space_background.dart';
import 'widgets/help_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/stat_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storageService});

  final LocalStorageService storageService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _rotateController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  int _totalEarnedStars = 0;
  int _unlockedChallenges = 1;
  int _unlockedWords = 0;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    AudioService().playBgm('menu_music.wav');
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
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        gradient: const LinearGradient(
                          colors: [AppColors.cyan, AppColors.purple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
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
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            AppStrings.appSubtitle,
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Glass Action Buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        onPressed: AudioService.withSound(() => showDialog<void>(
                              context: context,
                              builder: (_) => SettingsDialog(
                                  storageService: widget.storageService),
                            )),
                        icon: const Icon(Icons.settings_rounded, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        onPressed: AudioService.withSound(() => showDialog<void>(
                              context: context,
                              builder: (_) => const HelpDialog(),
                            )),
                        icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                // Main Animated Body
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),

                          // Animated 3D Floating Magic Emblem
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _floatController,
                              _pulseController,
                              _rotateController,
                            ]),
                            builder: (_, child) {
                              final floatY = sin(_floatController.value * pi) * 6;
                              final scale = 0.95 + _pulseController.value * 0.08;
                              final angle = _rotateController.value * 2 * pi;

                              return Transform.translate(
                                offset: Offset(0, floatY),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer Radial Glow Aura
                                      Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppColors.cyan.withValues(alpha: 0.35),
                                              AppColors.purple.withValues(alpha: 0.2),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.cyan.withValues(alpha: 0.3),
                                              blurRadius: 50,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Rotating Magic Ring
                                      Transform.rotate(
                                        angle: angle,
                                        child: Container(
                                          width: 116,
                                          height: 116,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.gold.withValues(alpha: 0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Stack(
                                            children: const [
                                              Positioned(
                                                top: 2,
                                                left: 54,
                                                child: Icon(Icons.star_rounded,
                                                    size: 10, color: AppColors.gold),
                                              ),
                                              Positioned(
                                                bottom: 2,
                                                left: 54,
                                                child: Icon(Icons.star_rounded,
                                                    size: 10, color: AppColors.cyan),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Central Glowing Emblem
                                      Container(
                                        width: 86,
                                        height: 86,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF2A1556),
                                              Color(0xFF0D1429),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: AppColors.gold,
                                            width: 2.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.gold.withValues(alpha: 0.4),
                                              blurRadius: 16,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '✨',
                                            style: TextStyle(fontSize: 42),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // Gradient Hero Title
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.white,
                                AppColors.cyan,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              AppStrings.heroTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Subtitle Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Text(
                              '500 Challenges • 100 Words • 5 Game Modes',
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Glass Live Stats Dashboard
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.09),
                                  Colors.white.withValues(alpha: 0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                StatBadge(
                                  icon: Icons.flag_rounded,
                                  value: '$_unlockedChallenges/500',
                                  label: 'LEVELS',
                                  accentColor: AppColors.cyan,
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white12,
                                ),
                                StatBadge(
                                  icon: Icons.menu_book_rounded,
                                  value: '$_unlockedWords/100',
                                  label: 'WORDS',
                                  accentColor: AppColors.purple,
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white12,
                                ),
                                StatBadge(
                                  icon: Icons.star_rounded,
                                  value: '$_totalEarnedStars',
                                  label: 'STARS',
                                  accentColor: AppColors.gold,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Massive 3D Glowing PLAY NOW Button
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + _pulseController.value * 0.025;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.cyan,
                                    AppColors.purple,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyan.withValues(alpha: 0.45),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: AudioService.withSound(() async {
                                    await Navigator.pushNamed(
                                      context,
                                      RouteNames.levelSelection,
                                    );
                                    if (mounted) {
                                      _refreshStats();
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white24,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        AppStrings.playNow,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Secondary Feature Cards: DAILY QUEST & MY WORDS
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0x1F16223D),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: AudioService.withSound(() async {
                                        await Navigator.pushNamed(
                                          context,
                                          RouteNames.dailyChallenge,
                                        );
                                        if (mounted) {
                                          _refreshStats();
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: AppColors.gold,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'DAILY QUEST',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.gold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0x1F16223D),
                                    border: Border.all(
                                      color: AppColors.purple.withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: AudioService.withSound(() async {
                                        await Navigator.pushNamed(
                                          context,
                                          RouteNames.wordCollection,
                                        );
                                        if (mounted) {
                                          _refreshStats();
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.menu_book_rounded,
                                            color: AppColors.purple,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'MY WORDS',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.purple,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
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
      ),
    );
  }
}
