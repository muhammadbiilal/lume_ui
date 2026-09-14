/// Holding a converted tool against the running reference.
///
/// `measure_destinations.mjs --tool <id>` records `getBoundingClientRect` for
/// every element a tool screen draws. [ToolParity] compares a Flutter finder
/// against one of them, relative to the tool bar's top-left on both sides —
/// the reference has a simulated status bar and a tablet stage, Flutter has
/// neither — and writes every compared value to
/// `docs/conversion_archive/parity/tool_<id>.md`, so the count of mechanically
/// compared values is a file, not a claim.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';

/// One logical pixel.
const double kToolTolerance = 1;

/// Far down a long screen, where Chrome's fractional line boxes and Flutter's
/// whole ones have added up (D20).
const double kToolDrift = 2;

/// A committed web measurement, or `null` where it was never taken.
Map<String, dynamic>? webToolCell(String cell) {
  final File f = File('docs/conversion_archive/measurements/$cell.json');
  if (!f.existsSync()) return null;
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

class ToolParity {
  ToolParity(this.tool);

  final String tool;
  final List<String> _rows = <String>[];
  int compared = 0;

  /// Compare [elements] against [cell]'s bounds and return what missed.
  List<String> bounds(
    WidgetTester tester,
    String cell,
    Map<String, Finder> elements, {
    Set<String> noWidth = const <String>{},
    Set<String> noHeight = const <String>{},
    Set<String> drifting = const <String>{},

    /// A recorded difference, in points, added to the reference's `y` — an
    /// element that sits lower by a documented amount. Written into the
    /// report beside the value, so it is never a silent allowance.
    Map<String, double> shifted = const <String, double>{},

    /// The same, added to the reference's `height`.
    Map<String, double> grown = const <String, double>{},
  }) {
    final Map<String, dynamic>? web = webToolCell(cell);
    expect(web, isNotNull, reason: '$cell has not been measured');
    final Map<String, dynamic> b = web!['bounds'] as Map<String, dynamic>;
    final Map<String, dynamic> bar = b['toolbar'] as Map<String, dynamic>;
    final Rect flutterBar = tester.getRect(find.byType(LumeToolbar));
    final List<String> misses = <String>[];

    elements.forEach((String name, Finder finder) {
      final Map<String, dynamic>? w = b[name] as Map<String, dynamic>?;
      if (w == null) {
        misses.add('$name was not measured in $cell');
        return;
      }
      expect(finder, findsWidgets, reason: '$cell: $name is not drawn');
      final Rect r = tester.getRect(finder.first);
      final Map<String, double> want = <String, double>{
        'x': (w['x'] as num) - (bar['x'] as num).toDouble(),
        'y':
            (w['y'] as num) -
            (bar['y'] as num).toDouble() +
            (shifted[name] ?? 0),
        if (!noWidth.contains(name)) 'width': (w['width'] as num).toDouble(),
        if (!noHeight.contains(name))
          'height': (w['height'] as num).toDouble() + (grown[name] ?? 0),
      };
      final Map<String, double> got = <String, double>{
        'x': r.left - flutterBar.left,
        'y': r.top - flutterBar.top,
        'width': r.width,
        'height': r.height,
      };
      final double tolerance = drifting.contains(name)
          ? kToolDrift
          : kToolTolerance;
      want.forEach((String p, double v) {
        final double d = got[p]! - v;
        compared++;
        final double? recorded = p == 'y'
            ? shifted[name]
            : p == 'height'
            ? grown[name]
            : null;
        _rows.add(
          '| $cell | `$name` | $p${recorded == null ? '' : ' (reference '
                    '${recorded >= 0 ? '+' : ''}${recorded.toStringAsFixed(0)}, '
                    'recorded)'} | ${v.toStringAsFixed(2)} | '
          '${got[p]!.toStringAsFixed(2)} | ${d.toStringAsFixed(2)} |',
        );
        if (d.abs() > tolerance) {
          misses.add(
            '$name.$p wanted ${v.toStringAsFixed(2)} got '
            '${got[p]!.toStringAsFixed(2)}',
          );
        }
      });
    });
    return misses;
  }

  /// Write the report. Call from `tearDownAll`.
  void write() {
    final Directory dir = Directory('docs/conversion_archive/parity')
      ..createSync(recursive: true);
    File('${dir.path}/tool_$tool.md').writeAsStringSync(
      '# $tool — measured against the reference\n\n'
      'Written by the tool\'s bounds test. Every row is a value read from the '
      'running reference and the same value read from Flutter, relative to '
      'the tool bar\'s top-left.\n\n'
      '**$compared values compared.**\n\n'
      '| cell | element | property | reference | Flutter | Δ |\n'
      '|---|---|---|---:|---:|---:|\n'
      '${_rows.join('\n')}\n',
    );
  }
}

/// Every string drawn under [of], trimmed, in paint order.
List<String> textsUnder(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => (t.data ?? t.textSpan!.toPlainText()).trim())
    .where((String s) => s.isNotEmpty)
    .toList();
