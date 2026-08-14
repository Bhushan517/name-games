import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'app/routes/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'data/repositories/level_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = await LocalStorageService.init();
  final levelRepository = LevelRepository(storageService);
  final appRouter = AppRouter(
    storageService: storageService,
    levelRepository: levelRepository,
  );

  runApp(
    SpellShapeQuestApp(
      appRouter: appRouter,
    ),
  );
}
