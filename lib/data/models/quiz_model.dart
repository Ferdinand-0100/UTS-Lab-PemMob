import 'package:quiz_app/data/models/question_model.dart';
import 'package:quiz_app/domain/entities/quiz.dart';

/// Data Transfer Object for [Quiz].
///
/// A "summary" form (without questions) is supported via
/// [QuizModel.summaryFromJson] so the home screen can list quizzes
/// cheaply; the full form via [fromJson] includes questions.
class QuizModel {
  const QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  /// Parses a full quiz payload including nested questions.
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>)
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: questions,
    );
  }

  /// Parses only metadata fields; [questions] is left empty.
  factory QuizModel.summaryFromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: const [],
    );
  }

  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;

  /// Converts to a domain [Quiz] entity.
  ///
  /// When [includeQuestions] is false the resulting entity has an empty
  /// question list — useful for list views.
  Quiz toEntity({bool includeQuestions = true}) => Quiz(
        id: id,
        title: title,
        description: description,
        questions: includeQuestions
            ? questions.map((q) => q.toEntity()).toList(growable: false)
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
