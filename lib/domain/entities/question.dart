/// A single question belonging to a [Quiz].
///
/// This entity lives in the domain layer and must contain no
/// serialization concerns. Mapping to/from JSON happens in the
/// data layer's [QuestionModel].
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  /// Unique identifier within the parent quiz.
  final String id;

  /// The prompt shown to the user.
  final String text;

  /// Ordered list of selectable answers.
  final List<String> options;

  /// Index into [options] that is considered correct.
  final int correctIndex;

  /// Optional rationale shown after answering.
  final String? explanation;

  /// Convenience: returns the correct option string.
  String get correctAnswer => options[correctIndex];
}
