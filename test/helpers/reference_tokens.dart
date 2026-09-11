/// Reads the reference's own `tokens.css` so the token tests assert against
/// the source rather than against a transcription of it.
///
/// This is the point of the whole exercise: a test that compares
/// `LumeColors.light.accent` to a hard-coded `#10998A` proves only that
/// someone typed the same thing twice. Parsing the stylesheet means the test
/// fails when the *design* and the Dart disagree — which is the only failure
/// worth being told about.
///
/// **Temporary.** It reads a file that is deleted at Phase F9. At that point
/// these tests are rewritten to assert the values directly, and the values
/// they freeze will have been proven correct by every comparison run before
/// then. Until then the stylesheet is the oracle.
library;

import 'dart:io';

import 'package:flutter/material.dart';

/// The reference stylesheet, parsed into its two token blocks.
class ReferenceTokens {
  ReferenceTokens._(this.light, this.dark);

  /// `:root` — the light theme.
  final Map<String, String> light;

  /// `[data-theme="dark"]` — the dark theme.
  final Map<String, String> dark;

  static const String path = 'assets/css/tokens.css';

  /// Whether the reference is still present. It is deleted at F9, and these
  /// tests skip rather than fail once it is gone.
  static bool get available => File(path).existsSync();

  static ReferenceTokens load() {
    final String css = File(path).readAsStringSync();

    Map<String, String> block(String selector) {
      final int start = css.indexOf(selector);
      if (start < 0) {
        throw StateError('no "$selector" block in $path');
      }
      final int open = css.indexOf('{', start);
      final int close = css.indexOf('\n}', open);
      final String body = css.substring(open + 1, close);
      final Map<String, String> out = <String, String>{};
      for (final RegExpMatch m in RegExp(
        r'(--[a-z0-9-]+)\s*:\s*([^;]+);',
      ).allMatches(body)) {
        out[m.group(1)!] = m.group(2)!.trim();
      }
      return out;
    }

    return ReferenceTokens._(block(':root'), block('[data-theme="dark"]'));
  }

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
