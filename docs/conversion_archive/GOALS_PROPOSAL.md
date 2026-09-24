# Savings Goals — proposal, and the approved model

**Status: approved for implementation under `ROLLOUT_WAVE_5.md`'s
authorisation, 2026-09-24.** This is a short proposal, not a full
historical record — Goals has no schedule, no deposit, no reschedule
rules, so most of `INSTALLMENTS_PROPOSAL.md`'s section list does not
apply. §7 is the decision table; §8 is the approved model it resolves
into. No figure below is invented — every one is either read from the
reference or is a real derivation the reference's own arithmetic already
performs.

## 0. Source inventory

| file | what it holds for Goals |
|---|---|
| `assets/js/tools/personal/goals.tool.js` (55 lines) | the whole screen: `build(c)`, the only function |
| `assets/js/tools/context.js` `goals()` (l. 1371–1385) | the data: three fixture goals and every derived figure |
| `assets/js/data/tool-data.js` `GOALS` (l. 779–783) | the three seed goals: `name, target, saved, by, icon, tone, monthly` |
| `assets/js/data/catalogue.js` l. 186 | `{ id: 'goals', n: 'Savings Goals', i: 'i-target', c: 'personal', g: 'personal', sens: 1, ints: ['savings'], m: '2 active', act: '', kw: 'save target money' }` — **`m: '2 active'` disagrees with the seed's 3 goals** |
| `assets/js/data/tool-specs.js` l. 281–283 | `a: 'dashboard', d: 'high', aware: 'currency locale', sensitive: 1, supports: 'history notifications offline export sharing', home: 1, rel: ['expenses', 'natsavings', 'compound']` |
| `assets/js/i18n/tools.js` l. 858–866 | 15 `goals.*` strings, **English only** — no `ur`/`ar` entries anywhere in the file |
| `assets/css/tools/shared.css` l. 1273–1283, 649 | `.goal*` row styling; `.goal__pct` is in the RTL numeral-isolation list, so percentages stay LTR digits under Urdu/Arabic |
| `assets/js/data/record-schemas.js` | **no Goals schema** — Goals never got the record-family treatment in the reference either |
| Flutter today | `feature_catalogue.dart` entry only (mirrors the catalogue row above, `homeEligible: true`, `notifications` declared); no `lib/features/goals/` directory exists |

**There are no real actions in the reference.** "Create your first goal"
and "Add a contribution" are both `toast:` stubs — nothing is created,
nothing is recorded, no form ever opens. "Share" is the one functional
control, producing a real computed quote
(`goals.saved + money(saved) + of + money(target) + ratio%`). No goal
card carries a tap handler; there is no detail view.

## 1. What it models, and what changes

A **savings goal**: a target amount, a deadline, and progress toward it.
The reference's own model has no persistence and no CRUD — it is a
read-only dashboard over one hardcoded array. Converting it to a real
record family (the whole point of this wave) means the reader can
actually create a goal and log a contribution, which the reference never
lets them do. This is not a redesign of Lume's screen — the composition,
section order, card layout and progress visuals below are all reproduced
from the reference exactly — it is replacing two dead `toast:` buttons
with the real forms the reference's own copy already promises
("Create your first goal", "Add a contribution").

## 2. Typed model — proposed

Following `FINANCIAL_RECORD_FAMILIES.md`'s shared foundations
(`LumeRecordId`, `LumeMoney`, dates as `LumeDate`, derived totals never
stored, a closed status enum with a transition table, a strict codec) and
`installments_model.dart`'s concrete shape:

```dart
enum GoalState { active, completed, abandoned }

class Goal {
  final LumeRecordId id;
  final String name;
  final LumeMoney target;
  final LumeDate? targetDate;   // optional — the reference always has one, but a reader need not set one
  final String? note;
  final GoalState state;        // active → completed | abandoned
  final DateTime createdAt;
  final int version;
}

class GoalContribution {
  final LumeRecordId id;
  final LumeRecordId goalId;
  final LumeMoney amount;
  final LumeDate on;
  final DateTime createdAt;
  final int version;
}
```

No `icon`/`tone` field is stored — the reference's three icon/tone pairs
(`i-shield`/accent, `i-plane`/violet, `i-grid`/amber) are decorative
assignment with no meaning to preserve; a reader-created goal gets an
icon the same way Baby Budget's categories do (a small fixed palette,
assigned round-robin or reader-chosen — see §7, D-G6).

