/// The design tokens the web reference's own `tokens.css` declared, frozen
/// here now that the reference is gone (Phase F9).
///
/// This file used to parse `assets/css/tokens.css` at test time, so a test
/// failed when the *design* and the Dart disagreed rather than when someone
/// typed the same hex twice. That protection is preserved, not weakened: the
/// values below are the exact `:root` and `[data-theme="dark"]` custom
/// properties the stylesheet held at the moment every `token_parity_test.dart`
/// assertion was last green, captured verbatim (`--token: 'raw css value'`,
/// unparsed) so the same parsing helpers below (`colour`, `px`, `font`,
/// `seconds`) still do the same work they always did. A future *design*
/// change updates the Dart source of truth (`LumeColors`, `LumeType`, …)
/// directly — there is no stylesheet left to re-derive these from, so a
/// deliberate change here is a deliberate, reviewed edit, the same as any
/// other constant in this codebase.
library;

import 'package:flutter/material.dart';

const Map<String, String> _light = <String, String>{
  '--accent-50': '#E9F7F4',
  '--accent-100': '#CFEDE7',
  '--accent-200': '#A5DED4',
  '--accent-400': '#34B39D',
  '--accent': '#10998A',
  '--accent-600': '#0B7F73',
  '--accent-700': '#086357',
  '--accent-ink': '#07564C',
  '--violet': '#6E62E5',
  '--indigo': '#3D4BC7',
  '--amber': '#E0913A',
  '--rose': '#DE6B7A',
  '--sky': '#3E9BD4',
  '--bg': '#F6F6F4',
  '--bg-sunk': '#EFEFEC',
  '--card': '#FFFFFF',
  '--card-2': '#FAFAF9',
  '--card-hover': '#F4F4F2',
  '--text': '#101113',
  '--text-2': '#56585F',
  '--text-3': '#8B8D95',
  '--border': 'rgba(16, 17, 19, .07)',
  '--border-2': 'rgba(16, 17, 19, .12)',
  '--overlay': 'rgba(16, 17, 19, .38)',
  '--tint-accent': '#E7F4F1',
  '--tint-neutral': '#F1F1EE',
  '--on-rose': '#FFFFFF',
  '--rose-ink': '#A3323F',
  '--on-amber': '#2A1A06',
  '--amber-ink': '#8A5410',
  '--shadow-xs': '0 1px 2px rgba(16, 24, 40, .05)',
  '--shadow-sm':
      '0 1px 2px rgba(16, 24, 40, .04), 0 2px 6px -2px rgba(16, 24, 40, .06)',
  '--shadow-md':
      '0 2px 4px -2px rgba(16, 24, 40, .05), 0 8px 20px -6px rgba(16, 24, 40, .10)',
  '--shadow-lg':
      '0 8px 16px -8px rgba(16, 24, 40, .10), 0 24px 48px -16px rgba(16, 24, 40, .20)',
  '--shadow-nav':
      '0 -1px 0 var(--border), 0 -8px 32px -12px rgba(16, 24, 40, .16)',
  '--shadow-accent':
      '0 8px 24px -8px color-mix(in srgb, var(--accent) 80%, transparent)',
  '--r-xs': '8px',
  '--r-icon': '12px',
  '--r-sm': '12px',
  '--r-md': '16px',
  '--r-lg': '20px',
  '--r-xl': '26px',
  '--r-full': '999px',
  '--pad': '20px',
  '--gap-card': '16px',
  '--gap-section': '24px',
  '--pad-card': '16px',
  '--pad-row': '12px 16px',
  '--font':
      '"Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
  '--font-num': '"Plus Jakarta Sans", ui-rounded, -apple-system, sans-serif',
  '--t-display': '800 28px/32px var(--font)',
  '--t-title': '700 20px/26px var(--font)',
  '--t-section': '700 17px/22px var(--font)',
  '--t-cardtitle': '700 15px/20px var(--font)',
  '--t-body': '400 14px/22px var(--font)',
  '--t-bodystrong': '500 14px/22px var(--font)',
  '--t-label': '700 12px/16px var(--font)',
  '--t-meta': '600 12px/16px var(--font)',
  '--t-metasm': '500 11px/16px var(--font)',
  '--t-tab': '700 10px/14px var(--font)',
  '--nav-rail': '84px',
  '--nav-side': '244px',
  '--content-max': '760px',
  '--content-wide': '1180px',
  '--list-pane': '380px',
  '--tap': '44px',
  '--ease': 'cubic-bezier(.22, .61, .36, 1)',
  '--ease-out': 'cubic-bezier(.16, 1, .3, 1)',
  '--ease-spring': 'cubic-bezier(.34, 1.4, .64, 1)',
  '--dur-fast': '.16s',
  '--dur': '.26s',
  '--dur-slow': '.42s',
  '--sticker-opacity': '1',
  '--mesh-opacity': '.55',
  '--grad-accent-a': '#0B7F73',
  '--grad-accent-b': '#23A894',
  '--grad-prayer-a': '#0B4F63',
  '--grad-prayer-b': '#10998A',
  '--grad-night-a': '#1F2352',
  '--grad-night-b': '#4B3E8E',
  '--grad-gold-a': '#5E4110',
  '--grad-gold-b': '#8A6420',
  '--grad-sky-a': '#1F5680',
  '--grad-sky-b': '#3E86BB',
  '--grad-flame-a': '#8A3A16',
  '--grad-flame-b': '#B36A22',
  '--grad-lock-a': '#2E3440',
  '--grad-lock-b': '#55606F',
  '--grad-sport-a': '#14513A',
  '--grad-sport-b': '#2E8F63',
  '--grad-warn-a': '#7A3A14',
  '--grad-warn-b': '#A8672C',
  '--grad-sos-a': '#8E1B2E',
  '--grad-sos-b': '#B83D48',
  '--grad-scan-a': '#1A1D22',
  '--grad-scan-b': '#2B3038',
  '--on-grad': '#FFFFFF',
  '--on-grad-dim': 'rgba(255, 255, 255, .82)',
};

