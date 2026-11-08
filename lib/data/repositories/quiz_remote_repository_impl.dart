import 'package:quiz_app/core/errors/failures.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/datasources/remote/supabase_quiz_datasource.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/domain/repositories/quiz_repository.dart';

/// [QuizRepository] backed by Supabase.
///
/// Unlike the local implementation there is no in-memory cache —
/// Supabase's own PostgREST layer handles repeated queries efficiently.
/// A simple in-request cache is added via [_cachedQuizzes] to avoid
/// redundant network calls within a single session load.
class QuizRemoteRepositoryImpl implements QuizRepository {
  QuizRemoteRepositoryImpl(this._dataSource);

  final SupabaseQuizDataSource _dataSource;
  List<Quiz>? _cachedQuizzes;

  @override
  Future<void> ensureLoaded() async {
    if (_cachedQuizzes != null) return;
    try {
      final models = await _dataSource.loadAll();
      _cachedQuizzes =
          models.map((m) => m.toEntity()).toList(growable: false);
    } catch (e) {
      _cachedQuizzes = null;
      throw UnexpectedFailure(e.toString());
    }
  }

  @override
  Result<List<Quiz>> getQuizzes() {
    final cached = _cachedQuizzes;
    if (cached == null) return const FailureResult(UnexpectedFailure());
    return Success(cached);
  }

  @override
  Result<Quiz> getQuizById(String id) {
    final cached = _cachedQuizzes;
    if (cached == null) return const FailureResult(UnexpectedFailure());
    final match = cached.where((q) => q.id == id).firstOrNull;
    if (match == null) {
      return FailureResult(NotFoundFailure('Quiz "$id" not found.'));
    }
    return Success(match);
  }

  /// Clears the cache so the next [ensureLoaded] re-fetches from Supabase.
  /// Call this after a quiz is created or deleted.
  void invalidate() => _cachedQuizzes = null;
}
