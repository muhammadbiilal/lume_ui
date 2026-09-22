/// The two harnesses that pump the real router must read the clock they
/// are given.
///
/// Both ignored it once. `pumpLumeRouter` hard-coded [kFixtureInstant], so
/// a tool that ticks could only be tested away from the router — three
/// World Clock screen tests were passing against a direct host and
/// asserting the wrong zone's wall time. `captureLumeRoute` did not
/// forward one at all, which made World Clock's goldens a function of the
/// machine's own time zone: [kFixtureInstant] is a local `DateTime`, and
/// every row of that tool is it converted somewhere else, so the whole
/// set would have differed on a build box in another zone.
///
/// Neither failure announces itself. The tests pass; they just prove
/// something other than what they say. So the seam is held here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';

import 'capture.dart';
import 'lume_harness.dart';

/// Reads the instant the tree is published with, and records it.
class _ClockProbe extends StatelessWidget {
  const _ClockProbe(this.seen);

  final List<DateTime> seen;

  @override
  Widget build(BuildContext context) {
    seen.add(LumeClockScope.of(context).now());
    return const SizedBox.shrink();
  }
}

void main() {
  // An instant that is nothing like the fixture's, in a zone the host is
  // very unlikely to be in, so a fallback cannot pass by coincidence.
  final DateTime pinned = DateTime.utc(2031, 2, 28, 3, 7, 11);

  group('pumpLumeRouter', () {
    testWidgets('publishes the clock it is given', (WidgetTester t) async {
      final List<DateTime> seen = <DateTime>[];
      await pumpLumeRouter(t, initialLocation: LumeRoutes.tools);
      // The probe reads whatever scope encloses it.
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LumeClockScope(
            clock: LumeClock.fixed(pinned),
            child: _ClockProbe(seen),
          ),
        ),
      );
      expect(seen.single, pinned);
    });

    testWidgets('a tool pumped through the router reads the test clock, '
        'not the fixture instant', (WidgetTester t) async {
      final List<DateTime> seen = <DateTime>[];
      await pumpLumeRouter(
        t,
        initialLocation: LumeRoutes.tools,
        clock: LumeClock.fixed(pinned),
      );
      final BuildContext context = t.element(find.byType(Navigator).first);
      seen.add(LumeClockScope.of(context).now());
      expect(
        seen.single,
        pinned,
        reason: 'the router must not substitute kFixtureInstant',
      );
      expect(seen.single, isNot(kFixtureInstant));
    });

    testWidgets('and falls back to the fixture instant when given none', (
      WidgetTester t,
    ) async {
      await pumpLumeRouter(t, initialLocation: LumeRoutes.tools);
      final BuildContext context = t.element(find.byType(Navigator).first);
      expect(LumeClockScope.of(context).now(), kFixtureInstant);
    });
  });

  group('captureLumeRoute', () {
    testWidgets('forwards the clock to the captured tree', (
      WidgetTester t,
    ) async {
      DateTime? seen;
      await captureLumeRoute(
        t,
        location: LumeRoutes.tools,
        name: 'helper_clock_probe',
        outDir: 'build/helper_shots',
        clock: LumeClock.fixed(pinned),
        after: (WidgetTester tester) async {
          seen = LumeClockScope.of(
            tester.element(find.byType(Navigator).first),
          ).now();
        },
      );
      expect(
        seen,
        pinned,
        reason:
            'a capture whose content depends on the instant must be '
            'able to pin it, or the image is a function of the host',
      );
    });

    testWidgets('and still pins the fixture instant when given none', (
      WidgetTester t,
    ) async {
      DateTime? seen;
      await captureLumeRoute(
        t,
        location: LumeRoutes.tools,
        name: 'helper_clock_probe_default',
        outDir: 'build/helper_shots',
        after: (WidgetTester tester) async {
          seen = LumeClockScope.of(
            tester.element(find.byType(Navigator).first),
          ).now();
        },
      );
      expect(seen, kFixtureInstant);
    });
  });
}
