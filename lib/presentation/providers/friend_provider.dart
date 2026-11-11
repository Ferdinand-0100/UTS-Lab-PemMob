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
    this.passedQuizCount = 0,
    this.totalQuizCount = 0,
  });

  final String friendshipId;
  final String userId;
  final String displayName;
  final FriendshipStatus status;
  final bool isSentByMe;

  /// Number of distinct quizzes this friend has passed at least once.
  final int passedQuizCount;

  /// Total distinct quizzes this friend has attempted.
  final int totalQuizCount;
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
      // ── 1. Fetch all friendships involving me ──────────────────────
      // Use a simple select without FK joins to avoid alias mismatches.
      final rows = await _client
          .from('friendships')
          .select('id, user_id, friend_id, status')
          .or('user_id.eq.${user.id},friend_id.eq.${user.id}');

      if (rows.isEmpty) {
        state = state.copyWith(friends: [], scores: [], loading: false);
        return;
      }

      // Collect all "other" user IDs so we can batch-fetch their names.
      final otherIds = <String>{};
      for (final row in rows) {
        final isSentByMe = row['user_id'] as String == user.id;
        otherIds.add(isSentByMe
            ? row['friend_id'] as String
            : row['user_id'] as String);
      }

      // ── 2. Batch-fetch display names for all other users ───────────
      final profileRows = await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', otherIds.toList());

      final nameById = <String, String>{
        for (final p in profileRows)
          p['id'] as String: p['display_name'] as String? ?? 'Unknown',
      };

      final friends = <FriendEntry>[];
      for (final row in rows) {
        final isSentByMe = row['user_id'] as String == user.id;
        final otherId = isSentByMe
            ? row['friend_id'] as String
            : row['user_id'] as String;
        final statusStr = row['status'] as String;

        friends.add(FriendEntry(
          friendshipId: row['id'] as String,
          userId: otherId,
          displayName: nameById[otherId] ?? 'Unknown',
          status: statusStr == 'accepted'
              ? FriendshipStatus.accepted
              : FriendshipStatus.pending,
          isSentByMe: isSentByMe,
        ));
      }

      // ── 3. Fetch scores for accepted friends ───────────────────────
      final acceptedFriendIds = friends
          .where((f) => f.status == FriendshipStatus.accepted)
          .map((f) => f.userId)
          .toList();

      final Map<String, int> passedMap = {};
      final Map<String, int> totalMap  = {};

      if (acceptedFriendIds.isNotEmpty) {
        // Fetch scores + quiz passing_score in one join.
        final scoreRows = await _client
            .from('scores')
            .select('user_id, quiz_id, percent, quizzes(passing_score)')
            .inFilter('user_id', acceptedFriendIds);

        final Set<String> seenAttempts = {};
        final Set<String> seenPassed   = {};

        for (final row in scoreRows) {
          final userId  = row['user_id'] as String;
          final quizId  = row['quiz_id'] as String;
          final percent = (row['percent'] as num).toDouble();
          final quiz    = row['quizzes'] as Map<String, dynamic>?;
          final passing = (quiz?['passing_score'] as num?)?.toDouble() ?? 60.0;
          final passed  = percent >= passing;

          final attemptKey = '$userId:$quizId';
          if (!seenAttempts.contains(attemptKey)) {
            seenAttempts.add(attemptKey);
            totalMap[userId] = (totalMap[userId] ?? 0) + 1;
          }
          if (passed) {
            if (!seenPassed.contains(attemptKey)) {
              seenPassed.add(attemptKey);
              passedMap[userId] = (passedMap[userId] ?? 0) + 1;
            }
          }
        }
      }

      // ── 4. Enrich friends with pass counts ─────────────────────────
      final enrichedFriends = friends.map((f) => FriendEntry(
            friendshipId:    f.friendshipId,
            userId:          f.userId,
            displayName:     f.displayName,
            status:          f.status,
            isSentByMe:      f.isSentByMe,
            passedQuizCount: passedMap[f.userId] ?? 0,
            totalQuizCount:  totalMap[f.userId]  ?? 0,
          )).toList();

      state = state.copyWith(
        friends: enrichedFriends,
        scores:  const [],   // feed removed — counts shown per card
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
              'No user found with that email. '
              'Make sure the email is correct and the user has registered.',
        );
        return;
      }

      final targetId = results.first['id'] as String;
      if (targetId == user.id) {
        state = state.copyWith(errorMessage: 'You cannot add yourself.');
        return;
      }

      await _client.from('friendships').insert({
        'user_id':   user.id,
        'friend_id': targetId,
        'status':    'pending',
      });

      await load();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        state = state.copyWith(
          errorMessage:
              'A friend request with this user already exists.',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Could not send request: ${e.message}',
        );
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
