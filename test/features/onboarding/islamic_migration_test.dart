/// The Islamic-content migration, one test per row of the policy.
///
/// This is the suite a Dayroz adapter has to satisfy. Nothing here touches a
/// widget: the question "does an upgrading user keep the experience they had"
/// is answerable without pumping a frame, and it is answered against
/// [LumeProfileRepository] doubles rather than against real storage.
///
/// The cases that matter most are the ones that used to be wrong. `null` was
/// read as "no", which silently switched off content a grandfathered user had
/// been using every day, and the cohort was guessed from the interests the
/// user happened to have selected — an inference about religion from chosen
/// tools, which §3 forbids outright.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/onboarding/domain/islamic_migration.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';

/// A repository that fails a set number of writes before it starts working.
///
/// Models the interrupted upgrade: the decision was reached, the process died
/// on the way to disk, and the application is launched again.
class _FlakyRepository implements LumeProfileRepository {
  _FlakyRepository({
    required this.installation,
    required LumeProfileRecord record,
    this.failuresLeft = 0,
  }) : _record = record;

  final LumeInstallationInfo installation;
  LumeProfileRecord _record;
  int failuresLeft;
  int writes = 0;

  @override
  bool get isDurable => false;

  @override
  Future<LumeInstallationInfo> readInstallation() async => installation;

  @override
  Future<LumeProfileRecord> readProfile() async => _record;

  @override
  Future<void> writeProfile(LumeProfileRecord record) async {
    if (failuresLeft > 0) {
      failuresLeft--;
      throw const _WriteFailed();
    }
    writes++;
    _record = record;
  }
}

class _WriteFailed implements Exception {
  const _WriteFailed();
}

