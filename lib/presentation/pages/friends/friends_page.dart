import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/presentation/providers/friend_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

/// Friends page — manage friendships and view friends' quiz progress.
///
/// Anti-Design signature moves:
///  (1) Accent-serif italic in the headline.
///  (3) Tilted stamp on section headers.
///  (5) Hairline crop ticks as dividers.
///  (6) Gap swing throughout.
///
/// Uses [AppTopStrip], [AppSectionLabel], [AppLoadingView], [AppErrorBanner]
/// from the shared widget library.
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(friendListProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    await ref.read(friendListProvider.notifier).sendRequest(email);
    _emailCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendListProvider);

    return Scaffold(
      backgroundColor: AppSurface.of(context).surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shared top strip ──────────────────────────────────────
            AppTopStrip(
              onBack: () => context.go(AppRouter.home),
              title: '03 FRIENDS',
            ),
            Expanded(
              child: state.loading
                  ? const AppLoadingView()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Headline(),
                                const SizedBox(height: AppColors.nudge * 2),
                                // Error banner
                                if (state.errorMessage != null) ...[
                                  AppErrorBanner(state.errorMessage!),
                                  const SizedBox(height: AppColors.nudge),
                                ],
                                // Add friend section
                                AppSectionLabel(
                                  label: 'ADD FRIEND',
                                  accentColor: AppColors.bubblegum,
                                ),
                                const SizedBox(height: AppColors.nudge),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FriendField(
                                        controller: _emailCtrl,
                                        hint: 'Friend\'s email',
                                      ),
                                    ),
                                    const SizedBox(width: AppColors.gapTight),
                                    GestureDetector(
                                      onTap: _sendRequest,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        color: AppColors.acid,
                                        child: Text(
                                          'SEND',
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppColors.nudge * 2),
                                AppSectionLabel(
                                  label: 'FRIENDS',
                                  accentColor: AppColors.bubblegum,
                                ),
                                const SizedBox(height: AppColors.nudge),
                              ],
                            ),
                          ),
                        ),
                        // Friend list
                        if (state.friends.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Text(
                                'NO FRIENDS YET.\nSEND A REQUEST ABOVE.',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: AppColors.displayLeading,
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList.builder(
                            itemCount: state.friends.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: _FriendCard(
                                entry: state.friends[i],
                                onAccept: () => ref
                                    .read(friendListProvider.notifier)
                                    .acceptRequest(
                                        state.friends[i].friendshipId),
                                onRemove: () => ref
                                    .read(friendListProvider.notifier)
                                    .removeFriend(
                                        state.friends[i].friendshipId),
                              ),
                            ),
                          ),
                        // Progress feed
                        if (state.scores.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: AppSectionLabel(
                                label: 'RECENT ACTIVITY',
                                accentColor: AppColors.bubblegum,
                              ),
                            ),
                          ),
                          SliverList.builder(
                            itemCount: state.scores.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: _ScoreCard(score: state.scores[i]),
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 48),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend field ───────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 6.0).clamp(AppColors.displayMin, AppColors.displayMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FRIENDS',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: displaySize,
            fontWeight: FontWeight.w800,
            height: AppColors.displayLeading,
            letterSpacing: -2.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          '& Progress',
          style: GoogleFonts.instrumentSerif(
            fontSize: displaySize * 0.85,
            fontStyle: FontStyle.italic,
            height: AppColors.displayLeading,
            letterSpacing: -1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Friend field ───────────────────────────────────────────────────────────

class _FriendField extends StatelessWidget {
  const _FriendField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.instrumentSans(
          fontSize: AppColors.bodySize, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.instrumentSans(
            fontSize: AppColors.bodySize, color: Theme.of(context).colorScheme.outlineVariant),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: AppColors.borderRule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: AppColors.borderFrame),
        ),
      ),
    );
  }
}

// ── Friend card ────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.entry,
    required this.onAccept,
    required this.onRemove,
  });

  final FriendEntry entry;
  final VoidCallback onAccept;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isPending = entry.status == FriendshipStatus.pending;
    final bgColor =
        isPending ? AppColors.bubblegum : Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border:
            Border.all(color: Theme.of(context).colorScheme.outline, width: AppColors.borderRule),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPending
                      ? (entry.isSentByMe
                          ? 'REQUEST SENT'
                          : 'WANTS TO BE FRIENDS')
                      : 'FRIEND',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          // Accept button (only for incoming pending requests)
          if (isPending && !entry.isSentByMe) ...[
            GestureDetector(
              onTap: onAccept,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                color: AppColors.acid,
                child: Text(
                  'ACCEPT',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppColors.gapTight),
          ],
          // Remove / cancel button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface, width: AppColors.borderRule),
              ),
              child: Text(
                isPending ? 'CANCEL' : 'REMOVE',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.alarm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score card ─────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final FriendScore score;

  @override
  Widget build(BuildContext context) {
    final bgColor = score.passed ? AppColors.acid : AppColors.alarm;
    final fgColor = score.passed ? c.ink : c.paper;
    final percentStr = '${score.percent.toStringAsFixed(0)}%';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border:
            Border.all(color: Theme.of(context).colorScheme.outline, width: AppColors.borderRule),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.displayName.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score.quizTitle,
                  style: GoogleFonts.instrumentSans(
                    fontSize: AppColors.bodySize,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percentStr,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: fgColor,
                ),
              ),
              Text(
                score.passed ? 'PASSED' : 'FAILED',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Headline (signature move 1) ────────────────────────────────────────────