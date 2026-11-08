import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Root widget for the application.
///
/// Uses [ConsumerWidget] so the router can watch auth state and
/// redirect unauthenticated users to the login screen.
class QuizApp extends ConsumerWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Quiz Master',
      theme: AppTheme.light,
      routerConfig: AppRouter.routerWithRef(ref),
      debugShowCheckedModeBanner: false,
    );
  }
}
