# Rollout wave 4 — what was read, what clears, and what is held

Written after wave 3 closed at **34 of 85** tools and the two C99
release-honesty corrections landed. Membership was decided by reading
every candidate's actual source — the web module, the data behind it,
the record schema if it has one, its translations, and the closest
converted Flutter tool — not from the catalogue's metadata.

## 0. The counts, recalculated

| | |
|---|---:|
| tools in `feature_catalogue.dart` | **85** |
| registered in `tool_registry.dart` | **34** |
| **unbuilt** | **51** |

Both directions check out: every registry id exists in the catalogue,
every catalogue id has exactly one `<id>.tool.js`, and no parity
artefact exists for any unbuilt tool.

## 1. The wave

**Three tools: `converter`, `birthdays`, `water`.**

Three, not five. The pool of genuinely unblocked tools is nearly
exhausted, and §5 shows the working for every one of the 51. Padding it
with a fourth would have meant shipping a screen whose substance is
invented, which is the thing this rollout exists to stop.

### 1.1 `converter` — Unit Converter

**Unblocked by an approved factor policy** (§3). Its hold was never
scheduling: it was that the reference's digital-storage factors are
binary under decimal names and its gallon is US under a bare `gal`, and
reversing either would have contradicted a `× 0.621` precedent already
shipped in three files. The policy settles both.

| | |
|---|---|
| reference | `assets/js/tools/everyday/converter.tool.js` (44 lines), `context.js:1096-1145` (`UNIT_CATS`, `converter()`) |
| data | 6 categories, **25 units** — not the "32 units" the catalogue badge claims |
| strings | 31 `uc.*` keys + 3 `convert.*`, **English only**; `ur` and `ar` fall back |
| styles | `assets/css/tools/shared.css:1015-1041` (`.convert*`), `components.css:435-467` (chips) |
| closest built Flutter tool | **Tip & Split** — `lib/features/tipsplit/` — a typed field plus a chip strip over a pure `domain/` value type, with `LumeHorizontalStrip.chips` already drawing a *correctly selected* chip |
| capability | `inputOnly` — every figure is the number the reader typed, converted exactly |
| freshness | `local`; source `On device` |

### 1.2 `birthdays` — Birthdays & Anniversaries

| | |
|---|---|
| reference | `assets/js/tools/personal/birthdays.tool.js` (35 lines), `context.js:1581-1589` |
| record schema | **already exists** — `assets/js/data/record-schemas.js:749-811`, with `nextOn`, `facts`, `empty` and three seeds |
| closest built Flutter tool | **Events** — `lib/features/events/` — the same date-keyed record family over the shared `LumeRecordTool<T>` host |
| capability | `readerRecords` + `sampleInParityOnly` — **changed after the owner's wave-4 directive**: the seeds go to the parity reproduction only, so a shipping build opens the collection empty (C100) |

The correction it carries: the reference's countdowns and ages are
**constants** — `days: 4/18/51/88`, `turning: 29/6/5/61`, `thisMonth: 2`
— while its own record schema computes both properly from a stored date.
Lume draws the schema's arithmetic. That is exactly the split Shopping
and Todos already corrected.

### 1.3 `water` — Water

| | |
|---|---|
| reference | `assets/js/tools/personal/water.tool.js` (36 lines), `context.js:1620-1644` |
| record schema | **already exists** — `record-schemas.js:600-645`: `ml`, `kind`, `at`, with four seeds matching the reference's timeline exactly |
| closest built Flutter tool | **Shopping** for the record side, **Focus Timer** for the honest-subtraction side |
| capability | `readerRecords` + `sampleInParityOnly`, for the same reason as Birthdays — an invented drinking history is not a demonstration of a list (C100) |

Wave 3 held this tool under rule 9 — "a fixture would invent the
reader's own data". That hold is retired the way Focus's was, and
better: the entries are *records*, so today's intake, the glass count,
the remainder and the timeline are all real once the reader logs
anything.

**Two deliberate subtractions**, each measured and named in the parity
test rather than absorbed anywhere:

- **the week chart** — `week: [1800, 2100, 1650, 2000, 1900, 2200, 1250]`
  is seven constants, and the store holds no week;
- **`streak: 6`** — a literal, with nothing behind it.

