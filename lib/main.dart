import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/auth/presentation/pages/auth_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()..add(AuthCheckStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'Team Workspace',
        debugShowCheckedModeBanner: false,
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
        // We don't want to rebuild AuthWrapper just because AuthBloc is in 'Loading' 
        // because the AuthPage handles its own internal loading state (button loader).
        if (current is AuthInitial || current is AuthLoading) return false;
        return true;
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const DashboardPage();
        }
        // For Initial, Loading (initially), Unauthenticated, or Failure, show AuthPage.
        return const AuthPage();
      },
    );
  }
}
