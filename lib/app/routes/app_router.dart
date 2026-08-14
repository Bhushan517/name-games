import 'package:flutter/material.dart';
import '../../core/services/local_storage_service.dart';
import '../../data/models/generated_challenge.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/level_selection/presentation/level_selection_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/word_collection/presentation/word_collection_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter({
    required this.storageService,
    required this.wordRepository,
    required this.challengeRepository,
  });

  final LocalStorageService storageService;
  final WordRepository wordRepository;
  final ChallengeRepository challengeRepository;

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
          builder: (_) => LevelSelectionScreen(repository: challengeRepository),
        );

      case RouteNames.wordCollection:
        final progress = challengeRepository.getPlayerProgress();
        return MaterialPageRoute(
          builder: (_) => WordCollectionScreen(
            wordRepository: wordRepository,
            progress: progress,
          ),
        );

      case RouteNames.dailyChallenge:
        return MaterialPageRoute(
          builder: (_) => DailyChallengeScreen(
            challengeRepository: challengeRepository,
          ),
        );

      case RouteNames.game:
        final challenge = settings.arguments as GeneratedChallenge;
        return MaterialPageRoute<int>(
          builder: (_) => GameScreen(
            challenge: challenge,
            repository: challengeRepository,
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
