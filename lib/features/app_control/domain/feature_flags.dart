import 'package:equatable/equatable.dart';

/// One Remote Config parameter: key, in-app default and console description.
class FlagSpec {
  const FlagSpec(this.key, this.defaultValue, this.description);

  final String key;
  final Object defaultValue;
  final String description;
}

/// Everything the owner can switch remotely. The in-app defaults keep the app
/// fully working before the Remote Config template is published.
///
/// Keep in sync with `remoteconfig.template.json`.
abstract final class FlagKeys {
  static const appEnabled = 'app_enabled';
  static const appBlockedTitle = 'app_blocked_title';
  static const appBlockedMessage = 'app_blocked_message';
  static const subscriptionExpiredMessage = 'subscription_expired_message';
  static const contactPhone = 'contact_phone';
  static const contactEmail = 'contact_email';

  static const googleSignIn = 'feature_google_sign_in';
  static const requestAccess = 'feature_request_access';
  static const forgotPassword = 'feature_forgot_password';
  static const createTask = 'feature_create_task';
  static const editTask = 'feature_edit_task';
  static const deleteTask = 'feature_delete_task';
  static const statusUpdate = 'feature_status_update';
  static const taskComments = 'feature_task_comments';
  static const taskRating = 'feature_task_rating';
  static const addMember = 'feature_add_member';
  static const memberManagement = 'feature_member_management';
  static const notifications = 'feature_notifications';
  static const performanceInsights = 'feature_performance_insights';
  static const contactDeveloper = 'feature_contact_developer';
  static const themeSwitch = 'feature_theme_switch';
  static const editName = 'feature_edit_name';
  static const changePassword = 'feature_change_password';

  static const all = <FlagSpec>[
    FlagSpec(
      appEnabled,
      true,
      'Master switch. false shows the "unavailable" screen to everyone.',
    ),
    FlagSpec(
      appBlockedTitle,
      'Coopiq Internal is unavailable',
      'Title on the screen shown when app_enabled is false.',
    ),
    FlagSpec(
      appBlockedMessage,
      'The app is turned off for now. Contact us to get it back on.',
      'Message shown when app_enabled is false.',
    ),
    FlagSpec(
      subscriptionExpiredMessage,
      'Your subscription has ended. Contact us to renew and keep your team going.',
      'Message shown when the subscription is expired or suspended.',
    ),
    FlagSpec(
      contactPhone,
      '+919747344535',
      'Phone number for Call and WhatsApp buttons (with country code).',
    ),
    FlagSpec(
      contactEmail,
      'ishaque.kannoth.dev@gmail.com',
      'Email for the Email button.',
    ),
    FlagSpec(
      googleSignIn,
      true,
      'Show "Continue with Google" on the sign-in screen.',
    ),
    FlagSpec(
      requestAccess,
      true,
      'Allow new people to request access (self sign-up).',
    ),
    FlagSpec(
      forgotPassword,
      true,
      'Show "Forgot password?" on the sign-in screen.',
    ),
    FlagSpec(createTask, true, 'Admins can create new tasks.'),
    FlagSpec(editTask, true, 'Admins can edit tasks.'),
    FlagSpec(deleteTask, true, 'Admins can delete tasks.'),
    FlagSpec(statusUpdate, true, 'Status changes and one-tap complete.'),
    FlagSpec(taskComments, true, 'Comment box on task details.'),
    FlagSpec(taskRating, true, 'Admins can rate completed work.'),
    FlagSpec(addMember, true, 'Admins can add employees directly.'),
    FlagSpec(
      memberManagement,
      true,
      'Admins can approve and deactivate employees.',
    ),
    FlagSpec(notifications, true, 'Notification bell and phone notifications.'),
    FlagSpec(
      performanceInsights,
      true,
      'Performance scores, charts and leaderboard.',
    ),
    FlagSpec(contactDeveloper, true, 'Contact developer row on Profile.'),
    FlagSpec(themeSwitch, true, 'Theme picker on Profile.'),
    FlagSpec(editName, true, 'Users can edit their display name.'),
    FlagSpec(changePassword, true, 'Change password (reset email) on Profile.'),
  ];

