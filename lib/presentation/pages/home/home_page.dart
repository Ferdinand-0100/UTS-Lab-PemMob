import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/providers/theme_provider.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

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
      setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);

    final Widget content;
    if (!_loaded || state.loading) {
      content = const _LoadingView();
    } else if (state.errorMessage != null) {
      content = _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(homeNotifierProvider.notifier).load(),
      );
    } else if (state.quizzes.isEmpty) {
      content = const _EmptyView();
    } else {
      content = _QuizList(
        quizzes: state.quizzes,
        slabColors: _slabColors,
        isAdmin: ref.watch(authStateProvider).valueOrNull?.isAdmin ?? false,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(child: content),
      floatingActionButton: _AdminFab(),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin FAB
// ---------------------------------------------------------------------------

class _AdminFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null || !user.isAdmin) return const SizedBox.shrink();
    final s = AppSurface.of(context);

    return Semantics(
      label: 'Create new quiz',
      button: true,
      child: GestureDetector(
        onTap: () => context.push(AppRouter.quizCreate),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.acid,
            border: Border.all(color: s.onSurface, width: AppColors.borderFrame),
          ),
          child: Icon(Icons.add, color: s.onSurface, size: 28),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav strip
// ---------------------------------------------------------------------------

class _MonoNavStrip extends ConsumerWidget {
  const _MonoNavStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final displayName = user?.displayName ?? '';
    final isAdmin = user?.isAdmin ?? false;
    final s = AppSurface.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: s.onSurface, width: AppColors.borderRule),
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
              color: s.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (displayName.isNotEmpty) ...[
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: s.onSurface,
                          ),
                        ),
                        if (isAdmin)
                          Text(
                            'ADMIN',
                            style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              letterSpacing: 1.5,
                              color: s.guide,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  tooltip: 'Toggle dark mode',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: s.onSurface,
                  ),
                  onPressed: () {
                    final current = ref.read(themeModeProvider);
                    ref.read(themeModeProvider.notifier).state =
                        current == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                  },
                ),
                if (!isAdmin) ...[
                  Semantics(
                    label: 'Friends',
                    button: true,
                    child: GestureDetector(
                      onTap: () => context.push(AppRouter.friends),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bubblegum,
                          border: Border.all(
                            color: s.onSurface,
                            width: AppColors.borderRule,
                          ),
                        ),
                        child: Text(
                          'FRIENDS',
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
                  const SizedBox(width: 6),
                ],
                Semantics(
                  label: 'Sign out',
                  button: true,
                  child: GestureDetector(
                    onTap: () async =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: s.onSurface,
                          width: AppColors.borderRule,
                        ),
                      ),
                      child: Text(
                        'SIGN OUT',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: s.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline slab
// ---------------------------------------------------------------------------

class _HeadlineSlab extends StatelessWidget {
  const _HeadlineSlab({required this.quizCount, required this.isAdmin});
  final int quizCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 5.2).clamp(AppColors.displayMin, AppColors.displayMax);

    return Container(
      width: double.infinity,
      color: s.surface,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
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
                  color: s.guide.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
          screenW < 600
              ? _headlineStack(displaySize, s)
              : _headlineRow(displaySize, s),
        ],
      ),
    );
  }

  Widget _headlineStack(double displaySize, AppSurface s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _displayText(displaySize, s),
        const SizedBox(height: AppColors.gapWide / 4),
        _factsColumn(s),
      ],
    );
  }

  Widget _headlineRow(double displaySize, AppSurface s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(flex: 3, child: _displayText(displaySize, s)),
        const SizedBox(width: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: AppColors.nudge),
          child: _factsColumn(s),
        ),
      ],
    );
  }

  Widget _displayText(double displaySize, AppSurface s) {
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
            color: s.onSurface,
          ),
        ),
        Text(
          'Master',
          style: GoogleFonts.instrumentSerif(
            fontSize: displaySize * 0.95,
            fontStyle: FontStyle.italic,
            height: AppColors.displayLeading,
            letterSpacing: -1.5,
            color: s.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _factsColumn(AppSurface s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _monoFact('QUIZZES', '$quizCount AVAILABLE', s),
        const SizedBox(height: AppColors.gapTight),
        _monoFact('FORMAT', isAdmin ? 'EDIT MCQ' : 'TIMED MCQ', s),
      ],
    );
  }

  Widget _monoFact(String label, String value, AppSurface s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            color: s.guide,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: s.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Count sticker (signature move 2) — always on bubblegum, always ink text
// ---------------------------------------------------------------------------

class _CountSticker extends StatelessWidget {
  const _CountSticker({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);
    return ExcludeSemantics(
      child: Container(
        width: AppColors.stickerSize,
        height: AppColors.stickerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bubblegum,
          border: Border.all(color: s.onSurface, width: AppColors.borderRule),
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

// ---------------------------------------------------------------------------
// Accent strip with sticker
// ---------------------------------------------------------------------------

class _AccentStripWithSticker extends StatelessWidget {
  const _AccentStripWithSticker(
      {required this.quizCount, required this.isAdmin});
  final int quizCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
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
                isAdmin ? 'SELECT A QUIZ TO EDIT' : 'SELECT A QUIZ TO BEGIN',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              ExcludeSemantics(
                child: Transform.rotate(
                  angle: AppColors.angleStamp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.ink, width: AppColors.borderRule),
                    ),
                    child: Text(
                      isAdmin ? 'EDIT ->' : 'BEGIN ->',
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
        Positioned(
          top: -(AppColors.stickerSize / 3),
          right: 16,
          child: _CountSticker(count: quizCount),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Crop ticks + grid guide — theme-aware
// ---------------------------------------------------------------------------

class _CropTicks extends StatelessWidget {
  const _CropTicks();

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
              4, (_) => SizedBox(
                    width: 10,
                    height: 10,
                    child: CustomPaint(painter: _CropTickPainter(s.guide)),
                  )),
        ),
      ),
    );
  }
}

class _CropTickPainter extends CustomPainter {
  const _CropTickPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppColors.borderRule
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width * 0.4, size.height / 2), paint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height * 0.4), paint);
  }

  @override
  bool shouldRepaint(_CropTickPainter old) => old.color != color;
}

