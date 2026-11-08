import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/pages/home/home_page.dart';
import 'package:quiz_app/presentation/pages/quiz_play/quiz_play_page.dart';
import 'package:quiz_app/presentation/pages/quiz_result/quiz_result_page.dart';

/// Centralized route configuration using [GoRouter].
///
/// Use the static helpers ([quizPlayPath], [quizResultPath]) to build
/// concrete paths — never manipulate the route pattern strings directly.
class AppRouter {
  AppRouter._();

  // Route patterns — used only by GoRouter internally.
  static const String home = '/';
  static const String _quizPlay = '/quiz/:id';
  static const String _quizResult = '/quiz/:id/result';

  /// Concrete path to the quiz-play screen for [quizId].
  static String quizPlayPath(String quizId) => '/quiz/$quizId';

  /// Concrete path to the quiz-result screen for [quizId].
  static String quizResultPath(String quizId) => '/quiz/$quizId/result';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: _quizPlay,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuizPlayPage(quizId: id);
        },
      ),
      GoRoute(
        path: _quizResult,
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
