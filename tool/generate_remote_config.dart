// Regenerates remoteconfig.template.json from the in-app flag list:
//   dart run tool/generate_remote_config.dart
import 'dart:convert';
import 'dart:io';

import 'package:transient_team_ws/features/app_control/domain/feature_flags.dart';

const _groups = <String, List<String>>{
  'App access': [
    FlagKeys.appEnabled,
    FlagKeys.appBlockedTitle,
    FlagKeys.appBlockedMessage,
    FlagKeys.subscriptionExpiredMessage,
  ],
  'Contact details': [FlagKeys.contactPhone, FlagKeys.contactEmail],
  'Sign-in screen': [
    FlagKeys.googleSignIn,
    FlagKeys.requestAccess,
    FlagKeys.forgotPassword,
  ],
  'Tasks': [
    FlagKeys.createTask,
    FlagKeys.editTask,
    FlagKeys.deleteTask,
    FlagKeys.statusUpdate,
    FlagKeys.taskComments,
    FlagKeys.taskRating,
  ],
  'Team': [FlagKeys.addMember, FlagKeys.memberManagement],
  'Insights & notifications': [
    FlagKeys.notifications,
    FlagKeys.performanceInsights,
  ],
  'Profile': [
    FlagKeys.contactDeveloper,
    FlagKeys.themeSwitch,
    FlagKeys.editName,
    FlagKeys.changePassword,
  ],
};

void main() {
  final specs = {for (final spec in FlagKeys.all) spec.key: spec};
  final grouped = _groups.values.expand((keys) => keys).toSet();
  final missing = specs.keys.where((key) => !grouped.contains(key)).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Add these keys to a group: $missing');
    exit(1);
  }

  Map<String, Object> parameter(FlagSpec spec) => {
    'defaultValue': {'value': spec.defaultValue.toString()},
    'description': spec.description,
    'valueType': spec.defaultValue is bool ? 'BOOLEAN' : 'STRING',
  };

  final template = {
    'parameterGroups': {
      for (final entry in _groups.entries)
        entry.key: {
          'parameters': {
            for (final key in entry.value) key: parameter(specs[key]!),
          },
        },
    },
  };
  File('remoteconfig.template.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(template)}\n',
  );
  stdout.writeln('Wrote remoteconfig.template.json (${specs.length} parameters).');
}
