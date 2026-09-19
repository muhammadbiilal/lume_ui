/// The IANA time-zone database, behind one typed, injectable service.
///
/// `package:timezone` 0.11.1 with its **`latest_all`** data (tzdb 2025c):
/// every zone and every backward link, so a record holding an identifier
/// that has since been renamed (`Europe/Kiev`) still resolves, while new
/// selections store the canonical one (`Europe/Kyiv`). The aliases and the
/// canonical set are Lume's own generated tables (`lume_zone_aliases.dart`),
/// reviewed at each deliberate database update.
///
/// **Boundary.** The database is loaded once, by this service
/// ([LumeTimeZoneService.shared]); widgets and view models never touch
/// `package:timezone` or its global state, and nothing here calls
/// `setLocalLocation` — every calculation names the zone it uses. Instants
/// come from the injected clock (`LumeClockScope`); this file never reads
/// the device's clock or guesses its zone.
///
/// **Identity.** A zone is its IANA identifier. Abbreviations ("PKT", "EST")
/// and fixed offsets ("+05:00") are refused as identities: the first are
/// ambiguous and the second are wrong across daylight saving.
library;

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'lume_zone.dart';
import 'lume_zone_aliases.dart';

/// Where a zone came from — carried with every resolution, never only
/// logged.
enum LumeZoneSource {
  /// The reader chose it (`profile.timeZone`).
  configured,

  /// The reader's stored choice is a renamed identifier, resolved through
  /// its alias.
  migratedAlias,

  /// The country table's zone, under the reader's "Follow region" setting
  /// (Account › Time) — reference data, not a measurement.
  fixture,

  /// The device's own zone, as a platform adapter verified it.
  device,

  /// No zone could be used.
  unavailable,
}

/// What resolving a zone came to.
enum LumeZoneOutcome {
  /// A canonical IANA identifier.
  canonical,

  /// A backward link; calculations use the zone it names.
  alias,

  /// Nothing configured, so the verified device zone.
  device,

  /// Nothing configured, and no verified device zone.
  missingDevice,

  /// An explicit identifier the database does not hold.
  unknown,

  /// An explicit value that is not an IANA identifier at all ("PKT",
  /// "+05:00", "").
  malformed,

  /// The database is not loaded.
  databaseUnavailable,

  /// The zone resolved but a conversion through it failed.
  conversionFailed,
}

/// A device zone as a platform adapter reports it. Detecting it is the
/// platform's concern; this build has no adapter, so it is [unknown].
@immutable
class LumeDeviceZone {
  const LumeDeviceZone(this.id) : verified = true;
  const LumeDeviceZone.unknown() : id = null, verified = false;

  final String? id;
  final bool verified;
}

/// One resolution: what was asked, where it came from, what it came to.
@immutable
class LumeZoneResolution {
  const LumeZoneResolution._({
    required this.outcome,
    required this.source,
    this.requested,
    this.canonicalId,
    this.zone,
  });

  /// A zone a fixture or a test supplies directly — said as [source]
  /// `fixture`, never passed off as the reader's configured zone.
  const LumeZoneResolution.fixed(LumeZone this.zone)
    : outcome = LumeZoneOutcome.canonical,
      source = LumeZoneSource.fixture,
      requested = null,
      canonicalId = null;

  final LumeZoneOutcome outcome;
  final LumeZoneSource source;

  /// The identifier exactly as it was stored or configured — kept for
  /// diagnosis and migration, never rewritten by a read.
  final String? requested;

  /// The canonical identifier the calculation uses; what a label shows.
  final String? canonicalId;

  /// The zone to calculate in, or `null` when there is none.
  final LumeZone? zone;

  bool get resolved => zone != null;

  /// A resolved identifier that is not the canonical one.
  bool get isAlias => outcome == LumeZoneOutcome.alias;

  @override
  String toString() =>
      'LumeZoneResolution(${outcome.name}, ${source.name}, '
      '$requested → $canonicalId)';
}

/// A deliberate rewrite of one stored identifier: from what, to what, and
/// whether anything changes. Planning it never writes; the caller does.
@immutable
class LumeZoneMigration {
  const LumeZoneMigration(this.from, this.to);

  final String from;

  /// The canonical identifier, or `null` when [from] cannot be migrated
  /// (unknown or malformed) and must be left as it is.
  final String? to;

  bool get changes => to != null && to != from;
}

/// A wall clock read through a zone, or why it could not be.
@immutable
class LumeZoneClock {
  const LumeZoneClock._(this.local, this.offset, this.failure);

  /// The zone's wall clock — a naive value; its fields are the zone's.
  final DateTime? local;
  final Duration? offset;
  final LumeZoneOutcome? failure;

  bool get ok => failure == null;
}

/// The one IANA zone database.
class LumeTimeZoneService implements LumeZoneDatabase {
  LumeTimeZoneService._(this._available);

  /// A service with no database — for the unavailable path, and tests of it.
  LumeTimeZoneService.detached() : _available = false;

  static LumeTimeZoneService? _shared;

  /// The application's service. The database is loaded on the first call
  /// and never again (`initializeTimeZones` replaces the whole database, so
  /// loading it twice would be wasted work, not a second copy).
  static LumeTimeZoneService get shared => _shared ??= _load();

  static LumeTimeZoneService _load() {
    try {
      tz_data.initializeTimeZones();
      return LumeTimeZoneService._(tz.timeZoneDatabase.isInitialized);
    } on Object {
      return LumeTimeZoneService._(false);
    }
  }

  final bool _available;

  final Map<String, _IanaZone> _zones = <String, _IanaZone>{};

  /// The tzdb release in the bundled data.
  static const String databaseVersion = kLumeTzdbVersion;

