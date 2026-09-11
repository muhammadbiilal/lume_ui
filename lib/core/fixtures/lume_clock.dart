/// Time, injected.
///
/// Nothing in Lume calls `DateTime.now()`. Two reasons, and the second is the
/// one that bites.
///
/// **Screenshots and goldens have to be reproducible.** A golden taken on a
/// Tuesday afternoon that renders "Asr in 01:24" is a golden that fails on
/// Wednesday morning. Fixtures pin the clock, so the image is a function of the
/// fixture and nothing else.
///
/// **The reference froze its own clock, and that was a mockup artifact.** The
/// prototype's status bar always reads 9:41. Lume shows the real time at
/// runtime — a frozen clock in a shipping application is a bug — and pins it
/// only where determinism is the point.
///
/// Read the clock from the widget tree with [LumeClockScope.of], never as a
/// global. A screen that reaches for the ambient clock is a screen a test
/// cannot pin.
library;

import 'package:flutter/widgets.dart';

/// A source of the current time.
abstract class LumeClock {
  const LumeClock();

  /// The current moment, in the device's local zone.
  DateTime now();

  /// The real system clock. What the application runs on.
  const factory LumeClock.system() = _SystemClock;

  /// A clock stopped at [instant]. What fixtures, screenshots and goldens run
  /// on.
  const factory LumeClock.fixed(DateTime instant) = _FixedClock;
}

class _SystemClock extends LumeClock {
  const _SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class _FixedClock extends LumeClock {
  const _FixedClock(this._instant);

  final DateTime _instant;

  @override
  DateTime now() => _instant;
}

/// The instant every fixture, screenshot and golden is taken at.
///
/// Chosen so the derived values are unambiguous and exercise the formatting:
/// a Monday, so weekday arithmetic is visible; September, so the month name is
/// long in every language; 16:41, so a 12-hour locale renders "4:41 PM" and a
/// 24-hour one renders "16:41" and the two cannot be confused; and the 41
/// minutes are a nod to the reference's own frozen 9:41.
final DateTime kFixtureInstant = DateTime(2026, 9, 7, 16, 41, 32);

/// Publishes a clock to the subtree.
class LumeClockScope extends InheritedWidget {
  const LumeClockScope({super.key, required this.clock, required super.child});

  final LumeClock clock;

  /// The nearest clock, or the system clock when none was provided.
  ///
  /// The fallback is deliberate: a widget used outside the shell still works.
  /// A *test* that wants determinism must provide a scope, and
  /// `test/helpers/lume_harness.dart` does so by default.
  static LumeClock of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LumeClockScope>()?.clock ??
      const LumeClock.system();

  /// A scope pinned to [kFixtureInstant].
  static Widget fixed({Key? key, required Widget child}) => LumeClockScope(
    key: key,
    clock: LumeClock.fixed(kFixtureInstant),
    child: child,
  );

  @override
  bool updateShouldNotify(LumeClockScope old) => old.clock != clock;
}
