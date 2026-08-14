import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

class SpellShapeQuestApp extends StatelessWidget {
  const SpellShapeQuestApp({
    super.key,
    required this.appRouter,
  });

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.darkTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: appRouter.generateRoute,
    );
  }
}
