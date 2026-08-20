import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'app/routes/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'data/repositories/challenge_repository.dart';
import 'data/repositories/word_repository.dart';
import 'data/sources/local_word_data_source.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/services/ad_service.dart';
import 'core/services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MobileAds and AdService safely without blocking the app startup
  Future(() async {
    try {
      await MobileAds.instance.initialize();
      await AdService().init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ad initialization failed: $e');
      }
    }
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = await LocalStorageService.init();
  await AudioService().init(storageService);
  final wordDataSource = LocalWordDataSource();
  final wordRepository = WordRepository(wordDataSource);
  final challengeRepository = ChallengeRepository(
    wordRepository: wordRepository,
    storageService: storageService,
  );

  // Pre-cache challenges asynchronously on app start
  challengeRepository.getChallenges();

  final appRouter = AppRouter(
    storageService: storageService,
    wordRepository: wordRepository,
    challengeRepository: challengeRepository,
  );

  runApp(
    SpellShapeQuestApp(
      appRouter: appRouter,
    ),
  );
}
