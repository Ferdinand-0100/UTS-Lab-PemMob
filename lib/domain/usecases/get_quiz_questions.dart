import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/domain/repositories/quiz_repository.dart';

/// Use case: fetch a single quiz with all its questions, ready for play.
class GetQuizQuestions {
  const GetQuizQuestions(this._repository);
  final QuizRepository _repository;

  Result<Quiz> call(String quizId) => _repository.getQuizById(quizId);
}
