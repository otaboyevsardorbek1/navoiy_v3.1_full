// lib/data/datasources/remote/navoiy_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/settings_service.dart';
import '../../../core/constants/app_constants.dart';

class NavoiyRemoteDataSource {
  final Dio _dio;
  String get _base => SettingsService.instance.apiBaseUrl;

  NavoiyRemoteDataSource() : _dio = ApiClient.instance.dio;

  // ─── Asarlar ──────────────────────────────────────────────────────────────

  Future<ApiResult<List<AsarModel>>> getAsarlar({
    String? category,
    String? search,
    int page = 1,
    int limit = AppConstants.pageSize,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      };
      final res = await _dio.get('$_base/asarlar', queryParameters: params);
      final list = (res.data['items'] as List? ?? res.data as List? ?? [])
          .map((e) => AsarModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  Future<ApiResult<AsarModel>> getAsarById(int id) async {
    try {
      final res = await _dio.get('$_base/asarlar/$id');
      return ApiResult.success(AsarModel.fromJson(res.data));
    } on DioException catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  // ─── Sherlar ──────────────────────────────────────────────────────────────

  Future<ApiResult<List<SherModel>>> getSherlar({
    String? type,
    String? search,
    int? asarId,
    int page = 1,
    int limit = AppConstants.pageSize,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (search != null) 'search': search,
        if (asarId != null) 'asar_id': asarId,
      };
      final res = await _dio.get('$_base/sherlar', queryParameters: params);
      final list = (res.data['items'] as List? ?? res.data as List? ?? [])
          .map((e) => SherModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  // ─── Favorites ────────────────────────────────────────────────────────────

  Future<ApiResult<bool>> toggleFavorite({
    required String type,
    required int id,
    required bool isFavorite,
  }) async {
    try {
      if (isFavorite) {
        await _dio.post('$_base/favorites', data: {'type': type, 'id': id});
      } else {
        await _dio.delete('$_base/favorites/$type/$id');
      }
      return const ApiResult.success(true);
    } on DioException catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['detail'] ?? d['message'] ?? 'Server xatosi';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Ulanish muddati tugadi';
      case DioExceptionType.connectionError:
        return 'Internet yo\'q';
      default:
        return e.message ?? 'Noma\'lum xato';
    }
  }
}
