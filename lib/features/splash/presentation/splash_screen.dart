import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../shared/widgets/space_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.storageService});

  final LocalStorageService storageService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _enterController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  void _handleNavigation() {
    final isFirst = widget.storageService.isFirstLaunch();
    final delayMs = isFirst ? 2700 : 1400;

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      final targetRoute = isFirst ? RouteNames.onboarding : RouteNames.home;
      Navigator.pushReplacementNamed(context, targetRoute);
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: FadeTransition(
              opacity: _enterController,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _enterController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _spinController,
                      child: Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              AppColors.cyan,
                              AppColors.purple,
                              AppColors.pink,
                              AppColors.cyan,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.35),
                              blurRadius: 45,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.background,
                          ),
                          child: const Icon(
                            Icons.gesture_rounded,
                            color: AppColors.cyan,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'SPELL & SHAPE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Text(
                      'Q U E S T',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 130,
                      child: LinearProgressIndicator(
                        color: AppColors.cyan,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
