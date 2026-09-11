/// Time is injected, and fixtures pin it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';

import '../../helpers/lume_harness.dart';

void main() {
  test('a fixed clock does not move', () {
    final LumeClock c = LumeClock.fixed(kFixtureInstant);
    expect(c.now(), kFixtureInstant);
    expect(c.now(), c.now());
  });

  test('the system clock does move', () {
    const LumeClock c = LumeClock.system();
    final DateTime a = c.now();
    expect(a.difference(DateTime.now()).abs().inSeconds, lessThan(2));
  });

  test('the fixture instant is chosen so formatting is unambiguous', () {
    // A Monday, so weekday arithmetic is visible; September, so the month name
    // is long in every language; 16:41, so 12-hour and 24-hour cannot be
    // confused with each other.
    expect(kFixtureInstant.weekday, DateTime.monday);
    expect(kFixtureInstant.month, 9);
    expect(kFixtureInstant.hour, 16);
    expect(kFixtureInstant.hour, greaterThan(12));
  });

  testWidgets('the harness pins the clock by default', (WidgetTester t) async {
    late DateTime seen;
    await pumpLume(
      t,
      LumeProbe(onBuild: (BuildContext c) => seen = LumeClockScope.of(c).now()),
    );
    expect(seen, kFixtureInstant);
  });

  testWidgets('a test may pin its own instant', (WidgetTester t) async {
    final DateTime other = DateTime(2027, 3, 14, 9, 26);
    late DateTime seen;
    await pumpLume(
      t,
      LumeProbe(onBuild: (BuildContext c) => seen = LumeClockScope.of(c).now()),
      now: other,
    );
    expect(seen, other);
  });

  testWidgets('outside a scope, the real clock is the fallback', (
    WidgetTester t,
  ) async {
    late DateTime seen;
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LumeProbe(
          onBuild: (BuildContext c) => seen = LumeClockScope.of(c).now(),
        ),
      ),
    );
    expect(seen.difference(DateTime.now()).abs().inSeconds, lessThan(2));
  });
}
