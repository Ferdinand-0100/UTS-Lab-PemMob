import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Home page: lists available quizzes in Anti-Design style.
///
/// Signature moves active on this screen:
///  (1) One accent-serif italic word inside the headline.
///  (2) Circular sticker overlapping the headline slab corner with quiz count.
///  (3) Tilted mono stamp at –5 deg.
///  (4) Decorative echo of "QUIZ" clipped by edge.
///  (5) Visible hairline grid guides / crop ticks.
///  (6) Gap swing — consecutive gaps alternate tight/wide.
///  (7) Neighbouring slabs of unequal width/indent.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _slabColors = [
    AppColors.alarm,
    AppColors.bubblegum,
    AppColors.acid,
  ];

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loaded) return;
      ref.read(quizPlayNotifierProvider.notifier).reset();
      ref.read(homeNotifierProvider.notifier).load();
      // Rebuild so the "not loaded yet" loading view hands over to real state.
      setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);

    final Widget content;
    if (!_loaded || state.loading) {
      // FIX: before the first post-frame load() the initial state would
      // otherwise render _EmptyView for one frame.
      content = const _LoadingView();
    } else if (state.errorMessage != null) {
      content = _ErrorView(
        message: state.errorMessage!,
        onRetry: () {
          ref.read(homeNotifierProvider.notifier).load();
        },
      );
    } else if (state.quizzes.isEmpty) {
      content = const _EmptyView();
    } else {
      content = _QuizList(quizzes: state.quizzes, slabColors: _slabColors);
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(child: content),
    );
  }
}

// ── Nav strip ──────────────────────────────────────────────────────────────

class _MonoNavStrip extends StatelessWidget {
  const _MonoNavStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            'QUIZ MASTER',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          const _MonoNavItem(index: '01', label: 'HOME'),
        ],
      ),
    );
  }
}

class _MonoNavItem extends StatelessWidget {
  const _MonoNavItem({required this.index, required this.label});
  final String index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$index ',
            style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.grid),
          ),
          TextSpan(
            text: label,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Headline slab ──────────────────────────────────────────────────────────

class _HeadlineSlab extends StatelessWidget {
  const _HeadlineSlab({required this.quizCount});
  final int quizCount;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 5.2).clamp(AppColors.displayMin, AppColors.displayMax);

    return Container(
      width: double.infinity,
      color: AppColors.paper,
      // gap swing: wide top, tight bottom
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── decorative echo — "QUIZ" clipped off right edge (signature move 4)
          Positioned(
            right: -displaySize * 0.28,
            top: 0,
            child: ExcludeSemantics(
              child: Text(
                'QUIZ',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: displaySize * 1.1,
                  fontWeight: FontWeight.w800,
                  height: AppColors.displayLeading,
                  letterSpacing: -2.0,
                  color: AppColors.grid.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
          // ── main content
          screenW < 600
              ? _headlineStack(displaySize)
              : _headlineRow(displaySize),
        ],
      ),
    );
  }

  Widget _headlineStack(double displaySize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _displayText(displaySize),
        // gap swing: wide
        // FIX: `~/` returns int, which is not assignable to SizedBox.height
        // (double). Use `/` so the value stays a double.
        const SizedBox(height: AppColors.gapWide / 4),
        _factsColumn(),
      ],
    );
  }

  Widget _headlineRow(double displaySize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(flex: 3, child: _displayText(displaySize)),
        const SizedBox(width: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: AppColors.nudge),
          child: _factsColumn(),
        ),
      ],
    );
  }

  /// Signature move 1: accent-serif italic on "MASTER"
  Widget _displayText(double displaySize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'QUIZ',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: displaySize,
            fontWeight: FontWeight.w800,
            height: AppColors.displayLeading,
            letterSpacing: -2.0,
            color: AppColors.ink,
          ),
        ),
        // Accent serif italic — the one exception word (signature move 1)
        Text(
          'Master',
          style: GoogleFonts.instrumentSerif(
            fontSize: displaySize * 0.95,
            fontStyle: FontStyle.italic,
            height: AppColors.displayLeading,
            letterSpacing: -1.5,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _factsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _monoFact('QUIZZES', '$quizCount AVAILABLE'),
        const SizedBox(height: AppColors.gapTight),
        _monoFact('FORMAT', 'TIMED · MCQ'),
        const SizedBox(height: AppColors.gapTight),
        _monoFact('PASS', '60%'),
      ],
    );
  }

  Widget _monoFact(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            color: AppColors.grid,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// ── Circular sticker (signature move 2) ───────────────────────────────────

/// Decorative sticker overlapping the headline/accent-strip boundary.
/// Carries the quiz count — a real existing value, not a new claim.
/// Hidden from AT as it duplicates the mono fact already announced.
class _CountSticker extends StatelessWidget {
  const _CountSticker({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppColors.stickerSize,
        height: AppColors.stickerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bubblegum,
          border: Border.all(color: AppColors.ink, width: AppColors.borderRule),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: AppColors.ink,
              ),
            ),
            Text(
              'QUIZZES',
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
    );
  }
}

// ── Accent strip with sticker overlap ─────────────────────────────────────

class _AccentStripWithSticker extends StatelessWidget {
  const _AccentStripWithSticker({required this.quizCount});
  final int quizCount;

  @override
  Widget build(BuildContext context) {
    // gap swing: tight above this, wide below
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.acid,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                'SELECT A QUIZ TO BEGIN',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              // Tilted mono stamp (signature move 3)
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
                        color: AppColors.ink,
                        width: AppColors.borderRule,
                      ),
                    ),
                    child: Text(
                      'BEGIN ->',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sticker overlapping top-right corner of the acid strip (signature move 2)
        Positioned(
          top: -(AppColors.stickerSize / 3),
          right: 16,
          child: _CountSticker(count: quizCount),
        ),
      ],
    );
  }
}

