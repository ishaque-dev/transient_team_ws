class AppConfig {
  const AppConfig({required this.appTitle});

  final String appTitle;

  /// Firestore root for all app data: `environments/prod/...`.
  String get dataNamespace => 'prod';
}
