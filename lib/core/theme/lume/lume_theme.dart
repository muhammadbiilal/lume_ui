/// The two Lume themes, and the only way widgets reach the tokens.
///
/// Lume is not a Material product wearing a palette. Material's own surfaces
/// are configured here so that a stray Material widget inherits something from
/// the Lume system rather than Roboto on `#FFFBFE` — but the interface is built
/// from Lume widgets, and a screen that reaches for `Theme.of(context).cardColor`
/// has taken the wrong door.
///
/// The right door is `context.lume`, `context.lumeType`, `context.lumeShadows`
/// and `context.lumeGradients`.
library;

import 'package:flutter/material.dart';

import 'lume_colors.dart';
import 'lume_elevation.dart';
import 'lume_gradients.dart';
import 'lume_space.dart';
import 'lume_type.dart';

/// Builds the light and dark [ThemeData].
abstract final class LumeTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colors: LumeColors.light,
    shadows: LumeShadows.light,
    gradients: LumeGradients.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colors: LumeColors.dark,
    shadows: LumeShadows.dark,
    gradients: LumeGradients.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required LumeColors colors,
    required LumeShadows shadows,
    required LumeGradients gradients,
  }) {
    final LumeType type = LumeType.standard;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: colors.tintAccent,
      onPrimaryContainer: colors.accent700,
      secondary: colors.violet,
      onSecondary: colors.onAccent,
      error: colors.roseInk,
      onError: colors.onRose,
      errorContainer: colors.rose,
      onErrorContainer: colors.onRose,
      surface: colors.card,
      onSurface: colors.text,
      onSurfaceVariant: colors.text2,
      surfaceContainerLowest: colors.bgSunk,
      surfaceContainerLow: colors.bg,
      surfaceContainer: colors.card,
      surfaceContainerHigh: colors.card2,
      surfaceContainerHighest: colors.cardHover,
      outline: colors.border2,
      outlineVariant: colors.border,
      scrim: colors.overlay,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      fontFamily: LumeType.family,
      textTheme: type.materialTextTheme,
      primaryTextTheme: type.materialTextTheme,

      // Lume draws its own press feedback. Material's ink splash is a different
      // design language and would appear underneath every Lume surface.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: colors.cardHover,

      // §9: a visible 2 px accent outline with 2 px offset.
      focusColor: colors.accent,

      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: LumeSpace.border,
        space: LumeSpace.border,
      ),

      iconTheme: IconThemeData(color: colors.text2, size: LumeSpace.iconLg),

      // A Material dialog or sheet that slips through still lands on Lume
      // shape and colour rather than on Material's defaults.
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LumeRadius.lg)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: LumeRadius.sheetTop),
      ),

      extensions: <ThemeExtension<dynamic>>[colors, type, shadows, gradients],
    );
  }
}

/// How every widget in the app reaches the design system.
extension LumeThemeX on BuildContext {
  /// The colour tokens.
  LumeColors get lume =>
      Theme.of(this).extension<LumeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? LumeColors.dark
          : LumeColors.light);

  /// The type scale. Prefer `LumeType.fit(context, style)` at the call site so
  /// the line height follows the locale's script.
  LumeType get lumeType =>
      Theme.of(this).extension<LumeType>() ?? LumeType.standard;

  /// The elevation tokens.
  LumeShadows get lumeShadows =>
      Theme.of(this).extension<LumeShadows>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? LumeShadows.dark
          : LumeShadows.light);

  /// The gradient colourways.
  LumeGradients get lumeGradients =>
      Theme.of(this).extension<LumeGradients>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? LumeGradients.dark
          : LumeGradients.light);

  /// Whether the dark theme is showing.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
