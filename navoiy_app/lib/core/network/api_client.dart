// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/settings_service.dart';
import 'auth_service.dart';

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();
  ApiClient._() {
    _init();
  }

  late final Dio _dio;
  Dio get dio => _dio;

  void _init() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LogInterceptor());
  }

  String get baseUrl => SettingsService.instance.apiBaseUrl;
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthService.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Check if token needs refresh before request
    if (!_isRefreshing && await AuthService.instance.isNearExpiry()) {
      _isRefreshing = true;
      final baseUrl = SettingsService.instance.apiBaseUrl;
      await AuthService.instance.refreshToken(
        Dio(),
        baseUrl,
      );
      _isRefreshing = false;

      // Re-read token after refresh
      final newToken = await AuthService.instance.getAccessToken();
      if (newToken != null) {
        options.headers['Authorization'] = 'Bearer $newToken';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired — try refresh
      final baseUrl = SettingsService.instance.apiBaseUrl;
      final refreshed =
          await AuthService.instance.refreshToken(Dio(), baseUrl);
      if (refreshed) {
        final newToken = await AuthService.instance.getAccessToken();
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await Dio().fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        }
      }
      // Refresh failed — clear session
      await AuthService.instance.clearSession();
    }
    handler.next(err);
  }
}

// ─── Log Interceptor ──────────────────────────────────────────────────────────

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API ERROR] ${err.message}');
    handler.next(err);
  }
}

// ─── API Result Wrapper ───────────────────────────────────────────────────────

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResult.success(this.data)
      : error = null,
        isSuccess = true;
  const ApiResult.failure(this.error)
      : data = null,
        isSuccess = false;
}
