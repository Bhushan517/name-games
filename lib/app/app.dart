import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

import '../core/services/audio_service.dart';

class SpellShapeQuestApp extends StatefulWidget {
  const SpellShapeQuestApp({
    super.key,
    required this.appRouter,
  });

  final AppRouter appRouter;

  @override
  State<SpellShapeQuestApp> createState() => _SpellShapeQuestAppState();
}

class _SpellShapeQuestAppState extends State<SpellShapeQuestApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
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
