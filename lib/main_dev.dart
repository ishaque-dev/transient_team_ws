import 'package:flutter/material.dart';
import 'package:transient_team_ws/app.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/di/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const devConfig = AppConfig(
    appTitle: 'Team Workspace (DEV)',
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://dev-api.example.com',
    userCollection: 'users_test',
  );

  await initDependencies(devConfig);

  runApp(const MyApp());
}
