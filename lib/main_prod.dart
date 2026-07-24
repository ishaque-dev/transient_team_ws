import 'package:flutter/material.dart';
import 'package:transient_team_ws/app.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/di/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const prodConfig = AppConfig(
    appTitle: 'Team Workspace',
    environment: AppEnvironment.prod,
    apiBaseUrl: 'https://api.example.com',
    userCollection: 'users',
  );

  await initDependencies(prodConfig);

  runApp(const MyApp());
}