class _GridGuide extends StatelessWidget {
  const _GridGuide();

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(height: AppColors.borderRule, color: s.guide),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz card — theme-aware
// ---------------------------------------------------------------------------

class _QuizCard extends StatefulWidget {
  const _QuizCard({
    super.key,
    required this.quiz,
    required this.index,
    required this.slabColor,
    required this.nudgeRight,
    required this.widthFactor,
    required this.isAdmin,
  });

  final Quiz quiz;
  final int index;
  final Color slabColor;
  final bool nudgeRight;
  final double widthFactor;
  final bool isAdmin;

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _navigate() {
    if (widget.isAdmin) {
      context.push(AppRouter.quizEditPath(widget.quiz.id));
    } else {
      context.push(AppRouter.quizPlayPath(widget.quiz.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);
    final bottomGap =
        widget.index.isEven ? AppColors.gapWide / 8 : AppColors.gapTight;
    final indexStr = (widget.index + 1).toString().padLeft(2, '0');
    final inverted = _pressed || _hovered;

    // When inverted: use onSurface bg + surface text (works in both modes).
    final cardBg = inverted ? s.onSurface : widget.slabColor;
    final textColor = inverted ? s.surface : AppColors.ink;

    return Semantics(
      label: widget.isAdmin
          ? 'Edit quiz ${widget.index + 1}: ${widget.quiz.title}.'
          : 'Quiz ${widget.index + 1}: ${widget.quiz.title}. '
              '${widget.quiz.description}. ${widget.quiz.length} questions.',
      button: true,
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _navigate();
                return null;
              }),
        },
        child: Focus(
          child: Builder(builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
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
                            color: cardBg,
                            border: Border.all(
                              color: s.onSurface,
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
                                      color: textColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!widget.isAdmin) ...[
                                    Text(
                                      'PASS ${widget.quiz.passingScore.toStringAsFixed(0)}%',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        letterSpacing: 1.0,
                                        color:
                                            textColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(
                                    '${widget.quiz.length} QS',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: textColor,
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
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.quiz.description,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: AppColors.supportingSize,
                                  height: AppColors.bodyLeading,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: AppColors.borderRule,
                                color: textColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: AppColors.gapTight),
                              Text(
                                widget.isAdmin ? 'EDIT ->' : 'START ->',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: textColor,
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

// ---------------------------------------------------------------------------
// Quiz list
// ---------------------------------------------------------------------------

const _widthCycle = [1.0, 0.84, 0.92];

class _QuizList extends StatelessWidget {
  const _QuizList(
      {required this.quizzes,
      required this.slabColors,
      required this.isAdmin});
  final List<Quiz> quizzes;
  final List<Color> slabColors;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MonoNavStrip(),
              _HeadlineSlab(quizCount: quizzes.length, isAdmin: isAdmin),
              const SizedBox(height: AppColors.gapTight),
              _AccentStripWithSticker(
                  quizCount: quizzes.length, isAdmin: isAdmin),
              const SizedBox(height: AppColors.nudge * 2),
              const _CropTicks(),
              const SizedBox(height: AppColors.gapTight),
              const _GridGuide(),
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
                isAdmin: isAdmin,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / error / empty states
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonoNavStrip(),
        Expanded(child: AppLoadingView()),
      ],
    );
  }
}

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
                AppErrorBanner(message),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);
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
              color: s.guide,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
