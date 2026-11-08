import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/question.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Quiz result page in Anti-Design style.
///
/// Signature moves active on this screen:
///  (1) Accent-serif italic word inside the pass/fail stamp label.
///  (2) Circular sticker on score slab corner carrying the raw score.
///  (3) Tilted mono stamp (PASS / FAIL) at –5 deg.
///  (4) Decorative echo of "RESULT" clipped off right edge.
///  (5) Hairline crop ticks above the breakdown list.
///  (6) Neighbouring slabs of unequal width, height, indent.
///  (7) Gap swing — alternating tight and wide gaps throughout.
///
/// Breakdown item surfaces:
///   correct    → acid slab, ink text
///   wrong      → alarm slab, paper text
///   unanswered → bubblegum slab, ink text
class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({required this.quizId, super.key});

  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(quizPlayNotifierProvider);

    // Guard: if the state is not active (user navigated here directly or
    // state was reset), send them back home.
    if (playState is! QuizPlayActive) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(AppRouter.home));
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: AppColors.borderFrame,
              color: AppColors.ink,
            ),
          ),
        ),
      );
    }

    final quiz = playState.quiz;
    final answers = playState.answers;
    final scoreResult = ref
        .read(calculateQuizScoreProvider)
        .call(questions: quiz.questions, answers: answers);

    final passed = scoreResult.passed;
    final slabColor = passed ? AppColors.acid : AppColors.alarm;
    final slabTextColor = passed ? AppColors.ink : AppColors.paper;
    final percentStr = '${scoreResult.percent.toStringAsFixed(0)}%';

    final unansweredCount =
        quiz.questions.where((q) => !answers.containsKey(q.id)).length;
    final wrongCount =
        scoreResult.totalCount - scoreResult.correctCount - unansweredCount;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopStrip(title: quiz.title),
            // gap swing: tight between strip and score slab
            _ScoreSlab(
              slabColor: slabColor,
              slabTextColor: slabTextColor,
              percentStr: percentStr,
              passed: passed,
              correctCount: scoreResult.correctCount,
              totalCount: scoreResult.totalCount,
            ),
            // gap swing: tight between score slab and score bar
            _ScoreBar(
              correct: scoreResult.correctCount,
              wrong: wrongCount,
              unanswered: unansweredCount,
              total: scoreResult.totalCount,
            ),
            // gap swing: wide before section label
            const _SectionLabel(label: 'BREAKDOWN'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: quiz.questions.length,
                itemBuilder: (context, index) {
                  final q = quiz.questions[index];
                  final selected = answers[q.id];
                  final isCorrect = selected == q.correctIndex;
                  final unanswered = selected == null;
                  return _BreakdownItem(
                    index: index,
                    question: q,
                    selected: selected,
                    isCorrect: isCorrect,
                    unanswered: unanswered,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: FilledButton(
                onPressed: () {
                  ref.read(quizPlayNotifierProvider.notifier).reset();
                  context.go(AppRouter.home);
                },
                child: const Text('BACK TO HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top strip ──────────────────────────────────────────────────────────────

class _TopStrip extends StatelessWidget {
  const _TopStrip({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // Signature move 4: decorative "RESULT" echo clipped off right edge.
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: AppColors.ink, width: AppColors.borderRule),
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
                'RESULTS',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: AppColors.grid,
                ),
              ),
            ],
          ),
        ),
        // Echo — decorative, hidden from AT
        Positioned(
          right: -28,
          top: 2,
          child: ExcludeSemantics(
            child: Text(
              'RESULT',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                height: 1.0,
                color: AppColors.grid.withValues(alpha: 0.22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Score slab ─────────────────────────────────────────────────────────────

class _ScoreSlab extends StatelessWidget {
  const _ScoreSlab({
    required this.slabColor,
    required this.slabTextColor,
    required this.percentStr,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
  });

  final Color slabColor;
  final Color slabTextColor;
  final String percentStr;
  final bool passed;
  final int correctCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 4.5).clamp(AppColors.displayMin, AppColors.displayMax);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          color: slabColor,
          // gap swing: wide top padding, tight bottom
          padding: const EdgeInsets.fromLTRB(16, 28, 100, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tilted pass/fail stamp (signature move 3)
              _PassFailStamp(passed: passed, textColor: slabTextColor),
              // gap swing: tight
              const SizedBox(height: AppColors.gapTight),
              Text(
                percentStr,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: displaySize,
                  fontWeight: FontWeight.w800,
                  height: AppColors.displayLeading,
                  letterSpacing: -3.0,
                  color: slabTextColor,
                ),
              ),
              // gap swing: wide
              const SizedBox(height: 12),
              Container(
                height: AppColors.borderRule,
                color: slabTextColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                '$correctCount CORRECT  ·  $totalCount TOTAL',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: slabTextColor,
                ),
              ),
            ],
          ),
        ),
        // Sticker on right edge with correct count (signature move 2)
        Positioned(
          right: 12,
          top: 16,
          child: ExcludeSemantics(
            child: Container(
              width: AppColors.stickerSize,
              height: AppColors.stickerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(
                  color: slabTextColor,
                  width: AppColors.borderFrame,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$correctCount',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'RIGHT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pass/fail stamp ────────────────────────────────────────────────────────

/// Signature move 3: tilted at stamp angle.
/// Signature move 1: accent-serif italic on "Passed" / "Failed".
class _PassFailStamp extends StatelessWidget {
  const _PassFailStamp({required this.passed, required this.textColor});
  final bool passed;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: AppColors.angleStamp,
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border:
              Border.all(color: textColor, width: AppColors.borderRule),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              passed ? '✓ ' : '✗ ',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: textColor,
              ),
            ),
            // Accent-serif italic (signature move 1)
            Text(
              passed ? 'Passed' : 'Failed',
              style: GoogleFonts.instrumentSerif(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score bar ──────────────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
  });

  final int correct;
  final int wrong;
  final int unanswered;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return Semantics(
      label: '$correct correct, $wrong wrong, $unanswered unanswered '
          'out of $total questions.',
      child: Container(
        color: AppColors.paper,
        // gap swing: wide top, tight bottom
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  if (correct > 0)
                    _ScoreSegment(
                      flex: correct,
                      color: AppColors.acid,
                      isLast: wrong == 0 && unanswered == 0,
                    ),
                  if (wrong > 0)
                    _ScoreSegment(
                      flex: wrong,
                      color: AppColors.alarm,
                      isLast: unanswered == 0,
                    ),
                  if (unanswered > 0)
                    _ScoreSegment(
                      flex: unanswered,
                      color: AppColors.bubblegum,
                      isLast: true,
                    ),
                ],
              ),
            ),
            // gap swing: tight
            const SizedBox(height: AppColors.gapTight),
            Row(
              children: [
                if (correct > 0) ...[
                  _BarLegendItem(
                    color: AppColors.acid,
                    label: '$correct CORRECT',
                  ),
                  const SizedBox(width: 16),
                ],
                if (wrong > 0) ...[
                  _BarLegendItem(
                    color: AppColors.alarm,
                    label: '$wrong WRONG',
                  ),
                  const SizedBox(width: 16),
                ],
                if (unanswered > 0)
                  _BarLegendItem(
                    color: AppColors.bubblegum,
                    label: '$unanswered SKIPPED',
                  ),
              ],
            ),
            // gap swing: wide before hairline
            const SizedBox(height: 16),
            Container(height: AppColors.borderRule, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _ScoreSegment extends StatelessWidget {
  const _ScoreSegment({
    required this.flex,
    required this.color,
    required this.isLast,
  });

  final int flex;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.only(right: isLast ? 0 : 2),
        color: color,
      ),
    );
  }
}

class _BarLegendItem extends StatelessWidget {
  const _BarLegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              letterSpacing: 3.0,
              color: AppColors.grid,
            ),
          ),
          const SizedBox(width: 12),
          // Crop tick ornament (signature move 5)
          ExcludeSemantics(
            child: Row(
              children: [
                Container(width: 16, height: AppColors.borderRule, color: AppColors.grid),
                const SizedBox(width: 3),
                Container(width: 4, height: 4, color: AppColors.grid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown item ─────────────────────────────────────────────────────────

/// Each item alternates width/indent (signature move 6):
///   even index → full width
///   odd index  → 92% width, nudged right
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
    final screenW = MediaQuery.sizeOf(context).width;
    final indexStr = (index + 1).toString().padLeft(2, '0');

    final (bgColor, fgColor, monoLabel) = switch (true) {
      _ when isCorrect  => (AppColors.acid, AppColors.ink, '✓ CORRECT'),
      _ when unanswered => (AppColors.bubblegum, AppColors.ink, '— SKIPPED'),
      _                 => (AppColors.alarm, AppColors.paper, '✗ WRONG'),
    };

    String answerLine;
    if (unanswered) {
      answerLine = 'NOT ANSWERED';
    } else {
      answerLine =
          'YOU: ${String.fromCharCode(65 + selected!)}. ${question.options[selected!]}';
    }
    final correctLine =
        'CORRECT: ${String.fromCharCode(65 + question.correctIndex)}. '
        '${question.correctAnswer}';

    // Alternating width and indent for stagger rhythm (signature move 6/7)
    final isNarrow = index.isOdd;
    final cardWidth =
        isNarrow ? (screenW - 32) * 0.92 : double.infinity;
    final leftPad = isNarrow ? AppColors.nudge : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: index.isEven ? AppColors.nudge : AppColors.gapTight,
        left: leftPad,
      ),
      child: SizedBox(
        width: cardWidth,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: AppColors.ink,
              width: AppColors.borderRule,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    indexStr,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: fgColor.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    monoLabel,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppColors.gapTight),
              Text(
                question.text,
                style: GoogleFonts.instrumentSans(
                  fontSize: AppColors.bodySize,
                  height: AppColors.bodyLeading,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: AppColors.borderRule,
                color: fgColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppColors.gapTight),
              Text(
                answerLine,
                style: GoogleFonts.spaceMono(
                  fontSize: AppColors.labelSize,
                  letterSpacing: 0.3,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 4),
                Text(
                  correctLine,
                  style: GoogleFonts.spaceMono(
                    fontSize: AppColors.labelSize,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
