import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/pages/auth/auth_page.dart';
import 'package:quiz_app/presentation/pages/friends/friends_page.dart';
import 'package:quiz_app/presentation/pages/home/home_page.dart';
import 'package:quiz_app/presentation/pages/quiz_create/quiz_create_page.dart';
import 'package:quiz_app/presentation/pages/quiz_play/quiz_play_page.dart';
import 'package:quiz_app/presentation/pages/quiz_result/quiz_result_page.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';

/// Centralized route configuration using [GoRouter].
///
/// Use the static helpers ([quizPlayPath], [quizResultPath]) to build
/// concrete paths — never manipulate the route pattern strings directly.
class AppRouter {
  AppRouter._();

  // Route paths
  static const String auth = '/auth';
  static const String home = '/';
  static const String quizCreate = '/quiz/create';
  static const String friends = '/friends';
  static const String _quizPlay = '/quiz/:id';
  static const String _quizResult = '/quiz/:id/result';

  /// Concrete path to the quiz-play screen for [quizId].
  static String quizPlayPath(String quizId) => '/quiz/$quizId';

  /// Concrete path to the quiz-result screen for [quizId].
  static String quizResultPath(String quizId) => '/quiz/$quizId/result';

  static GoRouter routerWithRef(WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return GoRouter(
      initialLocation: home,
      // Redirect unauthenticated users to /auth, authenticated users
      // away from /auth to home.
      redirect: (context, state) {
        final isLoggedIn = authAsync.valueOrNull != null;
        final isOnAuth = state.matchedLocation == auth;

        if (!isLoggedIn && !isOnAuth) return auth;
        if (isLoggedIn && isOnAuth) return home;
        return null;
      },
      refreshListenable: _AuthListenable(ref),
      routes: [
        GoRoute(
          path: auth,
          builder: (context, state) => const AuthPage(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: quizCreate,
          builder: (context, state) => const QuizCreatePage(),
        ),
        GoRoute(
          path: friends,
          builder: (context, state) => const FriendsPage(),
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

  /// Fallback static router (used before ProviderScope is available).
  /// In practice [routerWithRef] is always used via [AppRouter.router].
  static final router = GoRouter(
    initialLocation: auth,
    routes: [
      GoRoute(
        path: auth,
        builder: (context, state) => const AuthPage(),
      ),
    ],
  );
}

/// Makes GoRouter re-evaluate its redirect when auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(WidgetRef ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
