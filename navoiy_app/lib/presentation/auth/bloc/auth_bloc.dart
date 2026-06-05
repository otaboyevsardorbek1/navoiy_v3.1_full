// lib/presentation/auth/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/utils/settings_service.dart';
import '../../../data/models/models.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionRefreshRequested extends AuthEvent {
  const AuthSessionRefreshRequested();
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final SettingsService _settings;

  AuthBloc({
    required AuthService authService,
    required SettingsService settings,
  })  : _authService = authService,
        _settings = settings,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionRefreshRequested>(_onSessionRefresh);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          // Check if token needs refresh
          if (await _authService.isNearExpiry() && !_settings.isOfflineMode) {
            add(const AuthSessionRefreshRequested());
          }
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        await _authService.clearSession();
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      AuthResponse? auth;

      if (_settings.isOfflineMode) {
        auth = await _authService.loginOffline(event.username, event.password);
        if (auth == null) {
          emit(const AuthError(message: 'Login yoki parol noto\'g\'ri'));
          return;
        }
      } else {
        final dio = Dio();
        auth = await _authService.loginOnline(
          dio,
          _settings.apiBaseUrl,
          LoginRequest(
            username: event.username,
            password: event.password,
            rememberMe: event.rememberMe,
          ),
        );
        if (auth == null) {
          emit(const AuthError(message: 'Tizimga kirib bo\'lmadi'));
          return;
        }
      }

      emit(AuthAuthenticated(user: auth.user));
    } on String catch (message) {
      emit(AuthError(message: message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.clearSession();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionRefresh(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (_settings.isOfflineMode) return;
      final dio = Dio();
      final refreshed = await _authService.refreshToken(dio, _settings.apiBaseUrl);
      if (!refreshed) {
        await _authService.clearSession();
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      // Silent fail for refresh
    }
  }
}
