/// The one-shot Islamic-content migration, and the rule it follows.
///
/// `islamic` is nullable in the stored record, and a `null` means at least
/// three different things:
///
/// * nobody has ever been asked, because this install is minutes old;
/// * somebody was asked long ago by a build that had nowhere to put the
///   answer, and the application showed them Islamic content regardless;
/// * the field should be there and is not, because something wrote a partial
///   record.
///
/// Those do not share an answer, so `null → false` was wrong. A user upgrading
/// from a build that showed them Islamic content every day would have opened
/// the new version to find it gone, having asked for nothing.
///
/// The cohort is therefore read from [LumeInstallationInfo] — explicit
/// metadata the storage layer owns — and never from the profile's own fields.
/// In particular it is never read from country, city, language, locale, name
/// or which tools were chosen. §3 of the product specification says religion
/// is never inferred, and a list of selected interests is an inference like any
/// other.
///
/// ## The policy
///
/// | Installation | `islamic` before | after |
/// |---|---|---|
/// | fresh | absent | `false` — off by default |
/// | existing | `true` | `true` — preserved |
/// | existing | `false` | `false` — preserved |
/// | legacy, pre-preference | absent | `true` — previous behaviour preserved |
/// | existing | absent | `false` — partial record, neutral answer |
/// | unknown | anything | untouched, and the marker is **not** written |
/// | marker already present | anything | untouched |
///
/// Nothing outside this file decides any of it, and no widget calls it.
library;

import 'package:flutter/foundation.dart';

import 'onboarding_state.dart';
import 'profile_repository.dart';

/// Why the migration did what it did.
///
/// Returned rather than logged, so a test can assert the reasoning and not
/// merely the result — several rows of the policy table produce `false` for
/// entirely different reasons.
enum LumeMigrationDecision {
  /// The marker was already there. Nothing was read, nothing was written.
  alreadyDone,

  /// A fresh installation. Off by default.
  freshDefaultOff,

  /// The user had said one way or the other. Kept, whichever way it pointed.
  keptExplicit,

  /// An installation from before the preference existed, which had been
  /// showing Islamic content. Turned on, so that nothing the user was already
  /// seeing disappears on upgrade.
  grandfatheredOn,

  /// A current-schema profile with the field missing: a partial write rather
  /// than a cohort. Answered neutrally, off.
  repairedPartial,

  /// The storage layer could not say which cohort this is. No value, no
  /// marker, nothing written — so the migration can run properly later.
  deferredUnknown,
}

/// What one run of the migration concluded.
@immutable
class LumeMigrationResult {
  const LumeMigrationResult({
    required this.record,
    required this.decision,
    required this.changed,
  });

  /// The record as it should now be stored. Carries both the decided value and
  /// the marker, so persisting it is one atomic write.
  final LumeProfileRecord record;

  final LumeMigrationDecision decision;

  /// Whether [record] differs from what was passed in. `false` means the
  /// caller has nothing to write.
  final bool changed;
}

/// The migration, as a pure function of a record and a cohort.
abstract final class LumeIslamicDefaultMigration {
  /// The marker written when the decision is made.
  ///
  /// One marker per migration: adding a second one later cannot re-run this
  /// one, and this one cannot suppress that one.
  static const String marker = 'islamic-default-2026-09';

  /// Apply the policy table above.
  ///
  /// Idempotent: `apply(apply(r, i).record, i)` returns the same record with
  /// [LumeMigrationDecision.alreadyDone]. The only case that repeats work is
  /// [LumeInstallationState.unknown], which deliberately leaves no marker so
  /// that a later run with real metadata can still decide.
  static LumeMigrationResult apply(
    LumeProfileRecord record,
    LumeInstallationInfo installation,
  ) {
    if (record.migrations.contains(marker)) {
      return LumeMigrationResult(
        record: record,
        decision: LumeMigrationDecision.alreadyDone,
        changed: false,
      );
    }

    // An adapter that cannot name the cohort must not be guessed at. Leaving
    // no marker is the whole point: the decision is postponed, not made badly.
    if (installation.state == LumeInstallationState.unknown) {
      return LumeMigrationResult(
        record: record,
        decision: LumeMigrationDecision.deferredUnknown,
        changed: false,
      );
    }

    final Set<String> migrations = <String>{...record.migrations, marker};

    // An answer the user gave is an answer, in every cohort. This is checked
    // before the cohort so that a half-written upgrade — value persisted, then
    // the process killed before the marker — converges on the user's value
    // rather than on the cohort default.
    if (record.islamic != null) {
      return LumeMigrationResult(
        record: record.copyWith(migrations: migrations),
        decision: LumeMigrationDecision.keptExplicit,
        changed: true,
      );
    }

    final (
      bool islamic,
      LumeMigrationDecision decision,
    ) = switch (installation.state) {
      // Nobody has been asked yet. The flow will ask; until it does, off.
      LumeInstallationState.fresh => (
        false,
        LumeMigrationDecision.freshDefaultOff,
      ),
      // The build that wrote this profile showed Islamic content to everyone,
      // so `true` is what that user has been living with. Preserving observed
      // behaviour is not an inference about who they are, and they can turn it
      // off in one switch — which is the failure worth having, against making
      // content they use every day vanish without being asked.
      LumeInstallationState.legacyPreIslamic => (
        true,
        LumeMigrationDecision.grandfatheredOn,
      ),
      // The schema says the field should be present. It is not, so this is a
      // damaged or partial record rather than a cohort, and the neutral answer
      // is the product default.
      LumeInstallationState.existing => (
        false,
        LumeMigrationDecision.repairedPartial,
      ),
      LumeInstallationState.unknown => throw StateError('handled above'),
    };

    return LumeMigrationResult(
      record: record.copyWith(islamic: islamic, migrations: migrations),
      decision: decision,
      changed: true,
    );
  }
}

/// Runs the one-shot migrations against a repository, once, at startup.
///
/// Deliberately not a widget, not a provider and not something the onboarding
/// flow calls. The flow is handed a record that has already been through here.
class LumeProfileMigrator {
  const LumeProfileMigrator(this.repository);

  final LumeProfileRepository repository;

  /// Read, decide, write only if something changed, and hand back the record
  /// the rest of startup should use.
  ///
  /// The write is a single [LumeProfileRepository.writeProfile] carrying both
  /// the value and the marker. If it fails, nothing is persisted and the next
  /// launch reaches exactly the same decision from exactly the same inputs.
  Future<LumeMigrationResult> run() async {
    final LumeProfileRecord record = await repository.readProfile();
    final LumeInstallationInfo installation = await repository
        .readInstallation();

    final LumeMigrationResult result = LumeIslamicDefaultMigration.apply(
      record,
      installation,
    );
    if (result.changed) await repository.writeProfile(result.record);
    return result;
  }
}
