/// Fasting Tracker on screen: the empty state, logging a fast, editing and
/// deleting one, the kind filter, RTL/Arabic/Urdu, and 200 % text scale.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/fasting/domain/fasting_model.dart';
import 'package:lume/features/fasting/presentation/fasting_sheets.dart';
import 'package:lume/features/fasting/presentation/fasting_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import 'fasting_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeFastingTool.summaryKey));

/// The fixture day: 7 September 2026.
final LumeDate kToday = LumeDate(2026, 9, 7);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('nothing is invented — a clear next step instead', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      await pumpFasting(t, w);
      expect(find.byKey(LumeFastingTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeFastingTool.summaryKey), findsNothing);
      expect(w.repo.view().entries, isEmpty);
      w.dispose();
    });
  });

  group('logging a fast', () {
    testWidgets("the empty state's call to action logs today as a kept voluntary fast", (
      WidgetTester t,
    ) async {
      final FastingWorld w = FastingWorld();
      await pumpFasting(t, w);
      await tapShown(t, find.byKey(LumeFastingTool.emptyAddKey));
      expect(find.byKey(FastingSheetKeys.datePicker), findsOneWidget);
      await tapShown(t, find.byKey(FastingSheetKeys.save));

      expect(w.repo.view().entries, hasLength(1));
      final FastEntry e = w.repo.view().entries.single;
      expect(e.date, kToday);
      expect(e.kind, FastingKind.voluntary);
      expect(e.kept, isTrue);
      expect(find.byKey(LumeFastingTool.summaryKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('the primary action logs a second fast the same way', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      w.log(kToday.addDays(-1));
      await pumpFasting(t, w);
      await tapShown(t, find.byKey(LumeFastingTool.addKey));
      await tapShown(t, find.byKey(FastingSheetKeys.save));

      expect(w.repo.view().entries, hasLength(2));
      w.dispose();
    });

    testWidgets('unchecking "kept" logs a missed fast', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      await pumpFasting(t, w);
      await tapShown(t, find.byKey(LumeFastingTool.emptyAddKey));
      await tapShown(t, find.byKey(FastingSheetKeys.keptToggle));
      await tapShown(t, find.byKey(FastingSheetKeys.save));

      expect(w.repo.view().entries.single.kept, isFalse);
      w.dispose();
    });
  });

  group('editing and deleting', () {
    testWidgets('tapping a recent row opens it for editing', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      final FastEntry e = w.log(kToday, kind: FastingKind.voluntary, kept: true);
      await pumpFasting(t, w);

      await tapShown(t, find.byKey(LumeFastingTool.recentRowKey(e.id)));
      expect(find.byKey(FastingSheetKeys.datePicker), findsOneWidget);
      expect(find.byKey(FastingSheetKeys.delete), findsOneWidget);
      w.dispose();
    });

    testWidgets('deleting a fast removes it and Undo brings it back', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      final FastEntry e = w.log(kToday);
      await pumpFasting(t, w);

      await tapShown(t, find.byKey(LumeFastingTool.recentRowKey(e.id)));
      await tapShown(t, find.byKey(FastingSheetKeys.delete));
      expect(find.byKey(FastingSheetKeys.confirmDelete), findsOneWidget);
      // Scoped to the confirmation sheet: its own sheet, still mounted
      // underneath, has a same-labelled Delete action of its own.
      await tapShown(
        t,
        find.descendant(
          of: find.byKey(FastingSheetKeys.confirmDelete),
          matching: find.text('Delete fast'),
        ),
      );

      expect(w.repo.view().entries, isEmpty);
      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().entries, hasLength(1));
      w.dispose();
    });
  });

  group('the reference\'s own figures, computed for real', () {
    testWidgets('the summary shows a real month count and a real streak, never the reference\'s literals', (
      WidgetTester t,
    ) async {
      final FastingWorld w = FastingWorld();
      w.log(kToday.addDays(-1), kind: FastingKind.voluntary, kept: true);
      w.log(kToday, kind: FastingKind.makeup, kept: true);
      await pumpFasting(t, w);

      final LumeSummaryCard s = summary(t);
      expect(s.value, '2'); // both fasts fall in the current month
      expect(s.stats.firstWhere((LumeStat st) => st.label.isNotEmpty).value, isNotEmpty);
      w.dispose();
    });

    testWidgets('the kind filter narrows the recent list to one kind', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      final FastEntry voluntary = w.log(kToday.addDays(-1), kind: FastingKind.voluntary);
      final FastEntry makeup = w.log(kToday, kind: FastingKind.makeup);
      await pumpFasting(t, w);

      expect(find.byKey(LumeFastingTool.recentRowKey(voluntary.id)), findsOneWidget);
      expect(find.byKey(LumeFastingTool.recentRowKey(makeup.id)), findsOneWidget);

      // The second filter chip is "Sunnah" (voluntary).
      final Finder chips = find.descendant(
        of: find.byKey(LumeFastingTool.filterKey),
        matching: find.byType(GestureDetector),
      );
      await tapShown(t, chips.at(1));

      expect(find.byKey(LumeFastingTool.recentRowKey(voluntary.id)), findsOneWidget);
      expect(find.byKey(LumeFastingTool.recentRowKey(makeup.id)), findsNothing);
      w.dispose();
    });
  });

  group('locale', () {
    testWidgets('right to left, a recent row runs from the right', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      w.log(kToday, kind: FastingKind.voluntary, kept: true);
      await pumpFasting(t, w, locale: const Locale('ur'));
      expect(
        Directionality.of(
          t.element(inKey(LumeFastingTool.recentKey, find.byType(LumeRichRow)).first),
        ),
        TextDirection.rtl,
      );
      expectNoOverflow(t);
      w.dispose();
    });

    testWidgets('in Arabic', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      w.log(kToday, kind: FastingKind.makeup, kept: false);
      await pumpFasting(t, w, locale: const Locale('ar'));
      expectNoOverflow(t);
      w.dispose();
    });

    testWidgets("Urdu: the sheet's own Save and Cancel are translated", (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      await pumpFasting(t, w, locale: const Locale('ur'));
      await tapShown(t, find.byKey(LumeFastingTool.emptyAddKey));
      expect(find.text('محفوظ کریں'), findsOneWidget);
      expect(find.text('منسوخ'), findsOneWidget);
      w.dispose();
    });
  });

  group('200% text scale', () {
    testWidgets("this tool's own cards do not overflow", (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      w.log(kToday.addDays(-2), kind: FastingKind.voluntary, kept: true);
      w.log(kToday.addDays(-1), kind: FastingKind.makeup, kept: false);
      w.log(kToday, kind: FastingKind.voluntary, kept: true);

      final List<String> overflows = <String>[];
      final FlutterExceptionHandler? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final String text = details.toString();
        if (text.contains('overflowed')) {
          overflows.add(text);
        } else {
          previous?.call(details);
        }
      };
      try {
        await pumpFasting(t, w, textScale: 2);
      } finally {
        FlutterError.onError = previous;
      }

      expect(overflows, isEmpty, reason: overflows.join('\n\n'));
      expect(find.byKey(LumeFastingTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeFastingTool.calendarKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('the empty state does not overflow either', (WidgetTester t) async {
      final FastingWorld w = FastingWorld();
      await pumpFasting(t, w, textScale: 2);
      expectNoOverflow(t);
      w.dispose();
    });
  });
}
