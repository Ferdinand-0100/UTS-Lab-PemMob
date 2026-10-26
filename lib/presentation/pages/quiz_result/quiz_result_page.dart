import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Quiz result page: shows the score and a breakdown.
///
/// Pulls the completed answers from the [quizPlayNotifierProvider]
/// state before resetting it.
class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({required this.quizId, super.key});

  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(quizPlayNotifierProvider);

    // If the notifier was reset before we got here, send the user home.
    if (playState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.home);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final quiz = playState.quiz;
    final answers = playState.answers;

    // Compute the score.
    final scoreResult = ref
        .read(calculateQuizScoreProvider)
        .call(questions: quiz.questions, answers: answers);

    return Scaffold(
      appBar: AppBar(title: Text('${quiz.title} - Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              scoreResult.passed ? Icons.emoji_events : Icons.sentiment_neutral,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '${scoreResult.correctCount}/${scoreResult.totalCount} correct',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              '${scoreResult.percent.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: quiz.questions.length,
                separatorBuilder: (context, _) => const Divider(),
                itemBuilder: (context, index) {
                  final q = quiz.questions[index];
                  final selected = answers[q.id];
                  final isCorrect = selected == q.correctIndex;
                  return ListTile(
                    leading: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(q.text),
                    subtitle: Text(
                      selected == null
                          ? 'Not answered'
                          : 'You: ${q.options[selected]}',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                ref.read(quizPlayNotifierProvider.notifier).reset();
                context.go(AppRouter.home);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
