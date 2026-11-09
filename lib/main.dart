import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'app_dependencies.dart';

/// Ponto de entrada do app Flutter (AP2B).
/// A CLI da AP1B continua disponível em `bin/fleet_track_cli.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No Android/iOS o sqflite usa o SQLite nativo; no desktop usamos FFI.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dependencias = await AppDependencies.criarPadrao();
  runApp(FleetTrackApp(dependencies: dependencias));
}
