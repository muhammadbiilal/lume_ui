# Tools: inventory, archetypes and the order they are built in

Phase F6A evidence. Every count here is produced by
`docs/conversion_archive/tool/inventory_tools.mjs`, which imports the catalogue,
the tool specifications and the record schemas as modules and reads each tool
module as text. Its output is `measurements/tool_inventory.json`; nothing below
was counted by hand.

## 1. What exists

| | count | source |
|---|---:|---|
| Catalogue features | **85** | `assets/js/data/catalogue.js` `FEATURES` |
| Tool modules (`*.tool.js`) | **85** | `assets/js/tools/<category>/` |
| Modules the registry installs | **85** | `assets/js/tools/registry.js` `MODULES` |
| Tool specifications | **85** | `assets/js/data/tool-specs.js` `SPECS` |
| Shared tool modules | **7** | `engine.js`, `context.js`, `crud-engine.js`, `registry.js`, `shared/clock.js`, `shared/scanner.js`, `shared/direction.js` |
| Record families on the CRUD engine | **12** | `data/record-schemas.js` |
| Lines across the 85 modules | **4,764** | (plus 1,989 in `context.js`, 657 in `crud-engine.js`, 305 in `engine.js`) |
| Tools with an approved composition | **1** | `markets` (`tool-specs.js` `COMPOSITIONS`) |
| Tool screens built in Flutter | **0** | every id resolves to `FixtureToolScreen` |

By category: everyday 8 · planning 5 · islamic 17 · money 15 · daily 18 ·
personal 22. By density: low 11 · medium 25 · high 43 · very high 6.
Faith-gated 17; country-gated 7 (`tax` PK/GB/US/IN/AE/SA; `natsavings`,
`prizebonds`, `packages`, `loadshed`, `trains`, `vehicle` PK); Android-only 1
(`wastatus`); sensitive 9 (`documents`, `vaccines`, `health`, `cycle`,
`pregnancy`, `expenses`, `goals`, `subs`, `meds`).

### The smaller registry

Dayroz's `feature_registry.dart` holds **72** tools with different ids and route
paths (`DAYROZ_ARCHITECTURE_MAPPING.md` §6 risk 2). That figure is the
architecture audit's; this phase does not open `D:\dayroz\`, so the id-by-id
reconciliation that audit promised for F6 is **not produced here** — see
decision F6A-D1.

## 2. Reconciliation

| check | result |
|---|---|
| feature with no module | none |
| module with no feature | none |
| module declaring an id other than its file name | none |
| duplicate id | none |
| feature whose `act` opens something other than its own tool | **2** — `praytrack → tool:prayer`, `quransearch → sheet:search` |
| feature whose `act` is empty | **62** |

The registry refuses the first three at load (`registry.js:214-241`), so they
cannot drift. The two `act` mismatches and the 62 empty ones are **dead values,
not aliases**: `eligibility.js`'s `actFor()` returns `'tool:' + f.id` for every
feature, which is why `gen_catalogue.mjs:28-30` drops the field. Prayer Tracker
opens Prayer Tracker and Search the Qur'an opens its own tool in the running
reference. There are no module aliases and no market-specific modules: a
market-specific tool is one module whose data varies by country (`taxFor`,
`fuelFor`, `emergencyFor`, `holidaysFor`, `newsFor`, `leviesFor`).

## 3. The frame every tool shares

`engine.js` `build()` wraps every module the same way, whatever its archetype
label:

