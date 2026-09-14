/// The reference's generator, ported once and held against its output.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_random.dart';
import 'package:lume/core/fixtures/lume_reference_weather.dart';

void main() {
  test('seedRand walks as Park–Miller does', () {
    final LumeSeedRand r = LumeSeedRand(6612);
    // The first draws of `seedRand(6612)` in Node.
    final List<double> first = <double>[for (int i = 0; i < 3; i++) r.next()];
    expect(first.every((double v) => v >= 0 && v < 1), isTrue);
    expect(LumeSeedRand(6612).next(), first.first, reason: 'deterministic');
    expect(
      LumeSeedRand(0).next(),
      LumeSeedRand(2147483646).next(),
      reason: 'a non-positive seed wraps as the reference wraps it',
    );
  });

  test('heatDays(35, 6612, .32) is the grid the reference renders', () {
    expect(lumeHeatDays(35, 6612, 0.32), <int>[
      0, 3, 0, 3, 3, 3, 0, 3, 2, 1, 3, 2, 2, 3, 2, 2, 3, 3, //
      1, 3, 2, 3, 1, 0, 3, 0, 1, 3, 3, 1, 0, 3, 2, 3, 3,
    ]);
  });

  test('the weather port still draws from the same generator', () {
    // Pakistan's tomorrow, which C61 holds against Node.
    final List<LumeReferenceDay> days = lumeReferenceDaily(
      34,
      'P'.codeUnitAt(0) * 17,
    );
    expect(days[1].highC, 36);
    expect(days[1].lowC, 27);
  });
}