**Derived, never stored** (`goals_book.dart`, mirroring
`installments_book.dart`):

```text
saved(goal)      = Σ goal's own contributions
pct(goal)        = saved / target                              (clamped 0–1 for display; can exceed 1)
remaining(goal)  = target − saved                               (0 if saved ≥ target)
projected(goal)  = null if no targetDate or no contributions yet;
                   otherwise the reference's own formula, generalised:
                   monthlyPace = saved / monthsSinceCreated (0 if < 1 month)
                   monthsLeft  = ceil(remaining / monthlyPace) if monthlyPace > 0, else null
aggregate.saved   = Σ saved(goal) across active goals
aggregate.target  = Σ target across active goals
aggregate.ratio   = aggregate.saved / aggregate.target
aggregate.nextComplete = the active goal with the highest pct, its targetDate (or name if none)
monthlyHistory    = Σ contributions per calendar month, last 6 months ending this month —
                    real, derived from GoalContribution.on, zero-filled for months with none
```

This directly replaces the reference's `monthly` field (a goal-level
"planned contribution" the reader typed) and its fabricated `history`
array (§4). Nothing here needs a stored "monthly plan" — the projection
is computed from the reader's own pace, which is more honest than asking
for a plan up front and never checking it against reality.

## 3. What the reference fabricates, and the correction

| reference behaviour | evidence | Flutter correction |
|---|---|---|
| The "Contributions" bar chart is `history: [280,320,410,380,430,430]`, a hardcoded 6-value array with no relation to any goal, any contribution, or any date | `context.js:1383`, confirmed no per-goal or per-month ledger exists anywhere | Dropped and replaced with `monthlyHistory` above — real totals from the reader's own `GoalContribution` records, zero when there are none |
| "Create your first goal" and "Add a contribution" are `toast:` stubs | `goals.tool.js:20,52` | Real forms — see §5 |
| Catalogue badge says "2 active"; the seed has 3 goals | `catalogue.js:186` vs `tool-data.js:779–783` | The Tools tile states a purpose ("Track your savings goals"), not a count that can go stale — same correction Installments made (D-I14) |
| No goal has a stable `id`; no per-goal detail/edit exists | `goals.tool.js:34–46`, no `data-act` on any goal card | Every goal gets a `LumeRecordId` at creation; tapping a card opens a real detail view |
| `monthly` is a reader-typed "planned pace" per goal, never checked against actual contributions | `tool-data.js` fields | Not carried forward as a stored field — see §2's derived `projected` |
| Strings are English-only | `i18n/tools.js`, no `goals.*` in `ur`/`ar` blocks | Full translation, all three languages, matching every other shipped tool |

## 4. Screen composition — proposed, in the reference's order

1. **Summary card** — saved so far, "of {target} across all goals", a
   progress ring (aggregate ratio), three stats: active goals, this
   month's contributions total (not "Monthly" — see D-G2), next to
   complete.
2. **"Your goals" list** — one card per goal: icon, name, "{saved} of
   {target} · by {date}" (or no date if none set), a progress bar, "{X}
   to go · on track for {N months}" (or no projection line if
   under-determined). **New: tappable**, opening a detail view.
3. **Goal detail** (new — the reference has none): the same header figures
   for one goal, its contribution history as a list (date, amount),
   "Add a contribution", edit and archive/delete actions.
4. **"Contributions this half-year"** chart — the real `monthlyHistory`
   from §2, replacing the fabricated one.
5. **Button row**: "Add a goal" (opens the create form, replacing the
   toast), "Share" (kept — already a real, working feature).
