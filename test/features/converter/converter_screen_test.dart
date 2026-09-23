/// The Unit Converter screen: what it opens on, what it does when it is
/// used, and the two corrections a reader can see from the outside.
///
/// The factor table has its own test (`unit_table_test.dart`). This one is
/// about the screen: that the figures the table computes actually reach it,
/// that `GB → MB` reads a thousand *on the screen* and not only in the table,
/// that a gallon is never drawn as a bare `gal` anywhere a reader looks, and
/// that a reader in Urdu or Arabic gets their own digits without the card
/// reordering itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/features/converter/domain/unit_table.dart';
import 'package:lume/features/converter/presentation/converter_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';
import '../tools/tool_parity.dart';
import 'converter_harness.dart';

void main() {
  group('what it opens on', () {
    testWidgets('Length, metre to kilometre, amount 1', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);

      // `fieldsFor('converter', { amount: 1 })`.
      expect(
        tester
            .widget<TextField>(find.byKey(LumeConverterTool.amountKey))
            .controller!
            .text,
        kLumeConverterOpeningAmount,
      );
      // The reference's own opening pair for Length, and its own answer.
      expect(textsIn(tester, find.byKey(LumeConverterTool.fromKey)), <String>[
        'm',
      ]);
      expect(textsIn(tester, find.byKey(LumeConverterTool.toKey)), <String>[
        'km',
      ]);
      expect(converterResult(tester), '0.001');
    });

    testWidgets('the six categories read as the reference names them', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      expect(
        textsIn(tester, find.byKey(LumeConverterTool.categoriesKey)),
        <String>['Length', 'Weight', 'Volume', 'Area', 'Speed', 'Data'],
      );
    });

    testWidgets('All units holds every unit of the category, at 1 m', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);

      // `u.units.map(...)` — the amount in each, to four places. The mile is
      // the row the reference's truncated 1609.34 and the exact 1609.344
      // agree on once both are rounded for the display.
      expect(converterRow(tester, 'm'), '1');
      expect(converterRow(tester, 'km'), '0.001');
      expect(converterRow(tester, 'cm'), '100');
      expect(converterRow(tester, 'mi'), '0.0006');
      expect(converterRow(tester, 'ft'), '3.2808');
      expect(converterRow(tester, 'in'), '39.3701');
    });
  });

  group('using it', () {
    testWidgets('typing an amount moves the answer and every row', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await typeAmount(tester, '2500');

      expect(converterResult(tester), '2.5');
      expect(converterRow(tester, 'm'), '2,500');
      expect(converterRow(tester, 'km'), '2.5');
      expect(converterRow(tester, 'mi'), '1.5534');
      expect(converterRow(tester, 'ft'), '8,202.0997');
    });

    testWidgets('a decimal amount is read as one', (WidgetTester tester) async {
      await pumpConverter(tester);
      await typeAmount(tester, '1.5');
      expect(converterResult(tester), '0.0015');
      expect(converterRow(tester, 'cm'), '150');
    });

    testWidgets('swapping exchanges the units and the figure', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      expect(converterResult(tester), '0.001');

      await tester.tap(find.byKey(LumeConverterTool.swapKey));
      await tester.pumpAndSettle();

      expect(textsIn(tester, find.byKey(LumeConverterTool.fromKey)), <String>[
        'km',
      ]);
      expect(textsIn(tester, find.byKey(LumeConverterTool.toKey)), <String>[
        'm',
      ]);
      // One kilometre is a thousand metres, and All units is now read from
      // the kilometre.
      expect(converterResult(tester), '1,000');
      expect(converterRow(tester, 'm'), '1,000');
    });

    testWidgets('choosing a unit from the sheet changes the figure', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await pickUnit(tester, LumeConverterTool.toKey, 'mi');

      expect(textsIn(tester, find.byKey(LumeConverterTool.toKey)), <String>[
        'mi',
      ]);
      expect(converterResult(tester), '0.0006');

      await pickUnit(tester, LumeConverterTool.fromKey, 'km');
      expect(converterResult(tester), '0.6214');
    });

    testWidgets('choosing the unit the other side holds swaps them', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      // `to` is already the kilometre; asking `from` for it must not leave
      // the card converting kilometres into kilometres.
      await pickUnit(tester, LumeConverterTool.fromKey, 'km');

      expect(textsIn(tester, find.byKey(LumeConverterTool.fromKey)), <String>[
        'km',
      ]);
      expect(textsIn(tester, find.byKey(LumeConverterTool.toKey)), <String>[
        'm',
      ]);
      expect(converterResult(tester), '1,000');
    });

    testWidgets('every category opens on its own named pair', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);

      for (final LumeUnitKind kind in LumeUnitKind.values) {
        await tapCategory(tester, kind);
        final (String from, String to) = kLumeUnitDefaults[kind]!;
        expect(
          textsIn(tester, find.byKey(LumeConverterTool.fromKey)),
          <String>[lumeUnit(from).symbol],
          reason: '$kind opens from ${lumeUnit(from).id}',
        );
        expect(
          textsIn(tester, find.byKey(LumeConverterTool.toKey)),
          <String>[lumeUnit(to).symbol],
          reason: '$kind opens to ${lumeUnit(to).id}',
        );
        // And the list under it is that category's, not the last one's.
        expect(
          find.byKey(LumeConverterTool.rowKey(from)),
          findsOneWidget,
          reason: '$kind lists its own units',
        );
      }
    });

    testWidgets('a category change keeps the amount the reader typed', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await typeAmount(tester, '12');
      await tapCategory(tester, LumeUnitKind.mass);

      // 12 kg in grams.
      expect(converterResult(tester), '12,000');
    });

    testWidgets('an empty amount reads zero and throws nothing', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await typeAmount(tester, '');

      expect(converterResult(tester), '0');
      expect(converterRow(tester, 'mi'), '0');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the session carries the screen between openings', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      await pumpConverter(tester, session: session);
      await tapCategory(tester, LumeUnitKind.speed);
      await typeAmount(tester, '100');

      await pumpConverter(tester, session: session);
      expect(textsIn(tester, find.byKey(LumeConverterTool.fromKey)), <String>[
        'km/h',
      ]);
      // 100 km/h in miles per hour.
      expect(converterResult(tester), '62.1371');
    });
  });

  group('the corrections a reader can see', () {
    testWidgets('GB to MB reads a thousand, not 1024', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await tapCategory(tester, LumeUnitKind.data);
      await pickUnit(tester, LumeConverterTool.fromKey, 'GB');
      await pickUnit(tester, LumeConverterTool.toKey, 'MB');

      // `context.js:1116` makes this 1,024. A gigabyte is 1,000 megabytes.
      expect(converterResult(tester), '1,000');
      expect(converterRow(tester, 'MB'), '1,000');
      // And the binary factor the reference hid under `GB` is here under its
      // own name: 1 GB is 953.6743 MiB.
      expect(converterRow(tester, 'MiB'), '953.6743');
    });

    testWidgets('the Data note is drawn, and only for Data', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      expect(find.byKey(LumeConverterTool.dataNoteKey), findsNothing);

      await tapCategory(tester, LumeUnitKind.data);
      expect(find.byKey(LumeConverterTool.dataNoteKey), findsOneWidget);
      expect(
        textsIn(tester, find.byKey(LumeConverterTool.dataNoteKey)),
        contains(
          'kB, MB, GB and TB are powers of 1,000. '
          'KiB, MiB, GiB and TiB are powers of 1,024.',
        ),
      );

      // Every other category has nothing to disambiguate and says nothing.
      for (final LumeUnitKind kind in LumeUnitKind.values) {
        if (kind == LumeUnitKind.data) continue;
        await tapCategory(tester, kind);
        expect(
          find.byKey(LumeConverterTool.dataNoteKey),
          findsNothing,
          reason: '$kind carries no note',
        );
      }
    });

    testWidgets('both gallons are reachable, and neither is a bare gal', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await tapCategory(tester, LumeUnitKind.volume);

      // Both are in the list, told apart by name and by symbol.
      expect(
        textsIn(tester, find.byKey(LumeConverterTool.rowKey('gal_us'))),
        containsAll(<String>['Gallon (US)', 'gal (US)']),
      );
      expect(
        textsIn(tester, find.byKey(LumeConverterTool.rowKey('gal_imp'))),
        containsAll(<String>['Gallon (imperial)', 'gal (imperial)']),
      );

      // And they are different volumes: a litre is 0.2642 US gallons and
      // 0.22 imperial ones. The reference has one `gal`, and it is the US
      // one, so a UK reader is told 16.7 % too little.
      expect(converterRow(tester, 'gal_us'), '0.2642');
      expect(converterRow(tester, 'gal_imp'), '0.22');

      // Nowhere on the screen — the card, the rows, the sheet — does the
      // word stand on its own.
      for (final String unit in <String>['gal_us', 'gal_imp']) {
        await pickUnit(tester, LumeConverterTool.fromKey, unit);
        expect(
          textsIn(tester, find.byType(LumeConverterTool)),
          isNot(contains('gal')),
          reason: '$unit is never written as a bare gal',
        );
      }
    });

    testWidgets('the unit sheet lists the category, and only it', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await tester.tap(find.byKey(LumeConverterTool.fromKey));
      await tester.pumpAndSettle();

      for (final LumeUnit unit in lumeUnitsOf(LumeUnitKind.length)) {
        expect(
          find.byKey(LumeConverterTool.optionKey(unit.id)),
          findsOneWidget,
        );
      }
      expect(find.byKey(LumeConverterTool.optionKey('kg')), findsNothing);
    });

    testWidgets('there is no Recent section', (WidgetTester tester) async {
      await pumpConverter(tester);
      final List<String> screen = textsIn(
        tester,
        find.byType(LumeConverterTool),
      );
      // The reference's two literals, and the head above them.
      expect(screen, isNot(contains('Recent')));
      expect(screen.where((String s) => s.contains('6.21')), isEmpty);
      expect(screen.where((String s) => s.contains('2.20')), isEmpty);
    });
  });

  group('what it claims', () {
    testWidgets('On device, with no sample-data mark', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);

      // `inputOnly`: every figure is the reader's own amount converted
      // exactly, so there is nothing to disclose.
      expect(find.byKey(LumeSourceLine.sampleKey), findsNothing);
      expect(referenceSourceLine(tester), contains('On device'));
    });
  });

  group('other languages, and other shapes', () {
    // The figures go through the locale's own formatter, and that is the
    // whole of the claim: whatever digits, grouping and separator `Intl`
    // gives a reader, that is what the screen shows them. The oracle is
    // `intl` itself over the same tag `LumeFormatting` builds, so a data
    // update that brings ur or ar their own numerals moves both sides
    // together rather than failing here. As the data stands, `ur_PK` and
    // `ar_PK` both write Latin digits with a comma and a point — worth
    // knowing, and not worth asserting as a constant.
    testWidgets('Urdu reads its figures through the locale', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester, locale: const Locale('ur'));
      await typeAmount(tester, '2500');

      expect(
        converterResult(tester),
        intl.NumberFormat.decimalPattern('ur_PK').format(2.5),
      );
      expect(
        converterRow(tester, 'm'),
        intl.NumberFormat.decimalPattern('ur_PK').format(2500),
      );
      // And not the machine decimal an unformatted readout would be.
      expect(converterRow(tester, 'm'), isNot('2500'));
    });

    testWidgets('Arabic gets its own numerals, and the card does not reorder', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester, locale: const Locale('ar'));
      await typeAmount(tester, '2500');

      expect(
        converterResult(tester),
        intl.NumberFormat.decimalPattern('ar_PK').format(2.5),
      );
      expect(tester.takeException(), isNull);

      // `shared.css:646-652` forces `direction: ltr` on exactly these two, so
      // the digits keep their order inside a right-to-left page.
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeConverterTool.resultKey)),
        ),
        TextDirection.ltr,
      );
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeConverterTool.amountKey)),
        ),
        TextDirection.ltr,
      );
      // The row around them is the page's.
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeConverterTool.cardKey)),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('an Arabic-Indic amount typed in is read as a number', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester, locale: const Locale('ar'));
      // U+0662 U+0665 U+0660 U+0660 — 2500, as an Arabic keyboard sends it.
      await typeAmount(tester, '\u0662\u0665\u0660\u0660');
      expect(
        converterResult(tester),
        intl.NumberFormat.decimalPattern('ar_PK').format(2.5),
      );
    });

    for (final (String name, Size surface) in <(String, Size)>[
      ('a phone', LumeViewport.phone),
      ('a landscape phone', LumeViewport.landscapePhone),
      ('a wide window', LumeViewport.expanded),
    ]) {
      testWidgets('$name draws without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpConverter(tester, surface: surface);
        expect(tester.takeException(), isNull);
        await tapCategory(tester, LumeUnitKind.volume);
        await pickUnit(tester, LumeConverterTool.fromKey, 'gal_imp');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('200 % text overflows nothing this screen draws', (
      WidgetTester tester,
    ) async {
      // Two shared components do overflow at 200 %, and both are named in
      // [kSharedOverflowSources] with the reason. What this asserts is that
      // nothing the converter draws itself — the chip strip, the card, its
      // two sides, the swap, the note — adds a third.
      final List<FlutterErrorDetails> errors = await converterErrors(() async {
        await pumpConverter(tester, surface: LumeViewport.phone, textScale: 2);
        await tapCategory(tester, LumeUnitKind.volume);
        await typeAmount(tester, '123456');
        await pickUnit(tester, LumeConverterTool.fromKey, 'gal_imp');
      });

      expect(
        errors
            .where((FlutterErrorDetails d) => !fromSharedComponent(d))
            .map((FlutterErrorDetails d) => d.exception.toString())
            .toList(),
        isEmpty,
        reason: 'nothing the converter draws itself overflows at 200 %',
      );
      expect(converterResult(tester), isNotEmpty);
    });

    testWidgets('dark mode draws', (WidgetTester tester) async {
      await pumpConverter(tester, theme: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(converterResult(tester), '0.001');
    });
  });

  group('what a screen reader hears', () {
    testWidgets('the answer is a relation, not a loose number', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await typeAmount(tester, '5');
      expect(converterResultSpoken(tester), '5 m is 0.005 km');
    });

    testWidgets('the answer names the gallon it means', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      await tapCategory(tester, LumeUnitKind.volume);
      await pickUnit(tester, LumeConverterTool.toKey, 'gal_imp');
      expect(converterResultSpoken(tester), '1 L is 0.22 gal (imperial)');
    });

    testWidgets('Tab reaches every control on the card', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester);
      final List<BuildContext> focused = await tabThrough(tester);

      // A switch-access reader gets to all of it: the six categories, the
      // amount, both unit halves and the swap.
      for (final LumeUnitKind kind in LumeUnitKind.values) {
        expect(
          reachedKey(focused, LumeConverterTool.categoryKey(kind)),
          isTrue,
          reason: '$kind is reachable',
        );
      }
      expect(reachedKey(focused, LumeConverterTool.amountKey), isTrue);
      expect(reachedKey(focused, LumeConverterTool.fromKey), isTrue);
      expect(reachedKey(focused, LumeConverterTool.toKey), isTrue);
      expect(reachedKey(focused, LumeConverterTool.swapKey), isTrue);
    });

    testWidgets('every control has a name', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpConverter(tester);

      // The strip, the two units, the field and the swap.
      expect(find.bySemanticsLabel('What to convert'), findsOneWidget);
      expect(find.bySemanticsLabel('From, Metre'), findsNWidgets(2));
      expect(find.bySemanticsLabel('To, Kilometre'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Amount'), findsOneWidget);
      expect(find.bySemanticsLabel('Swap'), findsOneWidget);
      handle.dispose();
    });
  });
}
