import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/domain/entities/quiz.dart';

/// Abstract contract for quiz data access.
///
/// The domain layer defines this interface; the data layer provides
/// the implementation. This inversion keeps the domain independent of
/// any particular data source (local JSON, REST API, SQLite, etc.).
abstract class QuizRepository {
  /// Returns all available quizzes without their questions loaded.
  Result<List<Quiz>> getQuizzes();

  /// Returns a single quiz by [id], including all questions.
  Result<Quiz> getQuizById(String id);
}
