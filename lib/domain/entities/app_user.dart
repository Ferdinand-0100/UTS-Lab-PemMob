/// Roles a user can hold in the application.
enum UserRole { user, admin }

/// Authenticated user as a pure domain entity.
///
/// Contains only what the domain and presentation layers need —
/// no Supabase types leak beyond the data layer.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
}
