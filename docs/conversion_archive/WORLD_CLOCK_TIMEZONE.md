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
| `device` | "Follow this device", and the verified device zone |
| `missingDevice` | "Follow this device", and no verified device zone |
| `selectionRequired` | "Follow my region", where the country lists several canonical zones and the city does not decide between them |
| `unknown` | an explicit identifier the database does not hold |
| `malformed` | an explicit value that is not an identifier (see above) |
| `databaseUnavailable` | the database is not loaded |
| `conversionFailed` | a zone resolved, but reading an instant through it failed |

| source | meaning |
|---|---|
| `explicit` | the zone the reader named (`profile.timeZone`) |
| `migratedAlias` | the reader's named zone is a renamed identifier |
| `cityPolicy` | "Follow my region", decided by the reader's city (`kLumeCityZones`) |
| `regionPolicy` | "Follow my region", decided by the country's one canonical zone (`kLumeCountryZone`) |
| `device` | "Follow this device": the device's zone, as a platform adapter verified it |
| `fixture` | a deterministic reference or test fixture supplied the zone (`LumeZoneResolution.fixed`) — never a reader's preference |
| `unavailable` | nothing could be used |

### The reader's zone

Account › Time holds one preference: a zone the reader names
(`profile.timeZone`), or, with none named, **Follow my region** or **Follow
this device** (`profile.zoneFollow`). `reader()` resolves it in this order:

1. **The named zone.** An unknown or malformed one is reported as it is and
   never replaced by the region's or the device's — a task grouped on
   another zone's day would be wrong while claiming to be right. The
   identifier is kept for diagnosis and is never overwritten.
2. **Follow my region.** The city's zone, where the city is in the
   profile, belongs to the country and the table maps it (`cityPolicy`);
   else the country's zone, only where every zone CLDR lists for it is one
   canonical identity — the identifier or links to it (`regionPolicy`);
   else **`selectionRequired`**. The 27 countries listing several canonical
   zones are never given one of them — not even where their clocks agree
   today: Berlin and Büsingen (`Europe/Zurich`), or Kazakhstan's seven zones
   since 2024, stay distinct identities, because matching offsets over any
   window of years prove nothing about the next rule change. The device is
   not read.
3. **Follow this device.** The verified device zone (`device`); else
   `missingDevice`. The region is not read.
4. Otherwise a typed unavailable result.

Nothing else is an input: interface language, religion, interests,
currency, units, phone number and network location cannot change the
answer, and tests hold that.

**The default.** A profile that has never set a zone follows its region —
the reference's default, which Account › Time shows selected, and the only
one this build can honour: device-zone detection is a platform concern with
no adapter yet, so `deviceZoneProvider` is `LumeDeviceZone.unknown()` until
Dayroz supplies one, and "Follow this device" says the device's zone is not
available.

**Where the region's zones come from.**

| table | source | held by |
|---|---|---|
| `kLumeCountryZones` — every canonical zone of each country | CLDR 47 (ICU 77.1), `Intl.Locale.getTimeZones`, captured by `scripts/cldr_country_zones.mjs` into `scripts/data/cldr_country_zones.json`, canonicalised against tzdb 2025c | the generator |
| `kLumeCountryZoneIds` — each country's identifiers exactly as CLDR lists them, links included (`Asia/Kuwait`) | the same capture | used only to name a zone, never as its identity |
| `kLumeCountryZone` — the zone of the 167 of 194 countries whose list is one canonical zone | a country's list, canonicalised; exactly one member, or no entry | the generator; `lume_follow_region_test.dart` |
| `kLumeCityZones` — the zone of each listed city in the 27 countries with several (AR AU BR CA CD CL CN CY DE EC ES FM ID KI KZ MH MN MX MY NZ PG PS PT RU UA US UZ) | reviewed by hand against IANA's `zone.tab` descriptions | a test: every city of every several-zone country has an entry, every entry is one of its own country's zones, and no single-zone country has one |

