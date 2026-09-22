# World Clock — proposal, adopted

Written from the source, then adopted under the accelerated-wave
directive: nothing here touches safety, privacy, a new dependency, a
destructive migration, a religious ruling or a materially ambiguous
calculation, so the recommended decisions stand as decisions.

The one item with blast radius beyond this tool is scoped deliberately
and named in D-W9.

## 0. Sources inspected

| file | what it holds |
|---|---|
| `assets/js/tools/daily/worldclock.tool.js` (42 lines) | the whole screen: `build(c)`, four sections |
| `assets/js/tools/context.js` `worldClock()` (l. 1300–1329) | the arithmetic |
| `assets/js/tools/context.js` `clockNow()` (l. 219–222) | the headline figure |
| `assets/js/data/tool-data.js` `WORLD_CITIES` (l. 932–943) | **eight hard-coded rows** |
| `assets/js/services/locale.js` (l. 70–190) | locale, clock preference, zone, date |
| `docs/conversion_archive/WORLD_CLOCK_TIMEZONE.md` | the **already-approved** zone architecture |
| `lib/core/time/` | `lume_iana_zones.dart`, `lume_zone.dart`, `lume_zone_labels.dart` (+ data), `lume_zone_aliases.dart`, `lume_city_zones.dart`, `lume_country_zones.dart` |
| `lib/features/sunmoon/presentation/sunmoon_tool.dart` | the shape a per-place calculation takes in Lume |

**No measured cell exists.** The 42-line module is the reference, and
capture is part of the work (§8).

## 1. What the reference presents

Four sections: a summary card showing a time, a search field, a list of
eight cities with their times and offsets, and a card headed "Convert a
time" holding two `<select>`s.

## 2. What it computes

From one instant, `new Date()`:

```js
time   = Intl.DateTimeFormat(locale, {timeZone, hour, minute, hour12, weekday})
           .formatToParts(now)                       // reassembled as h + ':' + m
local  = new Date(now.toLocaleString('en-US', {timeZone: readersZone}))
there  = new Date(now.toLocaleString('en-US', {timeZone: cityZone}))
offset = Math.round((there - local) / 3600000)
label  = offset === 0 ? 'Same time' : (offset > 0 ? '+' : '') + offset + 'h'
```

The headline is `L.time(new Date().getHours(), new Date().getMinutes())`
— the **device's** clock, with no zone applied.

## 3. Defects

Twenty-six, of which these change what a reader is told:

| # | defect | evidence |
|---|---|---|
| 1 | The headline clock is the **device's** time, captioned with the **reader's configured zone**. A reader whose profile says `Asia/Karachi` on a phone set to `Europe/London` sees London's time labelled Karachi | `worldclock.tool.js:23-24`; `context.js:219-222` |
| 2 | The headline date is the device's date — `L.date()` passes no `timeZone`. Near midnight it names a day the reader's zone is not on | `locale.js:171-176` |
| 3 | The zone prints as a raw identifier, `Asia/Karachi`, though 1,655 CLDR names in en/ur/ar sit in the repo | `lume_zone_labels_data.dart` |
| 4 | The city list is **eight hard-coded rows, identical for every reader on earth**, with no way to add one | `tool-data.js:934-943` |
| 5 | The reader's own zone never appears as a row — the data comment claims it does; no code appends it | `tool-data.js:932-933` |
| 7 | Offsets are rounded to whole hours. **Every reader in India, Nepal, Iran, Afghanistan, Myanmar, central Australia or the Chatham Islands is told the wrong offset for all eight cities** | `context.js:1324` |
| 10 | A failed lookup leaves `offset = 0`, which the next line renders as **"Same time"**. Total failure is indistinguishable from a true zero | `context.js:1325, 1327` |
| 12 | No yesterday/tomorrow, ever. A bare weekday is printed on every row, same-day rows included | `context.js:1316, 1328` |
| 13 | **"Convert a time" is dead.** `wc_from` and `wc_to` appear nowhere else in the codebase — no input, no result, no handler | grep: 2 hits, both in this file |
| 14 | Its "From" default silently lies: unless the reader's country zone is one of the eight, the browser shows the first option — **Karachi** — as though it were theirs | `worldclock.tool.js:36-37` |
| 17 | Nothing ticks. `freshness: live` describes a screen stale the moment it is drawn | whole module |
| 18 | Every string is English-only; `ur` and `ar` fall back. In Urdu the whole screen is English but the weekday | `i18n/tools.js:279, 834-835` |
| 8, 20 | The offset label is hand-assembled ASCII (`'+' + n + 'h'`), and search is a naive ASCII substring — while `LumeZoneLabels.matches` already folds case, isolation marks and `_` | `context.js:1327`; `worldclock.tool.js:17-20` |