1. `toolHeader` — back, title, a sub-line (`recordSub` for a record tool, else
   the tool's own `headerSub`, else city-or-country · archetype label), and at
   most three actions: *Add* first for a record tool, then share, export,
   favourite and search as the spec declares them.
2. the module's body — preceded by the record list for a record tool
   (`withRecords`).
3. `sourceSection` — a `.srcbar` card carrying the freshness mark and the
   source line; an offline banner above it when the tool is networked.
4. `privacyNote` — for a sensitive tool.
5. `relatedSection` — eligibility-filtered related tools.

This is one contract, already standing in Flutter as `LumeToolFrame` (F3). It
is not an archetype and is not re-derived per tool.

## 4. Archetypes, re-derived from composition

`tool-specs.js` labels each tool with one of eleven archetypes. The label drives
three things in the reference — the header sub-line's word, the fallback screen
for a tool with no module (unused: all 85 have one), and the density check in
`tests/verify.js` — and **nothing about layout**. So the archetypes below are
derived from what the modules actually build, and the label is kept only where
the evidence agrees with it.

### 4.1 The record layer (orthogonal to the body)

The CRUD engine owns list, detail, create, edit and delete for twelve
families, placed by the frame ahead of the body. It sits under four different
labels (manager, planner, tracker, dashboard), so it is a **layer**, not an
archetype, and a record tool is converted as *record layer + its body
archetype*.

`todos` `reminders` `notes` `events` `shopping` `birthdays` `documents`
`health` `habits` `water` `expenses` `meds`

### 4.2 Body archetypes

Builders named are the `UI.*` calls the module makes (inventory `modules[].ui`).

| # | archetype | defining composition | members | reference |
|---|---|---|---|---|
| A | **Form calculator** | `field`/`formGrid` inputs → `summaryCard` result → `table` or `donut` breakdown → `buttonRow` | `tax` `loan` `compound` `fuelcost` `zakat` `age` `datecalc` `bmi` `tipsplit` `faraid` (10) | **Tax** |
| B | **Records manager** | `summaryCard` → `filterBar`/`sortBar` → grouped `richRow`s → `buttonRow`; record layer where present | `documents`† `health`† `meds`† `todos`† `notes`† `reminders`† `events`† `shopping`† `ledger` `installments` `committee` `vehicle` `subs` `vaccines` `alarms` `mediasaver` (16) | **Documents** |
| C | **Finance dashboard** | `summaryCard` with a ring aside and stats → `barChart`/`donut` → `meterRow`s → rows | `expenses`† `bills` `goals` `babybudget` (4) | **Expenses** |
| D | **Context dashboard** | `contextBar` bound to the personalise sheet → `summaryCard` → `metrics`/`timeline`/`table` for the reader's place and time | `weather` `prayer` `ramadan` `aqi` `sunmoon` `loadshed` `cricket` `pregnancy` (8) | proposed **Weather** — decision F6A-D2 |
| E | **Tracker** | `summaryCard` with `progressRing` → `barChart` → `heatmap` → insight rows | `learning` `habits`† `water`† `praytrack` `fasting` `streak` (6) | **Learning** |
| F | **Planner** | `contextBar` → `segmented` view → a date surface (`monthGrid`) → `timeline` agenda → `fab` | `calendar` (1 on the month grid); `hijri` `holidays` `mealplan` `cycle` `birthdays`† share only the label (5) | **Calendar** — decision F6A-D3 |
| G | **Data explorer** | `contextBar` → `summaryCard` → `searchBar` → `richRow`s with `sparkline`/`delta` → `lineChart` → `table` | `goldrates` `currency` `fuel` `natsavings` `prizebonds` `packages` `worldclock` `quransearch` (8); `markets` has its own approved composition | **Currency & Gold** — decision F6A-D4 |
| H | **Live tracking** | `searchBar`/`segmented` → `metrics` → `map` → `richRow` board → `journey` → `table` → `timeline` | `flights` `trains` `parcel` `mosques` `taraweeh` (5) | **Flights** |
| I | **Editorial reader** | `contextBar` → `searchBar` → scrolling chips → a lead article with `art` → `richRow`s with thumbnails | `news` (1) | **News** |
| J | **Scripture reader** | a `kard--reader` card (Arabic, translation, source, share/listen) → search/filter → rows | `quran` `hadith` `ayah` `duas` `names99` (5) | none yet — decision F6A-D5 |
| K | **Visual library** | `searchBar` → chips → `hscroll` of `imageCard`s → `richRow`s with `art` thumbnails | `recipes` `play` (2) | **Recipes** |
| L | **Clock instrument** | `shared/clock.js` `clockScreen` driven by the host's `runClock` | `timer` `stopwatch` `focus` (3) | **Timer** |
| M | **Camera instrument** | `shared/scanner.js` `scannerScreen`; a permission the user grants by acting | `qr` `docscan` (2); `passport` `wastatus` ask for a permission without the scanner | none yet — decision F6A-D5 |
| N | **Action interface** | an SOS card and a grid of call cards, each an external `tel:` link | `emergency` (1) | **Emergency** — decision F6A-D6 |
| — | **Singular instruments** | each has a host handler of its own and shares no builder with another | `calculator` (`calcToolRender`), `converter` (`swapConverter`), `tasbih` (`resetToolTasbih`), `speedtest` (`runSpeedTest`), `qibla` | converted one by one |

† on the record layer.

**Splits, and why.** The label *instrument* covers three unrelated things: a
clock (`clock.js`, three members), a camera (`scanner.js`, two) and five tools
that share nothing but the word — so it becomes L, M and the singular group.
*Dashboard* covers a budget and a prayer timetable: C draws charts over money,
D draws a place and a time and binds its context bar to the personalise sheet
(`sheet:personalise` in `weather`, `prayer`, `loadshed`), so they split.
*Reader* covers an editorial feed with generated art and scripture set in
Arabic with share actions; I and J split. *Library* loses `duas` and `names99`
to J, whose reader card they draw.

**Merges, and why.** *Manager* and the record layer's bodies are one
composition — `documents` and `ledger` draw the same summary, filter, sort and
grouped rows — so B is one archetype whether or not a record engine sits under
it.

**Not a reference: Markets.** Of the eight explorers, `markets` alone has tabs,
a sort bar, an asset detail view, a market sheet, 413 lines and its own
stylesheet. It is the explorer least like the others, so it cannot stand for
them; it is converted on its own approved composition in a later wave.

### 4.3 The counts, computed

`inventory_tools.mjs` now carries the archetype map as data and fails unless
every catalogue id appears exactly once across it. Its output
(`tool_inventory.json` → `archetypes`):

| | count |
|---|---:|
| Confirmed archetypes | **14** |
| Reference tools | **14** — one per archetype |
| Archetype members (references included) | **72** |
| One-off tools | **6** — `calculator` `converter` `tasbih` `speedtest` `qibla` `markets` |
| Tools on their own composition | **7** — `hijri` `holidays` `mealplan` `cycle` `birthdays` `passport` `wastatus` |
| Total | **85** |
| Record families (a layer across archetypes, not counted above) | 12 |

| archetype | reference |
|---|---|
| Form calculator | `tax` |
| Records manager | `documents` |
| Finance dashboard | `expenses` |
| Context dashboard | `weather` |
| Tracker | `learning` |
| Planner | `calendar` |
| Data explorer | `goldrates` (Currency & Gold) |
| Live tracking | `flights` |
| Editorial reader | `news` |
| Scripture reader | `hadith` |
| Visual library | `recipes` |
| Clock instrument | `timer` |
| Camera instrument | `qr` |
| Action interface | `emergency` |

**Why the count moved from 12 to 14.** The earlier "12" counted the
references that were *chosen* — ten archetypes plus Tax, and Expenses and
Documents counted once each — while two confirmed archetypes had none: the
scripture reader (J) and the camera instrument (M). D5 selects `hadith` and
`qr` for them, so every archetype now has exactly one, and the count is the
archetype count. Nothing else changed it:

* **No two references share an archetype.** Expenses (finance dashboard) and
  Documents (records manager) both sit on the record layer, but the layer is
  not an archetype; their bodies are different compositions.
* **No one-off was counted as a reference.** The five singular instruments had
  no reference in either count, and Markets moves from "explorer member" to
  one-off (D4) without changing the reference count, because it was never the
  explorer's reference.
* **Planner stays one member** (D3): the five tools that share only its label
  are counted on their own compositions, not as planner members.

## 5. Dependency graph

What each reference needs that Flutter does not have yet. "Frame" is the host
adapter every tool needs; the rest are proved shared by at least two real tools
before they are built.

```
spec port ──► tool host adapter ──► route dispatch
                                        │
     ┌──────────────┬───────────┬───────┼─────────┬───────────┬──────────┬──────────┐
     ▼              ▼           ▼       ▼         ▼           ▼          ▼          ▼
    Tax          Learning     Timer  Emergency  Recipes      News     Calendar   Currency&Gold
  donut          bar,heatmap  clock  tel: action imageCard   art row  month grid  sparkline,
  (Expenses)     (Expenses,   (stop- (decision)  (News)      (Recipes)(Hijri)     line chart
                  habits)     watch,                                              (currency,fuel)
                              focus)
                                        │
                              ┌─────────┴──────────┐
                              ▼                    ▼
                           Flights             Expenses ──► Documents
                         map, journey        record layer   record layer,
                         (mosques, parcel)   bar + donut    irreversible delete
```

| foundation | first needed by | proved shared by |
|---|---|---|
| spec port (archetype, density, supports, source, freshness) | every tool | all 85 |
| frame: `.srcbar` source card, six freshness qualities, header actions | every tool | all 85 |
| donut | Tax | `expenses` `loan` `faraid` `subs` `babybudget` |
| bar chart | Learning | `expenses` `bills` `goals` `focus` `water` `praytrack` … (13) |
| heatmap | Learning | `habits` `praytrack` `fasting` `streak` `ramadan` |
| clock screen, injectable clock | Timer | `stopwatch` `focus` |
| generated art, image card | Recipes | `news` `mediasaver` |
| month grid | Calendar | `hijri` (Hijri row), Today's week strip |
| sparkline, line chart | Currency & Gold | `currency` `fuel` `markets` `aqi` `bmi` `health` `compound` |
| map, flight journey | Flights | `mosques` `taraweeh` `trains` |
| record layer | Expenses | the other eleven families |

### Build order

1. spec port → host adapter → route dispatch
2. **Tax** (A) — the frame, fields, a gradient summary, a table, the donut
3. **Learning** (E) — bar chart, heatmap
4. **Timer** (L) — the clock screen over an injectable clock
5. **Emergency** (N) — pending F6A-D6
6. **Recipes** (K) — art and image cards
7. **News** (I) — art rows, lead article, chips
8. **Calendar** (F) — the month grid
9. **Currency & Gold** (G) — sparkline, line chart, deltas
10. **Flights** (H) — map and journey
11. **Expenses** (C) — the record layer, first family
12. **Documents** (B) — the record layer's second family and irreversible delete

## 6. Decisions this inventory raises

| id | question | recommendation |
|---|---|---|
| F6A-D1 | Reconcile the 85 Lume ids against Dayroz's 72 needs read access to `D:\dayroz\`, which this phase forbids. | Produce the table in a read-only pass when access is granted; nothing here depends on it. |
| F6A-D2 | Context dashboards (D) — Weather as the reference. | Approve; it reuses the reference weather port from the F5D closure. |
| F6A-D3 | Planner (F) is one tool on a month grid and five that only share the label. | Build Calendar as F's reference; convert the other five against their own compositions. |
| F6A-D4 | Explorer (G) reference is Currency & Gold, not Markets. | Approve; Markets follows on its approved composition. |
| F6A-D5 | Scripture reader (J) and camera instrument (M) have no reference yet. | Choose `hadith` for J and `qr` for M in the next wave. |
| F6A-D6 | Emergency's actions are `tel:` links that leave the app. | Reproduce the cards; whether a tap dials is a product decision before it ships. |
| F6A-D7 | Share opens the share-card sheet and Export writes a file and toasts its name. Neither system is converted, and writing a file needs a platform dependency. | Keep the controls drawn, named and inert (no false "Saved …"); convert the share-card system and export as their own foundation before a tool that depends on them ships. |
