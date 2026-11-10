import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/core/router/app_router.dart';
import 'package:transient_team_ws/core/theme/app_theme.dart';
import 'package:transient_team_ws/core/theme/theme_cubit.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';

/// iOS-style bounce on every scrollable, on every platform.
class _BouncingScrollBehavior extends MaterialScrollBehavior {
  const _BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class CoopiqApp extends StatefulWidget {
  const CoopiqApp({super.key});

  @override
  State<CoopiqApp> createState() => _CoopiqAppState();
}

class _CoopiqAppState extends State<CoopiqApp> {
  late final AuthBloc _auth = serviceLocator<AuthBloc>()
    ..add(AuthCheckStatus());
  late final AppControlCubit _control = serviceLocator<AppControlCubit>();
  late final GoRouter _router = createAppRouter(auth: _auth, control: _control);

  @override
  void dispose() {
    _router.dispose();
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = serviceLocator<AppConfig>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _auth),
        BlocProvider.value(value: _control),
        BlocProvider.value(value: serviceLocator<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: config.appTitle,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const _BouncingScrollBehavior(),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
