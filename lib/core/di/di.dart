import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/core/notifications/local_notifier.dart';
import 'package:transient_team_ws/core/notifications/notification_alert_tracker.dart';
import 'package:transient_team_ws/core/theme/theme_cubit.dart';
import 'package:transient_team_ws/features/app_control/data/app_control_remote_ds.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/google_credential_source.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_local_ds_impl.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_remote_ds_impl.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_repo_impl.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/auth_use_cases.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/notifications/data/data_sources/i_notification_remote_ds.dart';
import 'package:transient_team_ws/features/notifications/data/impl/notification_remote_ds_impl.dart';
import 'package:transient_team_ws/features/notifications/data/impl/notification_repo_impl.dart';
import 'package:transient_team_ws/features/notifications/domain/repository/i_notification_repo.dart';
import 'package:transient_team_ws/features/notifications/domain/use_cases/watch_notifications_use_case.dart';
import 'package:transient_team_ws/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:transient_team_ws/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_remote_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_repo_impl.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_use_cases.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_activity_cubit.dart';
import 'package:transient_team_ws/features/team/data/data_sources/account_provisioner.dart';
import 'package:transient_team_ws/features/team/data/data_sources/i_team_remote_ds.dart';
import 'package:transient_team_ws/features/team/data/impl/team_remote_ds_impl.dart';
import 'package:transient_team_ws/features/team/data/impl/team_repo_impl.dart';
import 'package:transient_team_ws/features/team/domain/repository/i_team_repo.dart';
import 'package:transient_team_ws/features/team/domain/use_cases/team_use_cases.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

import '../../firebase_options.dart';

final GetIt serviceLocator = GetIt.instance;

/// Web OAuth client ID for `coopiq-internal` (client_type 3 in
/// `google-services.json`). Android needs it to request an ID token that
/// Firebase Auth accepts.
const String _googleServerClientId =
    '301122535476-rod9hki9u39sjfto1lf1ni45e7omcp4g.apps.googleusercontent.com';

Future<void> initDependencies(AppConfig config) async {
  serviceLocator.registerLazySingleton(() => config);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator
    ..registerLazySingleton(() => sharedPreferences)
    ..registerLazySingleton(() => FirebaseAuth.instance)
    ..registerLazySingleton(() => FirebaseFirestore.instance)
    ..registerLazySingleton(
      () => FirestoreCollections(serviceLocator(), config.dataNamespace),
    )
    ..registerLazySingleton(() => ThemeCubit(serviceLocator()));

  // Remote Config switches + subscription, loaded before the first frame so
  // the app opens straight onto the right screen.
  final appControl = AppControlRemoteDs(
    FirebaseRemoteConfig.instance,
    serviceLocator(),
  );
  await appControl.initialize();
  serviceLocator
    ..registerLazySingleton(() => appControl)
    ..registerLazySingleton(() => AppControlCubit(appControl)..start());

  serviceLocator.registerLazySingleton(
    () => NotificationAlertTracker(SharedPreferencesAsync()),
  );
  final notifier = LocalNotifier(FlutterLocalNotificationsPlugin());
  await notifier.initialize();
  serviceLocator.registerLazySingleton<ILocalNotifier>(() => notifier);

  _initAuth();
  _initTasks();
  _initTeam();
  _initNotifications();
}

