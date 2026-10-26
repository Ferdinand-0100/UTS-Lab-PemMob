import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/datasources/local/quiz_local_datasource.dart';
import 'package:quiz_app/data/repositories/quiz_repository_impl.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/domain/repositories/quiz_repository.dart';
import 'package:quiz_app/domain/usecases/calculate_quiz_score.dart';
import 'package:quiz_app/domain/usecases/get_quizzes.dart';
import 'package:quiz_app/domain/usecases/get_quiz_questions.dart';

// ---------------------------------------------------------------------------
// Dependency injection via Riverpod providers.
//
// Keeping provider wiring in one place makes the composition explicit and
// easy to override in tests with ProviderContainer overrides.
// ---------------------------------------------------------------------------

final quizLocalDataSourceProvider = Provider<QuizLocalDataSource>(
  (ref) => const QuizLocalDataSource(),
);

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(ref.read(quizLocalDataSourceProvider));
});

final getQuizzesProvider = Provider<GetQuizzes>(
  (ref) => GetQuizzes(ref.read(quizRepositoryProvider)),
);

final getQuizQuestionsProvider = Provider<GetQuizQuestions>(
  (ref) => GetQuizQuestions(ref.read(quizRepositoryProvider)),
);

final calculateQuizScoreProvider = Provider<CalculateQuizScore>(
  (ref) => const CalculateQuizScore(),
);

/// State held while a quiz is in progress: list of quizzes for the home
/// screen and the loading status.
class HomeState {
  const HomeState({
    this.quizzes = const [],
    this.loading = false,
    this.errorMessage,
  });

  final List<Quiz> quizzes;
  final bool loading;
  final String? errorMessage;

  HomeState copyWith({
    List<Quiz>? quizzes,
    bool? loading,
    String? errorMessage,
  }) {
    return HomeState(
      quizzes: quizzes ?? this.quizzes,
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._getQuizzes, this._repository) : super(const HomeState());

  final GetQuizzes _getQuizzes;
  final QuizRepositoryImpl _repository;

  Future<void> load() async {
    state = state.copyWith(loading: true, errorMessage: null);
    // Ensure the async data source has populated the in-memory cache.
    try {
      await _repository.ensureLoaded();
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Failed to load quizzes.',
      );
      return;
    }
    final result = _getQuizzes();
    switch (result) {
      case Success(:final value):
        state = HomeState(quizzes: value, loading: false);
      case FailureResult():
        state = state.copyWith(loading: false, errorMessage: 'Failed to load quizzes.');
    }
  }
}

final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    ref.read(getQuizzesProvider),
    ref.read(quizRepositoryProvider) as QuizRepositoryImpl,
  );
});

/// Live quiz-play state: current question index and the map of
/// question id -> selected option index.
class QuizPlayState {
  const QuizPlayState({
    required this.quiz,
    this.currentIndex = 0,
    this.answers = const {},
    this.isComplete = false,
  });

  final Quiz quiz;
  final int currentIndex;
  final Map<String, int> answers;
  final bool isComplete;

  QuizPlayState copyWith({
    int? currentIndex,
    Map<String, int>? answers,
    bool? isComplete,
  }) {
    return QuizPlayState(
      quiz: quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class QuizPlayNotifier extends StateNotifier<QuizPlayState?> {
  QuizPlayNotifier(this._getQuizQuestions) : super(null);

  final GetQuizQuestions _getQuizQuestions;

  /// Loads a quiz by id and initializes play state.
  void start(String quizId) {
    final result = _getQuizQuestions(quizId);
    switch (result) {
      case Success(:final value):
        state = QuizPlayState(quiz: value);
      case FailureResult():
        // In a real app we'd surface this via a dedicated error state.
        state = null;
    }
  }

  /// Records an answer for the current question and advances the index.
  void answer(int optionIndex) {
    final current = state;
    if (current == null) return;
    final question = current.quiz.questions[current.currentIndex];
    final updatedAnswers = Map<String, int>.from(current.answers)
      ..[question.id] = optionIndex;

    final isLast = current.currentIndex == current.quiz.questions.length - 1;
    state = current.copyWith(
      answers: updatedAnswers,
      currentIndex: isLast ? current.currentIndex : current.currentIndex + 1,
      isComplete: isLast,
    );
  }

  /// Resets the notifier back to idle so a new quiz can start cleanly.
  void reset() => state = null;
}

final quizPlayNotifierProvider =
    StateNotifierProvider<QuizPlayNotifier, QuizPlayState?>((ref) {
  return QuizPlayNotifier(ref.read(getQuizQuestionsProvider));
});
