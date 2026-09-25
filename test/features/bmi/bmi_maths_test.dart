/// `LumeBmiResult.of`, checked against `bmi()` (`context.js:1161-1185`).
///
/// This is the maths in isolation, with no widget tree: the screen's own test
/// (`bmi_tool_test.dart`) is about the figures reaching the reader, and this
/// one is about the figures themselves being right — the formula, the four
/// WHO-style bands and their boundaries, the healthy-weight range, and the
/// zero-height guard the reference's own division carries.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/bmi/domain/bmi_maths.dart';

void main() {
  group('the formula', () {
    test('the metric opening figures — 175 cm, 75 kg', () {
      final LumeBmiResult r = LumeBmiResult.of(
        height: LumeBmiResult.defaultHeightMetric,
        weight: LumeBmiResult.defaultWeightMetric,
        imperial: false,
      );
      // 75 / 1.75² = 24.48979591836735...
      expect(r.value, closeTo(24.4898, 0.0001));
      expect(r.band, LumeBmiBand.healthy);
    });

    test('the imperial opening figures — 69 in, 165 lb', () {
      final LumeBmiResult r = LumeBmiResult.of(
        height: LumeBmiResult.defaultHeightImperial,
        weight: LumeBmiResult.defaultWeightImperial,
        imperial: true,
      );
      // 69 in = 1.7526 m; 165 lb × 0.453592 = 74.84268 kg.
      expect(r.value, closeTo(24.3659, 0.0001));
      expect(r.band, LumeBmiBand.healthy);
    });

    test('a cleared height reads zero rather than dividing by it', () {
      final LumeBmiResult r = LumeBmiResult.of(
        height: 0,
        weight: 70,
        imperial: false,
      );
      expect(r.value, 0);
      expect(r.healthyLowKg, 0);
      expect(r.healthyHighKg, 0);
      expect(r.idealKg, 0);
    });

    test('a negative height is treated the same way', () {
      final LumeBmiResult r = LumeBmiResult.of(
        height: -10,
        weight: 70,
        imperial: false,
      );
      expect(r.value, 0);
    });
  });

  group('the four bands', () {
    test('under 18.5 is underweight', () {
      final LumeBmiResult r = LumeBmiResult.of(
        height: 175,
        weight: 50,
        imperial: false,
      );
      expect(r.value, closeTo(16.3265, 0.0001));
      expect(r.band, LumeBmiBand.underweight);
    });

    test('18.5 up to 25 is healthy, both ends', () {
      expect(lumeBmiBandFor(18.5), LumeBmiBand.healthy);
      expect(lumeBmiBandFor(24.9999), LumeBmiBand.healthy);
    });

    test('25 up to 30 is overweight, both ends', () {
      expect(lumeBmiBandFor(25), LumeBmiBand.overweight);
      expect(lumeBmiBandFor(29.9999), LumeBmiBand.overweight);
    });

    test('30 and over is obese, with no ceiling', () {
      expect(lumeBmiBandFor(30), LumeBmiBand.obese);
      expect(lumeBmiBandFor(60), LumeBmiBand.obese);
    });

    test('just under 18.5 is still underweight', () {
      expect(lumeBmiBandFor(18.4999), LumeBmiBand.underweight);
    });
  });

  group('the healthy-weight range', () {
    test('18.5 to 24.9 kg/m² at 175 cm', () {
      final LumeBmiResult r = LumeBmiResult.of(
        height: 175,
        weight: 75,
        imperial: false,
      );
      // 18.5 × 1.75² = 56.65625; 24.9 × 1.75² = 76.25625.
      expect(r.healthyLowKg, closeTo(56.65625, 0.00001));
      expect(r.healthyHighKg, closeTo(76.25625, 0.00001));
      expect(r.idealKg, closeTo((56.65625 + 76.25625) / 2, 0.00001));
    });

    test("the range scales with height, not with the reader's own weight", () {
      final LumeBmiResult short = LumeBmiResult.of(
        height: 150,
        weight: 40,
        imperial: false,
      );
      final LumeBmiResult tall = LumeBmiResult.of(
        height: 190,
        weight: 40,
        imperial: false,
      );
      expect(tall.healthyLowKg, greaterThan(short.healthyLowKg));
      expect(tall.idealKg, greaterThan(short.idealKg));
    });
  });

  group('the gauge', () {
    test('is the reading over 40, held to the bar', () {
      expect(
        LumeBmiResult.of(height: 175, weight: 75, imperial: false).gauge,
        closeTo(24.4898 / 40, 0.0001),
      );
      expect(
        LumeBmiResult.of(height: 100, weight: 500, imperial: false).gauge,
        1.0,
      );
      expect(LumeBmiResult.of(height: 0, weight: 70, imperial: false).gauge, 0);
    });
  });

  group('the display weight', () {
    test('kilograms pass through unchanged', () {
      expect(lumeBmiDisplayWeight(70, imperial: false), 70);
    });

    test("kilograms convert to pounds the reference's own way", () {
      // Math.round(70 / 0.453592) = 154.
      expect(lumeBmiDisplayWeight(70, imperial: true), closeTo(154.324, 0.01));
    });
  });
}
