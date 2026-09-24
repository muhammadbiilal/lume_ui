# Meal Plan — proposal, and the approved model

**Status: approved for implementation under `ROLLOUT_WAVE_6.md`'s
authorisation, 2026-09-24.** Short proposal, matching `GOALS_PROPOSAL.md`'s
scope and depth. §5 is the decision table; §6 the approved model.

## 0. Source inventory

| file | what it holds for Meal Plan |
|---|---|
| `assets/js/tools/personal/mealplan.tool.js` (45 lines) | the whole screen: `build(c)`, the only function |
| `assets/js/tools/context.js` `mealPlan()` (l. 1646–1666) | the data: a 7-day rotation through 6 fixture recipes, and five fabricated headline figures |
| `assets/js/data/tool-data.js` `RECIPES` (l. 797) | the 6-recipe fixture the rotation draws from — shared with `recipes.tool.js`, not part of this tool's own scope |
| `assets/js/data/catalogue.js` l. 172 | `{ id: 'mealplan', n: 'Meal Planner', i: 'i-calendar', c: 'personal', g: 'personal', m: 'This week', act: '', kw: 'food menu week' }` |
| `assets/js/data/tool-specs.js` l. 250–251 | `a: 'planner', d: 'high', aware: 'units locale', supports: 'search offline export', src: 'On device', fresh: 'local', rel: ['recipes', 'shopping', 'expenses']` — the spec's own `src: 'On device'` frames this as local data, unlike Recipes' separately-declared `src: 'Recipe library'` |
| `assets/js/i18n/tools.js` l. 258, 986–989 | 13 `meal.*` strings, **English only** — no `ur`/`ar` entries anywhere |
| `assets/js/data/record-schemas.js` | **no Meal Plan schema** |
| Flutter today | `feature_catalogue.dart` placeholder entry only; one inbound "related tool" nav row from the already-built Recipes screen, nothing on the other end; no `lib/features/mealplan/` |

**There are no CRUD actions in the reference at all** — not even a
`toast:` stub. The only two controls are real inter-tool navigation
(`tool:shopping`, `tool:recipes`); the day-accordion open/close is a pure
client-side visual toggle with no `act:`.

## 1. What it models, and what changes

A **weekly meal schedule**: which meal, if any, the reader plans for each
of seven days' breakfast/lunch/dinner. The reference has no such thing —
it rotates through a 6-item fixture and reports five numbers that are
typed constants, unconnected to the rotation shown beside them
(`kcal: 1980` doesn't even match the real day-sums the reference's own
`kcalByDay` computes from the fixture). Converting it means building the
one thing the reference never had: a reader can actually write down what
they're eating each day. The composition — summary card, then the week's
seven days, then the two navigation buttons — is reproduced exactly.

## 2. Typed model — proposed

```dart
enum MealSlot { breakfast, lunch, dinner }

class MealPlanEntry {
  final LumeRecordId id;
  final LumeDate date;      // a specific calendar day, not "day 3 of a template"
  final MealSlot slot;
  final String text;        // what the reader plans to eat — free text, no nutrition data
  final DateTime createdAt;
  final int version;
}
```

One flat collection, no aggregate parent, no money — simpler than every
wave 5 family. At most one active entry per `(date, slot)`; writing to an
already-filled slot replaces its text rather than creating a second entry
for the same slot (an upsert, not an open-ended list the reader adds to —
the 21 slots always exist, only their content is optional).

**Derived, never stored:**

```text
filled       = count of (date, slot) pairs in the visible week with a
               non-empty entry — real, replacing the reference's
               `planned: 18` literal
week         = the 7 calendar days from the reader's today, matching the
               reference's own window (today plus the next six)
```

No `kcal`, `shopItems`, or `cost` field exists anywhere in this model —
not stored, not derived, not displayed. Nothing here claims a nutrition
or cost figure the reference itself never actually computed either.

## 3. Screen composition — proposed, in the reference's order

1. **Summary card** — kicker "This week", value "{filled} / 21", caption
   "meals planned" (real count, replacing `planned: 18`). No stat chips —
   the reference's three (avg kcal, shopping items, est. cost) are all
   dropped per §2; nothing honest replaces them without inventing a
   feature the reference doesn't have.
2. **The week** — seven expandable days (today open by default, matching
   the reference), each showing its three slots (breakfast/lunch/dinner).
   A filled slot shows its text; an empty one shows a placeholder
   inviting entry. Tapping any slot opens a small sheet to type, edit, or
   clear its text.
3. **Button row** — "Build a shopping list" (`tool:shopping`) and "Browse
   recipes" (`tool:recipes`), both kept exactly as the reference has them
   — genuine navigation, already functional, untouched.
4. **Empty state** — the reference has none (its fixture always has
   content); a reader with nothing filled sees the week's 21 empty slots
   rather than a separate empty-state screen, since "nothing planned yet"
   is just every slot being empty, not an absent collection.

## 4. CRUD — proposed

- **Set a slot's text**: tap a slot, type, save — upserts the one entry
  for that `(date, slot)`.
- **Clear a slot**: an explicit clear action in the same sheet — deletes
  the entry if one exists.
- No separate "add"/"delete a day" — days and slots are fixed structure,
  not records the reader creates or removes.

## 5. Decisions requiring approval

| id | decision | recommendation |
|---|---|---|
| D-M1 | Scope | **reader-entered scheduling only** — the owner's explicit choice (`ROLLOUT_WAVE_6.md` §0), over waiting for a verified nutrition database |
| D-M2 | The calorie chart and the three summary stats | **dropped entirely** — none can be honestly produced without either inventing a value the reference never asked the reader for, or a nutrition source this repo doesn't have |
| D-M3 | Which week is shown | **today plus the next six days**, matching the reference's own window, anchored to real calendar dates rather than a template day-index |
| D-M4 | Home eligibility | **no** — matches every personal record family's default; the reference's own spec has no `home` flag either |
| D-M5 | Sensitivity | **not sensitive** — a meal plan is not a category `RELEASE_HONESTY.md` treats as sensitive, and the reference sets no `sens` flag |
| D-M6 | Export | **not in v1** — the reference declares `supports: 'export'` but the tool itself has no export UI; not claiming a capability that doesn't exist yet |
| D-M7 | Tools tile status | **states a purpose** ("Plan your week's meals"), not the reference's stale "This week" |

## 6. Approved model (final)

Sections 0–5 are the proposal and stand as the approved model — no
further correction round before implementation, per this wave's
authorisation. §7 is what implementation must produce.

## 7. Evidence to produce

- `mealplan_domain_test.dart` — model/codec round-trip, upsert semantics
  (setting an already-filled slot replaces rather than duplicates),
  filled-count correctness, clearing a slot, delete/undo.
- `mealplan_screen_test.dart` — empty week, filling a slot, editing a
  filled slot, clearing a slot, the two navigation buttons still work,
  Urdu.
- `mealplan_catalogue_test.dart` — off Home, fixture starts empty
  (`readerRecords`), tile status is static text in all three languages.
- `test/goldens/mealplan_golden_test.dart` — the standard cell matrix,
  plus state goldens (all-empty week, partially filled, fully filled).
