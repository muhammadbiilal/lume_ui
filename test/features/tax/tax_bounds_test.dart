/// Tax, against the running reference: where everything is, and what it says.
///
/// `measure_destinations.mjs --tool tax` opens the tool the way a tile does
/// and records `getBoundingClientRect` for each element and the text of every
/// part; this pumps the Flutter tool through the router for the same reader
/// and holds both against it.
///
/// **Origin.** The reference draws a simulated status bar above the screen and
/// a tablet shell beside it, and Flutter has neither, so every position is
/// taken from the tool bar's own top-left on both sides. Widths and heights are
/// absolute.
///
/// **Words.** The reference renders its tool strings in English in Urdu and
/// Arabic; Flutter translates them (§11, D12). So words are compared in the
/// English cells, and the right-to-left cells are compared for order.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/tax/presentation/tax_tool.dart';

import '../../helpers/load_fonts.dart';
import 'tax_harness.dart';

const String kReport = 'docs/conversion_archive/TOOL_PARITY.md';

/// One logical pixel.
const double kTolerance = 1;

/// Below the bands: Chrome keeps a fractional line box and Flutter rounds it
/// (D20), and the related rail's two-line label is where it shows.
const double kDrift = 2;

void main() {
  setUpAll(loadLumeFonts);

  final List<String> report = <String>[];
  int compared = 0;

  tearDownAll(() {
    File(kReport).writeAsStringSync(
      '# Tool parity — measured\n\n'
      'Written by `test/features/tax/tax_bounds_test.dart`. Every row is a '
      'value read from the running reference and the same value read from '
      'Flutter, relative to the tool bar\'s top-left.\n\n'
      '**$compared values compared.**\n\n'
      '| cell | element | property | reference | Flutter | Δ |\n'
      '|---|---|---|---:|---:|---:|\n'
      '${report.join('\n')}\n',
    );
  });

  Finder boxOf(Finder inside) =>
      find.descendant(of: inside, matching: find.byType(Container)).first;

  /// Compares the listed properties of [name] and returns the misses.
  List<String> bounds(
    WidgetTester tester,
    String cell,
    Map<String, dynamic> web,
    Map<String, Finder> elements, {
    Set<String> noWidth = const <String>{},
    Set<String> drifting = const <String>{},
  }) {
    final Map<String, dynamic> b = web['bounds'] as Map<String, dynamic>;
    final Map<String, dynamic> bar = b['toolbar'] as Map<String, dynamic>;
    final Rect flutterBar = tester.getRect(find.byType(LumeToolbar));
    final List<String> misses = <String>[];

    elements.forEach((String name, Finder finder) {
      final Map<String, dynamic>? w = b[name] as Map<String, dynamic>?;
      if (w == null) return;
      expect(finder, findsWidgets, reason: '$cell: $name is not drawn');
      final Rect r = tester.getRect(finder.first);
      final Map<String, double> want = <String, double>{
        'x': (w['x'] as num) - (bar['x'] as num).toDouble(),
        'y': (w['y'] as num) - (bar['y'] as num).toDouble(),
        if (!noWidth.contains(name)) 'width': (w['width'] as num).toDouble(),
        'height': (w['height'] as num).toDouble(),
      };
      final Map<String, double> got = <String, double>{
        'x': r.left - flutterBar.left,
        'y': r.top - flutterBar.top,
        'width': r.width,
        'height': r.height,
      };
      final double tolerance = drifting.contains(name) ? kDrift : kTolerance;
      want.forEach((String p, double v) {
        final double d = got[p]! - v;
        compared++;
        report.add(
          '| $cell | `$name` | $p | ${v.toStringAsFixed(2)} | '
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

  Map<String, Finder> taxableElements(String title, String value) =>
      <String, Finder>{
        'toolbar': find.byType(LumeToolbar),
        'toolbar.title': find.text(title),
        'toolbar.action1': boxOf(find.byType(LumeIconButton).at(0)),
        'toolbar.action2': boxOf(find.byType(LumeIconButton).at(1)),
        'ctxbar': find.byType(LumeContextBar),
        'segmented': find.byKey(LumeTaxTool.periodKey),
        'kard': find
            .ancestor(
              of: find.byKey(LumeTaxTool.incomeKey),
              matching: find.byType(LumeCard),
            )
            .first,
        'field1': find.byKey(LumeTaxTool.incomeKey),
        'field2': find.byKey(LumeTaxTool.deductionsKey),
        'summary': find.byKey(LumeTaxTool.resultKey),
        'summary.value': find.text(value),
        'table': find.byKey(LumeTaxTool.bandsKey),
        'table.th1': find
            .ancestor(of: find.text('BAND'), matching: find.byType(Container))
            .first,
        'donutwrap': find.byKey(LumeTaxTool.splitKey),
        'btnrow': find.byType(LumeButtonRow),
        'btn1': find.byType(LumeButton).first,
        'srcbar': find.byType(LumeSourceBar),
        'fresh': find.byType(LumeFreshness),
        'related.title': find.text('Related tools'),
        'related': find.byType(LumeRelatedTools),
      };

  const Set<String> textBlocks = <String>{'toolbar.title', 'summary.value'};
  const Set<String> below = <String>{
    'donutwrap',
    'btnrow',
    'btn1',
    'srcbar',
    'fresh',
    'related.title',
    'related',
  };

  // From 600 up the reference sits the app on a stage — 24 of page and a
  // one-point frame on each side (KNOWN_DIFFERENCES, "the stage and the
  // device frame") — so a 700-wide browser holds a 650-wide app. Flutter is
  // pumped at the app's width, which is the layout being compared.
  for (final (String cell, Size size) in <(String, Size)>[
    ('tool_tax_default_pk_390x844_light_en', const Size(390, 5000)),
    ('tool_tax_default_pk_700x900_light_en', const Size(650, 5000)),
    ('tool_tax_default_pk_1100x900_light_en', const Size(1050, 5000)),
  ]) {
    testWidgets('where everything is · $cell', (WidgetTester tester) async {
      final Map<String, dynamic>? web = webCell(cell);
      expect(web, isNotNull, reason: '$cell has not been measured');
      await pumpTax(tester, surface: size);
      final List<String> misses = bounds(
        tester,
        cell,
        web!,
        taxableElements('Tax Calculator', 'Rs 228,900'),
        noWidth: textBlocks,
        drifting: below,
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });
  }

  testWidgets('where everything is · the untaxed composition', (
    WidgetTester tester,
  ) async {
    const String cell = 'tool_tax_default_ae_390x844_light_en';
    final Map<String, dynamic> web = webCell(cell)!;
    await pumpTax(tester, state: 'default_ae', surface: const Size(390, 5000));
    final List<String> misses = bounds(
      tester,
      cell,
      web,
      <String, Finder>{
        'toolbar': find.byType(LumeToolbar),
        'ctxbar': find.byType(LumeContextBar),
        'summary': find.byKey(LumeTaxTool.resultKey),
        'kard': find
            .ancestor(
              of: find.byKey(LumeTaxTool.incomeKey),
              matching: find.byType(LumeCard),
            )
            .first,
        'notecard': find.byType(LumeNoteCard),
        'table': find.byKey(LumeTaxTool.leviesKey),
        'srcbar': find.byType(LumeSourceBar),
        'related': find.byType(LumeRelatedTools),
      },
      drifting: <String>{'notecard', 'table', 'srcbar', 'related'},
    );
    expect(misses, isEmpty, reason: misses.join('\n'));
  });

  // ---------------------------------------------------------------- words

  List<String> textsIn(WidgetTester tester, Finder of) => tester
      .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
      .map((Text t) => (t.data ?? t.textSpan!.toPlainText()).trim())
      .where((String s) => s.isNotEmpty)
      .toList();

  void expectWords(
    WidgetTester tester,
    Map<String, dynamic> web, {
    required bool taxable,
  }) {
    final Map<String, dynamic> k = web['composition'] as Map<String, dynamic>;
    final Map<String, dynamic> header = k['header'] as Map<String, dynamic>;
    expect(find.text(header['title'] as String), findsOneWidget);
    expect(find.text(header['sub'] as String), findsOneWidget);
    expect(
      tester
          .widgetList<LumeIconButton>(find.byType(LumeIconButton))
          .map((LumeIconButton b) => b.label),
      (header['actions'] as List<dynamic>).map(
        (dynamic a) => (a as Map<String, dynamic>)['label'],
      ),
    );
    expect(
      textsIn(tester, find.byType(LumeContextBar)),
      k['context'],
      reason: 'the context strip',
    );

    final Map<String, dynamic> s = k['summary'] as Map<String, dynamic>;
    expect(textsIn(tester, find.byKey(LumeTaxTool.resultKey)), <String>[
      (s['kicker'] as String).toUpperCase(),
      s['value'] as String,
      s['caption'] as String,
      for (final dynamic st in s['stats'] as List<dynamic>) ...<String>[
        (st as Map<String, dynamic>)['value'] as String,
        st['label'] as String,
      ],
    ]);

    final Map<String, dynamic> table = k['table'] as Map<String, dynamic>;
    expect(
      textsIn(
        tester,
        find.byKey(taxable ? LumeTaxTool.bandsKey : LumeTaxTool.leviesKey),
      ),
      <String>[
        for (final dynamic h in table['head'] as List<dynamic>)
          (h as String).toUpperCase(),
        for (final dynamic row in table['rows'] as List<dynamic>)
          ...(row as List<dynamic>).cast<String>(),
      ],
    );

    final List<dynamic> fields = k['fields'] as List<dynamic>;
    final List<EditableText> inputs = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(
      inputs.map((EditableText e) => e.controller.text),
      fields.map((dynamic f) => (f as Map<String, dynamic>)['value']),
    );

    if (taxable) {
      final Map<String, dynamic> d = k['donut'] as Map<String, dynamic>;
      expect(textsIn(tester, find.byKey(LumeTaxTool.splitKey)), <String>[
        d['mid'] as String,
        d['sub'] as String,
        for (final dynamic key in d['keys'] as List<dynamic>) ...<String>[
          (key as Map<String, dynamic>)['label'] as String,
          key['value'] as String,
        ],
      ]);
      expect(
        tester
            .widgetList<LumeButton>(find.byType(LumeButton))
            .map((LumeButton b) => b.label),
        k['buttons'],
      );
      expect(
        textsIn(tester, find.byKey(LumeTaxTool.periodKey)),
        (k['segments'] as List<dynamic>).map(
          (dynamic x) => (x as Map<String, dynamic>)['label'],
        ),
      );
    } else {
      final Map<String, dynamic> note = k['note'] as Map<String, dynamic>;
      expect(find.text(note['title'] as String), findsWidgets);
      expect(find.text(note['text'] as String), findsOneWidget);
      expect(find.byType(LumeDonut), findsNothing);
      expect(find.byKey(LumeTaxTool.periodKey), findsNothing);
    }

    final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
    expect(find.text(src['fresh'] as String), findsOneWidget);
    expect(
      textsIn(
        tester,
        find.byType(LumeSourceLine),
      ).where((String t) => t != '·'),
      src['line'],
    );
    expect(textsIn(tester, find.byType(LumeRelatedTools)), k['related']);
  }

  for (final (String state, String cell, bool taxable)
      in <(String, String, bool)>[
        ('default_pk', 'tool_tax_default_pk_390x844_light_en', true),
        ('default_us', 'tool_tax_default_us_390x844_light_en', true),
        ('muslim_gb', 'tool_tax_muslim_gb_390x844_light_en', true),
        ('default_ae', 'tool_tax_default_ae_390x844_light_en', false),
      ]) {
    testWidgets('what it says · $cell', (WidgetTester tester) async {
      await pumpTax(tester, state: state, surface: const Size(390, 5000));
      expectWords(tester, webCell(cell)!, taxable: taxable);
    });
  }

  testWidgets('what it says · a year', (WidgetTester tester) async {
    await pumpTax(tester, surface: const Size(390, 5000));
    await tester.tap(find.text('Annual'));
    await tester.pumpAndSettle();
    expectWords(
      tester,
      webCell('tool_tax_default_pk_period-year_390x844_light_en')!,
      taxable: true,
    );
  });

  testWidgets('right to left, the order is the reference’s', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> web = webCell(
      'tool_tax_default_pk_390x844_light_ur',
    )!;
    final Map<String, dynamic> b = web['bounds'] as Map<String, dynamic>;
    await pumpTax(
      tester,
      surface: const Size(390, 5000),
      locale: const Locale('ur'),
    );
    expect(
      Directionality.of(tester.element(find.byType(LumeToolFrame))),
      TextDirection.rtl,
    );
    // The first related tool is at the right edge, as `.related__item`'s
    // first child is at 292 in the reference.
    final Rect first = tester.getRect(
      find
          .descendant(
            of: find.byType(LumeRelatedTools),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      first.left,
      closeTo((b['related.item1'] as Map<String, dynamic>)['x'] as num, 1),
    );
    // The back control leads from the right, and the actions close on the left.
    final Rect back = tester.getRect(find.byType(LumeBackButton));
    final Rect share = tester.getRect(find.byType(LumeIconButton).first);
    expect(back.center.dx, greaterThan(share.center.dx));
    // The first segment is Monthly, and it is the right-hand one.
    final Rect seg = tester.getRect(find.byKey(LumeTaxTool.periodKey));
    expect(
      tester.getCenter(find.text('ماہانہ')).dx,
      greaterThan(seg.center.dx),
    );
  });
}