**One decision that touches a health-adjacent default, stated plainly
so it can be reversed in one line.** The reference sets
`var target = 2000;` for every reader on earth. Lume reproduces that
figure as *the tool's default target*, and nothing more: no advice text,
no personalisation by body, climate or condition, no categorisation of
the reader, and no claim that it is a medical recommendation. That is
the whole of the health surface, and it is one constant in one file. If
a fixed daily-intake target is judged to be health guidance rather than
a goal display, say so and this tool leaves the wave; the other two are
independent of it.

## 2. What each of the three has to correct

| tool | defect in the reference | evidence | what Lume does |
|---|---|---|---|
| converter | `GB` = 1024, `TB` = 1048576 under **decimal** SI names | `context.js:1116-1117` | decimal names get decimal factors; binary units are named `KiB`/`MiB`/`GiB`/`TiB` (§3) |
| converter | a bare `gal` at 3.78541 L — US, shown to every reader | `context.js:1108` | `gal (US)` and `gal (imp)`, separately named; no bare `gal` |
| converter | **no unit picker at all** — `from` is always `units[0]`, `to` is `units[1]` or `units[3]` | `context.js:1129-1130` | both units are chosen |
| converter | the imperial heuristic picks `oz` for mass, `cup` for volume, `marla` for area | `context.js:1130` | no index heuristic; a named default per category |
| converter | every imperial constant truncated to 6 s.f. (`1609.34`, `0.453592`, `1.60934`) | `context.js:1100-1113` | exact defined values |
| converter | — *(withdrawn)* the reference has no temperature category, and one is **not** added: °C to °F is affine, not a ratio, and adding a category the reference does not have is a product decision rather than a conversion | `context.js:1134` | recorded as deferred in §7 rather than taken quietly |
| converter | "Recent" is two literals, `10 km → mi = 6.21` and `1 kg → lb = 2.20` | `context.js:1140-1143` | dropped; nothing records a conversion |
| converter | the selected chip emits `.chip.is-on`; the stylesheet defines `.chip.is-active` | `converter.tool.js:19` vs `components.css:463` | **measured**: on `tool_converter_default_pk_390x844_light_en` the selected chip renders `rgb(255,255,255)` on `rgb(86,88,95)` — identical to every unselected chip — so the strip tells the reader nothing about which category is on. Flutter draws it selected |
| converter | the catalogue badge says "32 units" over 25 | `catalogue.js:95` | corrected, and counted in the test |
| birthdays | countdowns and ages are constants; `thisMonth: 2` counts nothing | `context.js:1581-1589` | computed from the stored date, by the schema's own rule |
| birthdays | every control is `toast:` — the row, the FAB | `birthdays.tool.js` | real records, a real form |
| birthdays | `ur`/`ar` fall back to English | `i18n/tools.js:957-960` | all three languages |
| water | `streak: 6` and a seven-constant week chart | `context.js:1633, 1642` | dropped, and said |
| water | fl oz via `ml / 29.574` | `context.js:1626` | the exact 29.5735295625, from the shared table |
| water | the log is four literals, though a record schema holds the same four | `context.js:1636-1641` | the reader's own entries |

## 3. Unit Converter — the approved factor policy

Adopted as given, and recorded here so the table is checkable:

**Digital storage.** Decimal names take decimal factors —
kB = 1,000 B, MB = 10⁶, GB = 10⁹, TB = 10¹². Binary units are named
explicitly — KiB = 1,024 B, MiB = 1,048,576, GiB = 1,073,741,824,
TiB = 1,099,511,627,776. No binary factor ever appears under a decimal
name. The reference's `GB` overstates by **2.4 %** and its `TB` by
**4.9 %**.

**Volume.** US and Imperial gallons are separate named units. A bare
`gal` is never shown. An Imperial gallon is 20.1 % larger than a US one,
so a UK reader reading the reference's `gal` is told **16.7 % too
little**.

**Precision.** Factors are the exact defined values, carried at full
internal precision and rounded only for display; round-trip tests assert
against the displayed precision, not against the raw double.

**Corrections, not reproductions.** Every factor the reference truncated
is corrected, and every correction is listed in the next known-difference
entry.

## 4. The `× 0.621` precedent — documented, not silently changed

Three sites in `lib/` hard-code km → miles as `0.621`. The exact value is
**0.621371192237334**, so `0.621` is **0.0597 % low**:

| file:line | function | tool | what the error does |
|---|---|---|---|
| `lib/core/localization/lume_format.dart:476` | `LumeFormatting.speed(int kph)` | Weather, Flights, Explore | rounded to a whole number, so it only shows above ~838 km/h — harmless in practice, wrong as a constant |
| `lib/features/flights/presentation/flights_tool.dart:109` | `LumeFlightsTool.distance` | Flights | **visible**: a 6,000 km flight reads 3726 mi instead of 3728, and the error grows linearly — 4.5 mi at 12,000 km |
| `lib/features/weather/presentation/weather_tool.dart:186` | `_distance` | Weather | printed to one decimal, so it shows from ~81 km: 500 km reads 310.5 mi instead of 310.7 |

