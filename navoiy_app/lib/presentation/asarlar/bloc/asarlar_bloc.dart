// lib/presentation/asarlar/bloc/asarlar_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/models/models.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AsarlarEvent extends Equatable {
  const AsarlarEvent();
  @override
  List<Object?> get props => [];
}

class AsarlarLoadRequested extends AsarlarEvent {
  final String? category;
  final String? search;
  const AsarlarLoadRequested({this.category, this.search});
  @override
  List<Object?> get props => [category, search];
}

class AsarDetailRequested extends AsarlarEvent {
  final int id;
  const AsarDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class AsarFavoriteToggled extends AsarlarEvent {
  final int id;
  final bool isFavorite;
  const AsarFavoriteToggled(this.id, this.isFavorite);
  @override
  List<Object?> get props => [id, isFavorite];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AsarlarState extends Equatable {
  const AsarlarState();
  @override
  List<Object?> get props => [];
}

class AsarlarInitial extends AsarlarState {}

class AsarlarLoading extends AsarlarState {}

class AsarlarLoaded extends AsarlarState {
  final List<AsarModel> asarlar;
  final String? activeCategory;
  final String? searchQuery;

  const AsarlarLoaded({
    required this.asarlar,
    this.activeCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [asarlar, activeCategory, searchQuery];
}

class AsarDetailLoaded extends AsarlarState {
  final AsarModel asar;
  const AsarDetailLoaded(this.asar);
  @override
  List<Object?> get props => [asar];
}

class AsarlarError extends AsarlarState {
  final String message;
  const AsarlarError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class AsarlarBloc extends Bloc<AsarlarEvent, AsarlarState> {
  final DatabaseHelper _db;

  AsarlarBloc(this._db) : super(AsarlarInitial()) {
    on<AsarlarLoadRequested>(_onLoad);
    on<AsarDetailRequested>(_onDetail);
    on<AsarFavoriteToggled>(_onFavorite);
  }

  Future<void> _onLoad(AsarlarLoadRequested e, Emitter<AsarlarState> emit) async {
    emit(AsarlarLoading());
    try {
      final list = await _db.getAsarlar(
        category: e.category,
        search: e.search,
      );
      emit(AsarlarLoaded(
        asarlar: list,
        activeCategory: e.category,
        searchQuery: e.search,
      ));
    } catch (err) {
      emit(AsarlarError(err.toString()));
    }
  }

  Future<void> _onDetail(AsarDetailRequested e, Emitter<AsarlarState> emit) async {
    try {
      final asar = await _db.getAsarById(e.id);
      if (asar != null) {
        await _db.incrementReadCount(e.id);
        emit(AsarDetailLoaded(asar));
      }
    } catch (err) {
      emit(AsarlarError(err.toString()));
    }
  }

  Future<void> _onFavorite(AsarFavoriteToggled e, Emitter<AsarlarState> emit) async {
    await _db.toggleAsarFavorite(e.id, e.isFavorite);
    final current = state;
    if (current is AsarlarLoaded) {
      final updated = current.asarlar.map((a) {
        if (a.id == e.id) return a.copyWith(isFavorite: e.isFavorite);
        return a;
      }).toList();
      emit(AsarlarLoaded(
        asarlar: updated,
        activeCategory: current.activeCategory,
        searchQuery: current.searchQuery,
      ));
    }
  }
}
