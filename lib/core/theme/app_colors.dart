import 'package:flutter/material.dart';

/// CRT Console Design token set.
///
/// Two shell modes:
///   Light (day) — warm beige Game Boy plastic
///   Dark (night) — near-black midnight console
///
/// The CRT screen itself never changes (always dark teal + phosphor green).
abstract final class AppColors {
  // ── Light shell ───────────────────────────────────────────────────
  static const Color shell       = Color(0xFFC8C2B0); // warm console plastic
  static const Color shellDark   = Color(0xFF8E8878); // panel lips, bevels
  static const Color shellLight  = Color(0xFFE6E1D2); // top highlights
  static const Color outline     = Color(0xFF14161F); // all hard outlines

  // ── Dark shell (midnight console) ────────────────────────────────
  static const Color shellNight      = Color(0xFF1C1C1E); // near-black body
  static const Color shellNightDark  = Color(0xFF111113); // lips, deeper recesses
  static const Color shellNightLight = Color(0xFF2C2C2E); // raised surfaces
  static const Color outlineNight    = Color(0xFF3A3A3C); // softer outline on dark

  // ── CRT screen (identical in both modes) ─────────────────────────
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

  // ── Legacy aliases ────────────────────────────────────────────────
  static const Color acid        = Color(0xFF7CE38B);
  static const Color alarm       = btnRed;
  static const Color bubblegum   = Color(0xFF3F8F55);
  static const Color volt        = btnBlue;
  static const Color paper       = shellLight;
  static const Color ink         = outline;
  static const Color grid        = shellDark;
  static const Color paperDark   = crtBgDeep;
  static const Color inkDark     = phosphor;
  static const Color gridDark    = phosphorDim;

  // ── Spacing tokens ────────────────────────────────────────────────
  static const double nudge          = 12.0;
  static const double gapTight       = 8.0;
  static const double gapWide        = 96.0;
  static const double gapWideCompact = 64.0;
  static const double px             = 4.0;

  // ── Typography scale ──────────────────────────────────────────────
  static const double bodySize       = 11.0;
  static const double supportingSize = 10.0;
  static const double labelSize      = 9.0;
  static const double displayMin     = 20.0;
  static const double displayMax     = 36.0;
  static const double displayLeading = 1.2;
  static const double bodyLeading    = 1.6;

  // ── Border tokens ─────────────────────────────────────────────────
  static const double borderFrame = 3.0;
  static const double borderRule  = 2.0;

  // ── Button depth shadow ───────────────────────────────────────────
  static const double btnDepth = 5.0;

  // ── Angle tokens (radians) ────────────────────────────────────────
  static const double angleNote  =  0.0349;
  static const double angleStamp = -0.0873;

  // ── Sticker tokens ────────────────────────────────────────────────
  static const double stickerSize        = 72.0;
  static const double stickerSizeCompact = 52.0;
}

// ── Compile-time alias for text on accent slabs (always light) ───────────
abstract final class c {
  static const Color paper = AppColors.shellLight;
  static const Color ink   = AppColors.outline;
  static const Color grid  = AppColors.shellDark;
}

/// Theme-aware shell color resolver.
///
/// Shell surfaces (nav strip, control deck, top strip) change between
/// light (beige) and dark (near-black) modes.
/// CRT screen surfaces are always the same regardless of mode.
class AppShell {
  const AppShell._({
    required this.body,
    required this.strip,
    required this.highlight,
    required this.border,
    required this.onShell,
    required this.isDark,
  });

  /// Main scaffold / body background color.
  final Color body;

  /// Darker strip used for nav bars and top strips.
  final Color strip;

  /// Lighter raised surface color.
  final Color highlight;

  /// Border/outline color on shell elements.
  final Color border;

  /// Text color on the shell surface.
  final Color onShell;

  final bool isDark;

  static AppShell of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? _night : _day;
  }

  static const _day = AppShell._(
    body:      AppColors.shell,
    strip:     AppColors.shellDark,
    highlight: AppColors.shellLight,
    border:    AppColors.outline,
    onShell:   AppColors.shellLight,
    isDark:    false,
  );

  static const _night = AppShell._(
    body:      AppColors.shellNight,
    strip:     AppColors.shellNightDark,
    highlight: AppColors.shellNightLight,
    border:    AppColors.outlineNight,
    onShell:   AppColors.shellLight,
    isDark:    true,
  );
}

/// CRT screen surface — same in both modes.
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
    return const AppSurface._(
      surface:   AppColors.crtBg,
      onSurface: AppColors.phosphor,
      guide:     AppColors.phosphorDim,
    );
  }
}
