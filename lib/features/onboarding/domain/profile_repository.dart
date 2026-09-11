/// Where the profile lives, and what the storage layer can say about *itself*.
///
/// Two contracts, deliberately separate:
///
/// * [LumeProfileRepository] is the durable one. Dayroz implements it; this
///   repository ships only doubles. It is asynchronous because reading a real
///   store is, and because the startup gate has to be able to wait for it
///   rather than guess while it loads.
/// * `LumeOnboardingStore` (in `onboarding_state.dart`) is the flow's
///   synchronous handle on a record that has *already* been loaded. The flow
///   never waits on I/O mid-step.
///
/// The reason this file exists at all is [LumeInstallationInfo]. A one-shot
/// migration has to know which cohort an installation belongs to, and the one
/// thing it must never do is work that out from the data it is migrating. An
/// absent preference is absent for at least three different reasons, and they
/// do not share an answer. So the storage layer states the cohort explicitly,
/// out of band, and the migration reads it rather than inferring it.
library;

import 'package:flutter/foundation.dart';

import 'onboarding_state.dart';

/// The profile schema versions this application knows about.
///
/// A version is stamped on the record when it is written. It is the only
/// admissible evidence for how old a stored profile is — not the presence or
/// absence of any particular field.
abstract final class LumeProfileSchema {
  /// Before the Islamic preference existed. A profile written by one of these
  /// builds has no `islamic` field at all, and the application it came from
  /// showed Islamic content to everyone.
  static const int preIslamicPreference = 1;

  /// The first version carrying an explicit `islamic` preference.
  static const int islamicPreference = 2;

  /// What this build writes.
  static const int current = islamicPreference;
}

/// Which cohort an installation belongs to.
///
/// Stated by the storage layer. Never derived from a profile field.
enum LumeInstallationState {
  /// Nothing has ever been stored here — no profile, no schema version, no
  /// install marker. A first launch.
  fresh,

  /// A profile exists and was written at [LumeProfileSchema.islamicPreference]
  /// or later, by a build that had somewhere to put the preference.
  existing,

  /// A profile exists and predates the preference: stamped below
  /// [LumeProfileSchema.islamicPreference], or written before versions were
  /// stamped at all. The application that wrote it showed Islamic content
  /// unconditionally.
  legacyPreIslamic,

  /// The storage layer cannot say. A read failed, the metadata is unreadable,
  /// or the adapter has not been wired yet. Not a cohort but an admission, and
  /// the migration answers it by declining to decide.
  unknown,
}

/// What the storage layer says about itself before any preference is read.
@immutable
class LumeInstallationInfo {
  const LumeInstallationInfo({required this.state, this.schemaVersion});

  /// Nothing stored yet.
  const LumeInstallationInfo.fresh()
    : state = LumeInstallationState.fresh,
      schemaVersion = null;

  /// Stored by a build that had the preference.
  const LumeInstallationInfo.existing({
    this.schemaVersion = LumeProfileSchema.current,
  }) : state = LumeInstallationState.existing;

  /// Stored by a build that did not.
  const LumeInstallationInfo.legacy({this.schemaVersion})
    : state = LumeInstallationState.legacyPreIslamic;

  /// The adapter cannot tell.
  const LumeInstallationInfo.unknown()
    : state = LumeInstallationState.unknown,
      schemaVersion = null;

  final LumeInstallationState state;

  /// The version stamped on the stored profile. `null` for a fresh install,
  /// and for a legacy store written before stamping existed — which is why
  /// [state] rather than this field is what the migration switches on.
  final int? schemaVersion;

  @override
  bool operator ==(Object other) =>
      other is LumeInstallationInfo &&
      other.state == state &&
      other.schemaVersion == schemaVersion;

  @override
  int get hashCode => Object.hash(state, schemaVersion);

  @override
  String toString() => 'LumeInstallationInfo(${state.name}, v$schemaVersion)';
}

/// The durable profile contract. Implemented by Dayroz at integration.
///
/// Three obligations beyond the signatures:
///
/// 1. [readInstallation] answers from metadata the storage layer owns — an
///    install marker, a schema version, a migration table. It must never
///    answer by looking at whether a profile field happens to be set.
/// 2. [writeProfile] is **atomic**. The Islamic migration writes the decided
///    value and its marker in one record precisely so that a process killed
///    mid-write cannot leave the marker standing over an undecided value.
/// 3. [isDurable] tells the truth. A store that does not survive a restart
///    says so, and the startup gate refuses to treat it as a first-run
///    authority.
abstract interface class LumeProfileRepository {
  /// Which cohort this installation is, from explicit metadata.
  Future<LumeInstallationInfo> readInstallation();

  /// The stored record, or a default one on a fresh install.
  Future<LumeProfileRecord> readProfile();

  /// Persist the record and its schema stamp in a single atomic operation.
  Future<void> writeProfile(LumeProfileRecord record);

  /// Whether this implementation survives an application restart.
  ///
  /// `false` for every implementation in this repository. Nothing may report
  /// first-run behaviour as working while this is `false`.
  bool get isDurable;
}

/// A repository that holds the record for the life of the process.
///
/// Honest about what it is: [isDurable] is `false`, and a process that starts
/// with an empty store genuinely *is* a fresh installation, so that is what it
/// reports rather than pretending to remember one.
///
/// It exists so the flow and the tests have something to run against, and so
/// the shape of the contract is exercised. It is not persistence, and the
/// first-run gate stays unbuilt until a durable implementation arrives.
class LumeMemoryProfileRepository implements LumeProfileRepository {
  LumeMemoryProfileRepository({
    LumeProfileRecord? initial,
    LumeInstallationInfo? installation,
  }) : _record = initial ?? const LumeProfileRecord(),
       _installation =
           installation ??
           (initial == null
               ? const LumeInstallationInfo.fresh()
               : const LumeInstallationInfo.existing());

  LumeProfileRecord _record;
  final LumeInstallationInfo _installation;

  /// How many times the record has been written. The migration's idempotence
  /// is a claim about this number, so it is observable.
  int writes = 0;

  @override
  bool get isDurable => false;

  @override
  Future<LumeInstallationInfo> readInstallation() async => _installation;

  @override
  Future<LumeProfileRecord> readProfile() async => _record;

  @override
  Future<void> writeProfile(LumeProfileRecord record) async {
    writes++;
    _record = record;
  }
}

/// The flow's synchronous handle on a record the bootstrap has already loaded.
///
/// Reads are free — the record is in hand. Writes go straight back out through
/// [onWrite], so the flow's commit points reach the durable store without the
/// flow ever holding a repository or awaiting anything.
class LumeRepositoryOnboardingStore implements LumeOnboardingStore {
  LumeRepositoryOnboardingStore({
    required LumeProfileRecord initial,
    required this.onWrite,
  }) : _record = initial;

  LumeProfileRecord _record;

  /// Called with every committed record, in order.
  final void Function(LumeProfileRecord record) onWrite;

  @override
  LumeProfileRecord read() => _record;

  @override
  void write(LumeProfileRecord record) {
    _record = record;
    onWrite(record);
  }
}
