/// The seeded price walk, against the paths the reference drew with it.
///
/// `tool_goldrates_default_pk_390x844_light_en` records the `d` attribute of
/// the first currency's sparkline and of the 30-day chart. Rebuilding those
/// strings from [lumeWalk] and [LumeMetals] with the reference's own formula
/// — `points(vals, w, h, pad)` and `toFixed(1)` — proves the generator, the
/// figures it starts from and the geometry together, to the tenth of a unit.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_walk.dart';
import 'package:lume/features/goldrates/data/goldrates_fixtures.dart';

/// `extent` and `points` from `components.js`, and `path`.
String referencePath(
  List<double> v,
  double w,
  double h, {
  double padTop = 2,
  double padBottom = 2,
}) {
  double lo = v.reduce(math.min), hi = v.reduce(math.max);
  if (lo == hi) {
    lo -= 1;
    hi += 1;
  }
  final double step = v.length > 1 ? w / (v.length - 1) : w;
  return <String>[
    for (int i = 0; i < v.length; i++)
      '${i == 0 ? 'M' : 'L'}${(i * step).toStringAsFixed(1)} '
          '${(padTop + (h - padTop - padBottom) * (1 - (v[i] - lo) / (hi - lo))).toStringAsFixed(1)}',
  ].join(' ');
}

void main() {
  final Map<String, dynamic> explorer =
      (jsonDecode(
                File(
                  'docs/conversion_archive/measurements/'
                  'tool_goldrates_default_pk_390x844_light_en.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['composition']['explorer']
          as Map<String, dynamic>;

  final LumeMetals pk = LumeMetals.forCurrency('PKR');

  test('the dollar row\'s sparkline is the reference\'s, point for point', () {
    final LumeFxPair usd = pk.pairs.first;
    expect(usd.code, 'USD');
    expect(
      referencePath(usd.spark, 56, 22),
      (explorer['rows'] as List<dynamic>).first['spark'],
    );
  });

  test('the 30-day chart is the reference\'s, point for point', () {
    final Map<String, dynamic> chart =
        explorer['chart'] as Map<String, dynamic>;
    expect(
      referencePath(pk.history, 320, 132, padTop: 6, padBottom: 20),
      chart['line'],
    );
  });

  test(
    'precision follows the magnitude, and the running value is not rounded',
    () {
      final List<double> big = lumeWalk(7, 5, 290480, 0.01);
      final List<double> small = lumeWalk(7, 5, 0.6584, 0.01);
      for (final double v in big) {
        expect((v * 100).roundToDouble(), closeTo(v * 100, 1e-6));
      }
      for (final double v in small) {
        expect((v * 1e6).roundToDouble(), closeTo(v * 1e6, 1e-3));
      }
      expect(lumeWalk(7, 5, 1, 0.01), lumeWalk(7, 5, 1, 0.01));
    },
  );
}