No kg↔lb, mi↔m, gal↔L or in↔cm constant exists anywhere in `lib/`;
`0.621` is the only precedent, and Weather duplicates Flights rather than
sharing it.

**These three are not touched by this wave.** Unit Converter introduces
one shared, full-precision table; migrating Flights, Weather and
`LumeFormatting.speed` onto it changes figures on three already-accepted
screens and moves their goldens, so it is a **separate decision put to
the reader**, not a side effect of building a new tool.

## 5. The 51 unbuilt tools, by first blocker

Blockers: **1** immediately buildable · **2** needs durable record
storage · **3** needs a licensed or verified static source · **4** needs
a live feed · **5** needs permission, delivery or platform integration ·
**6** medical or sensitive-domain decision · **7** religious source or
ruling · **8** product/data-model decision · **9** already held for a
documented defect.

### Blocker 1 — immediately buildable (3)

| id | why it clears |
|---|---|
| `converter` | factor policy approved (§3); no source, feed, permission, storage or model decision left |
| `birthdays` | its record family already exists in the reference and the Flutter host is proven three times; the fabricated countdowns become real arithmetic |
| `water` | same — the record family exists and the timeline is the reader's own; two invented sections are dropped and named, and the one default is stated in §1.3 |

### Blocker 3 — needs a licensed or verified static source (4)

| id | the specific missing thing |
|---|---|
| `mosques` | a places directory; also faith-gated |
| `natsavings` | the National Savings schedule, which changes |
| `packages` | operator tariffs, which change |
| `passport` | per-country photo specifications. The reference's rule is "US = 2 × 2 in, **everywhere else** = 35 × 45 mm" (`context.js:1251-1259`), which is false for several markets. One sourcing decision away: it has **no invented personal data at all**, and its capture and import buttons are `toast:` stubs that the Play precedent already knows how to draw |

### Blocker 4 — needs a live feed (11)

`currency` (Interbank composite) · `markets` (exchange feed, 412 lines —
the largest unbuilt module) · `fuel` (regulator notification) ·
`prizebonds` (official draw results) · `aqi` (monitoring stations — the
index is a national constant nudged by a **hash of the city's letters**,
`tool-data.js:505-523`; delete it and nothing remains) · `loadshed`
(distribution company) · `trains` (operator live feed) · `cricket`
(licensed match feed; every figure is `D.CRICKET`, and the card makes an
explicit "Live" claim) · `vehicle` (excise records) · `parcel` (carrier
tracking; the Track button is a `toast:` stub, so only a text field that
cannot answer survives) · `bills` (the provider half of "On device +
provider": amount, due date, account reference, paid state — and its
six-month trend is a literal array).

If a bill is instead decided to be a record the reader types, its
blocker becomes 8 — there is no `bills` schema, and
`FINANCIAL_RECORD_FAMILIES.md` designs only four families. Either way
the first missing thing is a feed or a decision about where a bill comes
from.

### Blocker 5 — permission, delivery or platform integration (6)

| id | the specific missing thing |
|---|---|
| `reminders` | notification scheduling and permission. Everything else is ready — the record schema exists (`record-schemas.js:196-241`) and Events shipped on the same shape — but a reminder that never fires is a promise the build cannot keep, which `ROLLOUT_WAVE_2.md:51` already drew the line on |
| `alarms` | the same, for an alarm |
| `meds` | the same, plus the medical domain |
| `docscan` | the document pipeline the four on-screen steps promise — edge detection, perspective crop, enhancement, PDF export. Camera permission itself is **already solved** by QR Scanner (C78); this is narrower and specific |
| `speedtest` | a measurement endpoint and a connectivity/ISP integration. The reference's handler is `30 + Math.random() * 70` animated over 1.8 s and announced as a result. Given those two things the rest draws with **no invented personal data** — the nearest of all 51 to clearing |
| `mediasaver` | download and storage integration; also three invented library items and a "182 MB" figure |
| `wastatus` | shared-folder access on Android |

`meds` is counted here rather than under 6 because delivery is what it
hits first; its medical surface is a second blocker, not the first.

### Blocker 6 — medical or sensitive-domain decision (5)

