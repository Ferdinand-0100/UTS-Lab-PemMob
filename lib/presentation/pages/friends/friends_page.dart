import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/presentation/providers/friend_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

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
      backgroundColor: AppColors.shell,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shell top strip ──────────────────────────────────────
            AppTopStrip(
              onBack: () => context.crtNavigate(
                label: 'RETURNING...',
                onDone: () => context.go(AppRouter.home),
              ),
              title: 'FRIENDS',
            ),

            // ── CRT screen ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: CrtScreen(
                  padding: EdgeInsets.zero,
                  child: state.loading
                      ? const AppLoadingView()
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Screen title
                                    PhosphorText(
                                      'FRIENDS & PROGRESS',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    const SizedBox(height: 4),
                                    PhosphorText(
                                      'MANAGE YOUR PLAYER CONNECTIONS',
                                      fontSize: 7,
                                      dim: true,
                                    ),
                                    const SizedBox(height: 14),
                                    const PixelDivider(),
                                    const SizedBox(height: 12),

                                    // Error banner
                                    if (state.errorMessage != null) ...[
                                      AppErrorBanner(state.errorMessage!),
                                      const SizedBox(height: 10),
                                    ],

                                    // Add friend
                                    AppSectionLabel(
                                      label: 'ADD FRIEND',
                                      accentColor: AppColors.btnBlue,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ConsoleTextField(
                                            controller: _emailCtrl,
                                            hint: "Friend's email",
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PixelButton(
                                          label: 'SEND',
                                          onPressed: _sendRequest,
                                          color: AppColors.btnMagenta,
                                          textColor: AppColors.shellLight,
                                          fontSize: 9,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Friends section header
                                    AppSectionLabel(
                                      label: 'FRIENDS LIST',
                                      accentColor: AppColors.btnBlue,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),

                            // Friend list
                            if (state.friends.isEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Center(
                                    child: PhosphorText(
                                      'NO FRIENDS YET.\nSEND A REQUEST ABOVE.',
                                      fontSize: 9,
                                      dim: true,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverList.builder(
                                itemCount: state.friends.length,
                                itemBuilder: (context, i) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 0, 12, 8),
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

                            // Activity feed — hidden, pass counts
                            // are shown per friend card instead.

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 24),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // ── Bottom shell strip ───────────────────────────────────
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.shell,
                border: Border(
                  top: BorderSide(
                      color: AppColors.outline, width: AppColors.borderFrame),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend card ────────────────────────────────────────────────────

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
    final borderColor = isPending ? AppColors.btnYellow : AppColors.phosphorDim;
    final isAccepted = entry.status == FriendshipStatus.accepted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.crtBgDeep,
        border: Border.all(color: borderColor, width: AppColors.borderRule),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status LED
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isPending ? AppColors.btnYellow : AppColors.phosphor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (isPending
                              ? AppColors.btnYellow
                              : AppColors.phosphor)
                          .withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhosphorText(
                      entry.displayName.toUpperCase(),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 2),
                    PhosphorText(
                      isPending
                          ? (entry.isSentByMe
                              ? 'REQUEST SENT'
                              : 'WANTS TO CONNECT')
                          : 'CONNECTED',
                      fontSize: 7,
                      dim: true,
                    ),
                  ],
                ),
              ),
              // Accept button for incoming pending
              if (isPending && !entry.isSentByMe) ...[
                PixelButton(
                  label: 'ACCEPT',
                  onPressed: onAccept,
                  color: AppColors.btnGreen,
                  textColor: AppColors.shellLight,
                  fontSize: 7,
                  depth: 3,
                ),
                const SizedBox(width: 6),
              ],
              // Remove/cancel
              PixelButton(
                label: isPending ? 'CANCEL' : 'REMOVE',
                onPressed: onRemove,
                color: AppColors.btnRed,
                textColor: AppColors.shellLight,
                fontSize: 7,
                depth: 3,
              ),
            ],
          ),

          // ── Quiz pass count bar (accepted friends only) ──────────
          if (isAccepted && entry.totalQuizCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: AppColors.phosphorDim.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 6),
            _QuizPassBar(
              passed: entry.passedQuizCount,
              total: entry.totalQuizCount,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quiz pass bar ──────────────────────────────────────────────────

class _QuizPassBar extends StatelessWidget {
  const _QuizPassBar({required this.passed, required this.total});
  final int passed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allPassed = passed == total;
    final barColor = allPassed ? AppColors.phosphor : AppColors.btnYellow;

    return Row(
      children: [
        PhosphorText('QUIZZES', fontSize: 6, dim: true),
        const SizedBox(width: 6),
        // Block segments: one per quiz, filled = passed
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              final isFilled = i < passed;
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < total - 1 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: isFilled ? barColor : AppColors.crtBg,
                    border: Border.all(
                      color: isFilled
                          ? barColor
                          : AppColors.phosphorDim.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        // e.g.  2/3
        Text(
          '$passed/$total',
          style: GoogleFonts.silkscreen(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: barColor,
            shadows: [
              Shadow(
                color: barColor.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// (Score card removed — pass counts are shown per friend card instead.)
