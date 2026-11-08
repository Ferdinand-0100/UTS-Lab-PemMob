/// Centralized application constants.
///
/// Keep all magic strings and tunable values here so they can be
/// referenced consistently across layers without scattering literals.
class AppConstants {
  AppConstants._();

  /// Application display name shown in app bars and launchers.
  static const String appName = 'Quiz Master';

  /// Default number of seconds allowed per question.
  static const int defaultQuestionTimeSeconds = 30;

  /// Minimum score (in percent) to pass a quiz.
  static const double passingScorePercent = 60.0;

  // ---------------------------------------------------------------------------
  // Supabase
  // ---------------------------------------------------------------------------

  /// Supabase project URL.
  static const String supabaseUrl = 'https://ydewcvyhhmabuxevosqv.supabase.co';

  /// Supabase publishable (anon) key — safe to embed in client apps.
  static const String supabaseAnonKey =
      'sb_publishable_orSgllFVUm7i4kZPAEIePA_M5Z6T7TO';

  // ---------------------------------------------------------------------------
  // Admin registration
  // ---------------------------------------------------------------------------

  /// Secret code required to register as an admin.
  ///
  /// NOTE: This is client-side only and can be decompiled.
  /// Sufficient for a lab/course project; use a server-side check in
  /// production.
  static const String adminSecretCode = 'FerdinandTampan';
}
