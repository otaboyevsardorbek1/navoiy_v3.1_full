// lib/data/repositories/navoiy_repository.dart
import '../datasources/local/database_helper.dart';
import '../datasources/remote/navoiy_remote_datasource.dart';
import '../models/models.dart';
import '../../core/utils/settings_service.dart';
import '../../core/network/api_client.dart';

class NavoiyRepository {
  static NavoiyRepository? _instance;
  static NavoiyRepository get instance =>
      _instance ??= NavoiyRepository._();
  NavoiyRepository._();

  final _local = DatabaseHelper.instance;
  final _remote = NavoiyRemoteDataSource();

  bool get _isOnline => !SettingsService.instance.isOfflineMode;

  // ─── Asarlar ──────────────────────────────────────────────────────────────

  Future<List<AsarModel>> getAsarlar({
    String? category,
    String? search,
    int page = 1,
  }) async {
    if (_isOnline) {
      final result = await _remote.getAsarlar(
        category: category,
        search: search,
        page: page,
      );
      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
      // fallback to local on error
    }
    return _local.getAsarlar(category: category, search: search);
  }

  Future<AsarModel?> getAsarById(int id) async {
    if (_isOnline) {
      final result = await _remote.getAsarById(id);
      if (result.isSuccess && result.data != null) {
        await _local.incrementReadCount(id);
        return result.data;
      }
    }
    return _local.getAsarById(id);
  }

  Future<void> toggleAsarFavorite(int id, bool isFavorite) async {
    await _local.toggleAsarFavorite(id, isFavorite);
    if (_isOnline) {
      await _remote.toggleFavorite(
          type: 'asar', id: id, isFavorite: isFavorite);
    }
  }

  // ─── Sherlar ──────────────────────────────────────────────────────────────

  Future<List<SherModel>> getSherlar({
    String? type,
    String? search,
    int? asarId,
    int page = 1,
  }) async {
    if (_isOnline) {
      final result = await _remote.getSherlar(
        type: type,
        search: search,
        asarId: asarId,
        page: page,
      );
      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
    }
    return _local.getSherlar(type: type, search: search, asarId: asarId);
  }

  Future<void> toggleSherFavorite(int id, bool isFavorite) async {
    await _local.toggleSherFavorite(id, isFavorite);
    if (_isOnline) {
      await _remote.toggleFavorite(
          type: 'sher', id: id, isFavorite: isFavorite);
    }
  }
}
