/// To-dos on the IANA database: the reader's calendar date in the resolved
/// zone, every segment counted in local calendar dates, and an explicit zone
/// that cannot be read shown as such — never grouped on another zone's day.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/time_zone_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/presentation/record_family.dart';
import 'package:lume/features/todos/domain/todo_family.dart';
import 'package:lume/features/todos/presentation/todos_tool.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'wave2_harness.dart';

final LumeTimeZoneService zones = LumeTimeZoneService.shared;

LumeRecordContext at(DateTime instant, LumeZoneResolution zone) =>
    LumeRecordContext(
      l: AppLocalizationsEn(),
      f: const LumeFormatting(locale: Locale('en'), countryCode: 'PK'),
      now: instant,
      zone: zone,
      currency: 'PKR',
    );

LumeRecordContext inZone(DateTime instant, String id) =>
    at(instant, zones.resolveId(id));

final LumeMemoryRecordRepository store = wave2Store()..open('todos');

LumeTodo task(DateTime? due, {bool done = false}) =>
    const LumeTodoFamily().read(
      store.create('todos', <String, Object?>{
        'label': 'x',
        'due': due == null ? '' : lumeIsoDay(due, 0),
        'done': done,
      }).record!,
      inZone(kFixtureInstant, 'Asia/Karachi'),
    );

Set<LumeTodoWhen> segments(LumeTodo x, DateTime today) => <LumeTodoWhen>{
  for (final LumeTodoWhen w in LumeTodoWhen.values)
    if (w.holds(x, today)) w,
};

LumeProfileRepository reader({String? zone, String country = 'PK'}) =>
    LumeMemoryProfileRepository(
      initial: taxReader(country: country).copyWith(timeZone: zone),
    );

