import 'package:flutter/material.dart';

/// Anti-Design token set.
///
/// Token names mirror the CSS-variable names in the design spec so
/// they can be cross-referenced. Map these to Flutter's Color type.
abstract final class AppColors {
  // ── Surface tokens ──────────────────────────────────────────────
  /// Cold off-white "paper" surface.
  static const Color paper = Color(0xFFF3F2EC);

  /// Near-black "ink" text / stroke.
  static const Color ink = Color(0xFF0A0A0A);

  /// Hairline grid guide color.
  static const Color grid = Color(0xFFBDBCB4);

  // ── Slab accent tokens ───────────────────────────────────────────
  /// Acid lime slab.
  static const Color acid = Color(0xFFD7FF1F);

  /// Alarm orange-red slab.
  static const Color alarm = Color(0xFFFF3B1D);

  /// Bubblegum pink slab.
  static const Color bubblegum = Color(0xFFFF8FE0);

  /// Electric blue slab (invert with white / lime text only).
  static const Color volt = Color(0xFF2B2BFF);

  // ── Link tokens ───────────────────────────────────────────────────
  static const Color link = Color(0xFF0000EE);
  static const Color linkVisited = Color(0xFF551A8B);

  // ── Spacing tokens (logical pixels) ──────────────────────────────
  static const double nudge = 12.0;
  static const double gapTight = 8.0;
  static const double gapWide = 96.0;

  // ── Typography scale tokens ───────────────────────────────────────
  static const double bodySize = 16.0;
  static const double supportingSize = 15.0;
  static const double labelSize = 12.0;
  static const double displayMin = 64.0;
  static const double displayMax = 168.0;
  static const double displayLeading = 0.85;
  static const double bodyLeading = 1.45;

  // ── Border tokens ─────────────────────────────────────────────────
  static const double borderFrame = 3.0;
  static const double borderRule = 1.0;

  // ── Angle tokens (in radians for Flutter transforms) ──────────────
  /// 2 deg in radians ≈ 0.0349
  static const double angleNote = 0.0349;

  /// -5 deg in radians ≈ -0.0873
  static const double angleStamp = -0.0873;

  // ── Sticker tokens ────────────────────────────────────────────────
  /// Full sticker diameter.
  static const double stickerSize = 88.0;

  /// Compact sticker diameter (phone / dense screens).
  static const double stickerSizeCompact = 64.0;

  // ── Gap wide compact ─────────────────────────────────────────────
  static const double gapWideCompact = 64.0;
}
