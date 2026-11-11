/// CRT Console shared widget library for Quiz Master.
///
/// Every widget here renders in the retro handheld console aesthetic:
/// hard square corners, pixel font, phosphor-green screen text, chunky
/// plastic borders, and scanline overlays on every screen surface.
///
///  - [CrtScreen]        — dark teal inset with scanlines + inner shadow
///  - [ConsoleSlab]      — plastic shell panel with raised lip
///  - [PixelButton]      — chunky button with solid depth shadow + press sink
///  - [AppTopStrip]      — page header on the plastic shell
///  - [AppSectionLabel]  — pixel-label section header
///  - [AppMonoLabel]     — small uppercase pixel field label
///  - [AppLoadingView]   — CRT-style block progress bar
///  - [AppErrorBanner]   — red-tinted error block
///  - [AppLogo]          — logo block with hard border
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/services/sound_service.dart';
import 'package:quiz_app/core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════
// CrtScreen — dark inset with scanlines and inner shadow
// ═══════════════════════════════════════════════════════════════════

/// Wraps any child inside a CRT screen: dark teal background, scanline
/// overlay, heavy top-bezel inner shadow, and an outer hard border.
class CrtScreen extends StatelessWidget {
  const CrtScreen({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.showScanlines = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showScanlines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.crtBg,
        border: Border.all(color: AppColors.outline, width: AppColors.borderFrame),
        boxShadow: const [
          // Outer lift shadow on the shell
          BoxShadow(
            color: AppColors.outline,
            offset: Offset(0, AppColors.borderRule),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(padding: padding, child: child),
          // Scanlines overlay
          if (showScanlines)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),
          // Top-bezel inner shadow
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 20,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Corner vignette — simulates CRT tube curvature
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Color(0x33000000),
                    ],
                    stops: [0.6, 1.0],
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

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x26000000)  // ~15% black
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
// ConsoleSlab — plastic panel with raised lip
// ═══════════════════════════════════════════════════════════════════

/// A plastic shell panel.  Has a solid darker strip below the bottom
/// edge to simulate the raised slab "lip", like physical hardware.
class ConsoleSlab extends StatelessWidget {
  const ConsoleSlab({
    super.key,
    required this.child,
    this.color = AppColors.shell,
    this.padding = const EdgeInsets.all(12),
    this.lipHeight = 7.0,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double lipHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lip (darker strip behind, offset down)
        Positioned(
          left: 0, right: 0,
          bottom: -lipHeight,
          child: Container(
            height: lipHeight,
            decoration: BoxDecoration(
              color: AppColors.shellDark,
              border: const Border(
                left:   BorderSide(color: AppColors.outline, width: AppColors.borderRule),
                right:  BorderSide(color: AppColors.outline, width: AppColors.borderRule),
                bottom: BorderSide(color: AppColors.outline, width: AppColors.borderRule),
              ),
            ),
          ),
        ),
        // Main panel
        Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
          ),
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PixelButton — chunky with solid depth shadow + click sound
// ═══════════════════════════════════════════════════════════════════

/// A retro arcade-style button.
/// Resting state: has a solid bottom shadow (depth).
/// Pressed state: translateY(depth), shadow shrinks to 0 — sinks in.
/// Plays buttonClick.mp3 on every press.
class PixelButton extends ConsumerStatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.btnMagenta,
    this.textColor = AppColors.shellLight,
    this.depth = AppColors.btnDepth,
    this.icon,
    this.fullWidth = false,
    this.minHeight = 44.0,
    this.fontSize = 10.0,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double depth;
  final Widget? icon;
  final bool fullWidth;
  final double minHeight;
  final double fontSize;
  final bool enabled;

  @override
  ConsumerState<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends ConsumerState<PixelButton> {
  bool _pressed = false;

  Color get _shadowColor {
    final c = widget.color;
    return Color.fromARGB(
      255,
      (c.red * 0.55).round(),
      (c.green * 0.55).round(),
      (c.blue * 0.55).round(),
    );
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    ref.read(soundServiceProvider).playClick();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = _pressed ? 0.0 : widget.depth;
    final enabled = widget.enabled && widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? _handleTap : null,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 60),
          padding: EdgeInsets.only(top: _pressed ? widget.depth : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Shadow layer
              if (effectiveDepth > 0)
                Positioned(
                  left: 0, right: 0,
                  bottom: -effectiveDepth,
                  child: Container(
                    height: effectiveDepth,
                    decoration: BoxDecoration(
                      color: _shadowColor,
                      border: Border(
                        left:   BorderSide(color: AppColors.outline, width: AppColors.borderRule),
                        right:  BorderSide(color: AppColors.outline, width: AppColors.borderRule),
                        bottom: BorderSide(color: AppColors.outline, width: AppColors.borderRule),
                      ),
                    ),
                  ),
                ),
              // Button face
              Container(
                width: widget.fullWidth ? double.infinity : null,
                constraints: BoxConstraints(minHeight: widget.minHeight),
                decoration: BoxDecoration(
                  color: enabled ? widget.color : AppColors.shellDark,
                  border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label.toUpperCase(),
                      style: GoogleFonts.silkscreen(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: enabled
                            ? widget.textColor
                            : AppColors.shellDark.withValues(alpha: 0.6),
                      ),
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

// ═══════════════════════════════════════════════════════════════════
// PhosphorText — glowing green text for screen surfaces
// ═══════════════════════════════════════════════════════════════════

/// Text rendered in phosphor green with a subtle glow.
/// Use on [CrtScreen] surfaces only.
class PhosphorText extends StatelessWidget {
  const PhosphorText(
    this.text, {
    super.key,
    this.fontSize = AppColors.bodySize,
    this.dim = false,
    this.fontWeight = FontWeight.w400,
    this.letterSpacing = 1.5,
    this.height,
    this.textAlign,
    this.overflow,
  });

  final String text;
  final double fontSize;
  final bool dim;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double? height;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final color = dim ? AppColors.phosphorDim : AppColors.phosphor;
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      style: GoogleFonts.silkscreen(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
        height: height ?? AppColors.bodyLeading,
        shadows: [
          Shadow(
            color: AppColors.phosphorDim.withValues(alpha: 0.8),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ShellText — text on the plastic shell (not on screen)
// ═══════════════════════════════════════════════════════════════════

class ShellText extends StatelessWidget {
  const ShellText(
    this.text, {
    super.key,
    this.fontSize = AppColors.labelSize,
    this.fontWeight = FontWeight.w700,
    this.color = AppColors.outline,
    this.letterSpacing = 1.5,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.silkscreen(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppTopStrip — page header bar on the shell, plays click sound
// ═══════════════════════════════════════════════════════════════════

class AppTopStrip extends ConsumerWidget {
  const AppTopStrip({
    super.key,
    this.title,
    this.trailing,
    this.onBack,
    this.backLabel = '< HOME',
  });

  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.shellDark,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: AppColors.borderFrame),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: () {
                ref.read(soundServiceProvider).playClick();
                onBack!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.btnBlue,
                  border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.btnBlueSel,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ShellText(backLabel, fontSize: 8, color: AppColors.shellLight),
              ),
            ),
          if (title != null) ...[
            if (onBack != null) const SizedBox(width: 10),
            Expanded(
              child: ShellText(
                title!,
                fontSize: 9,
                color: AppColors.shellLight,
                letterSpacing: 2.0,
              ),
            ),
          ] else
            const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppSectionLabel — pixel section header with hard rule
// ═══════════════════════════════════════════════════════════════════

class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel({
    super.key,
    required this.label,
    this.accentColor = AppColors.phosphorDim,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: accentColor,
            border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
          ),
          child: ShellText(label, fontSize: 7, color: AppColors.crtBgDeep),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: AppColors.borderRule,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppMonoLabel — small field label on screen surfaces
// ═══════════════════════════════════════════════════════════════════

class AppMonoLabel extends StatelessWidget {
  const AppMonoLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PhosphorText(text, fontSize: 8, dim: true, letterSpacing: 2.0);
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppLoadingView — pixel block progress bar
// ═══════════════════════════════════════════════════════════════════

class AppLoadingView extends StatefulWidget {
  const AppLoadingView({super.key});

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _blocks;

  static const _totalBlocks = 10;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _blocks = IntTween(begin: 0, end: _totalBlocks).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrtScreen(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorText('LOADING...', fontSize: 11, fontWeight: FontWeight.w700),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _blocks,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_totalBlocks, (i) {
                    final filled = i < _blocks.value;
                    return Container(
                      width: 14,
                      height: 20,
                      margin: const EdgeInsets.only(right: 3),
                      color: filled ? AppColors.phosphor : AppColors.crtBgDeep,
                      foregroundDecoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.phosphorDim,
                          width: AppColors.borderRule,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppErrorBanner — red-tinted error block
// ═══════════════════════════════════════════════════════════════════

class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.btnRed,
        border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF8B1A0A),
            offset: Offset(0, AppColors.btnDepth),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Text(
        '!! ${message.toUpperCase()}',
        style: GoogleFonts.silkscreen(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.shellLight,
          height: 1.6,
          shadows: const [
            Shadow(color: Color(0xFF8B1A0A), blurRadius: 4),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppLogo — logo with CRT border
// ═══════════════════════════════════════════════════════════════════

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.crtBg,
        border: Border.all(color: AppColors.outline, width: AppColors.borderFrame),
        boxShadow: const [
          BoxShadow(
            color: AppColors.outline,
            offset: Offset(0, AppColors.borderRule),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/image.png',
            fit: BoxFit.cover,
            width: size,
            height: size,
            semanticLabel: 'Quiz Master logo',
            errorBuilder: (_, __, ___) => Center(
              child: PhosphorText('QM', fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          // Scanline over logo
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScanlinePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ConsoleTextField — CRT-styled text input
// ═══════════════════════════════════════════════════════════════════

class ConsoleTextField extends StatelessWidget {
  const ConsoleTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.isPassword = false,  // true → always SpaceMono regardless of obscure state
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  /// Mark true for password fields so SpaceMono is used even when revealed.
  final bool isPassword;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // Password fields always use SpaceMono:
    //  - obscured:  SpaceMono renders ● bullets that are visually distinct
    //  - revealed:  SpaceMono still reads better than Silkscreen for mixed-
    //               case passwords and special characters
    // All other fields use Silkscreen for the pixel-console look.
    final inputStyle = isPassword
        ? GoogleFonts.spaceMono(
            fontSize: AppColors.bodySize,
            color: AppColors.phosphor,
            letterSpacing: obscure ? 4.0 : 1.5,
            height: 1.6,
          )
        : GoogleFonts.silkscreen(
            fontSize: AppColors.bodySize,
            color: AppColors.phosphor,
            letterSpacing: 1.0,
            height: 1.6,
          );

    final hintStyle = GoogleFonts.silkscreen(
      fontSize: AppColors.bodySize,
      color: AppColors.phosphorDim,
      letterSpacing: 1.0,
      height: 1.6,
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      onChanged: onChanged,
      autofocus: autofocus,
      style: inputStyle,
      cursorColor: AppColors.phosphor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle,
        suffixIcon: suffixIcon != null
            ? Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: AppColors.phosphorDim),
                ),
                child: suffixIcon!,
              )
            : null,
      ),
      validator: validator == null
          ? null
          : (v) {
              final err = validator!(v);
              return err == null ? null : err.toUpperCase();
            },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PixelDivider — hard phosphor rule
// ═══════════════════════════════════════════════════════════════════

class PixelDivider extends StatelessWidget {
  const PixelDivider({super.key, this.color = AppColors.phosphorDim});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: AppColors.borderRule, color: color);
  }
}

// ═══════════════════════════════════════════════════════════════════
// BlinkingCursor — CRT block cursor that blinks every 600ms
// ═══════════════════════════════════════════════════════════════════

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key, this.fontSize = 11.0});
  final double fontSize;

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        '█',
        style: GoogleFonts.silkscreen(
          fontSize: widget.fontSize,
          color: AppColors.phosphor,
          height: 1.0,
          shadows: const [
            Shadow(color: AppColors.phosphorDim, blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CrtBootScreen — wraps a CrtScreen with a boot-on animation.
// The screen starts as a 2px horizontal line, expands to full height,
// then reveals content. Only plays once on first mount.
// ═══════════════════════════════════════════════════════════════════

class CrtBootScreen extends StatefulWidget {
  const CrtBootScreen({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<CrtBootScreen> createState() => _CrtBootScreenState();
}

class _CrtBootScreenState extends State<CrtBootScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expand;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    // Phase 1 (0–60%): CRT line expands vertically from center
    _expand = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Phase 2 (60–100%): content fades in
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    // Small delay so the user sees the boot flash
    Future.delayed(const Duration(milliseconds: 80), () {
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CrtScreen(
          padding: widget.padding,
          child: ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: _expand.value.clamp(0.004, 1.0),
              child: FadeTransition(
                opacity: _fadeIn,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ShellPanel — plastic shell surface with dot-matrix texture
// ═══════════════════════════════════════════════════════════════════

/// Use this instead of a bare Container with AppColors.shell to get the
/// subtle surface texture that makes the plastic feel physical.
class ShellPanel extends StatelessWidget {
  const ShellPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shell,
        border: border,
      ),
      padding: padding,
      child: Stack(
        children: [
          child,
          // Subtle dot-matrix texture overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ShellTexturePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09000000)  // ~3.5% black dots
      ..style = PaintingStyle.fill;
    const spacing = 6.0;
    const dotR = 0.8;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ShellTexturePainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
// ConsoleScaffold — full-page scaffold with plastic shell background
// ═══════════════════════════════════════════════════════════════════

/// Wraps a page in the plastic shell background color so the app
/// always looks like it's sitting inside a console body.
class ConsoleScaffold extends StatelessWidget {
  const ConsoleScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shell,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _ScanlinePainter (also used by AppLogo) - exported at file scope
// ═══════════════════════════════════════════════════════════════════
// (already defined above — no duplicate needed)

// ═══════════════════════════════════════════════════════════════════
// PixelProgressBar — segmented block progress bar (for quiz progress)
// ═══════════════════════════════════════════════════════════════════

class PixelProgressBar extends StatelessWidget {
  const PixelProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Question $current of $total',
      child: Container(
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.crtBgDeep,
          border: Border(
            bottom: BorderSide(color: AppColors.outline, width: AppColors.borderRule),
          ),
        ),
        child: Row(
          children: List.generate(total, (i) {
            final filled = i < current;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : 1,
                  top: 2, bottom: 2,
                ),
                color: filled ? AppColors.phosphor : AppColors.phosphorDim.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CrtNavLoader — full-screen loading overlay for screen transitions.
//
// Shows a CRT-boot style loading screen on top of whatever page is
// currently visible. Used via the [withCrtLoading] extension on
// BuildContext so navigation always has the same pacing.
// ═══════════════════════════════════════════════════════════════════

/// Minimum time the CRT loading screen is shown during navigation so
/// every transition feels like the console is "switching channels".
const Duration kCrtNavDuration = Duration(milliseconds: 900);

/// Pushes a full-screen [_CrtNavLoaderPage] overlay, waits at least
/// [kCrtNavDuration] AND for [work] to complete, then calls [onDone].
///
/// Usage:
/// ```dart
/// context.crtNavigate(
///   work: () => ref.read(friendListProvider.notifier).load(),
///   onDone: () => context.go(AppRouter.friends),
/// );
/// ```
extension CrtNavigationX on BuildContext {
  Future<void> crtNavigate({
    Future<void> Function()? work,
    required VoidCallback onDone,
    String label = 'LOADING...',
  }) async {
    // Show the overlay immediately
    final overlay = OverlayEntry(
      builder: (_) => _CrtNavLoaderOverlay(label: label),
    );
    Overlay.of(this).insert(overlay);

    // Wait for minimum delay AND any real work, whichever is longer
    await Future.wait([
      Future<void>.delayed(kCrtNavDuration),
      if (work != null) work(),
    ]);

    overlay.remove();
    if (mounted) onDone();
  }
}

class _CrtNavLoaderOverlay extends StatefulWidget {
  const _CrtNavLoaderOverlay({required this.label});
  final String label;

  @override
  State<_CrtNavLoaderOverlay> createState() => _CrtNavLoaderOverlayState();
}

class _CrtNavLoaderOverlayState extends State<_CrtNavLoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _blocks;
  static const _totalBlocks = 8;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: kCrtNavDuration,
    )..forward();
    _blocks = IntTween(begin: 0, end: _totalBlocks).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.shell,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CrtScreen(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PhosphorText(
                        widget.label,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(width: 6),
                      const BlinkingCursor(fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress blocks fill from left to right over kCrtNavDuration
                  AnimatedBuilder(
                    animation: _blocks,
                    builder: (_, __) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_totalBlocks, (i) {
                          final filled = i < _blocks.value;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 60),
                            width: 18,
                            height: 24,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: filled
                                  ? AppColors.phosphor
                                  : AppColors.crtBgDeep,
                              border: Border.all(
                                color: AppColors.phosphorDim,
                                width: AppColors.borderRule,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
