/// Global reusable widgets for the Quiz Master app.
///
/// All widgets in this file are theme-aware: they read surface/text colors
/// from [AppSurface.of(context)] so they render correctly in both light
/// and dark mode without any hardcoded color constants.
///
///   - [AppTopStrip]    — page header bar with optional back button & trailing
///   - [AppSectionLabel]— tilted-stamp section label with hairline rule
///   - [AppMonoLabel]   — small uppercase mono field label
///   - [AppLoadingView] — centred spinner + "LOADING..." text
///   - [AppErrorBanner] — alarm-colored error message block
///   - [AppLogo]        — branded logo block using assets/images/image.png
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';

// ── Top strip ───────────────────────────────────────────────────────────────

/// A page-top nav bar with an ink bottom border.
///
/// [title] is shown left (or right when [onBack] is set).
/// [trailing] is optional — rendered on the far right.
/// [onBack] renders a back-label button on the left.
class AppTopStrip extends StatelessWidget {
  const AppTopStrip({
    super.key,
    this.title,
    this.trailing,
    this.onBack,
    this.backLabel = '<- HOME',
  });

  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: s.onSurface, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Text(
                backLabel,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: s.onSurface,
                ),
              ),
            ),
          if (title != null) ...[
            if (onBack != null) const Spacer(),
            Text(
              title!,
              style: GoogleFonts.spaceMono(
                fontSize: onBack != null ? 10 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: onBack != null ? 1.5 : 2.0,
                color: s.onSurface,
              ),
            ),
          ],
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

/// Tilted stamp (signature move 3) with a hairline rule extending right.
///
/// [accentColor] defaults to [AppColors.acid].
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel({
    super.key,
    required this.label,
    this.accentColor = AppColors.acid,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);

    return Row(
      children: [
        ExcludeSemantics(
          child: Transform.rotate(
            angle: AppColors.angleStamp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor,
                border: Border.all(color: s.onSurface, width: AppColors.borderRule),
              ),
              child: Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  // Accent slabs (acid/bubblegum) are always light — use ink.
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: AppColors.borderRule,
            color: s.guide,
          ),
        ),
      ],
    );
  }
}

// ── Mono label ───────────────────────────────────────────────────────────────

/// Small uppercase mono label used above form fields.
class AppMonoLabel extends StatelessWidget {
  const AppMonoLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);

    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 9,
        letterSpacing: 2.0,
        color: s.guide,
      ),
    );
  }
}

// ── Loading view ─────────────────────────────────────────────────────────────

/// Centered spinner + "LOADING..." label. Theme-aware.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: AppColors.borderFrame,
              color: s.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING...',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              letterSpacing: 2.0,
              color: s.guide,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

/// Alarm-colored block for displaying an error message string.
/// Alarm red stays the same in both modes; text uses off-white for contrast.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.alarm,
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: GoogleFonts.spaceMono(
          fontSize: 11,
          // alarm slab always has light paper text regardless of mode
          color: AppColors.paper,
          height: 1.5,
        ),
      ),
    );
  }
}

// ── App logo ─────────────────────────────────────────────────────────────────

/// Branded image block using `assets/images/image.png`.
/// Border color adapts to the current theme surface.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = AppSurface.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: s.onSurface, width: AppColors.borderFrame),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        'assets/images/image.png',
        fit: BoxFit.cover,
        semanticLabel: 'Quiz Master logo',
      ),
    );
  }
}
