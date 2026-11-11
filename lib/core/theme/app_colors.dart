import 'package:flutter/material.dart';

/// CRT Console Design token set.
///
/// The app is themed as a chunky retro handheld console.
/// Every surface is either the plastic shell or the inset CRT screen.
/// Accents are arcade-bright button colors.
/// Text on screens uses phosphor green only.
abstract final class AppColors {
  // ── Plastic shell ────────────────────────────────────────────────
  static const Color shell       = Color(0xFFC8C2B0); // warm console plastic
  static const Color shellDark   = Color(0xFF8E8878); // panel lips, bevels
  static const Color shellLight  = Color(0xFFE6E1D2); // top highlights
  static const Color outline     = Color(0xFF14161F); // all hard outlines

  // ── CRT screen ───────────────────────────────────────────────────
  static const Color crtBg       = Color(0xFF0F2F3A); // dark teal screen
  static const Color crtBgDeep   = Color(0xFF0A1F27); // deeper shadow
  static const Color phosphor    = Color(0xFF7CE38B); // screen text / bubble
  static const Color phosphorDim = Color(0xFF3F8F55); // dimmer screen text

  // ── Arcade button colors ─────────────────────────────────────────
  static const Color btnBlue     = Color(0xFF2F6FED);
  static const Color btnBlueSel  = Color(0xFF0A18E6); // selected/pressed
  static const Color btnMagenta  = Color(0xFFC928C9); // primary action
  static const Color btnGreen    = Color(0xFF1F4D12); // play
  static const Color btnYellow   = Color(0xFFEDB93B); // pause
  static const Color btnRed      = Color(0xFFE5472A); // stop / alarm

  // ── Legacy aliases kept for accent slabs that never change ───────
  /// Always-light accent (maps to acid yellow-green → use shell highlight)
  static const Color acid        = Color(0xFF7CE38B); // phosphor green stands in
  static const Color alarm       = btnRed;
  static const Color bubblegum   = Color(0xFF3F8F55); // phosphorDim as a muted accent
  static const Color volt        = btnBlue;

  // ── Constant surface aliases (always-dark text on always-light bg) ─
  static const Color paper       = shellLight;
  static const Color ink         = outline;
  static const Color grid        = shellDark;

  // ── Dark surface aliases ─────────────────────────────────────────
  static const Color paperDark   = crtBgDeep;
  static const Color inkDark     = phosphor;
  static const Color gridDark    = phosphorDim;

  // ── Spacing tokens (logical pixels) ──────────────────────────────
  static const double nudge         = 12.0;
  static const double gapTight      = 8.0;
  static const double gapWide       = 96.0;
  static const double gapWideCompact = 64.0;

  // ── px unit — base pixel grid unit (all borders/lips/shadows use multiples)
  static const double px            = 4.0;

  // ── Typography scale tokens ───────────────────────────────────────
  static const double bodySize       = 11.0;  // pixel font reads small
  static const double supportingSize = 10.0;
  static const double labelSize      = 9.0;
  static const double displayMin     = 20.0;
  static const double displayMax     = 36.0;
  static const double displayLeading = 1.2;
  static const double bodyLeading    = 1.6;

  // ── Border tokens ─────────────────────────────────────────────────
  static const double borderFrame = 3.0;  // chunky 3px border
  static const double borderRule  = 2.0;  // standard border (2px min on console)

  // ── Button depth shadow (solid, not blurred) ──────────────────────
  static const double btnDepth    = 5.0;  // how many px the button "sticks out"

  // ── Angle tokens (radians) ────────────────────────────────────────
  static const double angleNote  =  0.0349; //  2 deg
  static const double angleStamp = -0.0873; // -5 deg

  // ── Sticker tokens ────────────────────────────────────────────────
  static const double stickerSize        = 72.0;
  static const double stickerSizeCompact = 52.0;
}

// ── compile-time alias for always-light text on accent slabs ─────────────
abstract final class c {
  static const Color paper = AppColors.shellLight;
  static const Color ink   = AppColors.outline;
  static const Color grid  = AppColors.shellDark;
}

/// Theme-aware surface resolver.
///
/// In this console theme we only have ONE visual mode — the CRT screen
/// is always dark teal with phosphor green text.  The "light" scaffold
/// is the plastic shell; the "screen" is always CRT-dark.
///
/// Usage: `final s = AppSurface.of(context);`
class AppSurface {
  const AppSurface._({
    required this.surface,
    required this.onSurface,
    required this.guide,
  });

  final Color surface;
  final Color onSurface;
  final Color guide;

  static AppSurface of(BuildContext context) {
    // We always use CRT-dark for screens; scaffold bg is handled via Scaffold.
    return const AppSurface._(
      surface:   AppColors.crtBg,
      onSurface: AppColors.phosphor,
      guide:     AppColors.phosphorDim,
    );
  }
}
