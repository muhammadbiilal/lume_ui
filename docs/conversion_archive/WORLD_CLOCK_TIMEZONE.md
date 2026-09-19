# World Clock — the time-zone dependency, documented before it is added

**F6B closure. Nothing is added yet.** World Clock needs the wall-clock time
of cities in zones other than the device's. Dart's `DateTime` knows UTC and
the device's own zone only, and this build's `LumeTimeZone`
(`lib/core/time/lume_time_zone.dart`) is a six-zone reference table that says
it is not a time-zone authority. Fixed UTC offsets are not a substitute: they
are wrong across daylight saving and across any rule change. This is the
dependency that would replace them, with the facts read from the package
itself (fetched into the pub cache for inspection; `pubspec.yaml` unchanged).

| question | answer |
|---|---|
| **Package, version** | `timezone` **0.11.1**, pinned exactly (`timezone: 0.11.1`), as every F6B platform package is |
| **Source** | `dart-lang/labs`, `pkgs/timezone` — the Dart team's labs monorepo; published on pub.dev |
| **Licence** | BSD 2-clause (`Copyright (c) 2014, timezone project authors`; two redistribution clauses, no endorsement clause), compatible with the project's other BSD/MIT dependencies |
| **tzdb version bundled** | **2025c** (the generated `lib/data/latest.dart` header says `Timezone data version: 2025c`; CHANGELOG: "the databases to 2025c") |
| **Its own dependencies** | `http` and `path`. `http` is used only by `browser.dart`/`standalone.dart` for loading a database from a URL; a mobile build that imports `data/latest_10y.dart` or `data/latest.dart` never calls it, but the package is still resolved — recorded, not hidden |
| **Data sets and size** | `latest_10y` (current and ±5 years of rules): 290 508 B of Dart source / 66 072 B `.tzf`; `latest` (canonical zones, full history): 1 114 252 B / 253 760 B; `latest_all` (with backward links): 1 956 531 B / 445 672 B. The Dart-source form is compiled into the binary; the `.tzf` form can ship as an asset instead. **Measured impact on the APK is to be recorded when it is added**, by building before and after — the source sizes above are an upper bound, not the answer |
| **Offline** | Fully offline: the database is compiled in (or an asset); nothing is fetched at run time |
| **DST and history** | Full IANA rules: daylight-saving transitions, historical offsets and the zones' own abbreviations, for every instant the chosen data set covers. `latest_10y` is enough for a clock that shows "now"; conversion of old dates needs `latest` |
| **Update process** | A new tzdb reaches Lume only as a new `timezone` release (the package's `tool/refresh.sh` fetches `tzdata-latest` from IANA and regenerates), taken as a deliberate version bump with its own test run. Between releases a rule change in a jurisdiction is wrong in Lume until then — the same gap every app with an embedded database has; Dayroz may instead ship the `.tzf` as an updatable asset |
| **Injectable clock** | The instant stays Lume's: `LumeClockScope` supplies `now`, and `TZDateTime.from(now, location)` turns it into a wall clock. The package's own `now()` is never called by widgets. It sits behind the existing `LumeZoneDatabase` boundary (`lume_zone.dart`), so World Clock and the market session never name the package |
| **Deterministic tests** | Tests fix the instant and assert known transitions (e.g. New York 2026-03-08 02:00 → 03:00, London 2026-03-29 01:00 → 02:00, Karachi and Tokyo with none). A guard test asserts the bundled data version string equals the pinned **2025c**, so a package update that changes rules fails loudly and is taken on purpose, with the expectations reviewed |
| **Maintenance status** | Maintained by the Dart team in `dart-lang/labs` — the repository for packages it maintains below the support level of `dart-lang/core` — with releases following IANA: 0.10.1 took 2025b, 0.10.2 took 2025c, 0.11.0 moved it into the labs monorepo, 0.11.1 made `Etc/UTC` the default. No release date is recorded here: it was read offline from the pub cache |
| **Flutter and Dart versions** | `environment: sdk: ^3.10.0`; Lume builds with Dart 3.12.2 (Flutter 3.44.8). Pure Dart — no platform code, so the same on Android, iOS and the web |
| **Initialisation** | Synchronous: `initializeTimeZones()` from `package:timezone/data/latest_all.dart` (or `latest_10y.dart`) once at start-up, before the zone database is first read; or `initializeDatabase(bytes)` with a `.tzf` asset loaded at start. Either happens inside the `LumeZoneDatabase` adapter, never in a widget |
| **A zone renamed or removed** | `getLocation(id)` throws `LocationNotFoundException` for an id the data set does not hold. Only `latest_all` carries IANA's backward links — `Asia/Calcutta`, `Europe/Kiev`, `US/Eastern` resolve there and not in `latest_10y` or `latest` (checked in the `.tzf` files). A clock a reader saved before a rename (Kiev became Kyiv in 2022) keeps working with `latest_all`; with the others it disappears. The adapter catches the exception and returns `null`, and World Clock says "no clock for" that id, as Sun & Moon does today — never the device's zone in its place. Stored ids are written canonical |
| **Localisation limits** | The package holds rules, not names: no localised city or zone names, and tzdb abbreviations ("PKT", "BST") are English and ambiguous. City names come from Lume's own city data and the zone's display from CLDR through `intl` (or Lume's ARBs); offsets are formatted by `LumeFormatting` in the reader's numerals and direction |
| **Device's own zone** | Not needed for World Clock (cities are chosen); if a feature needs the device's IANA id, that is a platform read (`flutter_timezone` or a channel) and a separate decision |

**Decision requested:** add `timezone: 0.11.1` behind `LumeZoneDatabase`,
with **`latest_all`** (backward links, so a renamed zone a reader saved still
resolves; 445 672 B as `.tzf`) rather than `latest_10y`, and record the
measured APK size change when it is added. Nothing is implemented until this
is approved, and no fixed offset stands in meanwhile.
