import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/pages/home/home_page.dart';
import 'package:quiz_app/presentation/pages/quiz_play/quiz_play_page.dart';
import 'package:quiz_app/presentation/pages/quiz_result/quiz_result_page.dart';

/// Centralized route configuration using [GoRouter].
///
/// Named routes keep navigation strings consistent and make deep
/// linking and shell routes easy to add later.
class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String quizPlay = '/quiz/:id';
  static const String quizResult = '/quiz/:id/result';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: quizPlay,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuizPlayPage(quizId: id);
        },
      ),
      GoRoute(
        path: quizResult,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuizResultPage(quizId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
