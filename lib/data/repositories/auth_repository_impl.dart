import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/core/errors/failures.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/datasources/remote/supabase_auth_datasource.dart';
import 'package:quiz_app/domain/entities/app_user.dart';
import 'package:quiz_app/domain/repositories/auth_repository.dart';

/// Concrete [AuthRepository] backed by [SupabaseAuthDataSource].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final SupabaseAuthDataSource _dataSource;

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentAuthUser;
    if (user == null) return null;
    // Role is not available synchronously without a profile fetch,
    // so we default to [UserRole.user] here. Use authStateChanges
    // (which fetches the profile) for the authoritative value.
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String? ?? '',
      role: UserRole.user,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges async* {
    await for (final authState in _dataSource.authStateChanges) {
      final user = authState.session?.user;
      if (user == null) {
        yield null;
        continue;
      }
      try {
        final profile = await _dataSource.fetchProfile(user.id);
        yield _profileToUser(user.id, user.email ?? '', profile);
      } catch (_) {
        // Profile not ready yet (race on first registration) — yield
        // a basic user and wait for the next auth state event.
        yield AppUser(
          id: user.id,
          email: user.email ?? '',
          displayName: '',
          role: UserRole.user,
        );
      }
    }
  }

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signIn(email: email, password: password);
      final profile = await _dataSource.fetchProfile(user.id);
      return Success(_profileToUser(user.id, user.email ?? '', profile));
    } catch (e) {
      return FailureResult(UnexpectedFailure(_friendlyError(e)));
    }
  }

  @override
  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final user = await _dataSource.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role.name,
      );
      final profile = await _dataSource.fetchProfile(user.id);
      return Success(_profileToUser(user.id, user.email ?? '', profile));
    } catch (e) {
      return FailureResult(UnexpectedFailure(_friendlyError(e)));
    }
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  // ---------------------------------------------------------------------------

  AppUser _profileToUser(
    String id,
    String email,
    Map<String, dynamic> profile,
  ) {
    final roleStr = profile['role'] as String? ?? 'user';
    return AppUser(
      id: id,
      email: email,
      displayName: profile['display_name'] as String? ?? '',
      role: roleStr == 'admin' ? UserRole.admin : UserRole.user,
    );
  }

  /// Maps raw Supabase / network exceptions to short, user-facing strings.
  String _friendlyError(Object e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return 'Incorrect email or password.';
      }
      if (msg.contains('email already') || msg.contains('already registered')) {
        return 'An account with this email already exists.';
      }
      if (msg.contains('password')) {
        return 'Password must be at least 6 characters.';
      }
      if (msg.contains('network') || msg.contains('connection')) {
        return 'Network error. Check your connection and try again.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Please confirm your email before signing in.';
      }
      // Fall back to Supabase's message, stripped of technical noise.
      return e.message;
    }
    if (e is PostgrestException) {
      return 'Database error. Please try again.';
    }
    final raw = e.toString();
    if (raw.contains('SocketException') || raw.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
