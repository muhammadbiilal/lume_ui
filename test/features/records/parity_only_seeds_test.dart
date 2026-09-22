/// Which collections a build a reader runs opens empty.
///
/// The families of wave 2 open with demonstration records everywhere: four
/// notes, five shopping items, two events, five expenses, four documents.
/// They are the reference's own, they are marked as samples, and a reader
/// clears them in a tap.
///
/// Wave 4's two are not the same kind of thing. A birthday is a person's
/// name and the day they were born; a drink is something the reader did at a
/// particular hour. Seeding those would not demonstrate a list — it would be
/// an invented account of the reader's own life, with "in 4 days", "turning
/// 29" and "1.25 L today" worked out on top of it and presented as theirs.
/// So `kLumeParityOnlySeeds` holds them, and only the build that reproduces
/// the reference is seeded (C100).
///
/// Asserted here rather than left to the two tools, because the rule is the
/// store's: a third tool added to that set later must be covered by the same
/// test without anyone remembering to write one.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';

/// The instant every seed is dated from, so a day count is not the clock's.
final DateTime kDay = DateTime(2026, 9, 7, 16, 41, 32);

/// Every collection that has seeds in the reproduction.
const List<String> kSeeded = <String>[
  'expenses',
  'documents',
  'notes',
  'todos',
  'events',
  'shopping',
  'birthdays',
  'water',
];

void main() {
  group('the two families a shipping build opens empty', () {
    test('are exactly Birthdays and Water', () {
      expect(kLumeParityOnlySeeds, <String>{'birthdays', 'water'});
    });

    test('have seeds in the reproduction and none outside it', () {
      for (final String collection in kLumeParityOnlySeeds) {
        expect(
          lumeRecordSeeds(collection, kDay, reproducesReference: true),
          isNotEmpty,
          reason: '$collection: the parity capture reproduces the reference',
        );
        expect(
          lumeRecordSeeds(collection, kDay),
          isNull,
          reason: '$collection: a build a reader runs invents nothing',
        );
      }
    });

    test('and every other family is seeded in both', () {
      for (final String collection in kSeeded) {
        if (kLumeParityOnlySeeds.contains(collection)) continue;
        expect(
          lumeRecordSeeds(collection, kDay),
          isNotEmpty,
          reason: '$collection was seeded before wave 4 and still is',
        );
        expect(
          lumeRecordSeeds(collection, kDay, reproducesReference: true),
          lumeRecordSeeds(collection, kDay),
          reason: '$collection does not depend on the build type at all',
        );
      }
    });

    test('a collection nothing has converted is empty either way', () {
      expect(lumeRecordSeeds('reminders', kDay), isNull);
      expect(
        lumeRecordSeeds('reminders', kDay, reproducesReference: true),
        isNull,
      );
    });
  });

  group('and the store draws what it is given', () {
    LumeMemoryRecordRepository store({required bool parity}) =>
        LumeMemoryRecordRepository(
          seeds: (String collection, DateTime now) =>
              lumeRecordSeeds(collection, now, reproducesReference: parity),
        );

    Future<List<LumeRecord>> read(
      LumeMemoryRecordRepository repo,
      String collection,
    ) async {
      repo.open(collection);
      // The first open is a loading state; the records arrive after it.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return repo.view(collection).items;
    }

    test(
      'three birthdays in the reproduction, none in a shipping build',
      () async {
        final LumeMemoryRecordRepository parity = store(parity: true);
        addTearDown(parity.dispose);
        expect(await read(parity, 'birthdays'), hasLength(3));

        final LumeMemoryRecordRepository shipping = store(parity: false);
        addTearDown(shipping.dispose);
        expect(await read(shipping, 'birthdays'), isEmpty);
      },
    );

    test('four drinks in the reproduction, none in a shipping build', () async {
      final LumeMemoryRecordRepository parity = store(parity: true);
      addTearDown(parity.dispose);
      final List<LumeRecord> drinks = await read(parity, 'water');
      expect(drinks, hasLength(4));
      // The reference's four, summing to the 1250 ml its summary prints.
      expect(
        drinks.fold<int>(0, (int a, LumeRecord r) => a + (r['ml']! as int)),
        1250,
      );
      // And every one of them carries a day, which the reference's schema
      // has no field for at all — without it "today's intake" is a claim
      // nothing can check. The store dates its own seeds from the day the
      // collection is first read, so the assertion is that they are all on
      // that day, not on a day written down here.
      final String today = lumeIsoDay(DateTime.now(), 0);
      for (final LumeRecord r in drinks) {
        expect(r['date'], today, reason: r.id);
      }

      final LumeMemoryRecordRepository shipping = store(parity: false);
      addTearDown(shipping.dispose);
      expect(await read(shipping, 'water'), isEmpty);
    });

    test('notes are seeded in both, as they were before wave 4', () async {
      for (final bool parity in <bool>[true, false]) {
        final LumeMemoryRecordRepository repo = store(parity: parity);
        addTearDown(repo.dispose);
        expect(await read(repo, 'notes'), hasLength(4), reason: '$parity');
      }
    });
  });

  group('and the capability says the same thing', () {
    test('both are the reader\'s records, and sampled only in parity', () {
      for (final String id in <String>['birthdays', 'water']) {
        expect(LumeDataCapability.readerRecords, contains(id));
        expect(LumeDataCapability.sampleInParityOnly, contains(id));
        expect(
          LumeDataCapability.fixture(id).isSample,
          isFalse,
          reason: '$id: nothing on a reader\'s screen is a sample',
        );
        expect(
          LumeDataCapability.fixture(id, reproducesReference: true).isSample,
          isTrue,
          reason: '$id: the reproduction discloses the seeds it draws',
        );
      }
    });

    test('the two sets agree: a parity-only seed is a parity-only sample', () {
      expect(
        kLumeParityOnlySeeds.difference(LumeDataCapability.sampleInParityOnly),
        isEmpty,
        reason:
            'a collection seeded only in parity must disclose only in parity, '
            'or the screen and the store are telling different stories',
      );
    });
  });
}
