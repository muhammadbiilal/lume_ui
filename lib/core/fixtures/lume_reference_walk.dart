/// A plausible price walk — `tool-data.js` `walk(seed, n, start, vol)`.
///
/// Each step multiplies the running value by `1 + (r − 0.5) × vol`, where `r`
/// is the reference's own seeded generator ([LumeSeedRand]), and records it
/// rounded to a precision that follows the magnitude: two decimals from 100,
/// four from 1, six below — so a rate of 0.6584 still moves. The running value
/// itself is never rounded, exactly as the reference keeps it.
library;

import 'dart:math' as math;

import 'lume_reference_random.dart';

List<double> lumeWalk(int seed, int n, double start, double vol) {
  final LumeSeedRand r = LumeSeedRand(seed);
  final int dp = start.abs() >= 100
      ? 2
      : start.abs() >= 1
      ? 4
      : 6;
  final double f = math.pow(10, dp).toDouble();
  double v = start;
  return <double>[
    for (int i = 0; i < n; i++)
      () {
        v = v * (1 + (r.next() - 0.5) * vol);
        // `Math.round` — half rounds up.
        return (v * f + 0.5).floorToDouble() / f;
      }(),
  ];
}
