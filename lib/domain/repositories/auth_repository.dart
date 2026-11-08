import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/domain/entities/app_user.dart';

/// Abstract contract for authentication operations.
///
/// Keeps the domain layer independent of any specific auth provider
/// (Supabase, Firebase, mock, etc.).
abstract class AuthRepository {
  /// The currently signed-in user, or null if not authenticated.
  AppUser? get currentUser;

  /// Stream that emits the current user on auth state changes.
  Stream<AppUser?> get authStateChanges;

  /// Signs in with [email] and [password].
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Registers a new account. Pass [role] as [UserRole.admin] only when
  /// the admin secret code has been verified on the calling side.
  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  });

  /// Signs out the current user.
  Future<void> signOut();
}
