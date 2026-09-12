/// Maps the art generators' sentinel colours onto the live theme.
///
/// The prototype paints its illustrations in CSS custom properties, so the
/// same drawing is a different set of colours in light and dark.
/// `flutter_svg` cannot resolve a custom property, so the generators
/// (`gen_onboarding_art.mjs`, `gen_home_art.mjs`) replace each `var(--token)`
/// with a sentinel that appears nowhere else in the art, and this puts the
/// theme's colour back at paint time.
///
/// The alternative — freezing one theme's hex values into the asset — would
/// have produced a light illustration on a dark ground, which is exactly what
/// §58 says not to ship.
///
/// One table, shared: a sentinel means the same thing in every drawing.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'lume_colors.dart';

@immutable
class LumeArtColours extends ColorMapper {
  const LumeArtColours(this.lume);

  final LumeColors lume;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color colour,
  ) => switch (colour.toARGB32() & 0x00FFFFFF) {
    0xFF0001 => lume.accent,
    0xFF0002 => lume.accent400,
    0xFF0003 => lume.accent600,
    0xFF0004 => lume.accent700,
    0xFF0005 => lume.violet,
    0xFF0006 => lume.sky,
    0xFF0007 => lume.card,
    0xFF0008 => lume.card2,
    0xFF0009 => lume.border,
    0xFF000A => lume.text,
    0xFF000B => lume.text2,
    0xFF000C => lume.text3,
    0xFF000D => lume.tintAccent,
    0xFF000E => lume.tintNeutral,
    0xFF000F => lume.bg,
    0xFF0010 => lume.amber,
    0xFF0011 => lume.rose,
    0xFF0012 => lume.border2,
    _ => colour,
  };

  @override
  bool operator ==(Object other) =>
      other is LumeArtColours && other.lume == lume;

  @override
  int get hashCode => lume.hashCode;
}
