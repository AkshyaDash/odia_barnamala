/// Global app configuration for development and production modes.
class AppConfig {
  /// Set to true to enable development mode with mocked services.
  /// In development mode, RevenueCat purchases are mocked and all languages
  /// can be purchased/unlocked without a real API key.
  static const bool isDevelopment = true;

  /// RevenueCat API Keys (must be replaced with real keys for production)
  static const String androidApiKey = 'REVENUECAT_ANDROID_API_KEY';
  static const String iosApiKey = 'REVENUECAT_IOS_API_KEY';

  /// Development mode: all paid languages unlock instantly for testing.
  /// Production mode: requires real RevenueCat API and valid purchases.
  static bool get useMockPurchases => isDevelopment;
}
