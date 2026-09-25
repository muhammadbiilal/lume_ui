# Rollout wave 9 — sixteen tools, "do the same as web"

Continues straight from Wave 8's own precedent (ten tools, no per-tool
discovery gate) with the owner's next instruction: pick the remaining
money/daily/religious-text tools this app can honestly support with the
reference's own real data, and build all of them in parallel. The
question this wave actually turned on wasn't architecture — it was
licensing and live data: several of these tools (Currency, Fuel, Markets,
Cricket, AQI, Loadshedding, Trains, Bills, National Savings, Prize Bonds,
Parcel, Public Holidays) look like they need a live feed, and this app
makes zero network calls anywhere. Rather than guess at a policy, the
question was put back to the reference itself.

## 0. The decision

> How does the web reference actually handle this?

Investigated directly: every one of the reference's "live" tools is a
static fixture in `tool-data.js` — there is no live network call anywhere
in Dayroz, for money data or otherwise. The one real precedent for
handling *small, real, unlicensed religious text honestly* was Hadith
(already shipped): port only what's real, disclose a fallback rather than
mistranslate, and correct the reference's own bugs rather than reproduce
them.

> Do the same as web.

Sixteen agents ran concurrently, each confined to its own
`lib/features/<id>/` and `test/features/<id>/`, told to port the
reference's own real fixture data faithfully — no live APIs invented
anywhere, no fabrication beyond what the reference's own `tool-data.js`
already has — and, for the three religious-text tools, to follow Hadith's
own honesty pattern rather than invent a second one.

## 1. The sixteen

| agent | id(s) | shape |
|---|---|---|
| 1 | `quran`, `quransearch`, `ayah` | religious-text reader, Hadith's `religious_content.dart` contract reused directly |
| 2 | `duas` | religious-text reader, same contract |
| 3 | `names99` | religious-text reader, same contract |
| 4 | `currency` | fixture-display, GoldRates archetype |
| 5 | `fuel`, `fuelcost` | fixture-display + calculator, sibling tools sharing one fixture |
| 6 | `markets` | fixture-display, explorer archetype |
| 7 | `natsavings` | fixture-display, PK-only |
| 8 | `prizebonds` | fixture-display, PK-only |
| 9 | `bills` | fixture-display |
| 10 | `packages` | fixture-display, PK-only |
| 11 | `cricket` | fixture-display, dashboard archetype |
| 12 | `aqi` | fixture-display, computed perturbation |
| 13 | `loadshed` | fixture-display, PK-only |
| 14 | `trains` | fixture-display, extends the existing §33 destination's own model additively |
| 15 | `holidays` | fixture-display, global with a per-country table + fallback |
| 16 | `parcel` | fixture-display, session-only selection (no record family) |

None of the sixteen is a reader-record family — every one defaults to
`isSample: true` in `LumeDataCapability.fixture()` automatically, the
architectural inverse of Wave 8 (whose ten tools were reader records).
`tool_capability.dart` needed **no changes at all** for this wave.

## 2. What was dropped or corrected, tool by tool

- **Quran/Quran Search/Ayah of the Day**: 12 of 114 surahs, 3 of 6,236
  ayat — disclosed on screen, not silently presented as complete. Dropped
  the reference's tafsir (one fixed sentence shown under every ayah
  regardless of which is displayed — wrong commentary for 2 of 3),
  continue-reading/juz/bookmarks (point to an ayah this build doesn't
  hold), a decorative scope/revealed filter bar on Search that the
  reference's own `quranSearch()` never reads, and a fake "Listen" button.
- **Duas**: fixed two real reference bugs — `DUA_CATEGORIES`' own printed
  counts don't match its actual 5-dua array (ported the real computed
  count instead), and its Share button shares a fixed dua not even in the
  array (fixed to share what's actually on screen, the same class of fix
  Hadith's own C68 made).
- **99 Names of Allah**: 12 of 99, disclosed ("the remaining 87 need a
  verified source"). Dropped the reference's "Practise" button (toasts,
  starts nothing), same precedent as Tasbih.
- **Currency**: the reference has no currency picker at all, only a swap
  between two fixed sides — added a real from/to picker, the same
  correction already precedented for Unit Converter. Dropped the
  reference's fabricated "recent conversions" history (nothing records a
  conversion; already-precedented subtraction from Converter's own
  `u.recent`).
- **Fuel Prices + Fuel Cost**: Fuel Cost's default price reads Fuel
  Prices' own fixture directly, not a duplicated table. Dropped Fuel
  Cost's fabricated trip-history rows (invented offsets from the current
  reading, the same pattern already declined for BMI/Focus Timer).
- **Markets**: the reference's own `markets.tool.js` is much bigger
  (stocks/forex/commodities per exchange, an FX converter, search/filter/
  sort) — this port covers the 3 world-board sections (indices/crypto/
  ETFs) the catalogue actually promises; the rest is flagged, not built.
