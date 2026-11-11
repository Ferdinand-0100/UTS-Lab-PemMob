import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/core/services/sound_service.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/question.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({required this.quizId, super.key});
  final String quizId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  /// Index of the question that has been answered, or -1 if none yet.
  /// Using an index instead of a plain bool means it resets automatically
  /// when the question index advances to a new value.
  int _answeredIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizPlayNotifierProvider.notifier).start(widget.quizId);
    });
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.crtBg,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.btnRed, width: AppColors.borderFrame),
        ),
        title: PhosphorText('QUIT QUIZ?', fontSize: 12, fontWeight: FontWeight.w700),
        content: PhosphorText('PROGRESS WILL BE LOST.', fontSize: 9, dim: true),
        actions: [
          PixelButton(
            label: 'STAY',
            onPressed: () => Navigator.of(ctx).pop(false),
            color: AppColors.btnBlue,
            textColor: AppColors.shellLight,
            fontSize: 9,
          ),
          const SizedBox(width: 8),
          PixelButton(
            label: 'QUIT',
            onPressed: () => Navigator.of(ctx).pop(true),
            color: AppColors.btnRed,
            textColor: AppColors.shellLight,
            fontSize: 9,
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final playState = ref.watch(quizPlayNotifierProvider);

    if (playState is QuizPlayError) {
      return Scaffold(
        backgroundColor: AppShell.of(context).body,
        body: SafeArea(
          child: Column(
            children: [
              AppTopStrip(
                title: 'ERROR',
                onBack: () => context.crtNavigate(
                  label: 'RETURNING...',
                  onDone: () => context.go(AppRouter.home),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CrtScreen(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppErrorBanner(playState.message),
                        const SizedBox(height: 16),
                        PixelButton(
                          label: 'RETRY',
                          onPressed: () => ref
                              .read(quizPlayNotifierProvider.notifier)
                              .start(widget.quizId),
                          color: AppColors.btnMagenta,
                          textColor: AppColors.shellLight,
                          fullWidth: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (playState is QuizPlayLoading) {
      return Scaffold(
        backgroundColor: AppShell.of(context).body,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: const AppLoadingView(),
          ),
        ),
      );
    }

    final active = playState as QuizPlayActive;

    if (active.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.replace(AppRouter.quizResultPath(widget.quizId));
      });
      return Scaffold(
        backgroundColor: AppShell.of(context).body,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: const AppLoadingView(),
          ),
        ),
      );
    }

    final question = active.quiz.questions[active.currentIndex];
    final total = active.quiz.questions.length;
    final currentQ = active.currentIndex + 1;
    final isLow = active.timeLeft <= 10;
    final isCritical = active.timeLeft <= 5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await _confirmExit();
        if (confirmed && context.mounted) {
          ref.read(quizPlayNotifierProvider.notifier).reset();
          context.crtNavigate(
            label: 'RETURNING...',
            onDone: () => context.go(AppRouter.home),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppShell.of(context).body,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Shell top strip ----------------------------------
              _QuizTopStrip(
                title: active.quiz.title,
                current: currentQ,
                total: total,
              ),

              // -- Segmented progress bar ---------------------------
              PixelProgressBar(current: currentQ, total: total),

              // -- Timer strip on shell -----------------------------
              _TimerStrip(
                secondsLeft: active.timeLeft,
                total: AppConstants.defaultQuestionTimeSeconds,
                isLow: isLow,
                isCritical: isCritical,
              ),

              // -- CRT question screen ------------------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                  child: CrtScreen(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question number badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: AppColors.phosphorDim,
                              child: Text(
                                'Q${currentQ.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                                style: GoogleFonts.silkscreen(
                                  fontSize: 8,
                                  color: AppColors.crtBgDeep,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const BlinkingCursor(fontSize: 9),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Question text
                        PhosphorText(
                          question.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                        ),
                        const SizedBox(height: 14),
                        const PixelDivider(),
                        const SizedBox(height: 10),
                        // Options
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: question.options
                                  .asMap()
                                  .entries
                                  .map((e) => _OptionButton(
                                        index: e.key,
                                        text: e.value,
                                        locked: _answeredIndex == active.currentIndex,
                                        onAnswered: () => setState(
                                            () => _answeredIndex = active.currentIndex),
                                        onTap: () => ref
                                            .read(quizPlayNotifierProvider.notifier)
                                            .answer(e.key),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // -- Bottom shell spacer ------------------------------
              const _BottomShell(),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Quiz top strip -------------------------------------------------

class _QuizTopStrip extends StatelessWidget {
  const _QuizTopStrip({
    required this.title,
    required this.current,
    required this.total,
  });
  final String title;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final sh = AppShell.of(context);
    return Container(
      decoration: BoxDecoration(
        color: sh.strip,
        border: Border(
          bottom: BorderSide(color: sh.border, width: AppColors.borderFrame),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.silkscreen(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: sh.onShell,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.crtBg,
              border: Border.all(color: AppColors.phosphorDim, width: AppColors.borderRule),
            ),
            child: PhosphorText(
              '${current.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Timer strip ----------------------------------------------------

class _TimerStrip extends StatelessWidget {
  const _TimerStrip({
    required this.secondsLeft,
    required this.total,
    required this.isLow,
    required this.isCritical,
  });
  final int secondsLeft;
  final int total;
  final bool isLow;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final sh = AppShell.of(context);
    final Color timerColor = isCritical
        ? AppColors.btnRed
        : isLow
            ? AppColors.btnYellow
            : AppColors.phosphor;

    return Container(
      decoration: BoxDecoration(
        color: sh.strip,
        border: Border(
          bottom: BorderSide(color: sh.border, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            'TIME',
            style: GoogleFonts.silkscreen(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: sh.body,
            ),
          ),
          const SizedBox(width: 10),
          // Digital readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.crtBgDeep,
              border: Border.all(color: timerColor, width: AppColors.borderRule),
            ),
            child: Text(
              secondsLeft.toString().padLeft(2, '0'),
              style: GoogleFonts.silkscreen(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: timerColor,
                letterSpacing: 3.0,
                shadows: [
                  Shadow(
                    color: timerColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Progress fill bar
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.crtBgDeep,
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: secondsLeft / total,
                child: Container(color: timerColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Option button --------------------------------------------------
// Shows a 280ms flash in the button's accent color when tapped,
// then calls onTap to advance. Gives micro-feedback before the
// next question appears.

class _OptionButton extends ConsumerStatefulWidget {
  const _OptionButton({
    required this.index,
    required this.text,
    required this.onTap,
    required this.locked,
    required this.onAnswered,
  });
  final int index;
  final String text;
  final VoidCallback onTap;
  final bool locked;
  final VoidCallback onAnswered;

  @override
  ConsumerState<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends ConsumerState<_OptionButton> {
  bool _pressed = false;
  bool _flashing = false;

  String get _letter => String.fromCharCode(65 + widget.index);

  static const _colors = [
    AppColors.btnGreen,
    AppColors.btnBlue,
    AppColors.btnMagenta,
    AppColors.btnYellow,
  ];

  Color get _accent => _colors[widget.index % _colors.length];

  Future<void> _handleTap() async {
    if (_flashing || widget.locked) return;
    widget.onAnswered(); // lock all other buttons immediately
    setState(() => _flashing = true);

    // Pause the countdown while the answer flash is showing.
    ref.read(quizPlayNotifierProvider.notifier).pauseTimer();

    // Play sound immediately.
    ref.read(soundServiceProvider).playAnswer();

    // Hold the flash for 2 seconds so the player can see which they picked.
    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      setState(() => _flashing = false);
      // Resume isn't needed here � answer() cancels the timer and either
      // starts a fresh one for the next question or marks complete.
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _flashing ? _accent : AppColors.crtBgDeep;
    final textColor = _flashing ? AppColors.crtBgDeep : null; // null = use PhosphorText default

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '$_letter. ${widget.text}',
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) { if (!widget.locked) setState(() => _pressed = true); },
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            transform: _pressed && !_flashing
                ? (Matrix4.identity()..translate(0.0, 3.0))
                : Matrix4.identity(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Depth shadow (hidden while flashing)
                if (!_pressed && !_flashing)
                  Positioned(
                    left: 0, right: 0, bottom: -4,
                    child: Container(
                      height: 4,
                      color: Color.fromARGB(
                        255,
                        (_accent.red * 0.4).round(),
                        (_accent.green * 0.4).round(),
                        (_accent.blue * 0.4).round(),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: _accent, width: AppColors.borderRule),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        color: _accent,
                        child: Center(
                          child: Text(
                            _letter,
                            style: GoogleFonts.silkscreen(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.crtBgDeep,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _flashing
                            ? Text(
                                widget.text,
                                style: GoogleFonts.silkscreen(
                                  fontSize: 9,
                                  color: AppColors.crtBgDeep,
                                  height: 1.6,
                                  letterSpacing: 1.5,
                                ),
                              )
                            : PhosphorText(
                                widget.text,
                                fontSize: 9,
                                height: 1.6,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Bottom shell ---------------------------------------------------

class _BottomShell extends StatelessWidget {
  const _BottomShell();

  @override
  Widget build(BuildContext context) {
    final sh = AppShell.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: sh.body,
        border: Border(
          top: BorderSide(color: sh.border, width: AppColors.borderFrame),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TAP AN ANSWER TO CONTINUE',
            style: GoogleFonts.silkscreen(
              fontSize: 6,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: sh.strip,
            ),
          ),
        ],
      ),
    );
  }
}
