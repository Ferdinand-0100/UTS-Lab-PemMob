import 'package:quiz_app/domain/entities/question.dart';

/// Use case: compute the score for a completed quiz.
///
/// Pure function — no dependencies, which makes it trivially testable.
/// Keeping scoring logic here ensures it is consistent regardless of
/// where the result is displayed.
class CalculateQuizScore {
  const CalculateQuizScore();

  /// [answers] maps question id -> selected option index.
  /// Returns a [ScoreResult] with count, total, and percent.
  ScoreResult call({
    required List<Question> questions,
    required Map<String, int> answers,
  }) {
    var correct = 0;
    for (final q in questions) {
      if (answers[q.id] == q.correctIndex) {
        correct++;
      }
    }
    final total = questions.length;
    final percent = total == 0 ? 0.0 : (correct / total) * 100;
    return ScoreResult(
      correctCount: correct,
      totalCount: total,
      percent: percent,
    );
  }
}

/// Immutable result of a quiz scoring calculation.
class ScoreResult {
  const ScoreResult({
    required this.correctCount,
    required this.totalCount,
    required this.percent,
  });

  final int correctCount;
  final int totalCount;
  final double percent;

  bool get passed => percent >= 60.0;
}