void main() {
  setUpAll(loadLumeFonts);

  group('the reader\'s date, in the resolved zone', () {
    // (zone, instant, the date it already is there)
    for (final (String id, DateTime instant, DateTime date)
        in <(String, DateTime, DateTime)>[
          (
            'Asia/Karachi',
            DateTime.utc(2026, 9, 7, 20, 30),
            DateTime(2026, 9, 8),
          ),
          ('Asia/Tokyo', DateTime.utc(2026, 9, 7, 16), DateTime(2026, 9, 8)),
          (
            'America/New_York',
            DateTime.utc(2026, 9, 7, 20, 30),
            DateTime(2026, 9, 7),
          ),
          (
            'Europe/Kyiv',
            DateTime.utc(2026, 9, 7, 21, 30),
            DateTime(2026, 9, 8),
          ),
          (
            'Europe/Kiev',
            DateTime.utc(2026, 9, 7, 21, 30),
            DateTime(2026, 9, 8),
          ),
          // Fractional offsets: +5:30 and +5:45.
          (
            'Asia/Kolkata',
            DateTime.utc(2026, 9, 7, 18, 29),
            DateTime(2026, 9, 7),
          ),
          (
            'Asia/Kolkata',
            DateTime.utc(2026, 9, 7, 18, 30),
            DateTime(2026, 9, 8),
          ),
          (
            'Asia/Kathmandu',
            DateTime.utc(2026, 9, 7, 18, 15),
            DateTime(2026, 9, 8),
          ),
          // Either side of the date line, at one instant.
          (
            'Pacific/Kiritimati',
            DateTime.utc(2026, 9, 7, 10),
            DateTime(2026, 9, 8),
          ),
          (
            'Pacific/Pago_Pago',
            DateTime.utc(2026, 9, 7, 10),
            DateTime(2026, 9, 6),
          ),
        ]) {
      test('$id at $instant is $date', () {
        final LumeRecordContext c = inZone(instant, id);
        expect(c.dayKnown, isTrue);
        expect(c.today, date);
      });
    }

    test('the alias reads Kyiv\'s clock and shows Kyiv\'s name', () {
      final LumeRecordContext c = inZone(
        DateTime.utc(2026, 9, 7),
        'Europe/Kiev',
      );
      expect(c.zone.outcome, LumeZoneOutcome.alias);
      expect(c.zoneLabel, 'Europe/Kyiv');
      expect(c.zone.requested, 'Europe/Kiev');
    });

    test('one instant, two zones: the same task in different segments', () {
      final DateTime instant = DateTime.utc(2026, 9, 7, 10);
      final LumeTodo due7 = task(DateTime(2026, 9, 7));
      // In Kiritimati the 7th has passed: an open task due then is overdue.
      expect(
        segments(due7, inZone(instant, 'Pacific/Kiritimati').today),
        <LumeTodoWhen>{LumeTodoWhen.today, LumeTodoWhen.week, LumeTodoWhen.all},
      );
      // In Pago Pago it is still the 6th: the task is tomorrow's.
      expect(
        segments(due7, inZone(instant, 'Pacific/Pago_Pago').today),
        <LumeTodoWhen>{LumeTodoWhen.week, LumeTodoWhen.all},
      );
    });
  });

  group('the segments, in calendar dates', () {
    final DateTime today = DateTime(2026, 9, 7);
    DateTime d(int n) => DateTime(2026, 9, 7 + n);

    for (final (String what, LumeTodo Function() x, Set<LumeTodoWhen> want)
        in <(String, LumeTodo Function(), Set<LumeTodoWhen>)>[
          ('window first date', () => task(d(0)), LumeTodoWhen.values.toSet()),
          (
            'window seventh date',
            () => task(d(6)),
            <LumeTodoWhen>{LumeTodoWhen.week, LumeTodoWhen.all},
          ),
          (
            'just outside the window',
            () => task(d(7)),
            <LumeTodoWhen>{LumeTodoWhen.all},
          ),
          ('open overdue', () => task(d(-1)), LumeTodoWhen.values.toSet()),
          (
            'completed overdue',
            () => task(d(-1), done: true),
            <LumeTodoWhen>{LumeTodoWhen.all},
          ),
          ('undated', () => task(null), LumeTodoWhen.values.toSet()),
          (
            'completed, due today',
            () => task(d(0), done: true),
            LumeTodoWhen.values.toSet(),
          ),
        ]) {
      test(what, () => expect(segments(x(), today), want));
    }

    test('DST spring: either side of New York\'s missing hour is the same '
        'date, and the window is seven dates', () {
      for (final DateTime instant in <DateTime>[
        DateTime.utc(2026, 3, 8, 6, 59), // 01:59 EST
        DateTime.utc(2026, 3, 8, 7), // 03:00 EDT
      ]) {
        final DateTime t = inZone(instant, 'America/New_York').today;
        expect(t, DateTime(2026, 3, 8));
        expect(LumeTodoWhen.week.holds(task(DateTime(2026, 3, 14)), t), isTrue);
        expect(
          LumeTodoWhen.week.holds(task(DateTime(2026, 3, 15)), t),
          isFalse,
        );
      }
    });

    test('DST autumn: 01:30 happens twice in New York; both are the 1st', () {
      for (final DateTime instant in <DateTime>[
        DateTime.utc(2026, 11, 1, 5, 30), // 01:30 EDT
        DateTime.utc(2026, 11, 1, 6, 30), // 01:30 EST
      ]) {
        final LumeRecordContext c = inZone(instant, 'America/New_York');
        expect(c.local.hour, 1);
        expect(c.today, DateTime(2026, 11, 1));
        expect(
          LumeTodoWhen.week.holds(task(DateTime(2026, 11, 7)), c.today),
          isTrue,
        );
        expect(
          LumeTodoWhen.week.holds(task(DateTime(2026, 11, 8)), c.today),
          isFalse,
        );
      }
    });
  });

  group('where the zone comes from', () {
    final DateTime instant = DateTime.utc(2026, 9, 7, 20, 30);

    test('a valid configured zone', () {
      final LumeRecordContext c = at(
        instant,
        zones.reader(configured: 'Asia/Tokyo', regionZone: 'Asia/Karachi'),
      );
      expect(c.dayKnown, isTrue);
      expect(c.zone.source, LumeZoneSource.configured);
    });

    test('none configured, none for the region: the verified device zone, '
        'and only then', () {
      final LumeRecordContext withDevice = at(
        instant,
        zones.reader(device: const LumeDeviceZone('America/New_York')),
      );
      expect(withDevice.zone.source, LumeZoneSource.device);
      expect(withDevice.today, DateTime(2026, 9, 7));
      final LumeRecordContext without = at(instant, zones.reader());
      expect(without.dayKnown, isFalse);
      expect(without.zone.outcome, LumeZoneOutcome.missingDevice);
    });

    for (final (String bad, LumeZoneOutcome outcome)
        in <(String, LumeZoneOutcome)>[
          ('Mars/Olympus_Mons', LumeZoneOutcome.unknown),
          ('PKT', LumeZoneOutcome.malformed),
        ]) {
      test('an explicit "$bad" is not replaced by the device\'s zone', () {
        final LumeRecordContext c = at(
          instant,
          zones.reader(
            configured: bad,
            regionZone: 'Asia/Karachi',
            device: const LumeDeviceZone('Asia/Karachi'),
          ),
        );
        expect(c.dayKnown, isFalse);
        expect(c.zone.outcome, outcome);
        expect(c.zone.requested, bad);
      });
    }
  });

  group('on screen', () {
    testWidgets('Tokyo groups normally', (WidgetTester t) async {
      await pumpWave2(t, 'todos', profile: reader(zone: 'Asia/Tokyo'));
      expect(find.byKey(LumeTodosTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeTodosTool.dayUnknownKey), findsNothing);
    });

    testWidgets('a stored alias is read, and never rewritten by reading', (
      WidgetTester t,
    ) async {
      final LumeProfileRepository profile = reader(zone: 'Europe/Kiev');
      await pumpWave2(t, 'todos', profile: profile);
      expect(find.byKey(LumeTodosTool.summaryKey), findsOneWidget);
      await pumpWave2(t, 'todos', profile: profile);
      expect((await profile.readProfile()).timeZone, 'Europe/Kiev');
    });

    for (final (String bad, Locale locale, TextDirection dir)
        in <(String, Locale, TextDirection)>[
          ('Mars/Olympus_Mons', const Locale('en'), TextDirection.ltr),
          ('PKT', const Locale('en'), TextDirection.ltr),
          ('Mars/Olympus_Mons', const Locale('ur'), TextDirection.rtl),
          ('Mars/Olympus_Mons', const Locale('ar'), TextDirection.rtl),
        ]) {
      testWidgets(
        'an explicit "$bad" (${locale.languageCode}): said, isolated, '
        'and nothing grouped by day',
        (WidgetTester t) async {
          final SemanticsHandle h = t.ensureSemantics();
          final LumeMemoryRecordRepository s = wave2Store();
          await pumpWave2(
            t,
            'todos',
            store: s,
            locale: locale,
            profile: reader(zone: bad),
            // A device zone is there, and must not stand in.
            overrides: <Override>[
              deviceZoneProvider.overrideWithValue(
                const LumeDeviceZone('Asia/Karachi'),
              ),
            ],
          );
          final Finder state = find.byKey(LumeTodosTool.dayUnknownKey);
          expect(state, findsOneWidget);
          final LumeToolState w = t.widget<LumeToolState>(
            find.descendant(of: state, matching: find.byType(LumeToolState)),
          );
          expect(w.text, contains('\u2068$bad\u2069'));
          expect(Directionality.of(t.element(state)), dir);
          expect(find.byKey(LumeTodosTool.summaryKey), findsNothing);
          expect(find.byKey(LumeTodosTool.whenKey), findsNothing);
          expect(find.byKey(LumeTodosTool.visibleKey), findsNothing);
          // The records are still listed, with dates rather than "Today".
          final List<String> subs = <String>[
            for (final LumeRecordRow r in t.widgetList<LumeRecordRow>(
              find.byType(LumeRecordRow),
            ))
              r.subtitle ?? '',
          ];
          expect(subs, hasLength(4));
          if (locale.languageCode == 'en') {
            expect(subs.join(' '), isNot(contains('Today')));
            expect(subs.join(' '), isNot(contains('Tomorrow')));
            expect(
              find.bySemanticsLabel(RegExp('Your day can’t be worked out')),
              findsOneWidget,
            );
          }
          // Nothing overwrote what the reader set.
          expect(
            s.view('todos').items.map((LumeRecord r) => r['due']),
            contains(lumeIsoDay(kFixtureInstant, 0)),
          );
          h.dispose();
        },
      );
    }

    testWidgets('a new task has no due date to guess when the day is unknown', (
      WidgetTester t,
    ) async {
      await pumpWave2(t, 'todos', profile: reader(zone: 'Mars/Olympus_Mons'));
      await tapVisible(t, find.byKey(LumeTodosTool.keys.add));
      expect(find.byKey(LumeTodosTool.keys.clearField('due')), findsNothing);
    });
  });
}
