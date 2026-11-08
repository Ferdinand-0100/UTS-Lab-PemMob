import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth and the `profiles` table.
///
/// Keeps all Supabase-specific types out of the repository layer.
class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Signs in and returns the Supabase [User].
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Sign-in failed: no user returned.');
    return user;
  }

  /// Creates a new Supabase Auth user and inserts a matching profile row.
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Registration failed: no user returned.');

    // Upsert the profile row so it exists even if the trigger is delayed.
    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
      'role': role,
    });

    return user;
  }

  /// Fetches a profile row from Supabase by [userId].
  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return data;
  }

  Future<void> signOut() => _client.auth.signOut();
}
