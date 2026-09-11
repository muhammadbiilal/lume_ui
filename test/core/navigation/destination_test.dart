/// The destination set: one definition, and what it guarantees.
///
/// These are the cheapest tests in the suite and they protect the most
/// expensive mistake — three navigations that disagree. If a bar, a rail and a
/// sidebar can only be built from [LumeDestinations], then they cannot hold
/// different lists, and the only thing left to test is the list itself.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_destination.dart';

void main() {
  String label(LumeDestinationId id) => id.name;

  group('the tab set', () {
    test('never exceeds five (§6)', () {
      for (final String country in <String>['PK', 'GB', 'US', 'SA', 'JP', '']) {
        expect(
          LumeDestinations.orderFor(country).length,
          lessThanOrEqualTo(LumeDestinations.maximum),
          reason: 'country $country',
        );
      }
    });

    test('Pakistan has Trains and not Explore', () {
      final List<LumeDestinationId> pk = LumeDestinations.orderFor('PK');
      expect(pk, contains(LumeDestinationId.trains));
      expect(pk, isNot(contains(LumeDestinationId.explore)));
    });

    test('everywhere else has Explore and not Trains', () {
      for (final String country in <String>['GB', 'US', 'AE', 'IN', 'BR']) {
        final List<LumeDestinationId> order = LumeDestinations.orderFor(
          country,
        );
        expect(order, contains(LumeDestinationId.explore), reason: country);
        expect(
          order,
          isNot(contains(LumeDestinationId.trains)),
          reason: country,
        );
      }
    });

    test('Home is first and Profile is last in every country', () {
      for (final String country in <String>['PK', 'GB', 'US']) {
        final List<LumeDestinationId> order = LumeDestinations.orderFor(
          country,
        );
        expect(order.first, LumeDestinationId.home, reason: country);
        expect(order.last, LumeDestinationId.profile, reason: country);
      }
    });

    test('holds no duplicates', () {
      for (final String country in <String>['PK', 'GB']) {
        final List<LumeDestinationId> order = LumeDestinations.orderFor(
          country,
        );
        expect(order.toSet().length, order.length, reason: country);
      }
    });
  });

  group('branch indices', () {
    test('are stable across a country change', () {
      // The point of a fixed branch order: a Pakistani user who moves to the
      // UK loses Trains from the bar, and Today's stack is still Today's
      // stack — because its branch index did not move underneath it.
      final Map<LumeDestinationId, int> before = <LumeDestinationId, int>{
        for (final LumeDestinationId id in LumeDestinations.orderFor('PK'))
          id: LumeDestinations.branchIndexOf(id),
      };
      final Map<LumeDestinationId, int> after = <LumeDestinationId, int>{
        for (final LumeDestinationId id in LumeDestinations.orderFor('GB'))
          id: LumeDestinations.branchIndexOf(id),
      };
      for (final LumeDestinationId id in before.keys) {
        if (after.containsKey(id)) {
          expect(after[id], before[id], reason: '${id.name} moved branch');
        }
      }
    });

    test('cover every destination exactly once', () {
      final List<int> indices = LumeDestinations.all
          .map(LumeDestinations.branchIndexOf)
          .toList();
      expect(indices.toSet().length, LumeDestinations.all.length);
      expect(indices, everyElement(greaterThanOrEqualTo(0)));
    });

    test('include every destination any country can show', () {
      for (final String country in <String>['PK', 'GB', 'US', 'SA']) {
        for (final LumeDestinationId id in LumeDestinations.orderFor(country)) {
          expect(
            LumeDestinations.all,
            contains(id),
            reason: '$country shows ${id.name}, which has no branch',
          );
        }
      }
    });
  });

  group('building the set', () {
    test('every destination has a glyph', () {
      for (final LumeDestinationId id in LumeDestinations.all) {
        expect(
          LumeDestinations.icons[id],
          isNotNull,
          reason: '${id.name} has no icon',
        );
      }
    });

    test('a route is derived from the id, never written twice', () {
      for (final LumeDestinationId id in LumeDestinations.all) {
        expect(id.path, '/${id.name}');
      }
    });

    test('a badge count reaches the screen reader', () {
      final List<LumeDestination> built = LumeDestinations.build(
        countryCode: 'PK',
        label: label,
        badges: const <LumeDestinationId, int>{LumeDestinationId.today: 3},
      );
      final LumeDestination today = built.firstWhere(
        (LumeDestination d) => d.id == LumeDestinationId.today,
      );
      expect(today.hasBadge, isTrue);
      expect(today.semanticLabel, contains('3'));
      expect(today.semanticLabel, isNot(today.label));
    });

    test('a dot reaches the screen reader without inventing a number', () {
      final List<LumeDestination> built = LumeDestinations.build(
        countryCode: 'PK',
        label: label,
        dots: const <LumeDestinationId>{LumeDestinationId.profile},
      );
      final LumeDestination profile = built.last;
      expect(profile.hasBadge, isTrue);
      expect(profile.badgeCount, isNull);
      expect(profile.semanticLabel, isNot(contains('0')));
    });

    test('a zero count is not a badge', () {
      final List<LumeDestination> built = LumeDestinations.build(
        countryCode: 'PK',
        label: label,
        badges: const <LumeDestinationId, int>{LumeDestinationId.today: 0},
      );
      final LumeDestination today = built.firstWhere(
        (LumeDestination d) => d.id == LumeDestinationId.today,
      );
      expect(today.hasBadge, isFalse);
      expect(today.semanticLabel, today.label);
    });

    test('an undecorated destination says only its label', () {
      final List<LumeDestination> built = LumeDestinations.build(
        countryCode: 'PK',
        label: label,
      );
      for (final LumeDestination d in built) {
        expect(d.semanticLabel, d.label);
      }
    });

    test('labels come from the caller, so this layer holds no strings', () {
      final List<LumeDestination> built = LumeDestinations.build(
        countryCode: 'PK',
        label: (LumeDestinationId id) => 'X${id.name}',
      );
      for (final LumeDestination d in built) {
        expect(d.label, startsWith('X'));
      }
    });
  });
}
