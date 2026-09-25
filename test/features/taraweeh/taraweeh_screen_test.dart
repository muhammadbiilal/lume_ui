/// Taraweeh on screen: first use, logging tonight, rakaat and Juz, Khatm
/// progress, RTL/Urdu and 200% text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/taraweeh/presentation/taraweeh_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import 'taraweeh_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeTaraweehTool.summaryKey));

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('nothing logged, the summary shows a real zero', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      await pumpTaraweeh(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.value, '0');
      expect(w.repo.view().nights, isEmpty);
      expect(find.byKey(LumeTaraweehTool.tonightKey), findsOneWidget);
      // Rakaat and Juz only appear once tonight has an entry.
      expect(find.byKey(LumeTaraweehTool.rakaatKey), findsNothing);
      expect(find.byKey(LumeTaraweehTool.juzKey), findsNothing);
      w.dispose();
    });
  });

  group('logging tonight', () {
    testWidgets('toggling the row logs tonight and the summary updates', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      await pumpTaraweeh(t, w);
      expect(summary(t).value, '0');

      await tapShown(t, find.bySemanticsLabel('Prayed tonight, Tonight'));

      expect(w.repo.view().nights, hasLength(1));
      expect(w.repo.view().nights.single.date, kToday);
      expect(w.repo.view().nights.single.rakaat, 20);
      expect(summary(t).value, '1');
      expect(find.byKey(LumeTaraweehTool.rakaatKey), findsOneWidget);
      expect(find.byKey(LumeTaraweehTool.juzKey), findsOneWidget);
      w.dispose();
    });

    testWidgets(
      'a streak already running keeps counting once tonight is added',
      (WidgetTester t) async {
        final TaraweehWorld w = TaraweehWorld();
        w.logTonight(kToday.addDays(-2));
        w.logTonight(kToday.addDays(-1));
        await pumpTaraweeh(t, w);
        expect(summary(t).value, '2');

        await tapShown(t, find.bySemanticsLabel('Prayed tonight, Tonight'));

        expect(summary(t).value, '3');
        w.dispose();
      },
    );

    testWidgets('toggling it off again clears tonight, with Undo', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      w.logTonight(kToday, rakaat: 8);
      await pumpTaraweeh(t, w);
      expect(summary(t).value, '1');

      await tapShown(t, find.bySemanticsLabel('Prayed tonight, Tonight'));
      expect(w.repo.view().nights, isEmpty);
      expect(summary(t).value, '0');
      expect(find.byKey(LumeTaraweehTool.rakaatKey), findsNothing);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().nights, hasLength(1));
      expect(w.repo.view().nights.single.rakaat, 8);
      expect(summary(t).value, '1');
      w.dispose();
    });
  });

  group('rakaat', () {
    testWidgets('choosing 8 rakaat updates tonight\'s entry', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      w.logTonight(kToday, rakaat: 20);
      await pumpTaraweeh(t, w);

      await tapShown(t, find.text('8 rakaat'));

      expect(w.repo.view().nights.single.rakaat, 8);
      w.dispose();
    });
  });

  group('juz — Khatm progress', () {
    testWidgets('incrementing the Juz stepper notes a Juz for tonight', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      w.logTonight(kToday);
      await pumpTaraweeh(t, w);

      await tapShown(t, find.bySemanticsLabel('More Juz reached'));

      expect(w.repo.view().nights.single.juz, 1);
      w.dispose();
    });

    testWidgets('decrementing from Juz 1 clears it back to not noted', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      w.logTonight(kToday);
      w.repo.setJuz(kToday, 1);
      await pumpTaraweeh(t, w);

      await tapShown(t, find.bySemanticsLabel('Fewer Juz reached'));

      expect(w.repo.view().nights.single.juz, isNull);
      w.dispose();
    });

    testWidgets('progress reflects distinct Juz logged across nights', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      for (int i = 0; i < 5; i++) {
        w.logTonight(kToday.addDays(-i));
        w.repo.setJuz(kToday.addDays(-i), i + 1);
      }
      await pumpTaraweeh(t, w);

      final LumeMeterRow meter = t.widget<LumeMeterRow>(
        find.byKey(LumeTaraweehTool.progressKey),
      );
      expect(meter.value, '5 of 30');
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: tonight\'s row is translated', (WidgetTester t) async {
      final TaraweehWorld w = TaraweehWorld();
      await pumpTaraweeh(t, w, locale: const Locale('ur'));
      expect(find.byType(LumeRecordRow), findsOneWidget);
      w.dispose();
    });

    testWidgets('Arabic: renders right-to-left with no overflow', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      w.logTonight(kToday);
      await pumpTaraweeh(t, w, locale: const Locale('ar'));
      expectNoOverflow(t);
      w.dispose();
    });
  });

  group('accessibility', () {
    testWidgets('200% text scale does not overflow, with a night logged', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      w.logTonight(kToday);
      w.repo.setJuz(kToday, 5);
      await pumpTaraweeh(t, w, textScale: 2);
      expectNoOverflow(t);
      expect(find.byKey(LumeTaraweehTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeTaraweehTool.calendarKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('200% text scale does not overflow on first use either', (
      WidgetTester t,
    ) async {
      final TaraweehWorld w = TaraweehWorld();
      await pumpTaraweeh(t, w, textScale: 2);
      expectNoOverflow(t);
      w.dispose();
    });
  });
}
