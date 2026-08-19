import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

import '../core/services/audio_service.dart';
import '../core/services/tts_service.dart';

class SpellShapeQuestApp extends StatefulWidget {
  const SpellShapeQuestApp({
    super.key,
    required this.appRouter,
  });

  final AppRouter appRouter;

  @override
  State<SpellShapeQuestApp> createState() => _SpellShapeQuestAppState();
}

class _SpellShapeQuestAppState extends State<SpellShapeQuestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService().disposeAll();
    TtsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AudioService().disposeAll();
      TtsService.dispose();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      TtsService.stop();
      AudioService().onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AudioService().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.darkTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: widget.appRouter.generateRoute,
    );
  }
}
