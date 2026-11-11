import 'package:flutter/material.dart';

/// Anti-Design token set.
///
/// Static color constants (accent slabs, spacing, typography) are defined
/// here. Surface colors (paper/ink/grid) vary by theme — use [AppSurface]
/// to read them from the live [BuildContext] instead of hardcoding.
abstract final class AppColors {
  // ── Light surface tokens ─────────────────────────────────────────
  static const Color paper     = Color(0xFFF3F2EC); // off-white
  static const Color ink       = Color(0xFF0A0A0A); // near-black
  static const Color grid      = Color(0xFFBDBCB4); // hairline guide

  // ── Dark surface tokens ──────────────────────────────────────────
  static const Color paperDark = Color(0xFF111111); // near-black surface
  static const Color inkDark   = Color(0xFFF0EFE8); // off-white text
  static const Color gridDark  = Color(0xFF4A4A44); // muted guide

  // ── Slab accent tokens (same in both modes) ──────────────────────
  static const Color acid      = Color(0xFFD7FF1F);
  static const Color alarm     = Color(0xFFFF3B1D);
  static const Color bubblegum = Color(0xFFFF8FE0);
  static const Color volt      = Color(0xFF2B2BFF);

  // ── Link tokens ───────────────────────────────────────────────────
  static const Color link        = Color(0xFF0000EE);
  static const Color linkVisited = Color(0xFF551A8B);

  // ── Spacing tokens (logical pixels) ──────────────────────────────
  static const double nudge         = 12.0;
  static const double gapTight      = 8.0;
  static const double gapWide       = 96.0;
  static const double gapWideCompact = 64.0;

  // ── Typography scale tokens ───────────────────────────────────────
  static const double bodySize       = 16.0;
  static const double supportingSize = 15.0;
  static const double labelSize      = 12.0;
  static const double displayMin     = 64.0;
  static const double displayMax     = 168.0;
  static const double displayLeading = 0.85;
  static const double bodyLeading    = 1.45;

  // ── Border tokens ─────────────────────────────────────────────────
  static const double borderFrame = 3.0;
  static const double borderRule  = 1.0;

  // ── Angle tokens (radians) ────────────────────────────────────────
  static const double angleNote  =  0.0349; //  2 deg
  static const double angleStamp = -0.0873; // -5 deg

  // ── Sticker tokens ────────────────────────────────────────────────
  static const double stickerSize        = 88.0;
  static const double stickerSizeCompact = 64.0;
}

// ── Theme-aware surface accessor ─────────────────────────────────────────
//
// Replace every hardcoded `c.paper` / `c.ink` / `c.grid` with
// `AppSurface.of(context).paper` etc., OR keep using the `ct(context)`
// shorthand alias defined below.
//
// The old compile-time `c` alias is kept for widgets that intentionally
// want the LIGHT values (e.g. text drawn on a fixed accent slab like
// AppColors.acid which is always light).

/// Compile-time constants — use only when the color must be LIGHT regardless
/// of theme (e.g. text on an acid/alarm slab that never changes).
abstract final class c {
  static const Color paper = AppColors.paper;
  static const Color ink   = AppColors.ink;
  static const Color grid  = AppColors.grid;
}

/// Theme-aware surface colors resolved from [BuildContext].
///
/// Usage:
/// ```dart
/// final s = AppSurface.of(context);
/// Container(color: s.surface, child: Text('hello', style: TextStyle(color: s.onSurface)));
/// ```
class AppSurface {
  const AppSurface._({
    required this.surface,
    required this.onSurface,
    required this.guide,
  });

  /// Background / card color (paper in light, near-black in dark).
  final Color surface;

  /// Primary text / stroke color (ink in light, off-white in dark).
  final Color onSurface;

  /// Hairline guide / muted label color.
  final Color guide;

  static AppSurface of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const AppSurface._(
            surface:   AppColors.paperDark,
            onSurface: AppColors.inkDark,
            guide:     AppColors.gridDark,
          )
        : const AppSurface._(
            surface:   AppColors.paper,
            onSurface: AppColors.ink,
            guide:     AppColors.grid,
          );
  }
}
