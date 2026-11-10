import 'package:flutter/material.dart';
import 'package:transient_team_ws/app.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/di/di.dart';

/// Shared start-up for every flavor entry point.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies(config);
  runApp(const CoopiqApp());
}
