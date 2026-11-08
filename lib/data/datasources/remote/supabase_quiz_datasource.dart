import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/data/models/question_model.dart';
import 'package:quiz_app/data/models/quiz_model.dart';

/// Fetches quiz data from Supabase.
///
/// Replaces [QuizLocalDataSource] as the primary data source once the
/// Supabase schema is in place. The local source is retained for offline
/// fallback / testing.
class SupabaseQuizDataSource {
  const SupabaseQuizDataSource(this._client);

  final SupabaseClient _client;

  /// Returns all quizzes with their questions eagerly loaded.
  Future<List<QuizModel>> loadAll() async {
    final rows = await _client
        .from('quizzes')
        .select('id, title, description, questions(id, text, options, correct_index, explanation, order)')
        .order('created_at');

    return rows.map<QuizModel>(_rowToModel).toList(growable: false);
  }

  /// Returns a single quiz by [id] with all questions.
  Future<QuizModel> loadById(String id) async {
    final row = await _client
        .from('quizzes')
        .select('id, title, description, questions(id, text, options, correct_index, explanation, order)')
        .eq('id', id)
        .single();

    return _rowToModel(row);
  }

  QuizModel _rowToModel(Map<String, dynamic> row) {
    final rawQuestions = (row['questions'] as List<dynamic>? ?? [])
      ..sort((a, b) =>
          ((a as Map)['order'] as int? ?? 0)
              .compareTo((b as Map)['order'] as int? ?? 0));

    final questions = rawQuestions
        .map((q) => QuestionModel.fromSupabase(q as Map<String, dynamic>))
        .toList(growable: false);

    return QuizModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      questions: questions,
    );
  }
}
