import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CRT Console theme.
///
/// Typography: Silkscreen (pixel font) with Press Start 2P as fallback.
/// All radii: 0 (hard square corners — no border-radius ever).
/// Buttons: solid bottom shadow for depth; press sinks the button.
/// Colors: shell plastic for scaffold, CRT teal for screen surfaces.
class AppTheme {
  AppTheme._();

  // ── Pixel font helper ─────────────────────────────────────────────
  static TextStyle _pixel(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.phosphor,
    double? letterSpacing,
  }) =>
      GoogleFonts.silkscreen(
        fontSize: size,
        fontWeight: weight,
        height: AppColors.bodyLeading,
        letterSpacing: letterSpacing ?? 1.5,
        color: color,
      );

  static TextStyle _pixelDark(double size, {FontWeight weight = FontWeight.w400}) =>
      _pixel(size, weight: weight, color: AppColors.crtBgDeep);

  // ── Text theme — all pixel font, all caps feel ────────────────────
  static TextTheme _buildTextTheme(Color baseColor) => TextTheme(
        displayLarge:   _pixel(AppColors.displayMax, weight: FontWeight.w700, color: baseColor),
        displayMedium:  _pixel(28, weight: FontWeight.w700, color: baseColor),
        displaySmall:   _pixel(AppColors.displayMin, weight: FontWeight.w700, color: baseColor),
        headlineLarge:  _pixel(18, weight: FontWeight.w700, color: baseColor),
        headlineMedium: _pixel(16, weight: FontWeight.w700, color: baseColor),
        headlineSmall:  _pixel(14, weight: FontWeight.w700, color: baseColor),
        titleLarge:     _pixel(13, weight: FontWeight.w700, color: baseColor),
        titleMedium:    _pixel(12, color: baseColor),
        titleSmall:     _pixel(10, color: baseColor),
        bodyLarge:      _pixel(AppColors.bodySize, color: baseColor),
        bodyMedium:     _pixel(AppColors.supportingSize, color: baseColor),
        bodySmall:      _pixel(AppColors.labelSize, color: baseColor),
        labelLarge:     _pixel(11, weight: FontWeight.w700, color: baseColor),
        labelMedium:    _pixel(AppColors.labelSize, color: baseColor),
        labelSmall:     _pixel(8, color: baseColor),
      );

  // ── Shared button style factory ───────────────────────────────────
  static ButtonStyle _consoleButtonStyle({
    required Color bg,
    required Color fg,
    required Color shadow,
    bool fullWidth = true,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return bg.withValues(alpha: 0.85);
        return bg;
      }),
      foregroundColor: WidgetStateProperty.all(fg),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.resolveWith((states) {
        return BorderSide(
          color: AppColors.outline,
          width: states.contains(WidgetState.focused)
              ? AppColors.borderFrame
              : AppColors.borderRule,
        );
      }),
      shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
      minimumSize: WidgetStateProperty.all(
        fullWidth ? const Size.fromHeight(48) : const Size(44, 44),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      textStyle: WidgetStateProperty.all(
        GoogleFonts.silkscreen(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
      ),
      // Animate the press by using elevation as the "depth shadow"
      elevation: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.pressed) ? 0 : AppColors.btnDepth;
      }),
      shadowColor: WidgetStateProperty.all(shadow),
      animationDuration: const Duration(milliseconds: 60),
      enableFeedback: true,
    );
  }

  // ── Light theme = warm beige Game Boy shell ──────────────────────
  static ThemeData get light => _build(
        scaffoldBg:  AppColors.shell,
        brightness:  Brightness.light,
      );

  // ── Dark theme = midnight black console shell ─────────────────────
  static ThemeData get dark => _build(
        scaffoldBg:  AppColors.shellNight,
        brightness:  Brightness.dark,
      );

  static ThemeData _build({
    required Color scaffoldBg,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme(
      brightness:           brightness,
      primary:              AppColors.btnMagenta,
      onPrimary:            AppColors.shellLight,
      primaryContainer:     AppColors.crtBg,
      onPrimaryContainer:   AppColors.phosphor,
      secondary:            AppColors.btnBlue,
      onSecondary:          AppColors.shellLight,
      secondaryContainer:   AppColors.crtBgDeep,
      onSecondaryContainer: AppColors.phosphor,
      tertiary:             AppColors.btnRed,
      onTertiary:           AppColors.shellLight,
      error:                AppColors.btnRed,
      onError:              AppColors.shellLight,
      surface:              AppColors.crtBg,
      onSurface:            AppColors.phosphor,
      outline:              AppColors.outline,
      outlineVariant:       AppColors.phosphorDim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: _buildTextTheme(AppColors.phosphor),

      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.shellNightDark
            : AppColors.shellDark,
        foregroundColor: AppColors.shellLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _pixel(11, weight: FontWeight.w700, color: AppColors.shellLight),
        iconTheme: const IconThemeData(color: AppColors.shellLight),
        shape: Border.all(color: AppColors.outline, width: AppColors.borderRule),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: _consoleButtonStyle(
          bg: AppColors.btnMagenta,
          fg: AppColors.shellLight,
          shadow: const Color(0xFF7A0F7A),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _consoleButtonStyle(
          bg: AppColors.btnBlue,
          fg: AppColors.shellLight,
          shadow: const Color(0xFF0A18E6),
        ),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.crtBg,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.phosphorDim,
        thickness: AppColors.borderRule,
        space: 0,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.phosphor,
        linearTrackColor: AppColors.phosphorDim,
        circularTrackColor: AppColors.phosphorDim,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.crtBgDeep,
        hintStyle: _pixel(AppColors.bodySize, color: AppColors.phosphorDim),
        labelStyle: _pixel(AppColors.labelSize, color: AppColors.phosphorDim),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.phosphorDim, width: AppColors.borderRule),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.phosphorDim, width: AppColors.borderRule),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.phosphor, width: AppColors.borderFrame),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.btnRed, width: AppColors.borderRule),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.btnRed, width: AppColors.borderFrame),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.phosphor : AppColors.crtBg),
        checkColor: WidgetStateProperty.all(AppColors.crtBgDeep),
        side: const BorderSide(color: AppColors.phosphorDim, width: AppColors.borderRule),
        shape: const RoundedRectangleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.crtBgDeep,
        contentTextStyle: _pixel(AppColors.labelSize, color: AppColors.phosphor),
        shape: const RoundedRectangleBorder(),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.crtBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.phosphorDim, width: AppColors.borderRule),
        ),
        titleTextStyle: _pixel(13, weight: FontWeight.w700, color: AppColors.phosphor),
        contentTextStyle: _pixel(AppColors.bodySize, color: AppColors.phosphorDim),
      ),
    );
  }
}
