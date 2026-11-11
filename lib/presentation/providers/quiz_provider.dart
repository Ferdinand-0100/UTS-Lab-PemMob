import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/datasources/remote/supabase_quiz_datasource.dart';
import 'package:quiz_app/data/repositories/quiz_remote_repository_impl.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/domain/repositories/quiz_repository.dart';
import 'package:quiz_app/domain/usecases/calculate_quiz_score.dart';
import 'package:quiz_app/domain/usecases/get_quizzes.dart';
import 'package:quiz_app/domain/usecases/get_quiz_questions.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Dependency injection via Riverpod providers.
//
// Keeping provider wiring in one place makes the composition explicit and
// easy to override in tests with ProviderContainer overrides.
// ---------------------------------------------------------------------------

final quizLocalDataSourceProvider = Provider<SupabaseQuizDataSource>(
  (ref) => SupabaseQuizDataSource(ref.read(supabaseClientProvider)),
);

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRemoteRepositoryImpl(ref.read(quizLocalDataSourceProvider));
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
/// screen, the loading status, and the current user's pass status per quiz.
class HomeState {
  const HomeState({
    this.quizzes = const [],
    this.userPassedQuizIds = const {},
    this.loading = false,
    this.errorMessage,
  });

  final List<Quiz> quizzes;

  /// Set of quiz IDs that the current user has passed at least once.
  final Set<String> userPassedQuizIds;

  final bool loading;
  final String? errorMessage;

  HomeState copyWith({
    List<Quiz>? quizzes,
    Set<String>? userPassedQuizIds,
    bool? loading,
    String? errorMessage,
  }) {
    return HomeState(
      quizzes: quizzes ?? this.quizzes,
      userPassedQuizIds: userPassedQuizIds ?? this.userPassedQuizIds,
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._getQuizzes, this._repository, this._ref)
      : super(const HomeState());

  final GetQuizzes _getQuizzes;
  final QuizRepository _repository;
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(loading: true, errorMessage: null);
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
        // Also fetch the current user's passed quiz IDs in parallel.
        final passedIds = await _fetchUserPassedQuizIds(value);
        state = HomeState(
          quizzes: value,
          userPassedQuizIds: passedIds,
          loading: false,
        );
      case FailureResult():
        state = state.copyWith(
            loading: false, errorMessage: 'Failed to load quizzes.');
    }
  }

  /// Fetches scores for the current user and returns the set of quiz IDs
  /// they have passed at least once.  Fails silently — pass badges are
  /// decorative; a failed fetch just shows no badges.
  Future<Set<String>> _fetchUserPassedQuizIds(List<Quiz> quizzes) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return {};

    try {
      final client = _ref.read(supabaseClientProvider);

      // Build a map of quizId → passingScore from the loaded quiz list
      // so we don't need to join quizzes again.
      final passingScoreByQuiz = {
        for (final q in quizzes) q.id: q.passingScore,
      };

      final rows = await client
          .from('scores')
          .select('quiz_id, percent')
          .eq('user_id', user.id);

      final passed = <String>{};
      for (final row in rows) {
        final quizId = row['quiz_id'] as String;
        final percent = (row['percent'] as num).toDouble();
        final passingScore = passingScoreByQuiz[quizId] ?? 60.0;
        if (percent >= passingScore) {
          passed.add(quizId);
        }
      }
      return passed;
    } catch (_) {
      return {};
    }
  }
}

final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    ref.read(getQuizzesProvider),
    ref.read(quizRepositoryProvider),
    ref,
  );
});

// ---------------------------------------------------------------------------
// Quiz-play state
// ---------------------------------------------------------------------------

/// Describes the lifecycle of a quiz-play session.
///
/// - [QuizPlayLoading]  — start() has not completed yet.
/// - [QuizPlayError]    — start() failed (e.g. unknown quiz id).
/// - [QuizPlayActive]   — a quiz is in progress or just completed.
sealed class QuizPlayState {
  const QuizPlayState();
}

class QuizPlayLoading extends QuizPlayState {
  const QuizPlayLoading();
}

