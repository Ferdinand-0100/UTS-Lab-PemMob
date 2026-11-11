import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Anti-Design theme configuration.
///
/// Typography bindings:
///   "Anti Display"    → Bricolage Grotesque  (heavy display headings)
///   "Anti Interface"  → Instrument Sans      (reading / UI text)
///   "Anti Mono"       → Space Mono           (labels, metadata, indices)
///
/// All component radii are 0 (square corners). Buttons are flat slabs
/// with ink borders and immediate invert on press/hover.
class AppTheme {
  AppTheme._();

  // ── Font helpers ───────────────────────────────────────────────────
  static TextStyle _display(double size, {FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        height: AppColors.displayLeading,
        letterSpacing: -1.5,
        color: AppColors.ink,
      );

  static TextStyle _interface(double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.instrumentSans(
        fontSize: size,
        fontWeight: weight,
        height: AppColors.bodyLeading,
        color: AppColors.ink,
      );

  static TextStyle _mono(double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: weight,
        color: AppColors.ink,
      );

  // ── Text theme ─────────────────────────────────────────────────────
  static TextTheme get _textTheme => TextTheme(
        // Display — used for the big headline slabs
        displayLarge: _display(AppColors.displayMin),
        displayMedium: _display(48),
        displaySmall: _display(36),

        // Headlines — question text, section titles
        headlineLarge: _interface(32, weight: FontWeight.w700),
        headlineMedium: _interface(26, weight: FontWeight.w700),
        headlineSmall: _interface(20, weight: FontWeight.w600),

        // Titles — card headers
        titleLarge: _interface(18, weight: FontWeight.w600),
        titleMedium: _mono(14),
        titleSmall: _mono(12),

        // Body
        bodyLarge: _interface(AppColors.bodySize),
        bodyMedium: _interface(AppColors.supportingSize),
        bodySmall: _interface(AppColors.labelSize),

        // Labels — mono metadata
        labelLarge: _mono(14, weight: FontWeight.w700),
        labelMedium: _mono(AppColors.labelSize),
        labelSmall: _mono(10),
      );

  // ── Light theme ────────────────────────────────────────────────────
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      primaryContainer: AppColors.acid,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.volt,
      onSecondary: AppColors.paper,
      secondaryContainer: AppColors.bubblegum,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.alarm,
      onTertiary: AppColors.paper,
      error: AppColors.alarm,
      onError: AppColors.paper,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      outline: AppColors.ink,
      outlineVariant: AppColors.grid,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: _textTheme,

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _mono(14, weight: FontWeight.w700).copyWith(
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        shape: const Border(
          bottom: BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
      ),

      // ── Filled buttons — blunt flat slabs ────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.ink;
            }
            return AppColors.paper;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.paper;
            }
            return AppColors.ink;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.ink, width: AppColors.borderFrame),
          ),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          animationDuration: Duration.zero,
          enableFeedback: true,
        ),
      ),

      // ── Outlined buttons ─────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.ink;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.paper;
            }
            return AppColors.ink;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.ink, width: AppColors.borderFrame),
          ),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          animationDuration: Duration.zero,
        ),
      ),

      // ── Cards — flat ink-bordered slabs, no radius ───────────────
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.paper,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(),
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.ink,
        thickness: AppColors.borderRule,
        space: 0,
      ),

      // ── Progress indicators ───────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.grid,
        circularTrackColor: AppColors.grid,
      ),
    );
  }
  // ── Dark theme ────────────────────────────────────────────────────
  static ThemeData get dark {
    const surface   = AppColors.paperDark;  // #111111
    const onSurface = AppColors.inkDark;    // #F0EFE8
    const guide     = AppColors.gridDark;   // #4A4A44

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary:              onSurface,
      onPrimary:            surface,
      primaryContainer:     AppColors.acid,
      onPrimaryContainer:   AppColors.ink,   // acid is always light
      secondary:            AppColors.volt,
      onSecondary:          onSurface,
      secondaryContainer:   AppColors.bubblegum,
      onSecondaryContainer: AppColors.ink,
      tertiary:             AppColors.alarm,
      onTertiary:           onSurface,
      error:                AppColors.alarm,
      onError:              onSurface,
      surface:              surface,
      onSurface:            onSurface,
      outline:              onSurface,
      outlineVariant:       guide,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,

      // Text — apply off-white to every text style
      textTheme: _textTheme.apply(
        bodyColor:    onSurface,
        displayColor: onSurface,
      ),

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _mono(14, weight: FontWeight.w700).copyWith(
          color: onSurface,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: onSurface),
        shape: const Border(
          bottom: BorderSide(color: onSurface, width: AppColors.borderRule),
        ),
      ),

      // ── Filled buttons ────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return onSurface;
            }
            return surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return surface;
            }
            return onSurface;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(
            const BorderSide(color: onSurface, width: AppColors.borderFrame),
          ),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          animationDuration: Duration.zero,
          enableFeedback: true,
        ),
      ),

      // ── Outlined buttons ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return onSurface;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return surface;
            }
            return onSurface;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(
            const BorderSide(color: onSurface, width: AppColors.borderFrame),
          ),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          animationDuration: Duration.zero,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(),
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: onSurface,
        thickness: AppColors.borderRule,
        space: 0,
      ),

      // ── Progress indicators ───────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: onSurface,
        linearTrackColor: guide,
        circularTrackColor: guide,
      ),
    );
  }
}