Full table of 26 in the audit; the rest are dead markup, unescaped
interpolation, an unstated `zones[0]` invariant, and a header comment
naming a feature the module does not contain.

## 4. Decisions — adopted

| # | decision | why it needs no approval |
|---|---|---|
| **D-W1** | **Its own presentation-only feature**, one file under `lib/features/worldclock/presentation/`, no repository, no records, pure statics for the logic | Sun & Moon is the same kind of tool — a per-place calculation with no records — and is exactly this shape |
| **D-W2** | **The list is global.** The reader's own zone first, then the reference's eight anchors; search reaches **all 341 canonical zones** by CLDR label and the 577 cities in `countries.json`, resolved through `kLumeCityZones ?? kLumeCountryZone` | `WORLD_CLOCK_TIMEZONE.md` names World Clock as `LumeZoneLabels`' first consumer. The master spec forbids hard-coding a small list |
| **D-W3** | **Added zones live in `LumeToolSession`, for the session only.** No new stored field, no migration | `LumeToolSession` is the settled home for tool state and is explicitly non-durable. Persisting them would be a stored-data decision, so it is not taken |
| **D-W4** | **It ticks, once a minute**, aligned to the minute boundary | `freshness: live`, membership of `onDeviceClocks`, and `RELEASE_HONESTY.md:72` already promise a running clock. The display is `h:mm`, so a minute is the unit |
| **D-W5** | **Offsets are exact to the minute**, from the reader's zone, in their digits, bidi-isolated. `+5:30` and `+5:45` are representable. "Same time" only when the difference is truly zero | Corrects defects 7, 8, 10. Exact calculation is settled convention |
| **D-W6** | **The day difference is said in words** — yesterday / today / tomorrow — in all three languages | Corrects defect 12 |
| **D-W7** | **"Convert a time" is built, not dropped.** It converts one instant between two zones from the same list | The reference declares it and ships a stub. Committee, Installments and Baby Budget each made a declared-but-stubbed capability real; that is the established treatment, not new scope |
| **D-W8** | **`worldclock` joins `LumeDataCapability.computed`**, so its source bar stops saying "Lume sample data" | Its figures come from a compiled-in IANA database and the device clock — nothing is seeded. Sun & Moon is the precedent, and the change makes an on-screen honesty claim more true, not less |
| **D-W9** | **`profile.clock` (12/24h) is threaded into this tool only.** The app-wide gap is documented, not fixed here | The preference is written by Account and reaches **no formatter anywhere in `lib/`**. Fixing that globally would change the rendered time on every screen and move existing goldens — blast radius beyond this wave. Ignoring it in the one tool whose subject is clocks would be worse |
| **D-W10** | **Failure is typed and said**, never substituted: an unresolvable zone gets a `LumeToolState` naming what was asked for | `LumeTimeZoneService` already reports nine typed outcomes and never substitutes. Corrects defect 10 |

## 5. Figures — worked examples

Reader in Karachi (`Asia/Karachi`, +05:00), instant `kFixtureInstant`
= 2026-09-07 16:41:32.

| row | zone | offset from reader | shown |
|---|---|---|---|
| your own | Asia/Karachi | — | 16:41, today |
| Delhi | Asia/Kolkata | **+0:30** — the reference says `+1h` | 17:11, today |
| Kathmandu | Asia/Kathmandu | **+0:45** — the reference says `+1h` | 17:26, today |
| London | Europe/London | −4:00 (BST) | 12:41, today |
| New York | America/New_York | −9:00 (EDT) | 07:41, today |
| Sydney | Australia/Sydney | +5:00 (AEST) | 21:41, today |
| Auckland | Pacific/Auckland | +7:00 | 23:41, today |
| Honolulu | Pacific/Honolulu | −15:00 | **01:41, yesterday** |

The last row is the one the reference cannot draw at all: it has no
yesterday.

## 6. Invariants

1. No figure comes from `DateTime.now()`; the instant is
   `LumeClockScope.of(context).now()`.
2. No offset is rounded to an hour.
3. No zone is substituted for another. An unresolvable zone is said.
4. The headline is the reader's zone, not the device's.
5. Every string exists in en, ur and ar.
6. Times, offsets and day words are bidi-isolated.
7. Nothing is stored.

## 7. Localisation

New keys in `app_en.arb`, `app_ur.arb`, `app_ar.arb`. Zone names come
from `LumeZoneLabels` (CLDR, already in three languages); city names come
from `countries.json`'s `names:{en,ur,ar}`. No user-facing English
literal in Dart.

## 8. Evidence

Measurement cells captured for the reference in the standard matrix, a
parity test reading them value by value with every deliberate difference
named, golden cases for the composition and for each state, and domain
tests over the arithmetic with the clock injected.
