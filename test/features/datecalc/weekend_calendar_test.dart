/// The Date Calculator counts weekends by a calendar it is given, not by a
/// rule of its own (F6B closure). The reference's Saturday–Sunday is kept as
/// the default and says it is a fixture; the country rules are fakes here —
/// Lume invents none, and Dayroz's country calendar is the obligation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/datecalc/domain/date_maths.dart';
import 'package:lume/features/datecalc/domain/weekend_calendar.dart';
import 'package:lume/features/datecalc/presentation/datecalc_tool.dart';

import '../wave1/wave1_tools_test.dart' show pumpTool;

/// A calendar that differs by country, and changes on a date: a fake of the
/// shape a real one has, with made-up rules.
class _Exceptional implements LumeWeekendCalendar {
  _Exceptional({required this.switchedOn, this.holidays = const <DateTime>{}});

  /// From this date, country "XA" moves from Friday–Saturday to
  /// Saturday–Sunday.
  final DateTime switchedOn;

  /// Single dates that are weekend days in "XA" whatever the weekday.
  final Set<DateTime> holidays;

  final List<String> asked = <String>[];

  @override
  bool get isReferenceFixture => false;

  @override
  bool isWeekend(String countryCode, DateTime day) {
    asked.add(countryCode);
    if (countryCode != 'XA') {
      return day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    }
    if (holidays.contains(DateTime(day.year, day.month, day.day))) return true;
    return day.isBefore(switchedOn)
        ? day.weekday == DateTime.friday || day.weekday == DateTime.saturday
        : day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  }
}

void main() {
  // Monday 7 September 2026 to Monday 21 September: two whole weeks.
  final DateTime mon = DateTime(2026, 9, 7);
  final DateTime twoWeeks = DateTime(2026, 9, 21);

  test('the reference rule is Saturday–Sunday, and says it is a fixture', () {
    expect(LumeFixedWeekend.reference.isReferenceFixture, isTrue);
    expect(LumeFixedWeekend.reference.weekdays, <int>{
      DateTime.saturday,
      DateTime.sunday,
    });
    final LumeDateSpan s = LumeDateSpan.of(mon, twoWeeks);
    expect((s.weekdays, s.weekends), (10, 4));
  });

  test('Friday–Saturday', () {
    const LumeFixedWeekend friSat = LumeFixedWeekend(<int>{
      DateTime.friday,
      DateTime.saturday,
    });
    final LumeDateSpan s = LumeDateSpan.of(mon, twoWeeks, weekend: friSat);
    expect((s.weekdays, s.weekends), (10, 4));
    // Thursday to Sunday: Friday and Saturday are the weekend, not Sunday.
    final LumeDateSpan t = LumeDateSpan.of(
      DateTime(2026, 9, 10),
      DateTime(2026, 9, 14),
      weekend: friSat,
    );
    expect((t.weekdays, t.weekends), (2, 2));
    final LumeDateSpan r = LumeDateSpan.of(
      DateTime(2026, 9, 10),
      DateTime(2026, 9, 14),
    );
    expect((r.weekdays, r.weekends), (2, 2), reason: 'Sat–Sun: Sat and Sun');
    final LumeDateSpan w = LumeDateSpan.of(
      DateTime(2026, 9, 11),
      DateTime(2026, 9, 12),
      weekend: friSat,
    );
    expect((w.weekdays, w.weekends), (0, 1), reason: 'a Friday alone');
  });

  test('a calendar that differs by country and changes on a date', () {
    final _Exceptional cal = _Exceptional(
      switchedOn: DateTime(2026, 9, 14),
      holidays: <DateTime>{DateTime(2026, 9, 16)},
    );
    // 7–13 Sept: Fri 11, Sat 12. 14–20 Sept: Wed 16 (one-off), Sat 19, Sun 20.
    final LumeDateSpan xa = LumeDateSpan.of(
      mon,
      twoWeeks,
      weekend: cal,
      country: 'XA',
    );
    expect((xa.weekdays, xa.weekends), (9, 5));
    expect(cal.asked.toSet(), <String>{'XA'}, reason: 'asked for its country');

    final LumeDateSpan pk = LumeDateSpan.of(
      mon,
      twoWeeks,
      weekend: cal,
      country: 'PK',
    );
    expect((pk.weekdays, pk.weekends), (10, 4));
  });

  testWidgets('the tool counts with the calendar it is given, for the '
      "reader's country", (WidgetTester tester) async {
    Future<(String, String)> counted(List<Override> overrides) async {
      await pumpTool(tester, 'datecalc', overrides: overrides);
      // Add days: 30 from today, so the span is not empty.
      await tester.tap(
        find.descendant(
          of: find.byKey(LumeDatecalcTool.modeKey),
          matching: find.text('Add days'),
        ),
      );
      await tester.pumpAndSettle();
      final List<LumeCompactRow> rows = tester
          .widgetList<LumeCompactRow>(
            find.descendant(
              of: find.byKey(LumeDatecalcTool.businessKey),
              matching: find.byType(LumeCompactRow),
            ),
          )
          .toList();
      return (rows[0].value!, rows[1].value!);
    }

    final (String weekdays, String weekends) = await counted(
      const <Override>[],
    );
    final _Everyday everyday = _Everyday();
    final (String none, String all) = await counted(<Override>[
      weekendCalendarProvider.overrideWithValue(everyday),
    ]);
    expect(int.parse(weekdays) + int.parse(weekends), 30);
    expect(none, '0');
    expect(
      int.parse(all),
      int.parse(weekdays) + int.parse(weekends),
      reason: 'every day of the same span is now a weekend day',
    );
    expect(everyday.countries, <String>{'PK'});
  });
}

class _Everyday implements LumeWeekendCalendar {
  final Set<String> countries = <String>{};

  @override
  bool get isReferenceFixture => false;

  @override
  bool isWeekend(String countryCode, DateTime day) {
    countries.add(countryCode);
    return true;
  }
}
