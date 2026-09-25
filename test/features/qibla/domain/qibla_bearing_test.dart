/// Qibla geometry — the great-circle bearing and distance to the Kaaba,
/// checked against publicly published qibla directions for three real
/// cities, not against a fixture of Lume's own making.
///
/// The three references (independently well known, not derived from this
/// port): Lahore/Islamabad's qibla is commonly published at roughly 258–260°
/// from true north (west-south-west — Pakistan faces just south of due
/// west); London's at roughly 119° (east-south-east — a commonly cited fact
/// about UK mosques' orientation); Jakarta's at roughly 295°
/// (west-north-west — the figure behind Indonesia's own public discussion of
/// mosques that face due west rather than correcting a few degrees north).
/// Held to two degrees either side, which is generous next to the spread
/// already published for each of these cities.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/qibla/domain/qibla_bearing.dart';

void main() {
  group('bearing', () {
    test('Lahore faces west-south-west, close to due west', () {
      final double b = LumeQiblaMath.bearing(31.55, 74.34);
      expect(b, closeTo(260, 2));
      expect(LumeQiblaMath.compassPoint(b), 'W');
    });

    test('London faces east-south-east', () {
      final double b = LumeQiblaMath.bearing(51.5074, -0.1278);
      expect(b, closeTo(119, 2));
      expect(LumeQiblaMath.compassPoint(b), 'SE');
    });

    test('Jakarta faces west-north-west, not due west', () {
      final double b = LumeQiblaMath.bearing(-6.2088, 106.8456);
      expect(b, closeTo(295, 2));
      expect(LumeQiblaMath.compassPoint(b), 'NW');
    });

    test('the Kaaba itself has no defined bearing to face — every direction '
        'reaches it, so this asserts only that the maths does not throw or '
        'wrap oddly at the singularity', () {
      expect(
        () => LumeQiblaMath.bearing(
          LumeQiblaMath.kaabaLat,
          LumeQiblaMath.kaabaLon,
        ),
        returnsNormally,
      );
    });

    test('is always within a full turn', () {
      for (final (double lat, double lon) in const <(double, double)>[
        (33.69, 73.05), // Islamabad
        (35.68, 139.69), // Tokyo
        (-33.87, 151.21), // Sydney
        (40.71, -74.01), // New York
        (1.35, 103.82), // Singapore
      ]) {
        final double b = LumeQiblaMath.bearing(lat, lon);
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
      }
    });
  });

  group('distance', () {
    test('Jeddah, a short drive from the Kaaba, is under 100 km', () {
      expect(LumeQiblaMath.distanceKm(21.49, 39.19), lessThan(100));
    });

    test('Islamabad is on the order of the widely published ~3,500 km', () {
      expect(
        LumeQiblaMath.distanceKm(33.69, 73.05),
        inInclusiveRange(3400, 3650),
      );
    });

    test('London is on the order of the widely published ~4,800 km', () {
      expect(
        LumeQiblaMath.distanceKm(51.5074, -0.1278),
        inInclusiveRange(4600, 5000),
      );
    });

    test('is symmetric with the bearing\'s own antipodal case: the farther '
        'point (roughly the Pacific, antipodal to the Kaaba) is close to '
        'half Earth\'s circumference away', () {
      // Antipode of the Kaaba: latitude negated, longitude rotated by 180°.
      final int d = LumeQiblaMath.distanceKm(
        -LumeQiblaMath.kaabaLat,
        LumeQiblaMath.kaabaLon - 180,
      );
      expect(d, inInclusiveRange(19800, 20100));
    });
  });

  group('compass point', () {
    // Each of the eight points spans 45°, centred on its own multiple of 45
    // (N on 0°, NE on 45°, and so on) — so the N/NE boundary falls at 22.5°,
    // not at 45° itself. These sit safely inside each slice rather than on a
    // boundary.
    test('the eight points, well inside each 45° slice', () {
      expect(LumeQiblaMath.compassPoint(0), 'N');
      expect(LumeQiblaMath.compassPoint(10), 'N');
      expect(LumeQiblaMath.compassPoint(50), 'NE');
      expect(LumeQiblaMath.compassPoint(90), 'E');
      expect(LumeQiblaMath.compassPoint(140), 'SE');
      expect(LumeQiblaMath.compassPoint(180), 'S');
      expect(LumeQiblaMath.compassPoint(220), 'SW');
      expect(LumeQiblaMath.compassPoint(270), 'W');
      expect(LumeQiblaMath.compassPoint(320), 'NW');
      expect(LumeQiblaMath.compassPoint(355), 'N');
    });
  });
}
