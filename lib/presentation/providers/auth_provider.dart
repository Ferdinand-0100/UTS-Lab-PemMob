import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/datasources/remote/supabase_auth_datasource.dart';
import 'package:quiz_app/data/repositories/auth_repository_impl.dart';
import 'package:quiz_app/domain/entities/app_user.dart';
import 'package:quiz_app/domain/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Dependency providers
// ---------------------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>(
  (ref) => SupabaseAuthDataSource(ref.read(supabaseClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(supabaseAuthDataSourceProvider)),
);

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

/// Streams the current [AppUser] (null when signed out).
///
/// The router listens to this to decide whether to show the auth gate.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

/// Tracks the UI state of the auth page (loading flag + error message).
class AuthState {
  const AuthState({this.loading = false, this.errorMessage});
  final bool loading;
  final String? errorMessage;

  AuthState copyWith({bool? loading, String? errorMessage}) => AuthState(
        loading: loading ?? this.loading,
        errorMessage: errorMessage,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, errorMessage: null);
    final result = await _repository.signIn(email: email, password: password);
    switch (result) {
      case Success():
        state = const AuthState();
      case FailureResult(:final failure):
        state = state.copyWith(loading: false, errorMessage: failure.message);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    state = state.copyWith(loading: true, errorMessage: null);
    final result = await _repository.register(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
    );
    switch (result) {
      case Success():
        state = const AuthState();
      case FailureResult(:final failure):
        state = state.copyWith(loading: false, errorMessage: failure.message);
    }
  }

  Future<void> signOut() => _repository.signOut();
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
