import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';

/// Saves a completed quiz score to the `scores` table in Supabase.
///
/// Uses autoDispose so it doesn't linger after the result page is popped.
class ScoreNotifier extends StateNotifier<AsyncValue<void>> {
  ScoreNotifier(this._client, this._ref)
      : super(const AsyncValue.data(null));

  final SupabaseClient _client;
  final Ref _ref;

  Future<void> saveScore({
    required String quizId,
    required int correct,
    required int total,
    required double percent,
  }) async {
    // Don't double-save
    if (state is AsyncLoading) return;

    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _client.from('scores').insert({
        'user_id': user.id,
        'quiz_id': quizId,
        'correct': correct,
        'total': total,
        'percent': percent,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // Saving a score is a best-effort operation — don't block the UI.
      state = AsyncValue.error(e, st);
    }
  }
}

final scoreNotifierProvider =
    StateNotifierProvider.autoDispose<ScoreNotifier, AsyncValue<void>>(
  (ref) => ScoreNotifier(ref.read(supabaseClientProvider), ref),
);
