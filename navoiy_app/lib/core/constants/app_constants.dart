// lib/core/constants/app_constants.dart
class AppConstants {
  // App info
  static const String appName = "Navoiy Asarlari";
  static const String appVersion = "1.0.0";
  static const String certificateNumber = "DGU 53808";

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String modeKey = 'app_mode'; // offline / online
  static const String apiBaseUrlKey = 'api_base_url';
  static const String sessionExpiryKey = 'session_expiry';

  // Default API
  static const String defaultApiBaseUrl = 'https://api.navoiy.uz/v1';

  // Session
  static const int sessionDurationHours = 24;
  static const int tokenRefreshThresholdMinutes = 30;

  // Pagination
  static const int pageSize = 20;

  // DB
  static const String dbName = 'navoiy.db';
  static const int dbVersion = 2;

  // Sync
  static const String syncVersionsKey = 'sync_versions';
  static const String bundleInitializedKey = 'bundle_initialized';
  static const String lastSyncKey = 'last_sync_time';
  static const String syncBundleVersionKey = 'sync_bundle_version';
  static const String lastSyncKey = 'last_sync_time';
  static const String syncBundleVersionKey = 'sync_bundle_version';

  // Themes
  static const String themeClassic = 'classic';
  static const String themeModern = 'modern';
  static const String themeDark = 'dark';

  // App Modes
  static const String modeOffline = 'offline';
  static const String modeOnline = 'online';
}
