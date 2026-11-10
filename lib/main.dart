import 'package:transient_team_ws/bootstrap.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';

Future<void> main() => bootstrap(const AppConfig(appTitle: AppStrings.appName));