  static Map<String, dynamic> get defaults => {
    for (final spec in all) spec.key: spec.defaultValue,
  };
}

class FeatureFlags extends Equatable {
  const FeatureFlags({
    required this.appEnabled,
    required this.appBlockedTitle,
    required this.appBlockedMessage,
    required this.subscriptionExpiredMessage,
    required this.contactPhone,
    required this.contactEmail,
    required this.googleSignIn,
    required this.requestAccess,
    required this.forgotPassword,
    required this.createTask,
    required this.editTask,
    required this.deleteTask,
    required this.statusUpdate,
    required this.taskComments,
    required this.taskRating,
    required this.addMember,
    required this.memberManagement,
    required this.notifications,
    required this.performanceInsights,
    required this.contactDeveloper,
    required this.themeSwitch,
    required this.editName,
    required this.changePassword,
  });

  factory FeatureFlags.read({
    required bool Function(String key) getBool,
    required String Function(String key) getString,
  }) {
    String text(String key) {
      final value = getString(key).trim();
      return value.isEmpty ? FlagKeys.defaults[key] as String : value;
    }

    return FeatureFlags(
      appEnabled: getBool(FlagKeys.appEnabled),
      appBlockedTitle: text(FlagKeys.appBlockedTitle),
      appBlockedMessage: text(FlagKeys.appBlockedMessage),
      subscriptionExpiredMessage: text(FlagKeys.subscriptionExpiredMessage),
      contactPhone: text(FlagKeys.contactPhone),
      contactEmail: text(FlagKeys.contactEmail),
      googleSignIn: getBool(FlagKeys.googleSignIn),
      requestAccess: getBool(FlagKeys.requestAccess),
      forgotPassword: getBool(FlagKeys.forgotPassword),
      createTask: getBool(FlagKeys.createTask),
      editTask: getBool(FlagKeys.editTask),
      deleteTask: getBool(FlagKeys.deleteTask),
      statusUpdate: getBool(FlagKeys.statusUpdate),
      taskComments: getBool(FlagKeys.taskComments),
      taskRating: getBool(FlagKeys.taskRating),
      addMember: getBool(FlagKeys.addMember),
      memberManagement: getBool(FlagKeys.memberManagement),
      notifications: getBool(FlagKeys.notifications),
      performanceInsights: getBool(FlagKeys.performanceInsights),
      contactDeveloper: getBool(FlagKeys.contactDeveloper),
      themeSwitch: getBool(FlagKeys.themeSwitch),
      editName: getBool(FlagKeys.editName),
      changePassword: getBool(FlagKeys.changePassword),
    );
  }

  /// The in-app defaults, used until Remote Config answers.
  factory FeatureFlags.defaults() {
    final values = FlagKeys.defaults;
    return FeatureFlags.read(
      getBool: (key) => values[key] as bool,
      getString: (key) => values[key] as String,
    );
  }

  final bool appEnabled;
  final String appBlockedTitle;
  final String appBlockedMessage;
  final String subscriptionExpiredMessage;
  final String contactPhone;
  final String contactEmail;
  final bool googleSignIn;
  final bool requestAccess;
  final bool forgotPassword;
  final bool createTask;
  final bool editTask;
  final bool deleteTask;
  final bool statusUpdate;
  final bool taskComments;
  final bool taskRating;
  final bool addMember;
  final bool memberManagement;
  final bool notifications;
  final bool performanceInsights;
  final bool contactDeveloper;
  final bool themeSwitch;
  final bool editName;
  final bool changePassword;

  @override
  List<Object?> get props => [
    appEnabled,
    appBlockedTitle,
    appBlockedMessage,
    subscriptionExpiredMessage,
    contactPhone,
    contactEmail,
    googleSignIn,
    requestAccess,
    forgotPassword,
    createTask,
    editTask,
    deleteTask,
    statusUpdate,
    taskComments,
    taskRating,
    addMember,
    memberManagement,
    notifications,
    performanceInsights,
    contactDeveloper,
    themeSwitch,
    editName,
    changePassword,
  ];
}
