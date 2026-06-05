// lib/presentation/sherlar/bloc/sherlar_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/models/models.dart';

abstract class SherlarEvent extends Equatable {
  const SherlarEvent();
  @override
  List<Object?> get props => [];
}

class SherlarLoadRequested extends SherlarEvent {
  final String? type;
  final String? search;
  const SherlarLoadRequested({this.type, this.search});
  @override
  List<Object?> get props => [type, search];
}

class SherFavoriteToggled extends SherlarEvent {
  final int id;
  final bool isFavorite;
  const SherFavoriteToggled(this.id, this.isFavorite);
  @override
  List<Object?> get props => [id, isFavorite];
}

abstract class SherlarState extends Equatable {
  const SherlarState();
  @override
  List<Object?> get props => [];
}

class SherlarInitial extends SherlarState {}
class SherlarLoading extends SherlarState {}

class SherlarLoaded extends SherlarState {
  final List<SherModel> sherlar;
  final String? activeType;
  const SherlarLoaded({required this.sherlar, this.activeType});
  @override
  List<Object?> get props => [sherlar, activeType];
}

class SherlarError extends SherlarState {
  final String message;
  const SherlarError(this.message);
  @override
  List<Object?> get props => [message];
}

class SherlarBloc extends Bloc<SherlarEvent, SherlarState> {
  final DatabaseHelper _db;

  SherlarBloc(this._db) : super(SherlarInitial()) {
    on<SherlarLoadRequested>(_onLoad);
    on<SherFavoriteToggled>(_onFavorite);
  }

  Future<void> _onLoad(SherlarLoadRequested e, Emitter<SherlarState> emit) async {
    emit(SherlarLoading());
    try {
      final list = await _db.getSherlar(type: e.type, search: e.search);
      emit(SherlarLoaded(sherlar: list, activeType: e.type));
    } catch (err) {
      emit(SherlarError(err.toString()));
    }
  }

  Future<void> _onFavorite(SherFavoriteToggled e, Emitter<SherlarState> emit) async {
    await _db.toggleSherFavorite(e.id, e.isFavorite);
    final cur = state;
    if (cur is SherlarLoaded) {
      final updated = cur.sherlar.map((s) {
        if (s.id == e.id) {
          return SherModel(
            id: s.id, title: s.title, content: s.content, type: s.type,
            description: s.description, asarId: s.asarId, asarTitle: s.asarTitle,
            isFavorite: e.isFavorite, likeCount: s.likeCount, audioUrl: s.audioUrl,
            createdAt: s.createdAt,
          );
        }
        return s;
      }).toList();
      emit(SherlarLoaded(sherlar: updated, activeType: cur.activeType));
    }
  }
}
