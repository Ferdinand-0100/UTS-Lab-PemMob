import 'package:quiz_app/core/errors/failures.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/datasources/local/quiz_local_datasource.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/domain/repositories/quiz_repository.dart';

/// Concrete [QuizRepository] backed by [QuizLocalDataSource].
///
/// Bridges the async data source to the synchronous domain contract
/// by performing an initial load and caching the result in memory.
/// Subsequent calls are cheap and synchronous, matching the contract.
class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._dataSource);

  final QuizLocalDataSource _dataSource;
  List<Quiz>? _cachedQuizzes;

  /// Loads (and caches) the full quiz list from the data source.
  Future<void> ensureLoaded() async {
    if (_cachedQuizzes != null) return;
    try {
      final models = await _dataSource.loadAll();
      _cachedQuizzes = models.map((m) => m.toEntity()).toList(growable: false);
    } on Failure catch (_) {
      // Surface the failure up via the Result API on the next call.
      _cachedQuizzes = null;
      rethrow;
    }
  }

  @override
  Result<List<Quiz>> getQuizzes() {
    final cached = _cachedQuizzes;
    if (cached == null) {
      return const FailureResult(UnexpectedFailure());
    }
    // Return summary-like entities (questions excluded) for the list.
    final summaries = cached
        .map((q) => Quiz(
              id: q.id,
              title: q.title,
              description: q.description,
              questions: const [],
            ))
        .toList(growable: false);
    return Success(summaries);
  }

  @override
  Result<Quiz> getQuizById(String id) {
    final cached = _cachedQuizzes;
    if (cached == null) {
      return const FailureResult(UnexpectedFailure());
    }
    final match = cached.where((q) => q.id == id).firstOrNull;
    if (match == null) {
      return FailureResult(NotFoundFailure('Quiz "$id" not found.'));
    }
    return Success(match);
  }
}
