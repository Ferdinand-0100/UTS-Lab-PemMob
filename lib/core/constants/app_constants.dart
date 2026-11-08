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
}
