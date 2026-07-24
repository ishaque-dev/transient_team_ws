import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/auth/presentation/pages/auth_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/dashboard_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = serviceLocator<AppConfig>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()..add(AuthCheckStatus()),
        ),
      ],
      child: MaterialApp(
        title: config.appTitle,
        debugShowCheckedModeBanner: config.isDev,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Only rebuild the whole screen when moving between major states.
        if (current is AuthInitial || current is AuthLoading) return false;
        return true;
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const DashboardPage();
        }
        return const AuthPage();
      },
    );
  }
}
