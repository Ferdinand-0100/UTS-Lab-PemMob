import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Quiz play page: shows one question at a time and records answers.
///
/// Uses a [WidgetsBindingObserver] to navigate to the result page when
/// the quiz is marked complete.
class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({required this.quizId, super.key});

  final String quizId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizPlayNotifierProvider.notifier).start(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playState = ref.watch(quizPlayNotifierProvider);

    if (playState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Navigate to the result page once the quiz is complete.
    if (playState.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.replace(
          AppRouter.quizResult.replaceFirst(':id', widget.quizId),
        );
      });
    }

    final question = playState.quiz.questions[playState.currentIndex];
    final total = playState.quiz.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(playState.quiz.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${playState.currentIndex + 1}/$total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (playState.currentIndex + 1) / total,
            ),
            const SizedBox(height: 24),
            _TimerBadge(
              secondsLeft: playState.timeLeft,
              totalSeconds: AppConstants.defaultQuestionTimeSeconds,
            ),
            const SizedBox(height: 24),
            Text(
              question.text,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final optionText = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: FilledButton.tonal(
                  onPressed: () =>
                      ref.read(quizPlayNotifierProvider.notifier).answer(index),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${String.fromCharCode(65 + index)}. $optionText',
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Circular countdown indicator for the current question.
///
/// Turns red in the final 5 seconds to signal urgency.
class _TimerBadge extends StatelessWidget {
  const _TimerBadge({
    required this.secondsLeft,
    required this.totalSeconds,
  });

  final int secondsLeft;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsLeft <= 5;
    final color = isUrgent
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Center(
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: secondsLeft / totalSeconds,
              strokeWidth: 4,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
            Text(
              '$secondsLeft',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
