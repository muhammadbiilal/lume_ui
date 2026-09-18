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
| **Device's own zone** | Not needed for World Clock (cities are chosen); if a feature needs the device's IANA id, that is a platform read (`flutter_timezone` or a channel) and a separate decision |

**Decision requested:** add `timezone: 0.11.1` behind `LumeZoneDatabase`,
with `latest_10y` for World Clock, and record the measured APK size change.