Countries with several canonical zones include some a reader might not
expect: Spain (the Canaries), Portugal (the Azores and Madeira), China
(Xinjiang's `Asia/Urumqi`), Ecuador (Galápagos), New Zealand (Chatham),
Germany (Büsingen), Malaysia (Sarawak), Cyprus, Palestine, Uzbekistan,
Kazakhstan, Argentina and Ukraine (`Europe/Simferopol`, which CLDR lists for
Crimea). Their listed cities have zones, so a reader who picked one is
unaffected; a reader with no city is asked to choose. No city infers the
Crimea zone, and nothing infers a zone — or a reader's territorial identity —
from currency, language, religion, phone number or network location.

A city decides only when it is in the profile and keyed by the profile's own
country (`US:New York`): "New York" under Pakistan is not New York's zone,
and a city the table does not know asks rather than borrows a neighbour's.

### How a zone is shown

Identity and presentation are separate layers (`lume_zone_labels.dart`).
Selecting, storing and comparing use the canonical identifier; what a reader
sees is **CLDR's localized location label** — the country's name for a zone
that is its country's only or primary one ("Pakistan", "باكستان"), else the
zone's exemplar city ("New York", "نیو یارک") — shown in CLDR's generic
location pattern, "Pakistan Time" / "پاکستان وقت" / "توقيت باكستان", so a
zone beside the reader's country never reads as a second "Pakistan". The
names and the patterns are CLDR 47's own text, captured from ICU's generic
location format by `scripts/cldr_country_zones.mjs` for English, Urdu and
Arabic (`lume_zone_labels_data.dart`, 1,655 names, three patterns); none is
translated by hand.

- **The reader's country names the zone.** `LumeZoneLabels.of(id, country:,
  language:)` looks first for the identifier CLDR lists for the reader's
  country under that zone: a Kuwait reader's zone is `Asia/Riyadh` and reads
  "Kuwait Time" / "توقيت الكويت" / "کویت وقت"; the Central African
  Republic's is `Africa/Lagos` and reads "Central African Republic Time",
  not Nigeria's. A
  country listing one zone under several identifiers with different labels
  gets no label rather than one of them.
- **Then** a link the reader stored for the zone, then the zone's own label.
- **No label, no invention.** The UTC and `Etc/*` family, and a handful of
  zero-offset zones in English, have no CLDR location label; the canonical
  identifier shows, as before.
- **A label is never a second identity.** Changing language changes the
  label and nothing else; tests hold that the identity is the same in every
  language.
- **Screen readers** hear the label and the identifier it stands for
  (`LumeZoneLabel.semantics`: "Kuwait Time, Asia/Riyadh"). Account › Time
  reads each row's title and identifier; Calendar's zone item and Events'
  Timezone fact are announced the same way ("Timezone, New York Time,
  America/New_York").
- **Search** (`LumeZoneLabels.matches`) finds a zone by its label or its
  canonical identifier, ignoring case, isolation marks and `_`. No screen
  searches zones yet; World Clock will use this.
- **Diagnostics keep the identifier.** `LumeZoneResolution.requested` and
  `canonicalId` are identifiers, and a zone that could not be read is
  named by what was asked for (To-dos' and Events' "Your day can't be
  worked out", Sun & Moon's "No clock for …"). An unreadable identifier
  has no label to show.
- **A label never hides ambiguity.** A country with several canonical zones
  still asks for a city or a choice; a label is only drawn for a zone that
  resolved. Two zones never merge because their labels read alike: rows
  are keyed by identifier, and each announces its own
  (`lume_zone_label_policy_test.dart`).
- **Where it shows.** Every screen that names a zone goes through this
  layer:
  - Account › Time lists each zone by its label with the identifier
    beneath, and Follow my region, Follow this device and a named zone
    show their labels.
  - Calendar's zone item and Events' Timezone fact show the label,
    bidi-isolated.
  - Sun & Moon's no-zone title shows what was asked for.
  - Weather names no zone.
  - To-dos explains an unresolved zone without naming a resolved one.

  World Clock, when built, uses the same layer. Migration is untouched: a
  label never changes what is stored. The visible difference from the
  reference's raw identifiers is C89.

### Aliases and migration

The alias and canonical tables are Lume's own, generated from the pinned data
(`scripts/generate_zone_aliases.dart`, output
`lib/core/time/lume_zone_aliases.dart`: **341 canonical identifiers, 257
aliases, 598 in all**). In the compiled database a link is a copy of its
target's rules, so the identifiers sharing one set of rules are a zone and its
links; the member the package lists as canonical is the zone. A test holds
the tables to the data exactly: every identifier is one or the other, every
alias names a canonical zone.

- **Resolution** uses the canonical zone's rules; **labels** show CLDR's
  name for it ("Ukraine Time" for `Europe/Kiev` or `Europe/Kyiv`),
  bidi-isolated, or the canonical identifier where CLDR has none.
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
3. Regenerating `lume_zone_aliases.dart` and `lume_country_zones.dart`
   (`dart run scripts/generate_zone_aliases.dart`, then `dart format`) and
   reviewing the diff: renamed, added and removed identifiers, and any
   country that gains or loses a canonical zone. A CLDR update is the same
   deliberate step: `node scripts/cldr_country_zones.mjs` records the ICU and
   CLDR versions it read, and its labels; the generator then writes
   `lume_zone_labels_data.dart`. Then `kLumeCityZones` is checked against
   the new zones (its test fails on any city left without one).
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
