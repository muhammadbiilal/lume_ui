# Wave 6 discovery — provisional, gate not lifted

**Status: discovery only. Not an approved wave.** `ROLLOUT_WAVE_5.md` §5
reads: *"Closure does not reopen §8 further than the scope in §0 — a
sixth wave is a new decision, not an inference from this one."* That
condition stands. This document is the research a sixth-wave decision
would be made from, produced because it was asked for, not because the
gate moved.

## 0. Where wave 5 left the count

| | |
|---|---:|
| tools in the catalogue | **85** |
| registered after wave 5 | **39** (37 + `goals`, `subs`) |
| unbuilt | **46** |

`ROLLOUT_WAVE_4.md` §5's blocker taxonomy already covers all 46 by
reading each one's actual source. This document does not re-derive that
survey; it re-checks whether anything has changed since, and finds a
single tool — Meal Plan — that clears the way Goals/Subscriptions did:
blocked on one product decision, not on sourcing, permissions, or a
medical/religious ruling.

## 1. Meal Plan — the candidate

**Source read in full**: `assets/js/tools/personal/mealplan.tool.js` (45
lines) and its data function `mealPlan()` in `context.js:1646-1666`.

### 1.1 What's real, what's fabricated

The reference is a hybrid, more precisely than the discovery doc's
earlier one-line summary suggested:

| element | status | evidence |
|---|---|---|
| The 7-day list, each day's breakfast/lunch/dinner slot, and the recipe assigned to each | **real** — rotates through a 6-item static recipe list (`D.RECIPES`, `tool-data.js:797`) by `i % 6`, `(i+2) % 6`, `(i+4) % 6` | `context.js:1650-1658` |
| `kcalByDay` (the bar chart's values) | **real** — `.reduce()` sum of each day's three assigned meals' actual kcal | `context.js:1662-1664` |
| `planned: 18`, `slots: 21`, `kcal: 1980`, `shopItems: 24`, `cost: 96` (the summary card's five headline figures) | **fabricated** — bare literals, no computation. `kcal: 1980` doesn't even agree with the real day-sums it sits beside (those run roughly 1050-1590 given the actual recipe kcal values) | `context.js:1661`, cross-checked against `tool-data.js:797`'s six recipes |

### 1.2 Interactions

Zero CRUD of any kind — not even a `toast:` stub. The only two controls
are real inter-tool navigation (`tool:shopping`, `tool:recipes`); the
day-accordion open/close is a pure client-side visual toggle with no
`act:` at all. This is a **read-only display of hardcoded/rotated data**,
less interactive than Goals or Subscriptions were before wave 5 (both of
which had at least a toast stub on their primary action).

### 1.3 No record schema, no existing Flutter feature

`record-schemas.js` has no `mealplan` entry (confirmed by direct grep —
no matches). `lib/features/mealplan/` does not exist; only a catalogue
placeholder (`feature_catalogue.dart`) and one inbound "related tool" nav
row from the already-built Recipes screen point at an id with nothing on
the other end.

### 1.4 The one decision this needs

`tool-specs.js:250` declares Meal Plan `src: 'On device'` — the spec's
own framing already treats it as local data, unlike the adjacent Recipes
spec (`tool-specs.js` next entry), which declares `src: 'Recipe library'`
— textually marking Recipes, not Meal Plan, as the one that needs a
licensed source. That split is the decision:

- **Reader-entered scheduling** (a meal-slot → free-text-or-linked-recipe
  calendar, no kcal/cost claims): clears today, on-device, no new
  sourcing — the same shape as Shopping/Reminders' existing record
  families.
- **Verified nutrition-database integration** (real kcal/cost per meal):
  is a Blocker-3/4 problem — it needs a licensed nutrition data source,
  which nothing in this repo currently has, and would need its own
  sourcing decision before any model work starts.

Only the first path is buildable without a new external dependency. This
mirrors exactly the persistence-path decision Wave 5 needed before
Goals/Subscriptions could be scoped — a real product decision, not
something this document can settle on its own.

### 1.5 Recipes — a dependency, not part of this candidate's scope

Meal Plan's day rotation and "Browse recipes" button both point at the
Recipes tool, which is **already built** in Flutter
(`lib/features/recipes/`). Recipes' own reference is itself a stub (every
row tap is `toast: + name`, no detail view, `tool-specs.js` marks it
`fresh: 'static'` off a `'Recipe library'` source that doesn't exist yet)
— but Recipes already shipped in a prior wave with that limitation
accepted, so improving it is a separate decision from Meal Plan's, not a
prerequisite for it.

## 2. Everything else — confirmed still blocked, nothing has changed

Re-checked directly rather than assumed current:

- **Reminders** (the closest of Blocker 5): its record schema is
  unchanged at `record-schemas.js:196-241` since Wave 4 documented it.
  The repo has gained **no** local-notification or permission
  infrastructure since — `pubspec.yaml` has no `flutter_local_notifications`,
  `permission_handler`, or equivalent; `lib/features/notifications/` is
  an in-app inbox/banner UI over fixture data, not an OS-level scheduler.
  Still blocked on the same thing Wave 4 named: "a reminder that never
  fires is a promise the build cannot keep."
- **Alarms**: has no record schema at all (confirmed by grep) and no
  client-side persistence — further from buildable than reminders, not
  closer.
- Blocker 3 (licensed source: mosques, natsavings, packages, passport),
  Blocker 4 (live feed: currency, markets, fuel, and 8 others), Blocker 6
  (medical: bmi, cycle, pregnancy, health, vaccines), and Blocker 7
  (religious source: all 14 Islamic tools) are unchanged — none of these
  are decisions a coding wave can resolve on its own; each needs a
  sourcing, licensing, medical, or religious-ruling decision made outside
  this repo first.
- Habits and Streak remain excluded for the reason `WAVE_5_DISCOVERY.md`
  §1 already gave: their gap is the data model, not just storage, and the
  Option B persistence path chosen for Wave 5 doesn't close it.

## 3. Proposed wave 6 scope, if the gate is reopened

**One tool: `mealplan`**, scoped to reader-entered scheduling only. Not
inflated to hit a count — every other unbuilt tool needs a decision
outside this document's reach (sourcing, licensing, a permission/platform
integration this repo has no infrastructure for yet, or a medical/
religious ruling).

If approved, the process matches Wave 5's: a short `MEALPLAN_PROPOSAL.md`
(full source inventory already gathered above, typed record model, the
CRUD the reference never had at all, reference defects named, decision
table) before any code, then implementation, then the same integrated
gate wave 5 closed on.

## 4. What this document is not

It is not an authorisation. `ROLLOUT_WAVE_4.md` §8 and `ROLLOUT_WAVE_5.md`
§5 both stand: a sixth wave needs its own explicit decision, the same way
Wave 5's gate was reopened on the record rather than inferred. The
specific decision this candidate needs — reader-entered scheduling vs. a
nutrition-database path — is the reader/owner's to make, not something
this document settles.
