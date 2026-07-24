enum AppEnvironment { dev, prod }

class AppConfig {
  final String appTitle;
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String userCollection;

  const AppConfig({
    required this.appTitle,
    required this.environment,
    required this.apiBaseUrl,
    required this.userCollection,
  });

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProd => environment == AppEnvironment.prod;
}
