// lib/core/network/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../data/models/models.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Token Management ─────────────────────────────────────────────────────

  Future<void> saveSession(AuthResponse auth) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: auth.accessToken);
    if (auth.refreshToken != null) {
      await _secureStorage.write(key: AppConstants.refreshTokenKey, value: auth.refreshToken!);
    }

    final expiryTime = DateTime.now()
        .add(Duration(seconds: auth.expiresIn))
        .toIso8601String();
    await _secureStorage.write(key: AppConstants.sessionExpiryKey, value: expiryTime);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(auth.user.toJson()));
  }

  Future<String?> getAccessToken() async {
    if (await isSessionExpired()) return null;
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<bool> isSessionExpired() async {
    final expiryStr = await _secureStorage.read(key: AppConstants.sessionExpiryKey);
    if (expiryStr == null) return true;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  Future<bool> isNearExpiry() async {
    final expiryStr = await _secureStorage.read(key: AppConstants.sessionExpiryKey);
    if (expiryStr == null) return true;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return true;
    final threshold = DateTime.now().add(
      const Duration(minutes: AppConstants.tokenRefreshThresholdMinutes),
    );
    return threshold.isAfter(expiry);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token == null) return false;
    return !(await isSessionExpired());
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStoredUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.sessionExpiryKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }

  // ─── Offline Login ────────────────────────────────────────────────────────
  // For demo/offline mode: hardcoded credentials

  Future<AuthResponse?> loginOffline(String username, String password) async {
    // Offline mode: check against local stored credentials
    // Default demo credentials: admin/admin123
    final isValid = (username == 'admin' && password == 'admin123') ||
        (username == 'user' && password == 'user123');

    if (!isValid) return null;

    final user = UserModel(
      id: 1,
      username: username,
      email: '$username@navoiy.uz',
      fullName: username == 'admin' ? 'Administrator' : 'Foydalanuvchi',
      role: username == 'admin' ? 'admin' : 'user',
    );

    // Create a fake session that lasts 24 hours
    final fakeAuth = AuthResponse(
      accessToken: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: null,
      expiresIn: 86400,
      user: user,
    );

    await saveSession(fakeAuth);
    return fakeAuth;
  }

  // ─── Online Login ─────────────────────────────────────────────────────────

  Future<AuthResponse?> loginOnline(
    Dio dio,
    String baseUrl,
    LoginRequest request,
  ) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/login',
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);
        await saveSession(auth);
        return auth;
      }
      return null;
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<bool> refreshToken(Dio dio, String baseUrl) async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await dio.post(
        '$baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);
        await saveSession(auth);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['detail'] ?? data['message'] ?? 'Xatolik yuz berdi';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Aloqa muddati tugadi';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Internet aloqasi yo\'q';
    }
    return e.message ?? 'Xatolik yuz berdi';
  }
}
