import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/question.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Quiz play page in Anti-Design style.
///
/// Signature moves active on this screen:
///  (1) Giant question number nudged one token off-grid.
///  (2) Circular timer sticker carrying the live seconds value.
///  (3) Tilted mono stamp on the progress slab.
///  (5) Hairline crop ticks at question area boundary.
///  (6) Gap swing — alternating tight/wide gaps throughout.
///  (7) Slab neighbours of unequal height and indent (progress vs. timer).
///
/// Timer three-state color:
///   > 10 s  → acid (normal)
///   6–10 s  → volt / electric-blue inverted slab
///   ≤ 5 s   → alarm (urgent)
class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({required this.quizId, super.key});

  final String quizId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizPlayNotifierProvider.notifier).start(widget.quizId);
    });
  }

  /// Shows a confirmation dialog when the user tries to leave mid-quiz.
  /// Returns true to allow the pop, false to stay.
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(),
        title: Text(
          'QUIT QUIZ?',
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Your progress will be lost.',
          style: GoogleFonts.instrumentSans(
            fontSize: AppColors.bodySize,
            color: AppColors.ink,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('STAY'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('QUIT'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final playState = ref.watch(quizPlayNotifierProvider);

    // Error state — quiz id not found or data source failure.
    if (playState is QuizPlayError) {
      return _ErrorScaffold(
        message: playState.message,
        onRetry: () =>
            ref.read(quizPlayNotifierProvider.notifier).start(widget.quizId),
      );
    }

    // Still loading (initial state before start() resolves).
    if (playState is QuizPlayLoading) return const _LoadingScaffold();

    final active = playState as QuizPlayActive;

    if (active.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.replace(AppRouter.quizResultPath(widget.quizId));
      });
      return const _LoadingScaffold();
    }

    final question = active.quiz.questions[active.currentIndex];
    final total = active.quiz.questions.length;
    final currentQ = active.currentIndex + 1;
    final timerState = _timerStateFor(active.timeLeft);

    return PopScope(
      // Intercept back navigation while a quiz is in progress.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await _confirmExit();
        if (confirmed && context.mounted) {
          ref.read(quizPlayNotifierProvider.notifier).reset();
          context.go(AppRouter.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopStrip(
                title: active.quiz.title,
                current: currentQ,
                total: total,
              ),
              // gap swing: tight between strip and progress
              _ProgressSegments(current: currentQ, total: total),
              // gap swing: wide between progress and timer slab
              _TimerSlab(
                secondsLeft: active.timeLeft,
                totalSeconds: AppConstants.defaultQuestionTimeSeconds,
                timerState: timerState,
                currentQ: currentQ,
              ),
              // gap swing: tight between timer and question
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Giant question number nudged off-grid (signature move 1)
                      _QuestionNumber(
                        current: currentQ,
                        total: total,
                      ),
                      // gap swing: tight
                      const SizedBox(height: AppColors.gapTight),
                      _QuestionText(question: question),
                      // gap swing: wide before options
                      const SizedBox(height: AppColors.nudge * 2),
                      // Crop tick hairline (signature move 5)
                      _OptionsDivider(),
                      // gap swing: tight
                      const SizedBox(height: AppColors.nudge),
                      ...question.options.asMap().entries.map((entry) {
                        return _OptionButton(
                          index: entry.key,
                          text: entry.value,
                          onTap: () => ref
                              .read(quizPlayNotifierProvider.notifier)
                              .answer(entry.key),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TimerUrgency _timerStateFor(int seconds) {
    if (seconds <= 5) return _TimerUrgency.alarm;
    if (seconds <= 10) return _TimerUrgency.volt;
    return _TimerUrgency.normal;
  }
}

// ── Timer urgency enum ─────────────────────────────────────────────────────

enum _TimerUrgency { normal, volt, alarm }

// ── Top strip ──────────────────────────────────────────────────────────────

class _TopStrip extends StatelessWidget {
  const _TopStrip({
    required this.title,
    required this.current,
    required this.total,
  });

  final String title;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Text(
            '${current.toString().padLeft(2, '0')} / '
            '${total.toString().padLeft(2, '0')}',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: AppColors.ink,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress segments ──────────────────────────────────────────────────────

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Question $current of $total',
      child: SizedBox(
        height: 10,
        child: Row(
          children: List.generate(total, (i) {
            final filled = i < current;
            // Unequal flex — repeating 3/2/4 pattern.
            final flex = switch (i % 3) {
              0 => 3,
              1 => 2,
              _ => 4,
            };
            return Expanded(
              flex: flex,
              child: Container(
                margin: EdgeInsets.only(
                  right: i < total - 1 ? AppColors.borderRule * 2 : 0,
                ),
                color: filled ? AppColors.ink : AppColors.grid,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Timer slab ─────────────────────────────────────────────────────────────

/// Three visual states:
///   normal (>10 s)  → acid, ink text
///   volt   (6–10 s) → volt (electric blue), paper text
///   alarm  (≤ 5 s)  → alarm (orange-red), paper text
///
/// Carries a tilted stamp showing question index (signature move 3).
/// Circular sticker with live seconds is layered on the right (signature move 2).
class _TimerSlab extends StatelessWidget {
  const _TimerSlab({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.timerState,
    required this.currentQ,
  });

  final int secondsLeft;
  final int totalSeconds;
  final _TimerUrgency timerState;
  final int currentQ;

  @override
  Widget build(BuildContext context) {
    final (slabColor, textColor, stateLabel) = switch (timerState) {
      _TimerUrgency.normal => (AppColors.acid, AppColors.ink, 'TIME'),
      _TimerUrgency.volt   => (AppColors.volt, AppColors.paper, '!TIME'),
      _TimerUrgency.alarm  => (AppColors.alarm, AppColors.paper, '!!TIME'),
    };

    return Semantics(
      label: '$secondsLeft seconds remaining',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            color: slabColor,
            padding: const EdgeInsets.fromLTRB(16, 10, 100, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  stateLabel,
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    letterSpacing: 2.0,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
                // Tilted stamp — question number (signature move 3)
                ExcludeSemantics(
                  child: Transform.rotate(
                    angle: AppColors.angleStamp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.7),
                          width: AppColors.borderRule,
                        ),
                      ),
                      child: Text(
                        'Q${currentQ.toString().padLeft(2, '0')}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 60,
                  height: 4,
                  child: LinearProgressIndicator(
                    value: secondsLeft / totalSeconds,
                    backgroundColor: textColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ],
            ),
          ),
          // Circular sticker with live seconds (signature move 2)
          Positioned(
            right: 12,
            top: -AppColors.stickerSizeCompact / 3,
            child: ExcludeSemantics(
              child: Container(
                width: AppColors.stickerSizeCompact,
                height: AppColors.stickerSizeCompact,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slabColor,
                  border: Border.all(
                    color: textColor,
                    width: AppColors.borderFrame,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  secondsLeft.toString().padLeft(2, '0'),
                  style: GoogleFonts.spaceMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Options divider with crop ticks (signature move 5) ────────────────────

class _OptionsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          _tickMark(),
          Expanded(
            child: Container(
              height: AppColors.borderRule,
              color: AppColors.grid,
            ),
          ),
          _tickMark(),
        ],
      ),
    );
  }

  Widget _tickMark() {
    return SizedBox(
      width: 8,
      height: 8,
      child: CustomPaint(painter: _TickPainter()),
    );
  }
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grid
      ..strokeWidth = AppColors.borderRule
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Giant question number (signature move 1) ──────────────────────────────

/// The number is rendered very large and pushed nudge-px to the left of the
/// grid — the disorder token in action. Hidden from AT since the number is
/// spoken by the top strip's "01/03" counter.
class _QuestionNumber extends StatelessWidget {
  const _QuestionNumber({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.translate(
        offset: const Offset(-AppColors.nudge, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              current.toString().padLeft(2, '0'),
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                height: 0.9,
                letterSpacing: -3.0,
                color: AppColors.grid,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ ${total.toString().padLeft(2, '0')}',
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                color: AppColors.grid,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question text ──────────────────────────────────────────────────────────

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Text(
      question.text,
      style: GoogleFonts.instrumentSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      ),
    );
  }
}

// ── Option button ──────────────────────────────────────────────────────────

/// Flat ink-bordered slab with immediate invert on press/hover.
/// Keyboard: Enter/Space via Actions + ActivateIntent.
class _OptionButton extends StatefulWidget {
  const _OptionButton({
    required this.index,
    required this.text,
    required this.onTap,
  });

  final int index;
  final String text;
  final VoidCallback onTap;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _pressed = false;
  bool _hovered = false;

  String get _letter => String.fromCharCode(65 + widget.index);

  @override
  Widget build(BuildContext context) {
    final inverted = _pressed || _hovered;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.gapTight),
      child: Semantics(
        button: true,
        label: '$_letter. ${widget.text}',
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: Focus(
            child: Builder(builder: (ctx) {
              final focused = Focus.of(ctx).hasFocus;
              return GestureDetector(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() => _hovered = false),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: inverted ? AppColors.ink : AppColors.paper,
                      border: Border.all(
                        color: AppColors.ink,
                        width: focused
                            ? AppColors.borderFrame
                            : AppColors.borderRule,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_letter.',
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: inverted ? AppColors.paper : AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.text,
                            style: GoogleFonts.instrumentSans(
                              fontSize: AppColors.bodySize,
                              height: AppColors.bodyLeading,
                              color: inverted ? AppColors.paper : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Loading scaffold ───────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: AppColors.borderFrame,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LOADING...',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                letterSpacing: 2.0,
                color: AppColors.grid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error scaffold ─────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: AppColors.alarm,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ERROR',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.paper,
                      ),
                    ),
                    const SizedBox(height: AppColors.gapTight),
                    Text(
                      message,
                      style: GoogleFonts.instrumentSans(
                        fontSize: AppColors.bodySize,
                        color: AppColors.paper,
                        height: AppColors.bodyLeading,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('RETRY'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => context.go(AppRouter.home),
                    child: const Text('HOME'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
