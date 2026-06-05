// lib/core/utils/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  SettingsService._();

  String _themeName = AppConstants.themeClassic;
  String _appMode = AppConstants.modeOffline;
  String _apiBaseUrl = AppConstants.defaultApiBaseUrl;
  bool _initialized = false;

  String get themeName => _themeName;
  String get appMode => _appMode;
  String get apiBaseUrl => _apiBaseUrl;
  bool get isOfflineMode => _appMode == AppConstants.modeOffline;
  bool get initialized => _initialized;

  ThemeData get currentTheme => AppTheme.fromString(_themeName);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _themeName = prefs.getString(AppConstants.themeKey) ?? AppConstants.themeClassic;
    _appMode = prefs.getString(AppConstants.modeKey) ?? AppConstants.modeOffline;
    _apiBaseUrl = prefs.getString(AppConstants.apiBaseUrlKey) ?? AppConstants.defaultApiBaseUrl;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    _themeName = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeKey, themeName);
    notifyListeners();
  }

  Future<void> setAppMode(String mode) async {
    _appMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.modeKey, mode);
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String url) async {
    _apiBaseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiBaseUrlKey, _apiBaseUrl);
    notifyListeners();
  }
}
