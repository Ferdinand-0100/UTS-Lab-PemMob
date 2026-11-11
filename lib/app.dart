import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

class QuizApp extends ConsumerWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CRT console theme — single palette in both light and dark mode.
    return MaterialApp.router(
      title: 'Quiz Master',
      theme: AppTheme.light,
      darkTheme: AppTheme.light, // same CRT theme always
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.routerWithRef(ref),
      debugShowCheckedModeBanner: false,
    );
  }
}