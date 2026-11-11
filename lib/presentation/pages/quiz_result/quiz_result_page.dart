import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/question.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/providers/score_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

class QuizResultPage extends ConsumerStatefulWidget {
  const QuizResultPage({required this.quizId, super.key});
  final String quizId;

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  bool _scoreSaved = false;

  @override
  Widget build(BuildContext context) {
    final playState = ref.watch(quizPlayNotifierProvider);

    if (playState is! QuizPlayActive) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(AppRouter.home));
      return Scaffold(
        backgroundColor: AppColors.shell,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: const AppLoadingView(),
        ),
      );
    }

    final quiz = playState.quiz;
    final answers = playState.answers;
    final scoreResult = ref
        .read(calculateQuizScoreProvider)
        .call(questions: quiz.questions, answers: answers);

    if (!_scoreSaved) {
      _scoreSaved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(scoreNotifierProvider.notifier).saveScore(
              quizId: widget.quizId,
              correct: scoreResult.correctCount,
              total: scoreResult.totalCount,
              percent: scoreResult.percent,
            );
      });
    }

    final passed = scoreResult.passed;
    final percentStr = '${scoreResult.percent.toStringAsFixed(0)}%';
    final unansweredCount =
        quiz.questions.where((q) => !answers.containsKey(q.id)).length;
    final wrongCount =
        scoreResult.totalCount - scoreResult.correctCount - unansweredCount;

    return Scaffold(
      backgroundColor: AppColors.shell,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shell top strip ──────────────────────────────────────
            _ResultTopStrip(title: quiz.title),

            // ── Score panel on shell ─────────────────────────────────
            _ScorePanel(
              passed: passed,
              percentStr: percentStr,
              correct: scoreResult.correctCount,
              total: scoreResult.totalCount,
              wrong: wrongCount,
              unanswered: unansweredCount,
              rawPercent: scoreResult.percent,
            ),

            // ── CRT breakdown screen ─────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: CrtScreen(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: AppColors.phosphorDim,
                                width: AppColors.borderRule),
                          ),
                        ),
                        child: PhosphorText(
                          'BREAKDOWN',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          itemCount: quiz.questions.length,
                          itemBuilder: (context, i) {
                            final q = quiz.questions[i];
                            final selected = answers[q.id];
                            return _BreakdownItem(
                              index: i,
                              question: q,
                              selected: selected,
                              isCorrect: selected == q.correctIndex,
                              unanswered: selected == null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom action strip ──────────────────────────────────
            _BottomActionStrip(
      onHome: () {
                ref.read(quizPlayNotifierProvider.notifier).reset();
                context.crtNavigate(
                  label: 'RETURNING HOME...',
                  onDone: () => context.go(AppRouter.home),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result top strip ───────────────────────────────────────────────

class _ResultTopStrip extends StatelessWidget {
  const _ResultTopStrip({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.shellDark,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: AppColors.borderFrame),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ShellText(title.toUpperCase(), fontSize: 8, color: AppColors.shellLight),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: AppColors.phosphorDim,
            child: Text(
              'RESULTS',
              style: GoogleFonts.silkscreen(
                fontSize: 7,
                color: AppColors.crtBgDeep,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score panel ────────────────────────────────────────────────────

class _ScorePanel extends StatefulWidget {
  const _ScorePanel({
    required this.passed,
    required this.percentStr,
    required this.correct,
    required this.total,
    required this.wrong,
    required this.unanswered,
    required this.rawPercent,
  });
  final bool passed;
  final String percentStr;
  final int correct;
  final int total;
  final int wrong;
  final int unanswered;
  final double rawPercent;

  @override
  State<_ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<_ScorePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _counter;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _counter = Tween<double>(begin: 0, end: widget.rawPercent).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Small delay so the screen is visible before counting starts
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = widget.passed ? AppColors.btnGreen : AppColors.btnRed;
    final shadowColor = widget.passed
        ? const Color(0xFF0A2007)
        : const Color(0xFF8B1A0A);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.crtBgDeep,
        border: Border(
          top: const BorderSide(color: AppColors.outline, width: AppColors.borderRule),
          bottom: BorderSide(color: panelColor, width: AppColors.borderFrame),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, AppColors.btnDepth),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pass/fail stamp
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: panelColor, width: AppColors.borderRule),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.passed ? '■ ' : '✕ ',
                        style: GoogleFonts.silkscreen(fontSize: 9, color: panelColor),
                      ),
                      Text(
                        widget.passed ? 'PASSED' : 'FAILED',
                        style: GoogleFonts.silkscreen(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: panelColor,
                          shadows: [
                            Shadow(color: panelColor.withValues(alpha: 0.5), blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Animated percent counter
                AnimatedBuilder(
                  animation: _counter,
                  builder: (_, __) {
                    return Text(
                      '${_counter.value.toStringAsFixed(0)}%',
                      style: GoogleFonts.silkscreen(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: panelColor,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: panelColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                PhosphorText(
                  '${widget.correct} CORRECT  /  ${widget.total} TOTAL',
                  fontSize: 8,
                  dim: true,
                ),
              ],
            ),
          ),
          // Score tally column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TallyRow(label: 'CORRECT', value: widget.correct, color: AppColors.phosphor),
              const SizedBox(height: 4),
              _TallyRow(label: 'WRONG', value: widget.wrong, color: AppColors.btnRed),
              const SizedBox(height: 4),
              _TallyRow(label: 'SKIPPED', value: widget.unanswered, color: AppColors.btnYellow),
            ],
          ),
        ],
      ),
    );
  }
}

class _TallyRow extends StatelessWidget {
  const _TallyRow({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.silkscreen(
              fontSize: 7, color: AppColors.phosphorDim, letterSpacing: 1.0),
        ),
        const SizedBox(width: 6),
        Container(
          width: 28,
          padding: const EdgeInsets.symmetric(vertical: 2),
          color: color.withValues(alpha: 0.15),
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
          ),
          child: Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              style: GoogleFonts.silkscreen(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Breakdown item ─────────────────────────────────────────────────

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.index,
    required this.question,
    required this.selected,
    required this.isCorrect,
    required this.unanswered,
  });
  final int index;
  final Question question;
  final int? selected;
  final bool isCorrect;
  final bool unanswered;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final String monoLabel;

    if (isCorrect) {
      borderColor = AppColors.phosphor;
      monoLabel = '■ CORRECT';
    } else if (unanswered) {
      borderColor = AppColors.btnYellow;
      monoLabel = '— SKIPPED';
    } else {
      borderColor = AppColors.btnRed;
      monoLabel = '✕ WRONG';
    }

    final answerLine = unanswered
        ? 'NOT ANSWERED'
        : 'YOU: ${String.fromCharCode(65 + selected!)}.  ${question.options[selected!]}';
    final correctLine =
        'ANS: ${String.fromCharCode(65 + question.correctIndex)}.  ${question.correctAnswer}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.crtBgDeep,
          border: Border.all(color: borderColor, width: AppColors.borderRule),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Q${(index + 1).toString().padLeft(2, '0')}',
                  style: GoogleFonts.silkscreen(
                      fontSize: 8,
                      color: borderColor.withValues(alpha: 0.6),
                      letterSpacing: 1.0),
                ),
                const Spacer(),
                Text(
                  monoLabel,
                  style: GoogleFonts.silkscreen(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                    shadows: [
                      Shadow(
                          color: borderColor.withValues(alpha: 0.5),
                          blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PhosphorText(
              question.text,
              fontSize: 9,
              height: 1.5,
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: borderColor.withValues(alpha: 0.3)),
            const SizedBox(height: 6),
            PhosphorText(answerLine, fontSize: 8, dim: true),
            if (!isCorrect) ...[
              const SizedBox(height: 4),
              Text(
                correctLine,
                style: GoogleFonts.silkscreen(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.phosphor,
                  letterSpacing: 1.0,
                  shadows: const [
                    Shadow(color: AppColors.phosphorDim, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom action strip ────────────────────────────────────────────

class _BottomActionStrip extends StatelessWidget {
  const _BottomActionStrip({required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.shell,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: AppColors.borderFrame),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: PixelButton(
        label: '< BACK TO HOME',
        onPressed: onHome,
        color: AppColors.btnMagenta,
        textColor: AppColors.shellLight,
        fullWidth: true,
        fontSize: 10,
      ),
    );
  }
}
