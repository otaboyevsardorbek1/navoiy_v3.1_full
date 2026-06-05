// lib/presentation/sync/bloc/sync_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/utils/settings_service.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override List<Object?> get props => [];
}

class SyncFullRequested extends SyncEvent { const SyncFullRequested(); }
class SyncDeltaRequested extends SyncEvent { const SyncDeltaRequested(); }
class SyncAsarRequested extends SyncEvent {
  final String slug;
  const SyncAsarRequested(this.slug);
  @override List<Object?> get props => [slug];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SyncState extends Equatable {
  const SyncState();
  @override List<Object?> get props => [];
}

class SyncIdle extends SyncState { const SyncIdle(); }

class SyncInProgress extends SyncState {
  final SyncProgress progress;
  const SyncInProgress(this.progress);
  @override List<Object?> get props => [progress.current, progress.total];
}

class SyncSuccess extends SyncState {
  final SyncResult result;
  const SyncSuccess(this.result);
  @override List<Object?> get props => [result.downloaded, result.failed];
}

class SyncFailure extends SyncState {
  final String message;
  const SyncFailure(this.message);
  @override List<Object?> get props => [message];
}

class SyncOfflineMode extends SyncState { const SyncOfflineMode(); }

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc() : super(const SyncIdle()) {
    on<SyncFullRequested>(_onFull);
    on<SyncDeltaRequested>(_onDelta);
    on<SyncAsarRequested>(_onAsar);
  }

  Future<void> _onFull(SyncFullRequested e, Emitter<SyncState> emit) async {
    if (SettingsService.instance.isOfflineMode) {
      emit(const SyncOfflineMode());
      return;
    }
    emit(SyncInProgress(SyncProgress(current: 0, total: 1, currentItem: 'Boshlanmoqda...', phase: 'Manifest yuklanmoqda...')));
    final result = await SyncManager.instance.performFullSync(
      onProgress: (p) => emit(SyncInProgress(p)),
    );
    if (result.success) {
      emit(SyncSuccess(result));
    } else {
      emit(SyncFailure(result.error ?? 'Sinxronlashda xatolik'));
    }
    await Future.delayed(const Duration(seconds: 2));
    emit(const SyncIdle());
  }

  Future<void> _onDelta(SyncDeltaRequested e, Emitter<SyncState> emit) async {
    if (SettingsService.instance.isOfflineMode) {
      emit(const SyncOfflineMode());
      return;
    }
    emit(SyncInProgress(SyncProgress(current: 0, total: 1, currentItem: 'Delta tekshirilmoqda...', phase: 'Yangilanishlar...')));
    final result = await SyncManager.instance.performDeltaSync();
    emit(result.success ? SyncSuccess(result) : SyncFailure(result.error ?? 'Xatolik'));
    await Future.delayed(const Duration(seconds: 2));
    emit(const SyncIdle());
  }

  Future<void> _onAsar(SyncAsarRequested e, Emitter<SyncState> emit) async {
    emit(SyncInProgress(SyncProgress(current: 0, total: 1, currentItem: e.slug, phase: 'Yuklanmoqda...')));
    final ok = await SyncManager.instance.downloadAsar(e.slug);
    emit(ok
        ? SyncSuccess(SyncResult(success: true, downloaded: 1))
        : SyncFailure('Yuklab bo\'lmadi: ${e.slug}'));
    await Future.delayed(const Duration(seconds: 1));
    emit(const SyncIdle());
  }
}
