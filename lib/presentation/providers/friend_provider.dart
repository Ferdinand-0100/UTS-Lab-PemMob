import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

enum FriendshipStatus { pending, accepted }

class FriendEntry {
  const FriendEntry({
    required this.friendshipId,
    required this.userId,
    required this.displayName,
    required this.status,
    required this.isSentByMe,
  });

  final String friendshipId;
  final String userId;
  final String displayName;
  final FriendshipStatus status;
  final bool isSentByMe;
}

class FriendScore {
  const FriendScore({
    required this.displayName,
    required this.quizTitle,
    required this.percent,
    required this.passed,
    required this.createdAt,
  });

  final String displayName;
  final String quizTitle;
  final double percent;
  final bool passed;
  final DateTime createdAt;
}

// ---------------------------------------------------------------------------
// Friend list notifier
// ---------------------------------------------------------------------------

class FriendListState {
  const FriendListState({
    this.friends = const [],
    this.scores = const [],
    this.loading = false,
    this.errorMessage,
  });

  final List<FriendEntry> friends;
  final List<FriendScore> scores;
  final bool loading;
  final String? errorMessage;

  FriendListState copyWith({
    List<FriendEntry>? friends,
    List<FriendScore>? scores,
    bool? loading,
    String? errorMessage,
  }) =>
      FriendListState(
        friends: friends ?? this.friends,
        scores: scores ?? this.scores,
        loading: loading ?? this.loading,
        errorMessage: errorMessage,
      );
}

class FriendListNotifier extends StateNotifier<FriendListState> {
  FriendListNotifier(this._client, this._ref)
      : super(const FriendListState());

  final SupabaseClient _client;
  final Ref _ref;

  Future<void> load() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = state.copyWith(loading: true, errorMessage: null);
    try {
      // Fetch friendships where I am either side.
      final rows = await _client
          .from('friendships')
          .select('id, user_id, friend_id, status, profiles!friendships_friend_id_fkey(display_name), sender:profiles!friendships_user_id_fkey(display_name)')
          .or('user_id.eq.${user.id},friend_id.eq.${user.id}');

      final friends = <FriendEntry>[];
      for (final row in rows) {
        final isSentByMe = row['user_id'] as String == user.id;
        final otherId = isSentByMe
            ? row['friend_id'] as String
            : row['user_id'] as String;
        final otherProfile = isSentByMe
            ? row['profiles'] as Map<String, dynamic>?
            : row['sender'] as Map<String, dynamic>?;
        final displayName =
            otherProfile?['display_name'] as String? ?? 'Unknown';
        final statusStr = row['status'] as String;

        friends.add(FriendEntry(
          friendshipId: row['id'] as String,
          userId: otherId,
          displayName: displayName,
          status: statusStr == 'accepted'
              ? FriendshipStatus.accepted
              : FriendshipStatus.pending,
          isSentByMe: isSentByMe,
        ));
      }

      // Fetch recent scores for accepted friends.
      final acceptedIds = friends
          .where((f) => f.status == FriendshipStatus.accepted)
          .map((f) => f.userId)
          .toList();

      final scores = <FriendScore>[];
      if (acceptedIds.isNotEmpty) {
        final scoreRows = await _client
            .from('scores')
            .select('percent, correct, total, created_at, quiz_id, profiles(display_name), quizzes(title, passing_score)')
            .inFilter('user_id', acceptedIds)
            .order('created_at', ascending: false)
            .limit(50);

        for (final row in scoreRows) {
          final profile = row['profiles'] as Map<String, dynamic>?;
          final quiz = row['quizzes'] as Map<String, dynamic>?;
          final percent = (row['percent'] as num).toDouble();
          final passingScore =
              (quiz?['passing_score'] as num?)?.toDouble() ?? 60.0;
          scores.add(FriendScore(
            displayName: profile?['display_name'] as String? ?? 'Unknown',
            quizTitle: quiz?['title'] as String? ?? 'Unknown Quiz',
            percent: percent,
            passed: percent >= passingScore,
            createdAt: DateTime.parse(row['created_at'] as String),
          ));
        }
      }

      state = state.copyWith(
        friends: friends,
        scores: scores,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Failed to load friends.',
      );
    }
  }

  Future<void> sendRequest(String email) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Clear any previous error before attempting
    state = state.copyWith(errorMessage: null);

    try {
      final results = await _client
          .from('profiles')
          .select('id, display_name')
          .eq('email', email.toLowerCase().trim())
          .limit(1);

      if (results.isEmpty) {
        state = state.copyWith(
          errorMessage:
              'No user found with that email. Make sure the email is correct and the user has registered.',
        );
        return;
      }

      final targetId = results.first['id'] as String;
      if (targetId == user.id) {
        state = state.copyWith(errorMessage: 'You cannot add yourself.');
        return;
      }

      await _client.from('friendships').insert({
        'user_id': user.id,
        'friend_id': targetId,
        'status': 'pending',
      });

      await load();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        state = state.copyWith(
            errorMessage: 'A friend request with this user already exists.');
      } else {
        state = state.copyWith(
            errorMessage: 'Could not send request: ${e.message}');
      }
    } catch (_) {
      state = state.copyWith(errorMessage: 'Could not send request.');
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    try {
      await _client
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', friendshipId);
      await load();
    } catch (_) {
      state = state.copyWith(errorMessage: 'Could not accept request.');
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      await _client.from('friendships').delete().eq('id', friendshipId);
      await load();
    } catch (_) {
      state = state.copyWith(errorMessage: 'Could not remove friend.');
    }
  }
}

final friendListProvider =
    StateNotifierProvider.autoDispose<FriendListNotifier, FriendListState>(
  (ref) => FriendListNotifier(ref.read(supabaseClientProvider), ref),
);
