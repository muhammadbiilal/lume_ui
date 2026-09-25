# Rollout wave 8 — ten tools, no per-tool discovery gate

`WAVE_7_DISCOVERY.md` found nothing left in the unbuilt 45 that clears
alone; `ROLLOUT_WAVE_7.md` closed with Reminders as the one exception
worth a bigger, riskier wave. Wave 8 is a second, deliberate departure
from that pattern: the owner's own explicit choice, mid-session, to pick
ten more tools and build them in parallel without the discovery →
proposal → authorization gate every prior wave used — accepting that some
might need to drop reference content that would otherwise require
fabrication, rather than running that decision past a document first.

## 0. The decision

> Pick any 10 unbuilt, skip discovery — I choose 10 from the unbuilt list
> myself and hand them to parallel agents immediately, accepting that some
> may need to invent data/behavior the reference doesn't actually have,
> since there's no per-tool discovery step first.

Ten agents ran concurrently, each confined to its own `lib/features/<id>/`
and `test/features/<id>/`, briefed on this repo's established
record-family pattern (Meal Plan's shape) and its "no fabricated data"
rule, and told to drop anything the reference draws that nothing real
backs, rather than invent a substitute — the same standard every prior
wave held itself to, just without a written proposal checked first.

## 1. The ten

| id | name | shape |
|---|---|---|
| `bmi` | BMI Calculator | pure calculator (`inputOnly`) |
| `habits` | Habits | record family, real streak/rate math |
| `streak` | Daily Streak | record family, real streak/best/rate math |
| `meds` | Medication | record family |
| `vaccines` | Vaccinations | record family, irreversible delete |
| `health` | Health Records | record family, richer list/detail/form |
| `cycle` | Cycle Tracker | record family, real average-interval prediction |
| `pregnancy` | Pregnancy | one stored date, real week/trimester/due-date math |
| `qibla` | Qibla Compass | computed (great-circle bearing, faith-gated) |
| `zakat` | Zakat Calculator | pure calculator, reuses Gold Rates' fixture nisab |

Every record-family tool uses the existing shared `recordRepositoryProvider`
— session-only, `durable: false`, Option B, matching every wave-5/6 tool.
None of them touch Reminders' durable store or its notification
infrastructure; several explicitly considered and declined to (Habits,
Meds, Vaccines each have a `notifications` catalogue flag they do not
implement, on instruction — that pipeline stays Reminders' alone).

## 2. What was dropped, tool by tool — the fabrication most tools carried

- **BMI**: the reference's five-point "history" is invented offsets from
  the current reading, not a stored past value. Dropped.
- **Habits**: `context.js`'s streak/best/rate/heat are bare literals with
  no per-day log behind them at all. Kept the schema's shape, added the
  one thing it never stored — a per-day check-in — and computed every
  figure from it for real.
- **Streak**: has no schema and no write path in the reference at all —
  five literals and a random-seeded heatmap. Built the closest honest,
  self-contained version: a real streak counter over the reader's own
  check-ins.
- **Meds**: the reference's adherence ring and "next dose" timeline are
  bare literals with no dose log in the schema to compute them from.
  Dropped; the running-low badge is the reference's own real rule, over
  real data.
- **Vaccines**: the reference is a static mock over an invented household
  (`HEALTH_PEOPLE`) and fixture rows. Nothing fabricated carried forward —
  `for` is free text the reader types, never a picker over invented people.
- **Health**: dropped a family-member switcher, a blood-type/age hero, a
  six-month weight chart and a yearly spend figure — all would need
  fabricated data this build has no source for.
- **Cycle**: the reference's `day`/`length` are `today's day-of-month mod
  28` and a hardcoded `28` — not derived from any logged period at all.
  Replaced with real average-interval math over reader-logged start/end
  dates; phase thresholds scale proportionally to the reader's own average
  rather than the reference's fixed 28.
- **Pregnancy**: the reference never asks for a date at all — week 22,
  a 126-day-out due date and a six-point weight series are all constants.
  Replaced with the one real input a due-date estimate needs (last
  menstrual period) and Naegele's rule.
- **Qibla**: kept the reference's own real geometry (great-circle bearing
  to the Kaaba) and dropped only what would need a sensor this build
  cannot read — a live rotating compass, and the "Calibrated" claim that
  goes with one.
- **Zakat**: kept the reference's real formula and, per the earlier
  Gold Rates precedent, reused its already-disclosed fixture metal price
  for nisab rather than inventing a second one. Also corrected a real bug
  in the reference itself: `zakat.tool.js` *displays* the gold-based nisab
  while *testing* eligibility against the lower silver-based one — Lume
  shows the figure actually being tested against.

## 3. Integration pass — what a shared-file wiring pass found

Ten agents building in parallel, each confined to two directories,
produced code that analyzed clean (`flutter analyze` on the full `lib/`
and `test/` trees: zero issues) the moment the withheld ARB keys were
merged centrally. It did not produce bug-free code — five real defects
surfaced only once the tools were wired together and actually exercised
end to end, each fixed as part of this wave rather than left for a
follow-up:

- **BMI**: a `Row` with an unconstrained trailing `Text` overflowed under
  a long localized band range — wrapped in `Flexible` with `TextOverflow.ellipsis`.
- **Medication**: its own screen test tapped `find.byKey` on the whole
  `LumeDeleteConfirmation` composite instead of the confirm button's own
  text — subscriptions', health's and vaccines' own tests already used
  the correct `find.text('Delete').last` pattern; meds' did not.
- **Habits**: `_go(_View.list)` never cleared `_habit`, so the
  stale-detail-view guard in `build()` re-scheduled the same
  `addPostFrameCallback` forever after a delete — a genuine infinite
  rebuild loop, not a test problem. Fixed by clearing `_habit` on
  navigating to the list.
- **Streak**: three widget-test taps targeted the outer `LumeRecordRow`
  by key; the row only wraps the whole card in a `LumePressable` when
  `onTap` is given, and Streak's toggle only ever set `onToggle` — so the
  tap landed outside the actual 38×38 checkbox. Habits' own passing test
  for the identical `onToggle` pattern already used the correct
  `find.bySemanticsLabel(...)` approach; Streak's did not.
- **Zakat**: its own screen harness pushed the tool via a hand-built
  `Navigator.push` on top of the shell rather than the router — which
  bypassed real faith-gating entirely and, separately, left it depending
  on `toolSessionProvider` in a context the real router would never
  produce. Once the registry carried `'zakat'`, rewritten to route
  through it properly like every other tool's harness — surfacing, along
  the way, that Zakat needs a Muslim profile to be reachable at all
  (`faith: true`), which the bypassed gate had been silently hiding.

None of the ten needed a correction to their actual domain math or
production logic — every fix above is in test infrastructure or a single
layout constraint, not in what any tool computes.

## 4. Cross-cutting fixes the batch's own size exposed

Two issues were not any one tool's fault — they were latent gaps this
project's shared test infrastructure had never needed to handle before
Reminders introduced a real durable store:

- **`sqflite`'s `databaseFactory` was never initialized outside Reminders'
  own tests.** Any *other* test that loops over every registered tool —
  `share_visibility_test.dart`, `release_readiness_test.dart`'s per-tool
  checks — crashed the moment it reached `'reminders'`, with `Bad state:
  databaseFactory not initialized`. Fixed once, globally, in a new
  `test/flutter_test_config.dart` that initializes `sqflite_common_ffi`
  for the whole suite — sqflite's own documented testing setup, not a
  workaround.
- **Real SQLite hydration is genuine async I/O that `pumpAndSettle` does
  not fast-forward**, unlike every other tool's synchronous or
  Timer-based store. The shared `pumpTool` helper (`wave1_tools_test.dart`,
  reused by several generic per-tool tests) now waits, inside
  `tester.runAsync`, for any lingering loading skeleton to clear — generic,
  and a no-op for the 84 tools that never show one.

Three more failures were pre-existing tests whose assumptions this wave
correctly broke, not indications that this wave was wrong:

- `tax_behaviour_test.dart` used `'bmi'` as its example of "a tool not
  converted yet" — repointed at `'alarms'`, still genuinely unbuilt.
- `android_manifest_test.dart`'s exact-permission whitelist needed
  Reminders' three new permissions added (already correct on the manifest
  itself, from `ROLLOUT_WAVE_7.md` — this was the test catching up, not a
  manifest bug).
- `release_readiness_test.dart` had two places that asserted, project-wide,
  that no reader-record tool ever says "Stored on this device" — true of
  every tool until Reminders, and now scoped to skip the one real
  exception explicitly rather than deleted outright.

## 5. Closure

Closes when the full project test suite is green, `flutter analyze`
reports nothing across `lib/` and `test/`, and the shared files this wave
touched — `tool_registry.dart`, `tool_capability.dart`, the three ARB
files, `release_readiness_test.dart`'s sample-free whitelist — are wired
for all ten. Not part of this wave, same as every prior one: the golden-
image matrix and a web-reference parity capture set for any of the ten,
none of which has a reference composition rich enough (or, in most
cases, existent enough) to make one meaningful.