class QuizPlayError extends QuizPlayState {
  const QuizPlayError(this.message);
  final String message;
}

class QuizPlayActive extends QuizPlayState {
  const QuizPlayActive({
    required this.quiz,
    this.currentIndex = 0,
    this.answers = const {},
    this.isComplete = false,
    this.timeLeft = AppConstants.defaultQuestionTimeSeconds,
  });

  final Quiz quiz;
  final int currentIndex;
  final Map<String, int> answers;
  final bool isComplete;

  /// Seconds remaining for the current question. Reaches 0 on timeout.
  final int timeLeft;

  QuizPlayActive copyWith({
    int? currentIndex,
    Map<String, int>? answers,
    bool? isComplete,
    int? timeLeft,
  }) {
    return QuizPlayActive(
      quiz: quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      timeLeft: timeLeft ?? this.timeLeft,
    );
  }
}

class QuizPlayNotifier extends StateNotifier<QuizPlayState> {
  QuizPlayNotifier(this._getQuizQuestions) : super(const QuizPlayLoading());

  final GetQuizQuestions _getQuizQuestions;

  Timer? _timer;
  bool _paused = false;

  /// Loads a quiz by id and initializes play state.
  void start(String quizId) {
    _timer?.cancel();
    _paused = false;
    state = const QuizPlayLoading();
    final result = _getQuizQuestions(quizId);
    switch (result) {
      case Success(:final value):
        state = QuizPlayActive(quiz: value);
        _startTimer();
      case FailureResult(:final failure):
        state = QuizPlayError(failure.message);
    }
  }

  /// Pauses the countdown without changing the remaining time.
  /// Call this when the answer flash starts.
  void pauseTimer() {
    _paused = true;
    _timer?.cancel();
  }

  /// Resumes the countdown from wherever it was paused.
  /// Call this after the flash ends, just before advancing.
  void resumeTimer() {
    if (!_paused) return;
    _paused = false;
    final current = state;
    // Only restart if still active and not yet complete.
    if (current is QuizPlayActive && !current.isComplete) {
      _startTimer();
    }
  }

  /// Records an answer for the current question and advances the index.
  void answer(int optionIndex) {
    final current = state;
    if (current is! QuizPlayActive || current.isComplete) return;
    final question = current.quiz.questions[current.currentIndex];
    final updatedAnswers = Map<String, int>.from(current.answers)
      ..[question.id] = optionIndex;

    _advanceFrom(current.copyWith(answers: updatedAnswers));
  }

  /// Called when the timer hits zero: advance with no answer recorded.
  void _timeout() {
    if (_paused) return; // don't time out while flash is showing
    final current = state;
    if (current is! QuizPlayActive || current.isComplete) return;
    _advanceFrom(current.copyWith(timeLeft: 0));
  }

  /// Shared logic for advancing to the next question or finishing the quiz.
  void _advanceFrom(QuizPlayActive current) {
    _timer?.cancel();
    _paused = false;

    final isLast = current.currentIndex == current.quiz.questions.length - 1;
    if (isLast) {
      state = current.copyWith(isComplete: true);
    } else {
      state = current.copyWith(
        currentIndex: current.currentIndex + 1,
        timeLeft: AppConstants.defaultQuestionTimeSeconds,
      );
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused) return; // tick silently while paused
      final current = state;
      if (current is! QuizPlayActive || current.isComplete) {
        timer.cancel();
        return;
      }
      if (current.timeLeft <= 1) {
        timer.cancel();
        _timeout();
      } else {
        state = current.copyWith(timeLeft: current.timeLeft - 1);
      }
    });
  }

  /// Resets the notifier back to idle so a new quiz can start cleanly.
  void reset() {
    _timer?.cancel();
    _paused = false;
    state = const QuizPlayLoading();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quizPlayNotifierProvider =
    StateNotifierProvider<QuizPlayNotifier, QuizPlayState>((ref) {
  return QuizPlayNotifier(ref.read(getQuizQuestionsProvider));
});