6. **Empty state** (the reference's own, currently dead code) — becomes
   live: a reader who deletes every goal sees it, with a working
   "Create your first goal" action.
7. **On-screen disclosure** (Option B): a persistent, visible line —
   "Goals are cleared when you close Lume" — on the summary card, not
   hidden in settings, matching Water/Birthdays' C100 precedent.

No search or sort bar — the reference has neither for Goals (unlike
Subscriptions), and three-to-a-dozen goals doesn't need one; add later if
a reader ever has enough goals to want it (D-G7).

## 5. CRUD — proposed

- **Add a goal**: name (required), target amount + currency (required),
  target date (optional), note (optional). Starts `active`, zero saved.
- **Edit a goal**: name, target, target date, note — editable any time
  (no "locked after first contribution" rule; unlike Installments' fixed
  schedule, a goal's target is allowed to move, since the reference
  itself never fixes one).
- **Add a contribution**: amount + date, defaulting to today. Cannot be
  edited after creation (matches Installments/Ledger's append-only
  payment pattern) but can be voided (kept, excluded from sums, undoable).
- **Archive / mark complete**: `active → completed` (reader-initiated, or
  offered automatically once `saved ≥ target`, reader confirms) or
  `active → abandoned` (reader-initiated, e.g. no longer saving for it).
  Both keep history; neither is a delete.
- **Delete a goal**: removes the goal and its contributions together,
  with Undo — matching every other family's delete pattern.

## 6. Persistence, privacy, localisation, coverage

- **Option B, unchanged**: the existing `LumeMemoryRecordRepository`,
  wrapped in a typed `GoalsRepository` exactly as `InstallmentsRepository`
  wraps it. No persistence package. The on-screen disclosure in §4.7 is
  not optional.
- **Sensitive**: `sens: 1` in the reference is kept — off Home despite the
  reference's `home: 1` (D-G1), out of notifications, no share of
  underlying figures beyond the existing quote-card share.
- **Localisation**: full `en`/`ur`/`ar` translation of every string —
  the reference's own English-only gap (§0) is not reproduced. RTL
  mirroring for the goal cards, progress ring and chart; percentages stay
  LTR digits (matching the reference's own numeral-isolation rule).
- **Coverage**: dark mode, phone/landscape/wide layouts, 200% text,
  keyboard and screen-reader labelling for the ring, bars and chart —
  same bar every shipped record family already clears, verified the same
  way (`VISUAL_VERIFICATION.md`'s matrix, `lume_progress`'s existing
  accessible-value pattern for the ring).

## 7. Decisions requiring approval

| id | decision | recommendation |
|---|---|---|
| D-G1 | Home eligibility | **no** — despite the reference's `home: 1`, a sensitive financial record stays off Home, matching Baby Budget/Installments |
| D-G2 | Summary stat "Monthly" | **replace with "this month's contributions"** (a real, derived figure) rather than reproduce the reference's reader-typed, never-verified `monthly` plan field |
| D-G3 | Contribution editing | **append-only, voidable, not editable** — matches Installments/Ledger's payment pattern |
| D-G4 | Target date | **optional** — the reference always has one, but nothing requires a reader to set one; `projected` is simply unavailable without it |
| D-G5 | Auto-complete on reaching target | **offer, don't force** — reader confirms marking a goal `completed`; still counted in the aggregate until they do |
| D-G6 | Icon/tone | **reader picks from a fixed small palette at creation** (same mechanism as Baby Budget's category colours), not derived from anything |
| D-G7 | Search/sort | **not in v1** — the reference has neither for Goals |
| D-G8 | Export | **yes**, JSON + CSV, reusing the existing transfer pattern (`sens: 1` → redact names by default, though a goal's "name" here is the goal's own title, not a person's — export as-is unless a reader opts to exclude it) |
| D-G9 | Notifications | **not in v1** — a Dayroz obligation, matching Installments D-I11 |
| D-G10 | Tools tile status | **states a purpose** ("Track your savings goals"), never a count |

## 8. Approved model (final)

Sections 0–7 above are the proposal and stand as the approved model — no
further correction round is needed before implementation, per this
wave's own authorisation to proceed without an additional pause. `§9`
Evidence below is what implementation must produce to close the tool.

## 9. Evidence to produce

- `goals_domain_test.dart` — model/codec round-trip, `GoalsBook`
  derivations (`pct`, `remaining`, `projected`, `monthlyHistory`,
  aggregate figures), transition rules, currency handling.
- `goals_screen_test.dart` — add/edit/delete goal, add/void contribution,
  empty state, archive/complete, Undo, validation.
- `goals_catalogue_test.dart` — sensitive, off Home, `outbound: none`,
  fixture is not sample data (starts empty), tile status is static text
  in all three languages.
- `test/goldens/goals_golden_test.dart` — the same cell matrix every
  shipped family uses (light/dark, en/ur/ar, phone/landscape/wide, 200%
  text), plus state goldens (empty, one goal, several, over-target,
  no-target-date).
- A web-reference capture set for a value/structural parity test
  (`goals_parity_test.dart`, mirroring `installments_parity_test.dart`),
  holding the reference's own header/summary/list figures to the
  corrected values named in §3.