void _initAuth() {
  final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  serviceLocator
    ..registerLazySingleton<IGoogleCredentialSource>(
      () => GoogleCredentialSource(
        GoogleSignIn.instance,
        clientId: isIos ? DefaultFirebaseOptions.ios.iosClientId : null,
        serverClientId: isIos ? null : _googleServerClientId,
      ),
    )
    ..registerLazySingleton<IAuthRemoteDs>(
      () => AuthRemoteDsImpl(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerLazySingleton<IAuthLocalDs>(
      () => AuthLocalDsImpl(serviceLocator()),
    )
    ..registerLazySingleton<IAuthRepo>(
      () => AuthRepoImpl(
        remoteDataSource: serviceLocator(),
        localDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => LoginUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => SignUpUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => GoogleSignInUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => LogoutUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => GetLoggedInUserUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => WatchUserProfileUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => SendPasswordResetUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => UpdateDisplayNameUseCase(authRepository: serviceLocator()),
    )
    ..registerLazySingleton(
      () => MarkNotificationsSeenUseCase(authRepository: serviceLocator()),
    )
    ..registerFactory(
      () => AuthBloc(
        loginUseCase: serviceLocator(),
        signUpUseCase: serviceLocator(),
        googleSignInUseCase: serviceLocator(),
        logoutUseCase: serviceLocator(),
        getLoggedInUserUseCase: serviceLocator(),
        watchUserProfileUseCase: serviceLocator(),
        sendPasswordResetUseCase: serviceLocator(),
      ),
    )
    ..registerFactoryParam<ProfileCubit, UserEntity, void>(
      (user, _) => ProfileCubit(
        user: user,
        updateName: serviceLocator(),
        sendPasswordReset: serviceLocator(),
      ),
    );
}

void _initTasks() {
  serviceLocator
    ..registerLazySingleton<ITaskRemoteDs>(
      () => TaskRemoteDsImpl(serviceLocator()),
    )
    ..registerLazySingleton<ITaskRepo>(
      () => TaskRepoImpl(remoteDs: serviceLocator()),
    )
    ..registerLazySingleton(() => WatchTasksUseCase(serviceLocator()))
    ..registerLazySingleton(() => WatchTaskActivityUseCase(serviceLocator()))
    ..registerLazySingleton(() => CreateTaskUseCase(serviceLocator()))
    ..registerLazySingleton(() => UpdateTaskUseCase(serviceLocator()))
    ..registerLazySingleton(() => ChangeTaskStatusUseCase(serviceLocator()))
    ..registerLazySingleton(() => RateTaskUseCase(serviceLocator()))
    ..registerLazySingleton(() => AddTaskCommentUseCase(serviceLocator()))
    ..registerLazySingleton(() => DeleteTaskUseCase(serviceLocator()))
    ..registerFactoryParam<TaskListBloc, TaskScope, void>(
      (scope, _) => TaskListBloc(watchTasks: serviceLocator(), scope: scope),
    )
    ..registerFactoryParam<TaskActionsCubit, UserEntity, void>(
      (actor, _) => TaskActionsCubit(
        actor: actor,
        createTask: serviceLocator(),
        updateTask: serviceLocator(),
        changeStatus: serviceLocator(),
        rateTask: serviceLocator(),
        addComment: serviceLocator(),
        deleteTask: serviceLocator(),
      ),
    )
    ..registerFactory(() => TaskActivityCubit(serviceLocator()));
}

void _initTeam() {
  serviceLocator
    ..registerLazySingleton<IAccountProvisioner>(
      () => FirebaseAccountProvisioner(DefaultFirebaseOptions.currentPlatform),
    )
    ..registerLazySingleton<ITeamRemoteDs>(
      () => TeamRemoteDsImpl(serviceLocator(), serviceLocator()),
    )
    ..registerLazySingleton<ITeamRepo>(
      () => TeamRepoImpl(remoteDs: serviceLocator()),
    )
    ..registerLazySingleton(() => WatchTeamMembersUseCase(serviceLocator()))
    ..registerLazySingleton(() => AddTeamMemberUseCase(serviceLocator()))
    ..registerLazySingleton(() => UpdateMemberRoleUseCase(serviceLocator()))
    ..registerLazySingleton(() => SetMemberActiveUseCase(serviceLocator()))
    ..registerFactoryParam<TeamCubit, UserEntity, void>(
      (actor, _) => TeamCubit(
        actor: actor,
        watchMembers: serviceLocator(),
        addMember: serviceLocator(),
        updateRole: serviceLocator(),
        setActive: serviceLocator(),
        sendPasswordReset: serviceLocator(),
      ),
    );
}

void _initNotifications() {
  serviceLocator
    ..registerLazySingleton<INotificationRemoteDs>(
      () => NotificationRemoteDsImpl(serviceLocator()),
    )
    ..registerLazySingleton<INotificationRepo>(
      () => NotificationRepoImpl(remoteDs: serviceLocator()),
    )
    ..registerLazySingleton(() => WatchNotificationsUseCase(serviceLocator()))
    ..registerFactoryParam<NotificationsCubit, UserEntity, void>(
      (user, _) => NotificationsCubit(
        watchNotifications: serviceLocator(),
        markNotificationsSeen: serviceLocator(),
        localNotifier: serviceLocator(),
        user: user,
        tracker: serviceLocator(),
        alertsEnabled: () =>
            serviceLocator<AppControlCubit>().state.flags.notifications,
      ),
    );
}
