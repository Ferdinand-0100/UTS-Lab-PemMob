import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/domain/entities/quiz.dart';

/// Abstract contract for quiz data access.
///
/// The domain layer defines this interface; the data layer provides
/// the implementation. This inversion keeps the domain independent of
/// any particular data source (local JSON, REST API, SQLite, etc.).
abstract class QuizRepository {
  /// Ensures the underlying data source is ready to serve data.
  ///
  /// Callers must await this before invoking [getQuizzes] or
  /// [getQuizById]. Implementations are free to make this a no-op
  /// when the data is already available (e.g. already cached).
  Future<void> ensureLoaded();

  /// Returns all available quizzes without their questions loaded.
  Result<List<Quiz>> getQuizzes();

  /// Returns a single quiz by [id], including all questions.
  Result<Quiz> getQuizById(String id);
}
