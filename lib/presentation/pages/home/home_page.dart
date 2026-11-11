import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/services/sound_service.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/quiz.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/providers/theme_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
    final user = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppShell.of(context).body,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shell nav strip ──────────────────────────────────────
            _NavStrip(user: user, isAdmin: isAdmin),

            // ── CRT screen area ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: CrtBootScreen(
                  padding: EdgeInsets.zero,
                  child: !_loaded || state.loading
                      ? const AppLoadingView()
                      : state.errorMessage != null
                          ? _ErrorView(
                              message: state.errorMessage!,
                              onRetry: () =>
                                  ref.read(homeNotifierProvider.notifier).load(),
                            )
                          : state.quizzes.isEmpty
                              ? const _EmptyView()
                              : _QuizList(
                                  quizzes: state.quizzes,
                                  isAdmin: isAdmin,
                                  userPassedQuizIds: state.userPassedQuizIds,
                                ),
                ),
              ),
            ),

            // ── Shell control deck ───────────────────────────────────
            _ControlDeck(isAdmin: isAdmin),
          ],
        ),
      ),
    );
  }
}

// ── Shell nav strip ────────────────────────────────────────────────

class _NavStrip extends ConsumerWidget {
  const _NavStrip({required this.user, required this.isAdmin});
  final dynamic user;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = user?.displayName ?? '';
    final sh = AppShell.of(context);
    final isDark = sh.isDark;

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
          // Power LED — green in light, amber in dark
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? AppColors.btnYellow : AppColors.phosphor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sh.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.btnYellow : AppColors.phosphor)
                      .withValues(alpha: 0.7),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'QUIZ MASTER',
            style: GoogleFonts.silkscreen(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: sh.onShell,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: AppColors.btnRed,
              child: Text(
                'ADMIN',
                style: GoogleFonts.silkscreen(
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                  color: AppColors.shellLight,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (displayName.isNotEmpty) ...[
            Text(
              displayName.toUpperCase(),
              style: GoogleFonts.silkscreen(
                fontSize: 7,
                color: sh.onShell.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // ── Dark / Light mode toggle ───────────────────────────
          _ThemeToggle(),
          const SizedBox(width: 6),
          if (!isAdmin) ...[
            _ShellIconBtn(
              label: 'FRIENDS',
              color: AppColors.btnBlue,
              onTap: () => context.crtNavigate(
                label: 'LOADING FRIENDS...',
                onDone: () => context.push(AppRouter.friends),
              ),
            ),
            const SizedBox(width: 6),
          ],
          _ShellIconBtn(
            label: 'EXIT',
            color: AppColors.btnRed,
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

// ── Theme toggle button ────────────────────────────────────────────

class _ThemeToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends ConsumerState<_ThemeToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppShell.of(context).isDark;
    final sh = AppShell.of(context);
    // Sun icon in light mode, moon icon in dark mode
    final icon = isDark ? '☀' : '☾';
    final btnColor = isDark ? AppColors.shellNightLight : AppColors.shellDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        ref.read(soundServiceProvider).playClick();
        final current = ref.read(themeModeProvider);
        ref.read(themeModeProvider.notifier).state =
            current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: _pressed
            ? (Matrix4.identity()..translate(0.0, 2.0))
            : Matrix4.identity(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!_pressed)
              Positioned(
                left: 0, right: 0, bottom: -3,
                child: Container(
                  height: 3,
                  color: sh.strip,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: btnColor,
                border: Border.all(color: sh.border, width: AppColors.borderRule),
              ),
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.btnYellow : AppColors.shellLight,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellIconBtn extends ConsumerWidget {
  const _ShellIconBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = AppShell.of(context);
    // Scale padding and font with screen width:
    //   ≤ 360px → compact   (px: 6×3, font: 6)
    //   360–480px → default (px: 8×4, font: 7)
    //   > 480px → relaxed   (px: 12×6, font: 8)
    final screenW = MediaQuery.sizeOf(context).width;
    final double hPad = screenW <= 360 ? 6 : screenW <= 480 ? 8 : 12;
    final double vPad = screenW <= 360 ? 3 : screenW <= 480 ? 4 : 6;
    final double fontSize = screenW <= 360 ? 6 : screenW <= 480 ? 7 : 8;

    return GestureDetector(
      onTap: () {
        ref.read(soundServiceProvider).playClick();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: sh.border, width: AppColors.borderRule),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(
                255,
                (color.red * 0.5).round(),
                (color.green * 0.5).round(),
                (color.blue * 0.5).round(),
              ),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.silkscreen(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.shellLight,
          ),
        ),
      ),
    );
  }
}

// ── Quiz list inside CRT ───────────────────────────────────────────

class _QuizList extends StatelessWidget {
  const _QuizList({
    required this.quizzes,
    required this.isAdmin,
    required this.userPassedQuizIds,
  });
  final List<Quiz> quizzes;
  final bool isAdmin;
  final Set<String> userPassedQuizIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScreenHeader(count: quizzes.length, isAdmin: isAdmin),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            itemCount: quizzes.length,
            itemBuilder: (context, i) => _QuizCard(
              quiz: quizzes[i],
              index: i,
              isAdmin: isAdmin,
              hasPassed: userPassedQuizIds.contains(quizzes[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.count, required this.isAdmin});
  final int count;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.phosphorDim, width: AppColors.borderRule),
        ),
      ),
      child: Row(
        children: [
          PhosphorText('SELECT QUIZ', fontSize: 9, fontWeight: FontWeight.w700),
          const SizedBox(width: 6),
          const BlinkingCursor(fontSize: 9),
          const Spacer(),
          PhosphorText('$count AVAILABLE', fontSize: 8, dim: true),
        ],
      ),
    );
  }
}

// ── Quiz card ──────────────────────────────────────────────────────

class _QuizCard extends StatefulWidget {
  const _QuizCard({
    required this.quiz,
    required this.index,
    required this.isAdmin,
    required this.hasPassed,
  });
  final Quiz quiz;
  final int index;
  final bool isAdmin;
  final bool hasPassed;

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  bool _pressed = false;

  void _navigate() {
    if (widget.isAdmin) {
      context.crtNavigate(
        label: 'LOADING EDITOR...',
        onDone: () => context.push(AppRouter.quizEditPath(widget.quiz.id)),
      );
    } else {
      context.crtNavigate(
        label: 'LOADING QUIZ...',
        onDone: () => context.push(AppRouter.quizPlayPath(widget.quiz.id)),
      );
    }
  }

  /// Difficulty color based on passing score threshold:
  ///   < 60%  → green  (easy)
  ///   60–79% → blue   (medium)
  ///   ≥ 80%  → magenta (hard)
  Color get _difficultyAccent {
    final pass = widget.quiz.passingScore;
    if (pass < 60) return AppColors.btnGreen;
    if (pass < 80) return AppColors.btnBlue;
    return AppColors.btnMagenta;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _difficultyAccent;
    final indexStr = (widget.index + 1).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _navigate,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: _pressed
              ? (Matrix4.identity()..translate(0.0, 3.0))
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Depth shadow
              Positioned(
                left: 0, right: 0, bottom: -4,
                child: Container(
                  height: 4,
                  color: _pressed
                      ? Colors.transparent
                      : Color.fromARGB(
                          255,
                          (accent.red * 0.4).round(),
                          (accent.green * 0.4).round(),
                          (accent.blue * 0.4).round(),
                        ),
                ),
              ),
              // Card face
              Container(
                decoration: BoxDecoration(
                  color: AppColors.crtBgDeep,
                  border: Border.all(color: accent, width: AppColors.borderRule),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Index badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: accent,
                          child: Text(
                            indexStr,
                            style: GoogleFonts.silkscreen(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.crtBgDeep,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PhosphorText(
                            widget.quiz.title.toUpperCase(),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PhosphorText(
                          '${widget.quiz.length}Q',
                          fontSize: 8,
                          dim: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PhosphorText(
                      widget.quiz.description,
                      fontSize: 8,
                      dim: true,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: AppColors.borderRule,
                      color: accent.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!widget.isAdmin) ...[
                          PhosphorText(
                            'PASS ${widget.quiz.passingScore.toStringAsFixed(0)}%  ',
                            fontSize: 7,
                            dim: true,
                          ),
                          // Difficulty pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            color: accent.withValues(alpha: 0.2),
                            child: Text(
                              accent == AppColors.btnGreen
                                  ? 'EASY'
                                  : accent == AppColors.btnBlue
                                      ? 'MED'
                                      : 'HARD',
                              style: GoogleFonts.silkscreen(
                                fontSize: 6,
                                color: accent,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          // Pass badge — only shown after the user has passed
                          if (widget.hasPassed) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.phosphor,
                                border: Border.all(
                                    color: AppColors.phosphor, width: 1),
                              ),
                              child: Text(
                                '✓ PASSED',
                                style: GoogleFonts.silkscreen(
                                  fontSize: 6,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.crtBgDeep,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.phosphorDim,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                        const Spacer(),
                        PhosphorText(
                          widget.isAdmin ? '> EDIT' : '> PLAY',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Control deck (bottom shell) ────────────────────────────────────
// Game Boy-inspired: tall shell with large D-pad on the left,
// SELECT+START pill buttons in the center, and big circular A/B
// action buttons on the right. Speaker grille on the far right.

class _ControlDeck extends ConsumerWidget {
  const _ControlDeck({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShellPanel(
      border: const Border(
        top: BorderSide(color: AppColors.outline, width: AppColors.borderFrame),
      ),
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 34),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: D-pad ─────────────────────────────────────────
          _DPad(),

          const Spacer(),

          // ── Center: SELECT + START pills + admin button ─────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin)
                PixelButton(
                  label: '+ NEW QUIZ',
                  onPressed: () => context.push(AppRouter.quizCreate),
                  color: AppColors.btnMagenta,
                  textColor: AppColors.shellLight,
                  fontSize: 8,
                  depth: 3,
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PillButton(label: 'SELECT'),
                    const SizedBox(width: 10),
                    _PillButton(label: 'START'),
                  ],
                ),
              const SizedBox(height: 8),
              Builder(builder: (ctx) {
                final sh = AppShell.of(ctx);
                return Text(
                  isAdmin ? 'ADMIN MODE' : 'QUIZ MASTER',
                  style: GoogleFonts.silkscreen(
                    fontSize: 6,
                    color: sh.strip,
                    letterSpacing: 1.0,
                  ),
                );
              }),
            ],
          ),

          const Spacer(),

          // ── Right: B + A action buttons + speaker grille ─────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // B button (smaller, lower)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _ActionDot(
                  color: AppColors.btnMagenta,
                  label: 'B',
                  size: 42,
                ),
              ),
              const SizedBox(width: 10),
              // A button (larger, higher)
              _ActionDot(
                color: AppColors.btnMagenta,
                label: 'A',
                size: 50,
              ),
              const SizedBox(width: 14),
              // Speaker grille
              _SpeakerGrille(),
            ],
          ),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Game Boy D-pad: cross shape, each arm is 20×22px, center 22×22
    const arm = 23.0;
    const center = 25.0;
    const total = arm * 2 + center; // 62px

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        children: [
          // Up arm
          Positioned(
            top: 0, left: arm, right: arm,
            child: _DPadArm(height: arm),
          ),
          // Down arm
          Positioned(
            bottom: 0, left: arm, right: arm,
            child: _DPadArm(height: arm),
          ),
          // Left arm
          Positioned(
            left: 0, top: arm, bottom: arm,
            child: _DPadArm(width: arm),
          ),
          // Right arm
          Positioned(
            right: 0, top: arm, bottom: arm,
            child: _DPadArm(width: arm),
          ),
          // Center nub
          Positioned(
            left: arm, right: arm, top: arm, bottom: arm,
            child: Container(
              color: AppColors.outline,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Arrow indicators — themed to blend with shell surface
          Positioned(
            top: 3, left: 0, right: 0,
            child: Center(child: Builder(builder: (ctx) => Text(
              '▲', style: TextStyle(fontSize: 7, color: AppShell.of(ctx).strip, height: 1)))),
          ),
          Positioned(
            bottom: 3, left: 0, right: 0,
            child: Center(child: Builder(builder: (ctx) => Text(
              '▼', style: TextStyle(fontSize: 7, color: AppShell.of(ctx).strip, height: 1)))),
          ),
          Positioned(
            left: 3, top: 0, bottom: 0,
            child: Center(child: Builder(builder: (ctx) => Text(
              '◀', style: TextStyle(fontSize: 7, color: AppShell.of(ctx).strip, height: 1)))),
          ),
          Positioned(
            right: 3, top: 0, bottom: 0,
            child: Center(child: Builder(builder: (ctx) => Text(
              '▶', style: TextStyle(fontSize: 7, color: AppShell.of(ctx).strip, height: 1)))),
          ),
        ],
      ),
    );
  }
}

class _DPadArm extends StatelessWidget {
  const _DPadArm({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF111111),
            offset: Offset(1, 2),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// Oval SELECT / START pill button, like original Game Boy
class _PillButton extends ConsumerStatefulWidget {
  const _PillButton({required this.label});
  final String label;

  @override
  ConsumerState<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends ConsumerState<_PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        ref.read(soundServiceProvider).playClick();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: _pressed
            ? (Matrix4.identity()..translate(0.0, 2.0))
            : Matrix4.identity(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFCCCBBF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outline, width: 1.5),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: GoogleFonts.silkscreen(
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.btnBlue,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionDot extends ConsumerStatefulWidget {
  const _ActionDot({required this.color, required this.label, this.size = 40});
  final Color color;
  final String label;
  final double size;

  @override
  ConsumerState<_ActionDot> createState() => _ActionDotState();
}

class _ActionDotState extends ConsumerState<_ActionDot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shadowColor = Color.fromARGB(
      255,
      (widget.color.red * 0.4).round(),
      (widget.color.green * 0.4).round(),
      (widget.color.blue * 0.4).round(),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        ref.read(soundServiceProvider).playClick();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: _pressed
            ? (Matrix4.identity()..translate(0.0, 3.0))
            : Matrix4.identity(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!_pressed)
              Positioned(
                left: 0, right: 0, bottom: -4,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: shadowColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  radius: 0.7,
                  colors: [
                    widget.color.withValues(alpha: 0.85),
                    widget.color,
                    shadowColor,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: GoogleFonts.silkscreen(
                    fontSize: widget.size * 0.22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.shellLight.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Speaker grille — vertical slits like Game Boy
class _SpeakerGrille extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sh = AppShell.of(context);
    return SizedBox(
      width: 20,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          return Container(
            width: 2.5,
            decoration: BoxDecoration(
              color: sh.strip,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}

// ── Empty / Error / Loading views ──────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorText('NO QUIZZES', fontSize: 14, fontWeight: FontWeight.w700),
          SizedBox(height: 8),
          PhosphorText('AVAILABLE.', fontSize: 14, fontWeight: FontWeight.w700),
          SizedBox(height: 16),
          PhosphorText('[ INSERT QUIZ ]', fontSize: 9, dim: true),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppErrorBanner(message),
          const SizedBox(height: 16),
          PixelButton(
            label: 'RETRY',
            onPressed: onRetry,
            color: AppColors.btnRed,
            textColor: AppColors.shellLight,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
