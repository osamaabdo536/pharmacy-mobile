import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for storing
/// auth tokens and simple app prefs.
///
/// Must call [TokenStorage.init] once at app startup (in main.dart)
/// before using any other method — this lets us read tokens
/// synchronously (e.g. inside GoRouter's redirect).
class TokenStorage {
  TokenStorage._();

  static late SharedPreferences _prefs;

  static SharedPreferences get prefs => _prefs;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  /// Call this once in main.dart before runApp().
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Access Token ───────────────────────────────────
  static String? getAccessToken() => _prefs.getString(_keyAccessToken);

  static Future<void> setAccessToken(String token) =>
      _prefs.setString(_keyAccessToken, token);

  // ─── Refresh Token ──────────────────────────────────
  static String? getRefreshToken() => _prefs.getString(_keyRefreshToken);

  static Future<void> setRefreshToken(String token) =>
      _prefs.setString(_keyRefreshToken, token);

  // ─── Helpers ────────────────────────────────────────

  /// Used by GoRouter's redirect to decide login vs home.
  static bool hasToken() => getAccessToken() != null;

  /// Save both tokens at once (after login).
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
  }

  /// Called on logout or when role check fails.
  static Future<void> clearTokens() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
  }
}

/// Tracks whether the user has completed the first-launch onboarding flow.
class OnboardingStorage {
  OnboardingStorage._();

  static const _keyOnboardingCompleted = 'onboarding_completed';

  static bool hasCompletedOnboarding() =>
      TokenStorage.prefs.getBool(_keyOnboardingCompleted) ?? false;

  static Future<void> setOnboardingCompleted() =>
      TokenStorage.prefs.setBool(_keyOnboardingCompleted, true);
}