const Map<String, String> _dark = <String, String>{
  '--accent-50': '#0C2B27',
  '--accent-100': '#103B35',
  '--accent-200': '#17564D',
  '--accent-400': '#2FC0A9',
  '--accent': '#35CBB2',
  '--accent-600': '#58D8C2',
  '--accent-700': '#8AE7D7',
  '--accent-ink': '#B6F2E7',
  '--violet': '#9A90FF',
  '--indigo': '#7E8AF0',
  '--amber': '#EDB268',
  '--on-amber': '#2A1A06',
  '--amber-ink': '#F0C48A',
  '--on-rose': '#2A0E12',
  '--rose-ink': '#F0A3AD',
  '--rose': '#F0919C',
  '--sky': '#6EBAE8',
  '--bg': '#0A0A0B',
  '--bg-sunk': '#060607',
  '--card': '#141416',
  '--card-2': '#191A1C',
  '--card-hover': '#1E1F22',
  '--text': '#F3F3F4',
  '--text-2': '#A2A4AB',
  '--text-3': '#74767D',
  '--border': 'rgba(255, 255, 255, .075)',
  '--border-2': 'rgba(255, 255, 255, .14)',
  '--overlay': 'rgba(0, 0, 0, .6)',
  '--tint-accent': '#10312C',
  '--tint-neutral': '#1C1D20',
  '--shadow-xs': '0 1px 2px rgba(0, 0, 0, .5)',
  '--shadow-sm':
      '0 1px 2px rgba(0, 0, 0, .4), 0 2px 6px -2px rgba(0, 0, 0, .5)',
  '--shadow-md':
      '0 2px 4px -2px rgba(0, 0, 0, .4), 0 8px 20px -6px rgba(0, 0, 0, .55)',
  '--shadow-lg':
      '0 8px 16px -8px rgba(0, 0, 0, .5), 0 24px 48px -16px rgba(0, 0, 0, .7)',
  '--shadow-nav': '0 -1px 0 var(--border), 0 -8px 32px -12px rgba(0, 0, 0, .8)',
  '--shadow-accent':
      '0 8px 24px -10px color-mix(in srgb, var(--accent) 55%, transparent)',
  '--sticker-opacity': '.72',
  '--mesh-opacity': '.35',
  '--grad-accent-a': '#06463F',
  '--grad-accent-b': '#0E6F63',
  '--grad-prayer-a': '#072F3C',
  '--grad-prayer-b': '#0A6156',
  '--grad-night-a': '#14163a',
  '--grad-night-b': '#2E2760',
  '--grad-gold-a': '#3B2909',
  '--grad-gold-b': '#5E4415',
  '--grad-sky-a': '#133753',
  '--grad-sky-b': '#24567A',
  '--grad-flame-a': '#57240D',
  '--grad-flame-b': '#7A4716',
  '--grad-lock-a': '#1D222B',
  '--grad-lock-b': '#364049',
  '--grad-sport-a': '#0C3325',
  '--grad-sport-b': '#1B5C40',
  '--grad-warn-a': '#4E250D',
  '--grad-warn-b': '#6F441D',
  '--grad-sos-a': '#5C111E',
  '--grad-sos-b': '#7C2831',
  '--grad-scan-a': '#101216',
  '--grad-scan-b': '#1B1F25',
  '--on-grad': '#F4F6F5',
  '--on-grad-dim': 'rgba(244, 246, 245, .80)',
};

