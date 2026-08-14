import 'package:flutter/material.dart';
import '../../core/services/local_storage_service.dart';
import '../../data/repositories/level_repository.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/level_selection/presentation/level_selection_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter({
    required this.storageService,
    required this.levelRepository,
  });

  final LocalStorageService storageService;
  final LevelRepository levelRepository;

  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(storageService: storageService),
        );

      case RouteNames.onboarding:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              OnboardingScreen(storageService: storageService),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 450),
        );

      case RouteNames.home:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              HomeScreen(storageService: storageService),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        );

      case RouteNames.levelSelection:
        return MaterialPageRoute(
          builder: (_) => LevelSelectionScreen(repository: levelRepository),
        );

      case RouteNames.game:
        final levelIndex = (settings.arguments as int?) ?? 0;
        final level = levelRepository.getLevel(levelIndex);
        return MaterialPageRoute<int>(
          builder: (_) => GameScreen(
            level: level,
            repository: levelRepository,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
