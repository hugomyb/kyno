import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_exceptions.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'app_data_provider.dart';
import 'service_providers.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory AuthState.unauthenticated({String? error}) {
    return AuthState(status: AuthStatus.unauthenticated, error: error);
  }

  factory AuthState.authenticated({
    required String token,
    Map<String, dynamic>? user,
  }) {
    return AuthState(status: AuthStatus.authenticated, token: token, user: user);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late StorageService _storage;
  late AuthService _authService;

  @override
  AuthState build() {
    _storage = ref.watch(storageProvider);
    _authService = ref.watch(authServiceProvider);

    final token = _storage.loadAuthToken();
    if (token == null) {
      return AuthState.unauthenticated();
    }

    final next = AuthState.authenticated(token: token);
    _refreshUser();
    return next;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(email: email, password: password);
      await _storage.saveAuthToken(response.token);
      state = AuthState.authenticated(token: response.token, user: response.user);
      return true;
    } on UnauthorizedException {
      state = AuthState.unauthenticated(error: 'Identifiants invalides');
      return false;
    } on ApiException {
      state = AuthState.unauthenticated(error: 'Connexion impossible');
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } on ApiException {
      // Ignore API errors on logout.
    }
    await forceLogout();
  }

  Future<void> forceLogout() async {
    await _storage.clearAuthToken();
    state = AuthState.unauthenticated();
    // Invalidate app data provider to reset it
    ref.invalidate(appDataProvider);
  }

  Future<void> _refreshUser() async {
    try {
      final user = await _authService.me();
      state = state.copyWith(user: user);
    } on UnauthorizedException {
      await forceLogout();
    } on ApiException {
      // Keep existing auth state on transient errors.
    }
  }
}