  /// `Area/Location`, `Area/Sub/Location`, or a bare name such as `UTC` —
  /// letters first, then letters, digits, `_`, `-`, `+`. Offsets and empty
  /// strings are not identifiers.
  static final RegExp _shape = RegExp(
    r'^[A-Za-z][A-Za-z0-9_+\-]*(/[A-Za-z0-9_+\-]+)*$',
  );

  /// A bare run of two to five capitals — "PKT", "EST", "CET". Some are
  /// still legacy IANA names, but as a stored identity each is ambiguous or
  /// wrong across daylight saving, so none is accepted; `UTC`, `UCT` and
  /// `GMT` name one fixed zone and are.
  static final RegExp _abbreviation = RegExp(r'^[A-Z]{2,5}$');
  static const Set<String> _fixed = <String>{'UTC', 'UCT', 'GMT'};

  /// An offset dressed as a name — "UTC+5", "GMT-3", and IANA's own
  /// `Etc/GMT+5` family: a fixed offset, which is not a zone to store.
  static final RegExp _offset = RegExp(r'(^|/)(UTC|GMT|UT)?[+\-]\d');

  static bool isWellFormed(String id) =>
      id.length <= 64 &&
      _shape.hasMatch(id) &&
      !_offset.hasMatch(id) &&
      (_fixed.contains(id) || !_abbreviation.hasMatch(id));

  /// The canonical identifiers, for a picker.
  @override
  Iterable<String> get ids => kLumeCanonicalZones;

  /// [LumeZoneDatabase]: the zone for [id], canonical or alias, or `null`.
  @override
  LumeZone? zoneFor(String id) => resolveId(id).zone;

  /// Resolve a stored or configured identifier.
  LumeZoneResolution resolveId(
    String id, {
    LumeZoneSource source = LumeZoneSource.configured,
  }) {
    if (!isWellFormed(id)) {
      return LumeZoneResolution._(
        outcome: LumeZoneOutcome.malformed,
        source: LumeZoneSource.unavailable,
        requested: id,
      );
    }
    if (!_available) {
      return LumeZoneResolution._(
        outcome: LumeZoneOutcome.databaseUnavailable,
        source: LumeZoneSource.unavailable,
        requested: id,
      );
    }
    final String? target = kLumeCanonicalZones.contains(id)
        ? id
        : kLumeZoneAliases[id];
    final _IanaZone? zone = target == null ? null : _zone(target);
    if (zone == null) {
      return LumeZoneResolution._(
        outcome: LumeZoneOutcome.unknown,
        source: LumeZoneSource.unavailable,
        requested: id,
      );
    }
    final bool alias = target != id;
    return LumeZoneResolution._(
      outcome: alias ? LumeZoneOutcome.alias : LumeZoneOutcome.canonical,
      source: alias && source == LumeZoneSource.configured
          ? LumeZoneSource.migratedAlias
          : source,
      requested: id,
      canonicalId: target,
      zone: zone,
    );
  }

  /// The reader's zone: their explicit choice; else, under "Follow region",
  /// the country table's zone; else a verified device zone. An explicit
  /// choice that cannot be read is reported as it is — never replaced by
  /// another zone.
  LumeZoneResolution reader({
    String? configured,
    String? regionZone,
    LumeDeviceZone device = const LumeDeviceZone.unknown(),
  }) {
    if (configured != null) return resolveId(configured);
    if (regionZone != null && regionZone.isNotEmpty) {
      return resolveId(regionZone, source: LumeZoneSource.fixture);
    }
    if (device.verified && device.id != null) {
      final LumeZoneResolution r = resolveId(
        device.id!,
        source: LumeZoneSource.device,
      );
      if (!r.resolved) return r;
      return LumeZoneResolution._(
        outcome: LumeZoneOutcome.device,
        source: LumeZoneSource.device,
        requested: device.id,
        canonicalId: r.canonicalId,
        zone: r.zone,
      );
    }
    return const LumeZoneResolution._(
      outcome: LumeZoneOutcome.missingDevice,
      source: LumeZoneSource.unavailable,
    );
  }

  /// [instant] on [r]'s wall clock. The instant is kept: reading it in a
  /// second zone changes the fields, never the moment.
  LumeZoneClock clock(DateTime instant, LumeZoneResolution r) {
    final LumeZone? z = r.zone;
    if (z == null) return LumeZoneClock._(null, null, r.outcome);
    try {
      return LumeZoneClock._(z.wallClockAt(instant), z.offsetAt(instant), null);
    } on Object {
      return const LumeZoneClock._(
        null,
        null,
        LumeZoneOutcome.conversionFailed,
      );
    }
  }

  /// The migration of one stored identifier: an alias to its canonical
  /// zone; a canonical one to itself; anything unreadable to nothing.
  LumeZoneMigration plan(String stored) {
    final LumeZoneResolution r = resolveId(stored);
    return LumeZoneMigration(stored, r.canonicalId);
  }

  _IanaZone? _zone(String id) {
    final _IanaZone? cached = _zones[id];
    if (cached != null) return cached;
    try {
      return _zones[id] = _IanaZone(id, tz.getLocation(id));
    } on tz.LocationNotFoundException {
      return null;
    }
  }
}

/// A [LumeZone] over an IANA location.
class _IanaZone implements LumeZone {
  _IanaZone(this.id, this._location);

  @override
  final String id;

  final tz.Location _location;

  @override
  Duration offsetAt(DateTime instant) =>
      _location.timeZone(instant.millisecondsSinceEpoch).offset;

  @override
  DateTime wallClockAt(DateTime instant) {
    final tz.TZDateTime t = tz.TZDateTime.from(instant, _location);
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }
}
