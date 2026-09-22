/// Tasbih against the running reference.
///
/// The measurement tool's selector map has no entry for `.tasbih`, so the
/// block itself — the picker, the face, the ring and the actions — has no
/// recorded bounds of its own. What the capture does record is where
/// everything *after* the block sits, which is the same statement made
/// another way: the source bar and Related tools land where they land only if
/// the block above them is the height the reference measured. Those are the
/// values compared here.
///
/// **One recorded subtraction.** The reference's composition has a section
/// this conversion does not draw: "Recent sessions", two fixture rows
/// presented as the reader's own past dhikr (`context.js:384-387`). It is
/// dropped, and a note saying what is not kept (`l.tasbihNotKept`) is drawn
/// instead, so everything below sits higher by the difference between the
/// two. Both are named in [_shift] and both are written into
/// `docs/conversion_archive/parity/tool_tasbih.md` beside every value, which
/// is what the harness's `shifted` is for: a difference on the record, not a
/// tolerance quietly widened to swallow it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/tasbih/presentation/tasbih_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'tasbih_harness.dart';

/// The section the reference draws and this does not, in points: from the top
/// of "Recent sessions" to the top of the source bar, which is the section
/// plus the gap that follows it.
double _dropped(Map<String, dynamic> cell) {
  final Map<String, dynamic> b = cell['bounds'] as Map<String, dynamic>;
  final num history = (b['sect1'] as Map<String, dynamic>)['y'] as num;
  final num source = (b['sect2'] as Map<String, dynamic>)['y'] as num;
  return (source - history).toDouble();
}

/// What the note that replaces it costs: its own height and the gap above it.
double _note(WidgetTester tester) =>
    tester.getRect(find.byKey(LumeTasbihTool.notKeptKey)).height;

/// The recorded difference for everything below the block: the note this
/// conversion draws, less the section it drops, plus whatever else the cell
/// itself calls for ([extras], keyed by element).
Map<String, double> _shift(
  WidgetTester tester,
  Map<String, dynamic> cell,
  Iterable<String> names, {
  Map<String, double> extras = const <String, double>{},
}) {
  final double delta = _note(tester) - _dropped(cell);
  return <String, double>{
    for (final String n in names) n: delta + (extras[n] ?? 0),
  };
}

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('tasbih');
  tearDownAll(parity.write);

  const List<String> below = <String>[
    'srcbar',
    'fresh',
    'related.title',
    'related',
    'related.label',
  ];

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'toolbar.title': find.text('Tasbih'),
    'toolbar.sub': find.text('Instrument'),
    'srcbar': find.byType(LumeSourceBar),
    'fresh': find.byType(LumeFreshness),
    'related.title': find.text('Related tools'),
    'related': find.byType(LumeRelatedTools),
    'related.label': find.text('Daily Duas'),
  };

  /// The tool bar's title and sub-line are measured on their box in the
  /// capture and on their string in Flutter, so only the position is
  /// comparable.
  const Set<String> boxed = <String>{'toolbar.title', 'toolbar.sub'};

  group('where everything is', () {
    for (final (String cell, Size size, String state, ThemeMode theme)
        in <(String, Size, String, ThemeMode)>[
          (
            'tool_tasbih_muslim_pk_390x844_light_en',
            const Size(390, 5000),
            'muslim_pk',
            ThemeMode.light,
          ),
          (
            'tool_tasbih_muslim_pk_390x844_dark_en',
            const Size(390, 5000),
            'muslim_pk',
            ThemeMode.dark,
          ),
          (
            'tool_tasbih_muslim_gb_390x844_light_en',
            const Size(390, 5000),
            'muslim_gb',
            ThemeMode.light,
          ),
          (
            'tool_tasbih_muslim_pk_700x900_light_en',
            const Size(650, 5000),
            'muslim_pk',
            ThemeMode.light,
          ),
          (
            'tool_tasbih_muslim_pk_1100x900_light_en',
            const Size(1050, 5000),
            'muslim_pk',
            ThemeMode.light,
          ),
        ]) {
      // Above a phone the reference puts the app on a stage beside a rail,
      // and the tool bar is narrower than the window by exactly the rail. The
      // rail belongs to the shell, which only the router builds, so these two
      // cells need `tasbih` in the tool registry — and say so rather than
      // passing on a geometry that was never compared.
      final bool needsShell = size.width > 400 && !tasbihIsRegistered;
      testWidgets(
        needsShell
            ? '$cell — not compared: the shell rail needs tasbih in '
                  'kLumeToolRegistry'
            : cell,
        skip: needsShell,
        (WidgetTester tester) async {
          final Map<String, dynamic>? web = webToolCell(cell);
          expect(web, isNotNull, reason: '$cell has not been measured');
          await pumpTasbih(tester, state: state, surface: size, theme: theme);

          final List<String> misses = parity.bounds(
            tester,
            cell,
            elements(),
            noWidth: boxed,
            drifting: below.toSet(),
            shifted: _shift(tester, web!, below),
          );
          expect(misses, isEmpty, reason: misses.join('\n'));
        },
      );
    }
  });

  group('what it says, in each state the reference was captured in', () {
    for (final String state in <String>['muslim_pk', 'muslim_gb']) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpTasbih(tester, state: state);
        final Map<String, dynamic> k =
            webToolCell('tool_tasbih_${state}_390x844_light_en')!['composition']
                as Map<String, dynamic>;

        expect(
          tester
              .widget<LumeRelatedTools>(find.byType(LumeRelatedTools))
              .tools
              .map((LumeRelatedTool t) => t.name)
              .toList(),
          (k['related'] as List<dynamic>).cast<String>(),
        );

        final Map<String, dynamic> source = k['source'] as Map<String, dynamic>;
        expect(find.text(source['fresh'] as String), findsOneWidget);
        expect(
          referenceSourceLine(tester),
          (source['line'] as List<dynamic>).cast<String>(),
        );
      });
    }
  });

  group('the section the reference draws and this does not', () {
    testWidgets('the capture has it, and it is a fixture', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> cell = webToolCell(
        'tool_tasbih_muslim_pk_390x844_light_en',
      )!;
      final Map<String, dynamic> b = cell['bounds'] as Map<String, dynamic>;
      // The rows, in the reference's own words — a reader's dhikr that no
      // store ever held.
      expect(
        (b['sect1'] as Map<String, dynamic>)['text'],
        'Recent sessionsSubhanAllahToday33AstaghfirullahYesterday100',
      );
      await pumpTasbih(tester);
      expect(find.text('SubhanAllahToday'), findsNothing);
      expect(find.text('Recent sessions'), findsNothing);
    });
  });
}
