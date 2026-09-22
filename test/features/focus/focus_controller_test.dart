/// The focus clock, held to its policy.
///
/// Every reading of time here comes from [now], which the test moves by hand,
/// and every repaint comes from a [_Ticker] the test fires by hand. Nothing
/// waits, and nothing is measured from how often the ticker fired — which is
/// the defect this controller exists to correct.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/focus/application/focus_controller.dart';
import 'package:lume/features/tools/application/tool_session.dart';

class _Ticker implements Timer {
  _Ticker(this.onTick);
  final void Function(Timer) onTick;
  bool active = true;
  int ticks = 0;

  void fire() {
    if (!active) return;
    ticks++;
    onTick(this);
  }

  @override
  void cancel() => active = false;
  @override
  bool get isActive => active;
  @override
  int get tick => ticks;
}

void main() {
  late Duration now;
  late List<_Ticker> tickers;
  late LumeToolSession session;
  late List<LumeFocusPhase> finished;

  LumeFocusController clock() => LumeFocusController(
    session: session,
    elapsed: () => now,
    onFinished: finished.add,
    periodic: (Duration d, void Function(Timer) tick) {
      final _Ticker t = _Ticker(tick);
      tickers.add(t);
      return t;
    },
  );

  /// Fire every live ticker once, as the framework would.
  void tick() {
    for (final _Ticker t in <_Ticker>[...tickers]) {
      t.fire();
    }
  }

  setUp(() {
    now = const Duration(hours: 5);
    tickers = <_Ticker>[];
    session = LumeToolSession();
    finished = <LumeFocusPhase>[];
  });

  group('the lengths', () {
    test('a focus stretch opens at the reference\'s twenty-five minutes', () {
      final LumeFocusController c = clock();
      expect(c.phase, LumeFocusPhase.focus);
      expect(c.focusLength, const Duration(minutes: 25));
      expect(c.display, '25:00');
      expect(c.session, 1);
      expect(LumeFocusController.sessionsPerCycle, 4);
      c.dispose();
    });

    test('the break is five minutes, and is changeable', () {
      final LumeFocusController c = clock();
      expect(c.breakLength, const Duration(minutes: 5));
      c.setBreakLength(const Duration(minutes: 15));
      expect(c.breakLength, const Duration(minutes: 15));
      // Changing the break does not disturb the focus stretch on the clock.
      expect(c.display, '25:00');
      c.dispose();
    });

    test('choosing a focus length holds it and starts the stretch again', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 3);
      c.setFocusLength(const Duration(minutes: 45));
      expect(c.running, isFalse);
      expect(c.display, '45:00');
      // The three minutes were really spent, so they are still counted.
      expect(c.focused, const Duration(minutes: 3));
      c.dispose();
    });

    test('a length beyond the ends is held at them', () {
      final LumeFocusController c = clock()
        ..setFocusLength(const Duration(days: 30));
      expect(c.focusLength, LumeFocusController.maxLength);
      expect(c.display, '240:00', reason: 'minutes run past an hour');
      c.setFocusLength(const Duration(seconds: 1));
      expect(c.focusLength, LumeFocusController.minLength);
      expect(c.display, '01:00');
      c.dispose();
    });
  });

  group('start, pause, resume, reset', () {
    test('starting counts down, and only the running time counts', () {
      final LumeFocusController c = clock()..toggle();
      expect(c.running, isTrue);
      expect(c.status, LumeFocusStatus.running);
      now += const Duration(minutes: 1, seconds: 30);
      expect(c.display, '23:30');

      c.toggle();
      expect((c.running, c.status), (false, LumeFocusStatus.paused));
      now += const Duration(minutes: 10);
      expect(c.display, '23:30', reason: 'a pause stops the clock');

      c.toggle();
      now += const Duration(seconds: 30);
      expect(c.display, '23:00');
      c.dispose();
    });

    test('reset returns to the full stretch and keeps what was focused', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 4);
      c.reset();
      expect(
        (c.running, c.display, c.status),
        (false, '25:00', LumeFocusStatus.ready),
      );
      expect(c.focused, const Duration(minutes: 4));
      expect(c.completedSessions, 0, reason: 'reset finishes nothing');
      c.dispose();
    });

    test('pausing stops the repaint ticker too', () {
      final LumeFocusController c = clock()..toggle();
      expect(tickers.single.active, isTrue);
      now += const Duration(seconds: 2);
      c.toggle();
      expect(tickers.single.active, isFalse);
      c.dispose();
    });
  });

  group('skip', () {
    test('a skipped focus banks the minutes but finishes no session', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 7);
      c.skip();
      expect(c.phase, LumeFocusPhase.breakTime);
      expect(c.display, '05:00');
      expect(c.focused, const Duration(minutes: 7));
      expect(c.completedSessions, 0);
      expect(c.session, 1, reason: 'still the first session, now its break');
      expect(finished, isEmpty, reason: 'nothing ran out, nothing announced');
      c.dispose();
    });

    test('a skipped break moves on to the next session', () {
      final LumeFocusController c = clock()
        ..skip()
        ..skip();
      expect(c.phase, LumeFocusPhase.focus);
      expect(c.session, 2);
      expect(c.display, '25:00');
      c.dispose();
    });
  });

  group('running out', () {
    test('a finished focus counts the stretch, advances the count and offers '
        'the break', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 25);
      tick();
      expect(finished, <LumeFocusPhase>[LumeFocusPhase.focus]);
      expect(c.completedSessions, 1);
      expect(c.focused, const Duration(minutes: 25));
      expect(c.phase, LumeFocusPhase.breakTime);
      expect(c.display, '05:00');
      expect(
        c.running,
        isFalse,
        reason: 'the break waits to be started, it does not surprise anyone',
      );
      c.dispose();
    });

    test('it is announced once, however many ticks arrive after', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 26);
      tick();
      tick();
      tick();
      expect(finished, hasLength(1));
      c.dispose();
    });

    test('a finished break returns to focus and to the next session', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 25);
      tick();
      c.toggle();
      now += const Duration(minutes: 5);
      tick();
      expect(finished, <LumeFocusPhase>[
        LumeFocusPhase.focus,
        LumeFocusPhase.breakTime,
      ]);
      expect(c.phase, LumeFocusPhase.focus);
      expect(c.session, 2);
      expect(c.completedSessions, 1, reason: 'a break is not a session');
      c.dispose();
    });

    test('the session number runs round the cycle of four', () {
      final LumeFocusController c = clock();
      for (int i = 0; i < 4; i++) {
        c.toggle();
        now += c.length;
        tick();
        c.toggle();
        now += c.length;
        tick();
      }
      expect(c.completedSessions, 4);
      expect(c.session, 1, reason: 'the fifth stretch opens the cycle again');
      c.dispose();
    });
  });

  group('the clock', () {
    test('many small readings add up to exactly one large one — no drift', () {
      final LumeFocusController c = clock()..toggle();
      // Three thousand ten-millisecond steps, each with a repaint: were the
      // face counting ticks, it would now be thirty *thousand* seconds out.
      for (int i = 0; i < 3000; i++) {
        now += const Duration(milliseconds: 10);
        tick();
      }
      expect(c.elapsed, const Duration(seconds: 30));
      expect(c.display, '24:30');
      expect(tickers.single.ticks, 3000);
      c.dispose();
    });

    test('a tick that never arrives costs nothing', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 9, seconds: 20);
      expect(c.display, '15:40', reason: 'read from the clock, not the ticks');
      expect(tickers.single.ticks, 0);
      c.dispose();
    });

    test('a clock that seems to go back counts as no time', () {
      final LumeFocusController c = clock()..toggle();
      now -= const Duration(minutes: 40);
      expect(c.elapsed, Duration.zero);
      expect(c.display, '25:00');
      c.dispose();
    });

    test('a run past the stretch is held at it, never negative', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(days: 4000);
      expect(c.elapsed, const Duration(minutes: 25));
      expect(c.remaining, Duration.zero);
      expect(c.display, '00:00');
      c.dispose();
    });

    test('a part second still standing reads as a second', () {
      expect(
        LumeFocusController.format(const Duration(milliseconds: 1)),
        '00:01',
      );
      expect(LumeFocusController.format(Duration.zero), '00:00');
      expect(
        LumeFocusController.format(const Duration(milliseconds: -500)),
        '00:00',
      );
      expect(LumeFocusController.format(const Duration(minutes: 62)), '62:00');
    });

    test('no wall clock anywhere in the source', () {
      final String source = File(
        'lib/features/focus/application/focus_controller.dart',
      ).readAsStringSync();
      final String code = source
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('///'))
          .join('\n');
      expect(code, isNot(contains('DateTime')));
      expect(code, isNot(contains('Stopwatch')));
    });
  });

  group('lifecycle', () {
    test('away stops the repainting and not the elapsing', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 2);
      c.away();
      expect(c.running, isTrue);
      expect(tickers.single.active, isFalse);
      now += const Duration(minutes: 3);
      c.back();
      expect(tickers, hasLength(2));
      expect(tickers.last.active, isTrue);
      expect(c.elapsed, const Duration(minutes: 5));
      expect(c.display, '20:00');
      c.dispose();
    });

    test('a paused stretch stays paused across the background', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 6);
      c
        ..toggle()
        ..away();
      now += const Duration(hours: 1);
      c.back();
      expect(c.running, isFalse);
      expect(c.display, '19:00');
      c.dispose();
    });

    test('a stretch that ran out while Lume was away is settled on return, '
        'and not before — nothing is delivered in the background', () {
      final LumeFocusController c = clock()..toggle();
      c.away();
      now += const Duration(minutes: 40);
      expect(finished, isEmpty, reason: 'nothing was announced while away');
      c.back();
      expect(finished, <LumeFocusPhase>[LumeFocusPhase.focus]);
      expect(c.phase, LumeFocusPhase.breakTime);
      expect(c.completedSessions, 1);
      c.dispose();
    });
  });

  group('what survives', () {
    test('leaving the tool keeps the phase and the time, stopped', () {
      final LumeFocusController c = clock()..toggle();
      now += const Duration(minutes: 8);
      c.dispose();
      now += const Duration(hours: 2);

      final LumeFocusController again = clock();
      expect(again.running, isFalse);
      expect(again.display, '17:00');
      expect(again.phase, LumeFocusPhase.focus);
      again.dispose();
    });

    test('closing Lume keeps nothing at all', () {
      final LumeFocusController c = clock()
        ..setFocusLength(const Duration(minutes: 45))
        ..toggle();
      now += const Duration(minutes: 45);
      tick();
      expect(c.completedSessions, 1);
      c.dispose();

      // A new process: the session store is in memory, so it is a new one.
      session = LumeToolSession();
      final LumeFocusController fresh = clock();
      expect(fresh.display, '25:00', reason: 'the chosen length is gone too');
      expect(fresh.phase, LumeFocusPhase.focus);
      expect(fresh.session, 1);
      expect(fresh.completedSessions, 0);
      expect(fresh.focused, Duration.zero);
      expect(fresh.hasCounted, isFalse);
      fresh.dispose();
    });

    test('a held figure out of range is clamped, never trusted', () {
      session
        ..write(LumeFocusController.tool, 'heldMs', '-9000')
        ..write(LumeFocusController.tool, 'countedMs', '-1')
        ..write(LumeFocusController.tool, 'session', '99')
        ..write(LumeFocusController.tool, 'focusMs', '999999999999');
      final LumeFocusController c = clock();
      expect(c.elapsed, Duration.zero);
      expect(c.focused, Duration.zero);
      expect(c.session, LumeFocusController.sessionsPerCycle);
      expect(c.focusLength, LumeFocusController.maxLength);
      c.dispose();
    });
  });

  test('disposal leaves no timer behind', () {
    final LumeFocusController c = clock()..toggle();
    now += const Duration(seconds: 5);
    c.dispose();
    expect(tickers.every((_Ticker t) => !t.active), isTrue);
    expect(session.read(LumeFocusController.tool, 'heldMs'), '5000');
  });
}