- **National Savings**: PK-only, all 5 real instruments ported verbatim.
  Non-PK gets an honest unavailable state (Prize Bonds' own convention,
  not the reference's bare `emptyState`).
- **Prize Bonds**: the reference's "Your numbers"/save-a-number feature is
  dead code — the button never actually writes anything. Ported as a
  permanent, honest empty state, not a working save flow.
- **Bills**: every reference interaction is toast-only, nothing is ever
  written — confirmed fixture-display, not a record family. Kept one real
  reference quirk on purpose: the "Due" filter chip's own count (1)
  disagrees with what it actually lists (3 rows) — documented and tested,
  not silently fixed.
- **Mobile Packages**: PK-only, the 4 real carrier bundles (Jazz/Zong/
  Ufone/Telenor).
- **Cricket**: confirmed there is no live feed behind the reference's own
  "live" framing — flagged the catalogue's stale `freshness: live` (fixed
  below).
- **AQI**: the city perturbation is the same seeded string-hash
  `weather_fixtures.dart` already ported for its own embedded AQI card,
  independently re-ported here (self-contained per tool, matching this
  codebase's convention). Added an explicit "estimated, not measured"
  note near the headline number — the reference only ever disclosed that
  on the pollutant rows, never near the figure a reader actually reads
  first.
- **Loadshedding**: surfaced an architecture fact that matters project-
  wide (§3 below).
- **Trains**: the richer Trains *tool* (`trains.tool.js`), reached from a
  destination's departure row or from Tools/search directly — distinct
  from the §33 destination screen a prior wave already built. Extends
  that screen's own model additively (new optional fields, excluded from
  `==`/`hashCode`) rather than forking a parallel one.
- **Public Holidays**: 6 countries + a 3-entry global fallback, no year
  printed anywhere — checked, and the reference's own movable-holiday
  dates straddle two different real years inconsistently, so no single
  "this year" label would be honest. A visible note says these are
  illustrative reference dates instead. Fixed a real reference bug: "next
  holiday" was literally `list[0]` (Pakistan's own table happens to start
  in November); now computes the true nearest occurrence from today.
- **Parcel Tracker**: confirmed fixture-display — no reader-add-a-parcel
  flow exists in the reference at all, only a session-only "which of the
  2 fixture parcels is selected" state (Flights' own pattern). The
  Track/Notify buttons are kept for visual parity but proven, in tests, to
  be honest no-ops (a fixed toast regardless of what's typed, the list
  never filters).

## 3. Architecture finding, confirmed across four tools

Loadshedding's own agent noticed something that changes how every future
country-restricted tool should be written: when a catalogue entry
declares `countries: {'PK'}`, `LumeToolFrame` itself — not the tool —
already renders the generic unavailable state and skips `body` entirely
for an ineligible reader (`lume_tool_frame.dart`, the `!eligible` branch).
Prize Bonds, National Savings and Trains had each independently written
their *own* bespoke unavailable widget, unreachable by a real non-PK
reader for exactly this reason. This is not a bug to remove — it is
genuine defence-in-depth per §64 (if the catalogue's `countries` set is
ever widened before that country's fixture data lands, this is what
stands between the gap and a crash or invented data; it is exactly the
fallback that caught a real dispose-crash bug below). All four tools' own
"reader outside Pakistan" tests were rewritten to assert on the frame's
generic state instead of a widget that can never mount in production.

## 4. Integration pass

### ARB merge

272 new keys landed across `app_en.arb`/`app_ur.arb`/`app_ar.arb` (a
background agent handled the bulk of it from an authoritative,
analyzer-verified key list; ten of Duas/Cricket/Bills/Names99/Markets/
Loadshedding's own suggested strings were derived from the agents' own
reports directly). Two follow-up corrections once `flutter analyze`
actually ran clean:

- Ten more `bills*` keys the first pass had missed — a stale, partially
  regenerated `app_localizations.dart` (left over from an earlier agent's
  own verify-then-revert cycle) had been silently satisfying the analyzer
  on the very first pass, until a clean `flutter gen-l10n` exposed the
  real gap.
- `names99NoMatch`/`names99NoMatchText`: the ARB merge agent's own
  generic wording didn't match the original names99 agent's own widget
  test, which asserted a more specific phrase — the test's wording won.

### Registry and capability

