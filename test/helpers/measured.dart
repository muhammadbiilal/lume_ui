/// Reads the component measurements taken from the rendered prototype.
///
/// `docs/conversion_archive/tool/measure_components.mjs` drives the real
/// components in a real browser and records `getComputedStyle` for each. These
/// tests compare the Flutter widgets against *that*, not against a number
/// somebody typed into both places.
///
/// **Temporary.** The measurements outlive the prototype — they are JSON — but
/// the tool that produces them does not. At Phase F9 these files are either
/// frozen as the record of what the design was, or replaced by the goldens
/// that will by then have been proven against them.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

const String _dir = 'docs/conversion_archive/measurements';

/// One measured specimen.
class Measured {
  const Measured(this.name, this._json);

  final String name;
  final Map<String, dynamic> _json;

  Map<String, dynamic> get _style => _json['style'] as Map<String, dynamic>;

  String raw(String property) => _style[property] as String;

  /// A length in logical pixels — `'46px'` → `46.0`.
  double px(String property) {
    final String v = raw(property);
    if (v == 'normal' || v == 'auto' || v == 'none') return 0;
    return double.parse(RegExp(r'-?[\d.]+').firstMatch(v)!.group(0)!);
  }

  /// The rendered height of the specimen.
  double get height => (_json['rect']['height'] as num).toDouble();

  /// The rendered width.
  double get width => (_json['rect']['width'] as num).toDouble();

  double get fontSize => px('fontSize');
  FontWeight get fontWeight => FontWeight.values.firstWhere(
    (FontWeight w) => w.value == int.parse(raw('fontWeight')),
  );

  /// `letter-spacing`, in logical pixels. CSS resolves the `em` for us, which
  /// is the whole reason to read it from the browser rather than compute it.
  double get letterSpacing => px('letterSpacing');

  double get radius => px('borderTopLeftRadius');
  double get borderWidth => px('borderTopWidth');
  double get minHeight => px('minHeight');

  EdgeInsets get padding => EdgeInsets.fromLTRB(
    px('paddingLeft'),
    px('paddingTop'),
    px('paddingRight'),
    px('paddingBottom'),
  );

  double get gap => px('gap');

  Color get color => colour('color');
  Color get backgroundColor => colour('backgroundColor');
  Color get borderColor => colour('borderTopColor');

  bool get isUppercase => raw('textTransform') == 'uppercase';
  bool get isTabular => raw('fontVariantNumeric').contains('tabular-nums');
  bool get isLineThrough => raw('textDecorationLine').contains('line-through');
  bool get hasShadow => raw('boxShadow') != 'none';
  bool get hasGradient => raw('backgroundImage') != 'none';

  /// Parse whatever colour syntax the browser reported.
  ///
  /// Chrome serialises `color-mix()` results as `color(srgb r g b / a)` with
  /// components in 0–1, and everything else as `rgb()` / `rgba()` in 0–255.
  /// Both appear in these measurements, so both are handled.
  Color colour(String property) {
    final String v = raw(property).trim();

    final RegExpMatch? srgb = RegExp(r'color\(srgb ([^)]+)\)').firstMatch(v);
    if (srgb != null) {
      final List<String> parts = srgb
          .group(1)!
          .replaceAll('/', ' ')
          .split(RegExp(r'\s+'))
          .where((String s) => s.isNotEmpty)
          .toList();
      final double r = double.parse(parts[0]);
      final double g = double.parse(parts[1]);
      final double b = double.parse(parts[2]);
      final double a = parts.length > 3 ? double.parse(parts[3]) : 1.0;
      return Color.fromARGB(
        (a * 255).round(),
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
      );
    }

    final RegExpMatch? rgba = RegExp(r'rgba?\(([^)]+)\)').firstMatch(v);
    if (rgba != null) {
      final List<String> parts = rgba
          .group(1)!
          .split(',')
          .map((String s) => s.trim())
          .toList();
      return Color.fromARGB(
        parts.length > 3 ? (double.parse(parts[3]) * 255).round() : 255,
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    throw FormatException('unrecognised colour in $name.$property: $v');
  }
}

/// One measurement cell — a width, a theme and a direction.
class Measurements {
  const Measurements._(this.cell, this._components);

  final String cell;
  final Map<String, dynamic> _components;

  static const String defaultCell = 'components_390_light_ltr';

  static bool available([String cell = defaultCell]) =>
      File('$_dir/$cell.json').existsSync();

  static Measurements load([String cell = defaultCell]) {
    final File f = File('$_dir/$cell.json');
    if (!f.existsSync()) {
      throw StateError(
        '$_dir/$cell.json is missing. Run '
        'docs/conversion_archive/tool/measure_components.mjs to produce it.',
      );
    }
    final Map<String, dynamic> json =
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    return Measurements._(cell, json['components'] as Map<String, dynamic>);
  }

  /// The specimen by name, or a failure that says which one is missing rather
  /// than a null dereference three frames later.
  Measured operator [](String name) {
    final dynamic c = _components[name];
    if (c == null) {
      throw StateError(
        'no specimen "$name" in $cell. Add it to '
        'docs/conversion_archive/tool/fixture/specimens.js and re-measure.',
      );
    }
    return Measured(name, c as Map<String, dynamic>);
  }

  Iterable<String> get names => _components.keys;
}