`bmi` **(held, §6)** · `cycle` · `pregnancy` · `health` · `vaccines`.
Each needs a source, an age or cycle model, a disclaimer, and a privacy
and sharing decision before anything is drawn. The last three also
declare `Encrypted on device`, which no adapter here supports.

### Blocker 7 — religious source or ruling (14)

`prayer` · `qibla` · `praytrack` · `ramadan` · `fasting` · `taraweeh` ·
`ayah` · `quran` · `quransearch` · `duas` · `names99` · `hijri` ·
`zakat` · `faraid`. All faith-gated, all needing a verified licensed
source or a ruling. `zakat` additionally needs live metal rates;
`hijri` needs a month-start decision that is not arithmetic.

### Blocker 8 — product/data-model decision (5)

| id | the decision that is missing |
|---|---|
| `subs` | a typed subscription family — billing cycle as a recurrence rule, `LumeMoney` per subscription, renewal derivation, price changes, paused/cancelled state. **Storage is not the blocker**: the in-memory repository and its "Kept until you close Lume" line are what Expenses and Ledger already ship on. Delete the fixtures and the whole tool works honestly — it just has nowhere to put a subscription |
| `goals` | a typed goal + contribution family. Same shape; the reference even ships the empty state. Only the contributions chart cannot survive |
| `mealplan` | what a *planned meal* is. No schema exists anywhere, no control writes anything, and its five headline figures (`planned: 18, slots: 21, kcal: 1980, shopItems: 24, cost: 96`) are bare constants — `shopItems` and `cost` are claims about a shopping list and money that no adapter supplies. Its recipe library is separately flagged as needing an owned source |
| `habits` | per-day completion. The record schema holds only `name`, frequency, a **reader-typed** `streak` and notes — so `doneToday`, `best: 28`, `rate: 0.82`, the seven-day grid, the 35-day heatmap (a seeded PRNG) and the two insights are all underivable. An honest build drops five of its six sections; that is past the point where it is still the tool |
| `streak` | the same, with no schema at all: `current: 12, best: 28, thisMonth: 21, rate: 0.78` and a PRNG heatmap |

(`bills` has an alternative reading that lands here too — see blocker 4 —
but its first blocker is the provider feed, so it is counted there.)

### Blocker 9 — already held for a documented defect (2)

`fuelcost` · `holidays`. (`bmi` is also held, and is counted under 6,
where its first blocker actually is.) Holds stand unchanged: Fuel Cost
until its freshness, fuel-price source and imperial-unit contract are
resolved; Public Holidays until an authoritative holiday and Eid-date
source is approved.

### Tally

| blocker | count |
|---|---:|
| 1 immediately buildable | 3 |
| 3 licensed/verified static source | 4 |
| 4 live feed | 11 |
| 5 permission / delivery / platform | 7 |
| 6 medical or sensitive-domain | 5 |
| 7 religious source or ruling | 14 |
| 8 product/data-model decision | 5 |
| 9 held for a documented defect | 2 |
| **total** | **51** |

## 6. Holds that continue, unchanged

- **Fuel Cost** — freshness, fuel-price source and imperial-unit contract.
- **BMI** — medical source, age model, disclaimer, privacy, sharing.
- **Public Holidays** — an authoritative holiday and Eid-date source.
- Every scripture and religious-ruling tool without a verified licensed
  source.
- Every feed-backed tool without a real adapter.
- Every record-backed tool that needs Dayroz's durable encrypted store.
- Every tool needing a new permission or delivery behaviour.

## 7. Deliberately deferred inside this wave

- The three `× 0.621` sites (§4) — documented, put to the reader as a
  separate migration decision, not changed here.
- A **temperature category**. The reference has none, and °C ↔ °F is an
  affine conversion rather than a ratio, so it is a product addition and not
  a conversion. The §2 row that said it would be added was written before
  the table was, and is withdrawn there.
- A **personalised** hydration target — the default is the reference's
  own figure, editable, and nothing else (§1.3, and the owner's approved
  conditions recorded in C100).
- Water's week chart and streak; Unit Converter's "Recent" list —
  dropped, each measured per cell in its parity file.
- Any durable storage, backend behaviour, or release claim the current
  adapters cannot support.

## 8. Stop conditions

Stop after wave 4 closure. Do not begin a fifth wave, Dayroz
integration, an Expenses migration, backend work, Fuel Cost, BMI or
Public Holidays. Stop earlier only for a genuine blocker — and the one
foreseeable one is named in §1.3.