`tool_registry.dart` gained 19 entries (16 agents; Quran's family is 3
ids, Fuel's is 2). Every one of the sixteen already exposed a static
`.open(LumeToolRequest)` matching `LumeToolBuilder` — no naming surprises
this time, unlike Wave 8. `tool_capability.dart` needed no changes (§1).
`feature_catalogue.dart` already carried a complete, correct entry for
all sixteen ids — wave 9 agents only ever read it.

### A real, stale metadata bug found and fixed

Cricket's own catalogue entry declared `freshness: LumeFreshnessKind.live`
— stale copy from before this wave confirmed there is no live feed at
all. `LumeDataCapability.fixture()` already fell back to honest
`isSample: true` regardless (cricket was never added to
`onDeviceClocks`), so no reader was ever shown a false live claim, but the
declared metadata itself was wrong. Changed to `LumeFreshnessKind.cached`.

A second, subtler version of the same class of bug: `freshAnnual`'s
English text ("Current tax year") is Tax's own reference copy, silently
reused as the generic label for *any* tool with `annual` freshness —
which, before this wave, was only ever Tax. Holidays is the first other
tool to use it, and "Current tax year" on the Holidays screen would be
plainly wrong content, not just a stale label. Added `freshAnnualGeneric`
("Updated annually", matching the existing `freshDaily`/`freshWeekly`
"Updated ..." pattern) and kept Tax's own exact reference wording
untouched (`source_claims.dart`'s `annual` case now branches on
`feature.id == 'tax'`).

### Real bugs the test gate found

`flutter test`, run clean, found 34 real failures across ten of the
sixteen tools. Most were test-authoring mistakes of the two kinds this
project has already seen before (Wave 8's own "tap-target mismatch"
precedent): a `find.text(...)` matching two on-screen instances of the
same string (a bill's name in the main list *and* in its own History
section; a currency/certificate/train's name in a row *and* in a picker;
"XRP"'s ticker and name being the identical string in the reference's own
data), and a filter bar or suggested-search chip sitting off-screen in its
own horizontal scroller at 390 points wide, needing `tester.ensureVisible`
before a tap the test never gave it. One test assumed US month-first date
order ("Nov 9") where this app's own locale-aware formatting correctly
gives Pakistan's world-English order ("9 Nov") for a PK reader. One
assumed a fallback-language label stays in English even under a
translated interface locale, when the label is itself an ordinary
translated ARB string. One read `Directionality` from the wrong element
(a widget's own context sits *above* the `Directionality` it builds for
its children, not below it).

Three were real production bugs, found only once the tools were wired
together and actually exercised end to end — the same pattern Wave 8's
own five bugs followed:

- **Prize Bonds**: the exact `late final` ref-after-dispose crash class
  the Mobile Packages agent already found and fixed in its own tool —
  `_session`/`_number` were lazily initialized, first touched inside
  `dispose()` for a non-PK reader (whose `build()` never reaches the code
  that would have initialized them earlier), calling `ref` after the
  widget was already disposed. Fixed the same way: eager initialization
  in `initState()`. (National Savings was checked for the identical
  pattern — already safe, because its own `initState()` happens to force
  the same lazy field's resolution as a side effect.)
- **Loadshedding**: a full sentence ("Check your last bill") had been
  placed in `LumeCompactRow`'s `value:` slot — sized for a short reading,
  not a phrase — instead of its own `subtitle:` slot, which sits under the
  label with room to wrap. Overflowed only at 200% scale in Urdu. Moved
  to `subtitle:`; no ARB or shared-widget change needed.
- **Markets**: `assetRow`'s delta combines the absolute change and the
  percent in one string ("+1,162 +0.42%") — long enough on its own to
  overflow `LumeDelta`'s own row at 200% scale/RTL, and, combined with
  that row's logo + sparkline + value already being dense, to tip the
  whole row over by a hairline too.

### A shared-widget near-miss, caught before it shipped

The first attempt at fixing Markets'/Holidays'/Loadshedding's overflows
wrapped the trailing value/delta columns of the shared `LumeRichRow` and
`LumeCompactRow` in `Flexible`. That is wrong: those columns sit beside
that row's own title/label `Expanded`, and Flutter's flex layout splits
remaining space across *every* flex child in a row, not just the one that
needs it — `Expanded` is tight-fit and is forced to actually consume its
now-smaller share, visibly shrinking the title and dragging everything
after it left. Running the full suite caught this immediately: 246
failures, almost all `*_parity_test.dart`/`tool_golden_test.dart`
exact-pixel-position assertions across tools this wave never touched.
Reverted both wraps. The two real fixes that survived:

- `LumeFreshness`'s badge label and `LumeSourceLine`'s per-part text
  (`lume_badge.dart`) — safe, because neither widget's own `Row` has a
  competing `Expanded` sibling — now wrap in `Flexible` + ellipsis. This
  is a genuine, if narrow, behavioural change (an already-overflowing
  label now clips instead of erroring), which is exactly why it moved two
  pixels in GoldRates' own Urdu/Arabic golden images (`LumeDelta`, not
  this fix, turned out to be the actual cause once isolated — see below;
  no golden needed updating after all).
- `LumeDelta` gained an **opt-in** `maxWidth` parameter, `null` by
  default — every existing caller elsewhere in the app is completely
  unaffected, byte-for-byte. Markets' own two `LumeDelta` calls pass
  `maxWidth: 90`, capping only its own unusually long combined delta text,
  with zero blast radius anywhere else.

Full suite, run clean a final time after every fix: 6205 tests, 0
failures.

## 5. Closure

Closes when the full project test suite is green, `flutter analyze`
reports nothing across `lib/` and `test/`, and the shared files this wave
touched — `tool_registry.dart` (19 entries), `feature_catalogue.dart`
(cricket's freshness), the three ARB files, `lume_badge.dart` (two
defensive, non-breaking overflow guards plus one opt-in parameter),
`source_claims.dart` (Tax/Holidays split) — are wired for all sixteen. Not
part of this wave, same as every prior one: the golden-image matrix and a
web-reference parity capture set for any of the sixteen, none of which
has a reference composition rich enough to make one meaningful yet.