void main() {
  const LumeProfileRecord blank = LumeProfileRecord();

  LumeMigrationResult apply(
    LumeProfileRecord record,
    LumeInstallationInfo installation,
  ) => LumeIslamicDefaultMigration.apply(record, installation);

  group('the policy, row by row', () {
    test('a fresh installation defaults the experience off', () {
      final LumeMigrationResult r = apply(
        blank,
        const LumeInstallationInfo.fresh(),
      );
      expect(r.decision, LumeMigrationDecision.freshDefaultOff);
      expect(r.record.islamic, isFalse);
      expect(r.record.migrations, contains(LumeIslamicDefaultMigration.marker));
    });

    test('an existing user’s explicit yes is preserved', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(onboarded: true, islamic: true),
        const LumeInstallationInfo.existing(),
      );
      expect(r.decision, LumeMigrationDecision.keptExplicit);
      expect(r.record.islamic, isTrue);
    });

    test('an existing user’s explicit no is preserved', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(
          onboarded: true,
          islamic: false,
          // Faith interests present and the answer is still no. Nothing reads
          // the interest list to decide this.
          interests: <String>['quran', 'prayer'],
        ),
        const LumeInstallationInfo.existing(),
      );
      expect(r.decision, LumeMigrationDecision.keptExplicit);
      expect(
        r.record.islamic,
        isFalse,
        reason: 'somebody who turned it off must not find it back on',
      );
    });

    test('a pre-migration user with no value keeps what they were seeing', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(onboarded: true, interests: <String>['news']),
        const LumeInstallationInfo.legacy(
          schemaVersion: LumeProfileSchema.preIslamicPreference,
        ),
      );
      expect(r.decision, LumeMigrationDecision.grandfatheredOn);
      expect(
        r.record.islamic,
        isTrue,
        reason: 'the build they upgraded from showed it to everyone',
      );
    });

    test('a legacy store with no version stamp is still legacy', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(onboarded: true),
        const LumeInstallationInfo.legacy(),
      );
      expect(r.decision, LumeMigrationDecision.grandfatheredOn);
      expect(r.record.islamic, isTrue);
    });

    test('an installation whose marker exists is never migrated again', () {
      const LumeProfileRecord done = LumeProfileRecord(
        onboarded: true,
        islamic: false,
        migrations: <String>{LumeIslamicDefaultMigration.marker},
      );
      for (final LumeInstallationInfo info in <LumeInstallationInfo>[
        const LumeInstallationInfo.fresh(),
        const LumeInstallationInfo.existing(),
        const LumeInstallationInfo.legacy(),
        const LumeInstallationInfo.unknown(),
      ]) {
        final LumeMigrationResult r = apply(done, info);
        expect(r.decision, LumeMigrationDecision.alreadyDone, reason: '$info');
        expect(r.changed, isFalse);
        expect(identical(r.record, done), isTrue);
      }
    });
  });

  group('the cohort comes from metadata, never from the profile', () {
    test('the same record migrates differently per cohort', () {
      // One record, three installations, three answers. If the cohort were
      // being read out of the record these could not differ.
      const LumeProfileRecord record = LumeProfileRecord(onboarded: true);
      expect(
        apply(record, const LumeInstallationInfo.fresh()).record.islamic,
        isFalse,
      );
      expect(
        apply(record, const LumeInstallationInfo.legacy()).record.islamic,
        isTrue,
      );
      expect(
        apply(record, const LumeInstallationInfo.existing()).record.islamic,
        isFalse,
      );
    });

    test('country, city, region and name never move it', () {
      for (final (String country, String city, String name)
          in <(String, String, String)>[
            ('PK', 'Islamabad', 'Bilal'),
            ('SA', 'Riyadh', 'Fatima'),
            ('AE', 'Dubai', 'Omar'),
            ('US', 'New York', 'Sarah'),
            ('JP', 'Tokyo', 'Yuki'),
          ]) {
        final LumeProfileRecord legacy = apply(
          LumeProfileRecord(
            country: country,
            city: city,
            displayName: name,
            onboarded: true,
          ),
          const LumeInstallationInfo.legacy(),
        ).record;
        final LumeProfileRecord fresh = apply(
          LumeProfileRecord(country: country, city: city, displayName: name),
          const LumeInstallationInfo.fresh(),
        ).record;

        expect(legacy.islamic, isTrue, reason: '$country grandfathered');
        expect(fresh.islamic, isFalse, reason: '$country fresh');
      }
    });

    test('selected tools never move it either', () {
      // The old rule read `true` out of a faith interest. It is an inference
      // about religion from chosen tools, and it is gone: within one cohort
      // the answer is the same whatever the list holds.
      for (final List<String> interests in <List<String>>[
        <String>[],
        <String>['weather', 'news'],
        <String>['quran', 'prayer', 'hadith'],
        LumeOnboardingState.faithInterests.toList(),
      ]) {
        expect(
          apply(
            LumeProfileRecord(onboarded: true, interests: interests),
            const LumeInstallationInfo.legacy(),
          ).record.islamic,
          isTrue,
          reason: 'legacy: $interests',
        );
        expect(
          apply(
            LumeProfileRecord(onboarded: true, interests: interests),
            const LumeInstallationInfo.existing(),
          ).record.islamic,
          isFalse,
          reason: 'existing: $interests',
        );
      }
    });
  });

  group('malformed and partial legacy state', () {
    test('a current-schema record missing the value is repaired, off', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(onboarded: true, interests: <String>['quran']),
        const LumeInstallationInfo.existing(),
      );
      expect(r.decision, LumeMigrationDecision.repairedPartial);
      expect(r.record.islamic, isFalse);
      expect(r.record.migrations, contains(LumeIslamicDefaultMigration.marker));
    });

    test('an unknown cohort decides nothing and leaves no marker', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(onboarded: true),
        const LumeInstallationInfo.unknown(),
      );
      expect(r.decision, LumeMigrationDecision.deferredUnknown);
      expect(r.changed, isFalse);
      expect(r.record.islamic, isNull);
      expect(
        r.record.migrations,
        isNot(contains(LumeIslamicDefaultMigration.marker)),
        reason: 'a postponed decision must still be reachable',
      );
    });

    test('a deferred installation migrates properly once it can answer', () {
      const LumeProfileRecord record = LumeProfileRecord(onboarded: true);
      final LumeProfileRecord deferred = apply(
        record,
        const LumeInstallationInfo.unknown(),
      ).record;

      final LumeMigrationResult later = apply(
        deferred,
        const LumeInstallationInfo.legacy(),
      );
      expect(later.decision, LumeMigrationDecision.grandfatheredOn);
      expect(later.record.islamic, isTrue);
    });

    test('an unrelated marker does not stand in for this one', () {
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(
          onboarded: true,
          migrations: <String>{'some-other-migration'},
        ),
        const LumeInstallationInfo.legacy(),
      );
      expect(r.decision, LumeMigrationDecision.grandfatheredOn);
      expect(r.record.migrations, contains('some-other-migration'));
      expect(r.record.migrations, contains(LumeIslamicDefaultMigration.marker));
    });
  });

  group('running it more than once', () {
    test('is idempotent in every cohort', () {
      for (final LumeInstallationInfo info in <LumeInstallationInfo>[
        const LumeInstallationInfo.fresh(),
        const LumeInstallationInfo.existing(),
        const LumeInstallationInfo.legacy(),
      ]) {
        final LumeMigrationResult first = apply(
          const LumeProfileRecord(onboarded: true),
          info,
        );
        final LumeMigrationResult second = apply(first.record, info);
        expect(
          second.decision,
          LumeMigrationDecision.alreadyDone,
          reason: '$info',
        );
        expect(second.changed, isFalse);
        expect(second.record.islamic, first.record.islamic, reason: '$info');
      }
    });

    test('a later change by the user is never overwritten', () {
      final LumeProfileRecord migrated = apply(
        const LumeProfileRecord(onboarded: true),
        const LumeInstallationInfo.legacy(),
      ).record;
      expect(migrated.islamic, isTrue);

      // The user turns it off, and relaunches. Twice.
      LumeProfileRecord record = migrated.copyWith(islamic: false);
      for (int i = 0; i < 2; i++) {
        record = apply(record, const LumeInstallationInfo.legacy()).record;
      }
      expect(record.islamic, isFalse);
    });
  });

  group('an interrupted upgrade', () {
    test('nothing persisted: the next launch reaches the same decision', () {
      const LumeProfileRecord stored = LumeProfileRecord(onboarded: true);
      const LumeInstallationInfo info = LumeInstallationInfo.legacy();

      // The first run decides, and dies before the write lands, so `stored` is
      // still what is on disk.
      expect(apply(stored, info).record.islamic, isTrue);
      expect(apply(stored, info).record.islamic, isTrue);
    });

    test('value persisted, marker lost: the value wins', () {
      // Only reachable if an adapter breaks the atomic-write obligation. The
      // explicit check runs before the cohort check precisely so this lands on
      // the user's value rather than being decided a second time.
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(onboarded: true, islamic: true),
        const LumeInstallationInfo.fresh(),
      );
      expect(r.decision, LumeMigrationDecision.keptExplicit);
      expect(r.record.islamic, isTrue);
      expect(r.record.migrations, contains(LumeIslamicDefaultMigration.marker));
    });

    test('marker persisted, value lost: off, and documented as such', () {
      // The dangerous half of a non-atomic write, and the reason the contract
      // demands one operation. The record reads as undecided for ever, and
      // `draftFrom` treats that as off.
      final LumeMigrationResult r = apply(
        const LumeProfileRecord(
          onboarded: true,
          migrations: <String>{LumeIslamicDefaultMigration.marker},
        ),
        const LumeInstallationInfo.legacy(),
      );
      expect(r.decision, LumeMigrationDecision.alreadyDone);
      expect(r.record.islamic, isNull);
      expect(LumeOnboardingState.draftFrom(r.record).islamic, isFalse);
    });
  });

  group('the migrator, against a repository', () {
    test('writes once and then never again', () async {
      final LumeMemoryProfileRepository repo = LumeMemoryProfileRepository(
        initial: const LumeProfileRecord(onboarded: true),
        installation: const LumeInstallationInfo.legacy(),
      );
      final LumeProfileMigrator migrator = LumeProfileMigrator(repo);

      final LumeMigrationResult first = await migrator.run();
      expect(first.decision, LumeMigrationDecision.grandfatheredOn);
      expect(repo.writes, 1);

      final LumeMigrationResult second = await migrator.run();
      expect(second.decision, LumeMigrationDecision.alreadyDone);
      expect(repo.writes, 1, reason: 'nothing to write the second time');
      expect((await repo.readProfile()).islamic, isTrue);
    });

    test('an unknown cohort writes nothing at all', () async {
      final LumeMemoryProfileRepository repo = LumeMemoryProfileRepository(
        initial: const LumeProfileRecord(onboarded: true),
        installation: const LumeInstallationInfo.unknown(),
      );
      await LumeProfileMigrator(repo).run();
      expect(repo.writes, 0);
      expect((await repo.readProfile()).islamic, isNull);
    });

    test(
      'a failed write leaves the store untouched and retries clean',
      () async {
        final _FlakyRepository repo = _FlakyRepository(
          installation: const LumeInstallationInfo.legacy(),
          record: const LumeProfileRecord(onboarded: true),
          failuresLeft: 1,
        );
        final LumeProfileMigrator migrator = LumeProfileMigrator(repo);

        await expectLater(migrator.run(), throwsA(isA<Exception>()));
        expect(repo.writes, 0);
        expect((await repo.readProfile()).islamic, isNull);

        final LumeMigrationResult retry = await migrator.run();
        expect(retry.decision, LumeMigrationDecision.grandfatheredOn);
        expect(repo.writes, 1);
        expect((await repo.readProfile()).islamic, isTrue);
      },
    );

    test(
      'a fresh memory repository reports itself fresh, and not durable',
      () async {
        final LumeMemoryProfileRepository repo = LumeMemoryProfileRepository();
        expect(repo.isDurable, isFalse);
        expect(
          (await repo.readInstallation()).state,
          LumeInstallationState.fresh,
        );
        expect((await LumeProfileMigrator(repo).run()).record.islamic, isFalse);
      },
    );
  });

  group('skipping the flow does not overwrite a decided preference', () {
    test('a grandfathered user who skips keeps the experience', () {
      final LumeProfileRecord migrated = LumeIslamicDefaultMigration.apply(
        const LumeProfileRecord(onboarded: true),
        const LumeInstallationInfo.legacy(),
      ).record;

      final LumeProfileRecord skipped = LumeOnboardingState.skip(
        migrated,
        const LumeOnboardingDraft(),
      );
      expect(
        skipped.islamic,
        isTrue,
        reason: 'skipping a question is not answering it',
      );
      expect(skipped.onboarded, isTrue);
    });

    test('a fresh user who skips gets the neutral default', () {
      final LumeProfileRecord skipped = LumeOnboardingState.skip(
        LumeIslamicDefaultMigration.apply(
          blank,
          const LumeInstallationInfo.fresh(),
        ).record,
        const LumeOnboardingDraft(),
      );
      expect(skipped.islamic, isFalse);
      expect(skipped.interests, LumeOnboardingState.defaultInterests);
    });
  });
}
