/// Lume's motion — three durations and three curves, and nothing invents a
/// fourth.
///
/// §5 names the three durations by number: 160 ms feedback, 260 ms standard
/// transitions, 420 ms screen transitions. `tests/design.js` asserts all three.
///
/// Two rules.
///
/// **Reduced motion is honoured, and that includes indefinite animation.** A
/// skeleton shimmer and a live-data pulse run forever, and forever is exactly
/// what a user who asked for less motion did not want. It is also what makes
/// `pumpAndSettle` hang, so [stillness] is checked by every animating widget in
/// the system.
///
/// **Animations are fast and intentional.** No bouncing for its own sake;
/// [spring] overshoots slightly and only where a surface should feel picked up.
library;

import 'package:flutter/widgets.dart';

/// Durations and curves.
abstract final class LumeMotion {
  /// `--dur-fast` · 160 ms. Press feedback, hover, a chip toggling.
  static const Duration fast = Duration(milliseconds: 160);

  /// `--dur` · 260 ms. The standard transition.
  static const Duration standard = Duration(milliseconds: 260);

  /// `--dur-slow` · 420 ms. Screen transitions, sheets, the onboarding rise.
  static const Duration slow = Duration(milliseconds: 420);

  /// `--ease` · `cubic-bezier(.22, .61, .36, 1)`. The default.
  static const Curve ease = Cubic(0.22, 0.61, 0.36, 1);

  /// `--ease-out` · `cubic-bezier(.16, 1, .3, 1)`. Entrances — decelerates hard.
  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);

  /// `--ease-spring` · `cubic-bezier(.34, 1.4, .64, 1)`. Overshoots. Used where
  /// a surface should feel picked up, not everywhere.
  static const Curve spring = Cubic(0.34, 1.4, 0.64, 1);

  /// Whether this context has asked for less motion.
  ///
  /// True when the platform's reduce-motion setting is on, and true in tests
  /// that pump with `disableAnimations: true`.
  static bool stillness(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// A duration that collapses to nothing when motion is reduced.
  ///
  /// Use it for any transition. A duration of zero still ends in the same
  /// visual state; it just gets there immediately.
  static Duration duration(BuildContext context, Duration d) =>
      stillness(context) ? Duration.zero : d;

  /// Whether an *indefinite* animation may run — a shimmer, a pulse, a float.
  ///
  /// These do not have an end state to jump to, so they stop entirely rather
  /// than running instantly. Check this before starting a repeating controller.
  static bool mayRepeat(BuildContext context) => !stillness(context);
}
