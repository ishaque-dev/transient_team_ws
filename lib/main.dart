import 'package:flutter/material.dart';
import 'package:transient_team_ws/app.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/di/di.dart';

/// Default entry point (falls back to production config)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const defaultConfig = AppConfig(
    appTitle: 'Team Workspace',
    environment: AppEnvironment.prod,
    apiBaseUrl: 'https://api.example.com',
    userCollection: 'users',
  );

  await initDependencies(defaultConfig);

  runApp(const MyApp());
}
