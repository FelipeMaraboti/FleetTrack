import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'routes/app_routes.dart';

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
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        initialRoute: rotaInicial,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
