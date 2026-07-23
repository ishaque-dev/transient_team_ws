import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/core/database/db.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_local_ds_impl.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_remote_ds_impl.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_repo_impl.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/get_logged_in_user_use_case.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/login_use_case.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_local_ds.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_local_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_remote_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_repo_impl.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/create_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/get_task_by_id_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/get_tasks_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_bloc.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton(() => sharedPreferences);
  serviceLocator.registerLazySingleton(() => DatabaseHelper());
  serviceLocator.registerLazySingleton(() => FirebaseAuth.instance);
  serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);

  // Auth Feature
  _initAuth();

  // Tasks Feature
  _initTasks();
}

void _initAuth() {
  // Data Sources
  serviceLocator.registerLazySingleton<IAuthRemoteDs>(
    () => AuthRemoteDsImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<IAuthLocalDs>(
    () => AuthLocalDsImpl(serviceLocator()),
  );

  // Repository
  serviceLocator.registerLazySingleton<IAuthRepo>(
    () => AuthRepoImpl(
      remoteDataSource: serviceLocator(),
      localDataSource: serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerLazySingleton(() => LoginUseCase(authRepository: serviceLocator()));
  serviceLocator.registerLazySingleton(() => SignUpUseCase(authRepository: serviceLocator()));
  serviceLocator.registerLazySingleton(() => LogoutUseCase(authRepository: serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetLoggedInUserUseCase(authRepository: serviceLocator()));

  // Bloc
  serviceLocator.registerFactory(
    () => AuthBloc(
      loginUseCase: serviceLocator(),
      signUpUseCase: serviceLocator(),
      logoutUseCase: serviceLocator(),
      getLoggedInUserUseCase: serviceLocator(),
    ),
  );
}

void _initTasks() {
  // Data Sources
  serviceLocator.registerLazySingleton<ITaskRemoteDs>(
    () => TaskRemoteDsImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ITaskLocalDs>(
    () => TaskLocalDsImpl(serviceLocator()),
  );

  // Repository
  serviceLocator.registerLazySingleton<ITaskRepo>(
    () => TaskRepoImpl(
      remoteDs: serviceLocator(),
      localDs: serviceLocator(),
      authLocalDs: serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerLazySingleton(() => GetTasksUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => CreateTaskUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => UpdateTaskUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteTaskUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetTaskByIdUseCase(serviceLocator()));

  // Bloc
  serviceLocator.registerFactory(
    () => TaskBloc(
      getTasksUseCase: serviceLocator(),
      createTaskUseCase: serviceLocator(),
      updateTaskUseCase: serviceLocator(),
      deleteTaskUseCase: serviceLocator(),
    ),
  );
}
