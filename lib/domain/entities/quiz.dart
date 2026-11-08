import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/domain/entities/question.dart';

/// A quiz aggregate: metadata plus the ordered list of [Question]s.
///
/// Like [Question], this is a pure domain object. Persistence and
/// transport representations are handled by [QuizModel] in the data
/// layer.
class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.passingScore = AppConstants.passingScorePercent,
  });

  final String id;
  final String title;
  final String description;
  final List<Question> questions;

  /// Minimum percentage score required to pass this quiz.
  final double passingScore;

  /// Number of questions, exposed as a convenience for UIs.
  int get length => questions.length;
}
