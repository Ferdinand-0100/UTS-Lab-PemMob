import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/data/repositories/quiz_remote_repository_impl.dart';

/// A single question draft used while building a new quiz.
class QuestionDraft {
  const QuestionDraft({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.order,
    this.explanation,
    this.id, // non-null when editing an existing question
  });

  final String text;
  final List<String> options;
  final int correctIndex;
  final int order;
  final String? explanation;
  final String? id;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class QuizCreateState {
  const QuizCreateState({this.loading = false, this.errorMessage});
  final bool loading;
  final String? errorMessage;

  QuizCreateState copyWith({bool? loading, String? errorMessage}) =>
      QuizCreateState(
        loading: loading ?? this.loading,
        errorMessage: errorMessage,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class QuizCreateNotifier extends StateNotifier<QuizCreateState> {
  QuizCreateNotifier(this._client, this._ref) : super(const QuizCreateState());

  final SupabaseClient _client;
  final Ref _ref;

  Future<void> createQuiz({
    required String title,
    required String description,
    required double passingScore,
    required List<QuestionDraft> questions,
  }) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final quizResponse = await _client
          .from('quizzes')
          .insert({
            'title': title,
            'description': description,
            'passing_score': passingScore,
          })
          .select('id')
          .single();

      final quizId = quizResponse['id'] as String;

      final questionRows = questions
          .map(
            (q) => {
              'quiz_id': quizId,
              'text': q.text,
              'options': q.options,
              'correct_index': q.correctIndex,
              'explanation': q.explanation,
              'order': q.order,
            },
          )
          .toList();

      await _client.from('questions').insert(questionRows);

      _invalidateCache();
      state = const QuizCreateState();
    } on PostgrestException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Database error: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required String description,
    required double passingScore,
    required List<QuestionDraft> questions,
  }) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _client.from('quizzes').update({
        'title': title,
        'description': description,
        'passing_score': passingScore,
      }).eq('id', quizId);

      // Delete existing questions and re-insert — simpler than diffing.
      // Using .select() forces PostgREST to return the deleted rows, which
      // means RLS policies that silently block DELETE will instead throw a
      // PostgrestException rather than returning success with 0 rows deleted
      // (which would cause the insert below to append duplicates).
      await _client
          .from('questions')
          .delete()
          .eq('quiz_id', quizId)
          .select();

      final questionRows = questions
          .map(
            (q) => {
              'quiz_id': quizId,
              'text': q.text,
              'options': q.options,
              'correct_index': q.correctIndex,
              'explanation': q.explanation,
              'order': q.order,
            },
          )
          .toList();

      await _client.from('questions').insert(questionRows);

      _invalidateCache();
      state = const QuizCreateState();
    } on PostgrestException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Database error: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  void _invalidateCache() {
    // Invalidate the quiz cache so the home page reloads fresh data.
    final repo = _ref.read(quizRepositoryProvider);
    if (repo is QuizRemoteRepositoryImpl) repo.invalidate();
  }
}

final quizCreateNotifierProvider =
    StateNotifierProvider.autoDispose<QuizCreateNotifier, QuizCreateState>(
  (ref) => QuizCreateNotifier(
    ref.read(supabaseClientProvider),
    ref,
  ),
);
