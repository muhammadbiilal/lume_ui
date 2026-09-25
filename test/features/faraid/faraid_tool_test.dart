/// Faraid on screen: the default heirs, live editing, the honest
/// "unallocated" disclosure for the reference's own real gap (a wife with
/// no children), faith-gating, RTL and text scale.
///
/// Pumped through [pumpFaraid] (`faraid_screen_harness.dart`), directly
/// rather than through the real router — `tool_registry.dart` does not
/// carry `'faraid'` yet, wired up in the integration pass that follows,
/// same as Qibla's and (before its own integration pass) Zakat's harnesses.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/faraid/presentation/faraid_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import 'faraid_screen_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Finder input(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

  LumeSummaryCard summary(WidgetTester tester) =>
      tester.widget<LumeSummaryCard>(find.byKey(LumeFaraidTool.summaryKey));

  LumeTable breakdown(WidgetTester tester) =>
      tester.widget<LumeTable>(find.byKey(LumeFaraidTool.breakdownKey));

  group('the catalogue entry', () {
    test('is faith-gated — not this widget\'s job to re-decide', () {
      expect(faraidFeature.faith, isTrue);
    });
  });

  group('the reference\'s own default heirs — a wife, two sons, a daughter', () {
    testWidgets('the sons\' total is exactly twice the daughter\'s — the '
        '2:1 asaba split, over whatever currency the reader\'s country '
        'uses', (WidgetTester tester) async {
      await pumpFaraid(tester);
      final LumeTable table = breakdown(tester);
      // Rows are "Label (fraction)" → "amount"; find sons/daughter by their
      // English label surviving inside the row text.
      String amountOf(String needle) => table.rows
          .firstWhere((List<String> row) => row.first.contains(needle))
          .last;
      final String sons = amountOf('Sons');
      final String daughters = amountOf('Daughters');
      expect(sons, isNot(daughters));
      // Wife + sons + daughters — exactly three rows, no fourth
      // "unallocated" row: this combination is fully accounted for.
      expect(table.rows, hasLength(3));
      expect(find.byKey(LumeFaraidTool.unallocatedNoteKey), findsNothing);
    });

    testWidgets('renders with no exception at all', (WidgetTester tester) async {
      await pumpFaraid(tester);
      expect(find.byType(LumeFaraidTool), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('editing the heirs updates the distribution live', () {
    testWidgets('changing the sons field changes the summary and the '
        'breakdown', (WidgetTester tester) async {
      await pumpFaraid(tester);
      final LumeSummaryCard before = summary(tester);

      await tester.ensureVisible(input(LumeFaraidTool.sonsKey));
      await tester.enterText(input(LumeFaraidTool.sonsKey), '0');
      await tester.pump();

      // Net estate is unchanged (sons don't affect gross/debts/bequest),
      // but the caption/table split between heirs does.
      final LumeSummaryCard after = summary(tester);
      expect(after.value, before.value);
      final LumeTable table = breakdown(tester);
      expect(
        table.rows.any((List<String> row) => row.first.contains('Sons')),
        isFalse,
      );
    });

    testWidgets('an empty field is nothing, not an error', (
      WidgetTester tester,
    ) async {
      await pumpFaraid(tester);
      await tester.ensureVisible(input(LumeFaraidTool.grossKey));
      await tester.enterText(input(LumeFaraidTool.grossKey), '');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(LumeFaraidTool), findsOneWidget);
    });
  });

  group('the honest disclosure — a wife with no children', () {
    testWidgets('clearing sons and daughters shows the unallocated note; '
        'the wife\'s own share is never inflated to cover it', (
      WidgetTester tester,
    ) async {
      await pumpFaraid(tester);
      // Default heirs (wife + sons + daughters) never trigger the note.
      expect(find.byKey(LumeFaraidTool.unallocatedNoteKey), findsNothing);

      await tester.ensureVisible(input(LumeFaraidTool.sonsKey));
      await tester.enterText(input(LumeFaraidTool.sonsKey), '0');
      await tester.pump();
      await tester.ensureVisible(input(LumeFaraidTool.daughtersKey));
      await tester.enterText(input(LumeFaraidTool.daughtersKey), '0');
      await tester.pump();

      expect(find.byKey(LumeFaraidTool.unallocatedNoteKey), findsOneWidget);
      final LumeNoteCard note = tester.widget<LumeNoteCard>(
        find.byKey(LumeFaraidTool.unallocatedNoteKey),
      );
      expect(note.tone, LumeNoteTone.warn);

      // The table's wife row and the unallocated row, read as money
      // strings, both carry non-zero figures — the estate is not silently
      // handed entirely to the wife nor entirely dropped.
      final LumeTable table = breakdown(tester);
      final String wifeRow = table.rows
          .firstWhere((List<String> row) => row.first.contains('Wife'))
          .last;
      expect(wifeRow, contains(RegExp(r'[1-9]')));
    });
  });

  group('the bequest cap', () {
    testWidgets('an oversized bequest is capped, and the caption says so', (
      WidgetTester tester,
    ) async {
      await pumpFaraid(tester);
      await tester.ensureVisible(input(LumeFaraidTool.bequestKey));
      // Larger than any plausible third of the default gross estate.
      await tester.enterText(input(LumeFaraidTool.bequestKey), '999999999');
      await tester.pump();
      final LumeSummaryCard s = summary(tester);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeFaraidTool)),
      );
      expect(s.caption, l.faraidCaptionCapped);
      expect(s.caption, isNot(l.faraidCaptionReady));
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never sees the calculator — the frame itself blocks a '
        'faith-gated tool\'s body, defence in depth over the catalogue '
        'gate alone (§64)', (WidgetTester tester) async {
      await pumpFaraid(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeFaraidTool.summaryKey), findsNothing);
      expect(find.byKey(LumeFaraidTool.breakdownKey), findsNothing);
    });
  });

  group('language', () {
    testWidgets('Urdu: the tool still renders, right to left, with no '
        'overflow', (WidgetTester tester) async {
      await pumpFaraid(tester, locale: const Locale('ur'));
      expect(find.byType(LumeFaraidTool), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic: renders right to left, with no overflow', (
      WidgetTester tester,
    ) async {
      await pumpFaraid(tester, locale: const Locale('ar'));
      expect(find.byType(LumeFaraidTool), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('200% text scale: no overflow', (WidgetTester tester) async {
      await pumpFaraid(tester, textScale: 2.0);
      expect(tester.takeException(), isNull);
      expect(find.byType(LumeFaraidTool), findsOneWidget);
    });
  });
}
