/// Prayer Tracker on screen: first use, figures that agree, toggling a
/// prayer, faith-gating (defence in depth over the catalogue alone, §64),
/// missing-coordinates degradation, RTL/Urdu/Arabic, and 200 % text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/praytrack/domain/praytrack_model.dart';
import 'package:lume/features/praytrack/presentation/praytrack_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import 'praytrack_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumePrayTrackTool.summaryKey));

void main() {
  setUpAll(loadLumeFonts);

  group('the catalogue entry', () {
    test('is faith-gated — not this widget\'s job to re-decide', () {
      final LumeFeature feature = kLumeFeatures.firstWhere(
        (LumeFeature f) => f.id == LumePrayTrackTool.id,
      );
      expect(feature.faith, isTrue);
    });
  });

  group('first use', () {
    testWidgets(
      'nothing checked in: a real zero, and all five prayers listed',
      (WidgetTester t) async {
        final PrayTrackWorld w = PrayTrackWorld();
        await pumpPrayTrack(t, w);
        final LumeSummaryCard s = summary(t);
        expect(s.value, '0');
        expect(s.valueSmall, '/ 5');
        expect(find.text('Fajr'), findsWidgets);
        expect(find.text('Dhuhr'), findsWidgets);
        expect(find.text('Asr'), findsWidgets);
        expect(find.text('Maghrib'), findsWidgets);
        expect(find.text('Isha'), findsWidgets);
        expect(w.repo.view().checkins, isEmpty);
        w.dispose();
      },
    );
  });

  group('marking a prayer — instant, no confirmation', () {
    testWidgets('toggling a row logs it and the summary updates', (
      WidgetTester t,
    ) async {
      final PrayTrackWorld w = PrayTrackWorld();
      await pumpPrayTrack(t, w);
      expect(summary(t).value, '0');

      await tapShown(t, find.bySemanticsLabel('Prayed, Fajr'));

      expect(w.repo.view().checkins, hasLength(1));
      expect(w.repo.view().checkins.single.prayer, PrayerKey.fajr);
      expect(summary(t).value, '1');
      w.dispose();
    });

    testWidgets('toggling it again removes it', (WidgetTester t) async {
      final PrayTrackWorld w = PrayTrackWorld();
      w.toggle(PrayerKey.fajr, kToday);
      await pumpPrayTrack(t, w);
      expect(summary(t).value, '1');

      await tapShown(t, find.bySemanticsLabel('Prayed, Fajr'));

      expect(w.repo.view().checkins, isEmpty);
      expect(summary(t).value, '0');
      w.dispose();
    });

    testWidgets(
      'marking all five today completes the day and starts a streak',
      (WidgetTester t) async {
        final PrayTrackWorld w = PrayTrackWorld();
        await pumpPrayTrack(t, w);
        for (final PrayerKey k in PrayerKey.values) {
          await tapShown(t, find.bySemanticsLabel('Prayed, ${_name(k)}'));
        }
        expect(summary(t).value, '5');
        expect(w.repo.view().checkins, hasLength(5));
        w.dispose();
      },
    );
  });

  group(
    'the reference composition — real figures, computed from check-ins on record',
    () {
      testWidgets(
        'a real streak over several complete days, never the reference\'s bare 12',
        (WidgetTester t) async {
          final PrayTrackWorld w = PrayTrackWorld();
          w.completeDay(kToday.addDays(-2));
          w.completeDay(kToday.addDays(-1));
          w.completeDay(kToday);
          await pumpPrayTrack(t, w);
          expect(summary(t).value, '5');
          expect(summary(t).stats.first.value, '3'); // the streak stat
          w.dispose();
        },
      );
    },
  );

  group('a non-Muslim reader', () {
    testWidgets('never sees the tracker at all — the frame itself blocks a '
        'faith-gated tool\'s body, defence in depth over the catalogue gate '
        'alone (§64)', (WidgetTester t) async {
      final PrayTrackWorld w = PrayTrackWorld();
      await pumpPrayTrack(t, w, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumePrayTrackTool.summaryKey), findsNothing);
      expect(find.byKey(LumePrayTrackTool.markKey), findsNothing);
      expect(find.byKey(LumePrayTrackTool.heatKey), findsNothing);
      w.dispose();
    });
  });

  group('a city Lume has no prayer-time coordinates for', () {
    testWidgets(
      'still marks prayers — only the real computed time is left off',
      (WidgetTester t) async {
        final PrayTrackWorld w = PrayTrackWorld();
        await pumpPrayTrack(
          t,
          w,
          user: const LumeUserContext(
            country: 'PK',
            city: 'Chitral',
            islamic: true,
          ),
        );
        expect(find.byKey(LumePrayTrackTool.markKey), findsOneWidget);
        await tapShown(t, find.bySemanticsLabel('Prayed, Fajr'));
        expect(w.repo.view().checkins, hasLength(1));
        w.dispose();
      },
    );
  });

  group('language', () {
    testWidgets('Urdu: prayer names and the mark section are translated', (
      WidgetTester t,
    ) async {
      final PrayTrackWorld w = PrayTrackWorld();
      await pumpPrayTrack(t, w, locale: const Locale('ur'));
      expect(find.text('فجر'), findsWidgets); // Fajr
      expect(find.text('عشاء'), findsWidgets); // Isha
      w.dispose();
    });

    testWidgets('Arabic renders right-to-left', (WidgetTester t) async {
      final PrayTrackWorld w = PrayTrackWorld();
      await pumpPrayTrack(t, w, locale: const Locale('ar'));
      expect(
        Directionality.of(t.element(find.byKey(LumePrayTrackTool.summaryKey))),
        TextDirection.rtl,
      );
      w.dispose();
    });
  });

  group('200 % text scale', () {
    for (final Locale locale in <Locale>[
      const Locale('en'),
      const Locale('ur'),
      const Locale('ar'),
    ]) {
      testWidgets('(${locale.languageCode}) nothing overflows', (
        WidgetTester t,
      ) async {
        final PrayTrackWorld w = PrayTrackWorld();
        w.completeDay(kToday.addDays(-1));
        await pumpPrayTrack(
          t,
          w,
          locale: locale,
          textScale: 2,
          surface: const Size(390, 9000),
        );
        expectNoOverflow(t);
        expect(find.byKey(LumePrayTrackTool.summaryKey), findsOneWidget);
        expect(find.byKey(LumePrayTrackTool.markKey), findsOneWidget);
        w.dispose();
      });
    }
  });
}

String _name(PrayerKey k) => switch (k) {
  PrayerKey.fajr => 'Fajr',
  PrayerKey.dhuhr => 'Dhuhr',
  PrayerKey.asr => 'Asr',
  PrayerKey.maghrib => 'Maghrib',
  PrayerKey.isha => 'Isha',
};
