import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/presentation/providers/theme_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

class QuizApp extends ConsumerWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Quiz Master',
      theme: AppTheme.light,       // beige Game Boy shell
      darkTheme: AppTheme.dark,    // midnight black shell
      themeMode: themeMode,
      routerConfig: AppRouter.routerWithRef(ref),
      debugShowCheckedModeBanner: false,
    );
  }
}
