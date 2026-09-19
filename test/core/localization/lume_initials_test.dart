/// One initials rule for every tinted disc.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_initials.dart';

void main() {
  test('two words, or a camel-case word, give two: the reference logos', () {
    expect(lumeInitials('TechMart'), 'TM');
    expect(lumeInitials('HomeStore'), 'HS');
    expect(lumeInitials('Mobile Hub'), 'MH');
    expect(lumeInitials('ahmed raza'), 'AR');
  });

  test('never more than two', () {
    expect(lumeInitials('Big Box Mega Store'), 'BB');
    expect(lumeInitials('SuperMegaMart'), 'SM');
  });

  test('one plain word gives one', () {
    expect(lumeInitials('Wheels'), 'W');
    expect(lumeInitials('SARA'), 'S');
  });

  test('scripts without case split on spaces only', () {
    expect(lumeInitials('محمد علي'), 'مع');
    expect(lumeInitials('ٹیک مارٹ'), 'ٹم');
    expect(lumeInitials('بلال'), 'ب');
  });

  test('graphemes stay whole; no letters gives none', () {
    expect(lumeInitials('école Normale'), 'ÉN');
    expect(lumeInitials('  42  '), isNull);
    expect(lumeInitials(''), isNull);
  });
}