/// The frozen stylesheet, in its two token blocks.
class ReferenceTokens {
  const ReferenceTokens._(this.light, this.dark);

  /// `:root` — the light theme, as it read the day this was frozen.
  final Map<String, String> light;

  /// `[data-theme="dark"]` — the dark theme, as it read the day this was frozen.
  final Map<String, String> dark;

  static const ReferenceTokens frozen = ReferenceTokens._(_light, _dark);

  /// Parse a CSS colour — `#RGB`, `#RRGGBB` or `rgba(r, g, b, a)`.
  static Color colour(String value) {
    final String v = value.trim();

    if (v.startsWith('#')) {
      String hex = v.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((String c) => '$c$c').join();
      }
      return Color(int.parse('FF$hex', radix: 16));
    }

    final RegExpMatch? rgba = RegExp(r'rgba?\(([^)]+)\)').firstMatch(v);
    if (rgba != null) {
      final List<String> parts = rgba
          .group(1)!
          .split(',')
          .map((String s) => s.trim())
          .toList();
      final int r = int.parse(parts[0]);
      final int g = int.parse(parts[1]);
      final int b = int.parse(parts[2]);
      final double a = parts.length > 3 ? double.parse(parts[3]) : 1.0;
      // The same rounding Flutter applies: alpha is a byte.
      return Color.fromARGB((a * 255).round(), r, g, b);
    }

    throw FormatException('not a colour this parser understands: $value');
  }

  /// Parse a CSS length in px — `20px` → `20.0`.
  static double px(String value) =>
      double.parse(RegExp(r'-?[\d.]+').firstMatch(value.trim())!.group(0)!);

  /// Parse a CSS seconds duration — `.26s` → 260 ms.
  static Duration seconds(String value) {
    final double s = double.parse(
      RegExp(r'[\d.]+').firstMatch(value.trim())!.group(0)!,
    );
    return Duration(microseconds: (s * 1000000).round());
  }

  /// Parse a `font:` shorthand — `800 28px/32px var(--font)`.
  static ({FontWeight weight, double size, double lineHeight}) font(
    String value,
  ) {
    final RegExpMatch m = RegExp(
      r'(\d{3})\s+([\d.]+)px/([\d.]+)px',
    ).firstMatch(value.trim())!;
    return (
      weight: FontWeight.values.firstWhere(
        (FontWeight w) => w.value == int.parse(m.group(1)!),
      ),
      size: double.parse(m.group(2)!),
      lineHeight: double.parse(m.group(3)!),
    );
  }
}
