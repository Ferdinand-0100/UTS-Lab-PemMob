import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/domain/repositories/quiz_repository.dart';

/// Use case: fetch the list of quizzes for the home screen.
///
/// Use cases orchestrate domain logic and act as the single entry
/// point invoked by the presentation layer. Keeping them small and
/// focused makes them easy to test and swap out.
class GetQuizzes {
  const GetQuizzes(this._repository);
  final QuizRepository _repository;

  Result<List<Quiz>> call() => _repository.getQuizzes();
}
