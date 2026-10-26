import 'package:quiz_app/domain/entities/question.dart';

/// Data Transfer Object for [Question].
///
/// Knows how to (de)serialize JSON, converting to and from the
/// domain entity. The domain entity never sees JSON directly.
class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>)
        .map((e) => e as String)
        .toList(growable: false);
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      options: options,
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String?,
    );
  }

  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  Question toEntity() => Question(
        id: id,
        text: text,
        options: options,
        correctIndex: correctIndex,
        explanation: explanation,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
        if (explanation != null) 'explanation': explanation,
      };
}
