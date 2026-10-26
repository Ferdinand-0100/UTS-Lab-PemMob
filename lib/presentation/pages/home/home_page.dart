import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Home page: lists available quizzes.
///
/// Consumes [homeNotifierProvider] and triggers a load on first build.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fire the load once after the first frame so the widget is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Master')),
      body: switch (state.loading) {
        true => const Center(child: CircularProgressIndicator()),
        false when state.errorMessage != null => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(state.errorMessage!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(homeNotifierProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        false when state.quizzes.isEmpty => const Center(
            child: Text('No quizzes available.'),
          ),
        _ => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.quizzes.length,
            itemBuilder: (context, index) {
              final quiz = state.quizzes[index];
              return Card(
                child: ListTile(
                  title: Text(quiz.title),
                  subtitle: Text(quiz.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRouter.quizPlay.replaceFirst(
                    ':id',
                    quiz.id,
                  )),
                ),
              );
            },
          ),
      },
    );
  }
}
