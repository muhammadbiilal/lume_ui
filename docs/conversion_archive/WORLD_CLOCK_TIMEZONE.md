# The IANA time-zone foundation

**Added and approved** (the IANA foundation commit). World Clock itself is
**not** built: it waits on its own source-derived proposal. This file records
the dependency, the service every tool reads zones through, and the policy
for updating the database.

Dart's `DateTime` knows UTC and the device's own zone only. The conversion's
six-zone rule table (`lib/core/time/lume_time_zone.dart`) stays as fixture
infrastructure for the market sessions it was written for; every reader-zone
calculation now goes through the IANA database. Fixed UTC offsets are never a
substitute: they are wrong across daylight saving and across rule changes.

## The dependency

| question | answer |
|---|---|
| **Package, version** | `timezone` **0.11.1**, pinned exactly in `pubspec.yaml` (`timezone: 0.11.1` — no caret) |
| **Data variant** | **`latest_all`**, imported as `package:timezone/data/latest_all.dart` |
| **Bundled IANA database** | **2025c** (the generated data header; `lib/core/time/lume_zone_aliases.dart` carries the same version and a test holds it) |
| **Licence** | BSD-2-Clause (`Copyright (c) 2014, timezone project authors`) |
| **Source** | `dart-lang/labs`, `pkgs/timezone`, published on pub.dev |
| **Size** | Approved as approximately 443 KB. Measured in the package: `latest_all.tzf` is 445 672 bytes (435 KiB); the default `latest.tzf` is 253 760 bytes. **Measured APK impact:** the release APK is 77 410 165 bytes with the database against 75 853 621 without it (the wave 2 commit), **+1 556 544 bytes** (72.3 → 73.8 MB) — the `latest_all` data compiled into the Dart snapshot of each of the APK's three architectures, and the alias tables |
| **Why `latest_all`** | It is the complete bundled database. The default variant is smaller but omits IANA's deprecated and historical identifiers (the backward links): a record holding `Europe/Kiev`, `Asia/Calcutta` or `US/Eastern` would stop resolving. Migration compatibility is worth more here than the size saving |
| **Its own dependencies** | `http` and `path`, already resolved; `http` is used only by the package's URL loaders, which Lume never imports |
| **Maintenance** | Maintained by the Dart team in `dart-lang/labs`, releases following IANA (0.10.1 → 2025b, 0.10.2 → 2025c, 0.11.0 into the labs monorepo, 0.11.1 `Etc/UTC` as the default) |
| **SDK** | `sdk: ^3.10.0`; Lume builds with Dart 3.12.2 (Flutter 3.44.8). Pure Dart — the same on Android, iOS and the web |
| **Offline** | Entirely: the database is compiled in; nothing is fetched at run time |

## The service

`LumeTimeZoneService` (`lib/core/time/lume_iana_zones.dart`) is the one place
`package:timezone` is used.

- **Loaded once.** `LumeTimeZoneService.shared` calls `initializeTimeZones()`
  on first use; `main()` touches it before `runApp`, so the application
  boundary pays for it and no screen does. Providers
  (`lib/app/providers/time_zone_provider.dart`) hand the service and the
  device zone to screens; tests may override either.
- **No global state from screens.** Widgets and view models never import the
  package. Nothing calls `setLocalLocation`; the package's own `local` stays
  UTC, and every calculation names its zone.
- **Injected clock.** Instants come from `LumeClockScope`; the service reads
  no clock and guesses no zone.