// ── Crop tick ornaments (signature move 5) ────────────────────────────────

class _CropTicks extends StatelessWidget {
  const _CropTicks();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _cropTick(),
            _cropTick(),
            _cropTick(),
            _cropTick(),
          ],
        ),
      ),
    );
  }

  Widget _cropTick() {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(painter: _CropTickPainter()),
    );
  }
}

class _CropTickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grid
      ..strokeWidth = AppColors.borderRule
      ..style = PaintingStyle.stroke;
    // Horizontal arm
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width * 0.4, size.height / 2),
      paint,
    );
    // Vertical arm
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Hairline grid guide ────────────────────────────────────────────────────

class _GridGuide extends StatelessWidget {
  const _GridGuide({this.paddingH = 16.0});
  final double paddingH;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH),
        child: Container(
          height: AppColors.borderRule,
          color: AppColors.grid,
        ),
      ),
    );
  }
}

// ── Quiz card ──────────────────────────────────────────────────────────────

/// Alternating width + indent (signature move 7) and immediate invert.
/// Keyboard accessible via Actions + ActivateIntent.
class _QuizCard extends StatefulWidget {
  const _QuizCard({
    super.key,
    required this.quiz,
    required this.index,
    required this.slabColor,
    required this.nudgeRight,
    required this.widthFactor,
  });

  final Quiz quiz;
  final int index;
  final Color slabColor;
  final bool nudgeRight;
  final double widthFactor; // 1.0, 0.84, or 0.92

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _navigate() {
    context.push(AppRouter.quizPlayPath(widget.quiz.id));
  }

  @override
  Widget build(BuildContext context) {
    // gap swing: even index gets wide gap above, odd gets tight
    final bottomGap =
        widget.index.isEven ? AppColors.gapWide / 8 : AppColors.gapTight;

    final indexStr = (widget.index + 1).toString().padLeft(2, '0');
    final inverted = _pressed || _hovered;

    return Semantics(
      label: 'Quiz ${widget.index + 1}: ${widget.quiz.title}. '
          '${widget.quiz.description}. ${widget.quiz.length} questions.',
      button: true,
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _navigate();
              return null;
            },
          ),
        },
        child: Focus(
          child: Builder(builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              // FIX: size relative to the space the list actually gives the
              // card (screen minus 16px padding each side), not the screen.
              child: LayoutBuilder(builder: (context, constraints) {
                final cardWidth = constraints.maxWidth * widget.widthFactor;
                return Align(
                  alignment: widget.nudgeRight
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _navigate,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hovered = true),
                      onExit: (_) => setState(() => _hovered = false),
                      child: SizedBox(
                        width: cardWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: inverted ? AppColors.ink : widget.slabColor,
                            border: Border.all(
                              color: AppColors.ink,
                              width: focused
                                  ? AppColors.borderFrame
                                  : AppColors.borderRule,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    indexStr,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                      color: inverted
                                          ? AppColors.paper
                                              .withValues(alpha: 0.5)
                                          : AppColors.ink
                                              .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${widget.quiz.length} QS',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: inverted
                                          ? AppColors.paper
                                          : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppColors.gapTight),
                              Text(
                                widget.quiz.title.toUpperCase(),
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 0.9,
                                  letterSpacing: -0.5,
                                  color: inverted
                                      ? AppColors.paper
                                      : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.quiz.description,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: AppColors.supportingSize,
                                  height: AppColors.bodyLeading,
                                  color: inverted
                                      ? AppColors.paper
                                      : AppColors.ink,
                                ),
                              ),
                              // gap swing: tight before hairline, wide below it
                              const SizedBox(height: 20),
                              Container(
                                height: AppColors.borderRule,
                                color: inverted
                                    ? AppColors.paper.withValues(alpha: 0.4)
                                    : AppColors.ink,
                              ),
                              const SizedBox(height: AppColors.gapTight),
                              Text(
                                'START ->',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: inverted
                                      ? AppColors.paper
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}

// ── Full quiz list view ────────────────────────────────────────────────────

// Width cycle: 100%, 84%, 92% — never equal twice in a row.
const _widthCycle = [1.0, 0.84, 0.92];

class _QuizList extends StatelessWidget {
  const _QuizList({required this.quizzes, required this.slabColors});
  final List<Quiz> quizzes;
  final List<Color> slabColors;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MonoNavStrip(),
              _HeadlineSlab(quizCount: quizzes.length),
              // gap swing: tight after headline, sticker overlaps here
              const SizedBox(height: AppColors.gapTight),
              _AccentStripWithSticker(quizCount: quizzes.length),
              // gap swing: wide after accent strip
              const SizedBox(height: AppColors.nudge * 2),
              // Crop ticks (signature move 5)
              const _CropTicks(),
              const SizedBox(height: AppColors.gapTight),
              // Hairline grid guide (signature move 5)
              const _GridGuide(),
              // gap swing: wide below guide
              const SizedBox(height: AppColors.nudge * 2),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final slab = slabColors[index % slabColors.length];
              final widthFactor = _widthCycle[index % _widthCycle.length];
              return _QuizCard(
                key: ValueKey(quizzes[index].id),
                quiz: quizzes[index],
                index: index,
                slabColor: slab,
                nudgeRight: index.isEven,
                widthFactor: widthFactor,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Loading state ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MonoNavStrip(),
        const Spacer(),
        Center(
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
        const Spacer(),
      ],
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MonoNavStrip(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MonoNavStrip(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'NO QUIZZES\nAVAILABLE.',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: AppColors.displayLeading,
              color: AppColors.grid,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}