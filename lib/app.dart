import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class FleetTrackApp extends StatelessWidget {
  final AppDependencies dependencies;
  final String rotaInicial;

  const FleetTrackApp({
    super.key,
    required this.dependencies,
    this.rotaInicial = AppRoutes.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'FleetTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        darkTheme: AppTheme.escuro,
        initialRoute: rotaInicial,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