- **Identities.** A zone is its IANA identifier. Refused as identities, and
  reported `malformed`: abbreviations (`PKT`, `EST`, `CST` — two to five
  capitals; `UTC`, `UCT` and `GMT` excepted), fixed offsets (`+05:00`,
  `UTC+5`, and IANA's own `Etc/GMT+5` family), empty or badly shaped strings.
- **The same instant.** Reading an instant through a second zone changes the
  wall-clock fields and never the moment (`LumeZoneClock` carries the local
  time and the offset; the instant is recoverable from either).

### Typed outcomes

Every resolution (`LumeZoneResolution`) carries its outcome, its source, the
identifier exactly as asked (`requested`) and the canonical one
(`canonicalId`) — in the value, not only in logs.

| outcome | when |
|---|---|
| `canonical` | a canonical IANA identifier |
| `alias` | a backward link — calculations use the canonical zone it names |
| `device` | nothing configured and no region zone: the verified device zone |
| `missingDevice` | nothing configured, no region zone, no verified device zone |
| `unknown` | an explicit identifier the database does not hold |
| `malformed` | an explicit value that is not an identifier (see above) |
| `databaseUnavailable` | the database is not loaded |
| `conversionFailed` | a zone resolved, but reading an instant through it failed |

| source | meaning |
|---|---|
| `configured` | the reader's own zone (`profile.timeZone`) |
| `migratedAlias` | the reader's stored zone is a renamed identifier |
| `fixture` | the country table's zone, under Account › Time's "Follow region" — reference data (decision recorded below) |
| `device` | the device's zone, as a platform adapter verified it |
| `unavailable` | nothing could be used |

### The reader's zone

`reader()` takes, in order: the explicit zone; else, under "Follow region",
the country table's zone; else a verified device zone. **An explicit zone
that is unknown or malformed is reported as it is and never replaced** by the
region's or the device's — a task grouped on another zone's day would be
wrong while claiming to be right. The identifier is kept for diagnosis and
is never overwritten.

Device-zone detection is a platform concern: this build has no adapter, so
`deviceZoneProvider` is `LumeDeviceZone.unknown()` until Dayroz supplies one.

**Decision recorded:** the brief says a zone is not to be inferred from the
country. Account › Time (accepted in F5C) offers "Follow region" as the
default, which takes the country table's zone. It is kept, as the `fixture`
source, rather than removing an accepted setting in this step; approval is
requested to keep it, to relabel it, or to replace it with the device zone.

### Aliases and migration

The alias and canonical tables are Lume's own, generated from the pinned data
(`scripts/generate_zone_aliases.dart`, output
`lib/core/time/lume_zone_aliases.dart`: **341 canonical identifiers, 257
aliases, 598 in all**). In the compiled database a link is a copy of its
target's rules, so the identifiers sharing one set of rules are a zone and its
links; the member the package lists as canonical is the zone. A test holds
the tables to the data exactly: every identifier is one or the other, every
alias names a canonical zone.

- **Resolution** uses the canonical zone's rules; **labels** show the
  canonical identifier (`Europe/Kyiv`), bidi-isolated.
- **A read never rewrites** a stored identifier.
- **Migration is a deliberate operation**: `plan(stored)` returns a
  `LumeZoneMigration` (from, to, whether it changes); the caller writes.
  An alias plans to its canonical zone, a canonical identifier to itself
  (idempotent), an unreadable one to nothing. The represented instant is
  unchanged: an alias and its canonical zone read every instant identically
  (tested across DST changes and a 1990 date).
- **New selections** store canonical identifiers (`ids` lists only those).

## Updating the database

A tzdb update is a deliberate change, never an incidental dependency
refresh. It requires, in one reviewed change:

1. An explicit version bump of `timezone` in `pubspec.yaml`, with the new
   package version and IANA release named in the commit.
2. Review of the package changelog and of IANA's announcement for every
   release in between.
3. Regenerating `lume_zone_aliases.dart` and reviewing its diff: renamed,
   added and removed identifiers.
4. Updating the version guard (`kLumeTzdbVersion`) and the tests that pin it.
5. Renamed-zone and alias-resolution tests; DST-boundary tests; historical
   dates.
6. Regressions: To-dos' rolling window (`todos_zone_test.dart`), Events
   (`zone_consumers_test.dart`), Sun & Moon's local date, Weather and
   Calendar where they read a zone, and World Clock once it exists.
7. Golden review wherever a visible label or time changes.
8. A migration review for any removed or renamed identifier: records holding
   it must still resolve, or a migration must be planned for them.
9. A release-note entry.
