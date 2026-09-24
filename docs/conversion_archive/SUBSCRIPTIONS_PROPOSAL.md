# Subscriptions — proposal, and the approved model

**Status: approved for implementation under `ROLLOUT_WAVE_5.md`'s
authorisation, 2026-09-24.** Short proposal, matching `GOALS_PROPOSAL.md`'s
scope. §7 is the decision table; §8 the approved model it resolves into.
Subscriptions is closer in shape to Installments than to Goals — a
recurring due date drives status — so its repository leans on
`installments_book.dart`'s schedule/status pattern rather than Baby
Budget's one-off-spend shape.

## 0. Source inventory

| file | what it holds for Subscriptions |
|---|---|
| `assets/js/tools/personal/subs.tool.js` (62 lines) | the whole screen: `build(c)`, the only function |
| `assets/js/tools/context.js` `subscriptions()` (l. 1387–1405) | the data: five fixture subscriptions and every derived figure |
| `assets/js/data/tool-data.js` `SUBSCRIPTIONS` (l. 763–769) | the five seed subscriptions: `name, cat, price, cycle, renews, days, logo, tone` |
| `assets/js/data/catalogue.js` l. 187 | `{ id: 'subs', n: 'Subscriptions', i: 'i-refresh', c: 'personal', g: 'personal', sens: 1, ints: ['expenses'], m: '6 active', act: '', kw: 'netflix spotify recurring monthly' }` — **`m: '6 active'` disagrees with the seed's 5 subscriptions** |
| `assets/js/data/tool-specs.js` l. 284–286 | `a: 'manager', d: 'high', aware: 'currency locale timezone', sensitive: 1, supports: 'search filters sorting notifications history export', src: 'On device', fresh: 'local', home: 1, rel: ['expenses', 'bills', 'installments']` — note "filters" and "history" are claimed but no filter UI or history view exists in the reference; only search and sort are real |
| `assets/js/i18n/tools.js` l. 868–871, 485–486 | 14 `subs.*`/`n.sub.*` strings, **English only** — no `ur`/`ar` entries |
| `assets/css/` | **no `.sub`/`.subs`/`subscription` rules anywhere** — the tool reuses generic `.summary`, `.rrow`, `.donutwrap`, `.timeline` components wholesale |
| `assets/js/data/record-schemas.js` | **no Subscriptions schema** |
| Flutter today | `feature_catalogue.dart` entry (mirrors the row above, `homeEligible: true`, `notifications` declared) and a minimal `LumeSubscriptionRenewal {name, renewsOn, days}` used only by Home's "Upcoming" card — no `lib/features/subscriptions/` directory, no price/cycle/category modelled anywhere yet |

**There are no CRUD actions in the reference at all** — not even a
`toast:` stub. Search and sort are real (client-side, over the fixed
array). Tapping a row fires `toast:` + the subscription's name and does
nothing else. There is no add, edit, cancel or delete affordance
anywhere in the tool.

## 1. What it models, and what changes

A **recurring subscription**: a name, an amount, a billing cycle, and a
renewal date. The reference has no persistence and no CRUD — search and
sort over a static list is the entire feature. Converting it to a real
record family means the reader can add, edit and cancel a subscription,
none of which the reference lets them do at all (not even as a dead
button — this tool has zero creation-intent copy to reproduce, unlike
Goals). The composition below — summary card, search, sort, list, donut,
timeline — is reproduced exactly; what's added is the CRUD the reference
never had in the first place.

## 2. Typed model — proposed

```dart
enum SubscriptionCycle { monthly, yearly, custom }   // custom: an explicit day count, typed for later; only monthly/yearly seen in the reference
enum SubscriptionState { active, cancelled }

class Subscription {
  final LumeRecordId id;
  final String name;
  final String? category;         // free text in the reference ("Entertainment", "Music", ...) — kept free text, not an enum, since the reference never constrains it
  final LumeMoney amount;
  final SubscriptionCycle cycle;
  final int? customDays;          // only when cycle == custom
  final LumeDate startedOn;       // anchor date the renewal schedule is computed from — the reference has no equivalent (it hand-types renews+days independently, see §3); a reader must give a real anchor
  final SubscriptionState state;  // active → cancelled
  final DateTime cancelledAt;     // null while active
  final DateTime createdAt;
  final int version;
}
```

No `logo`/`tone` stored — same reasoning as Goals D-G6: decorative,
reader-assigned from a fixed palette or derived from the name's initial,
not a meaningful field to persist as reference data.

**Derived, never stored** (`subscriptions_book.dart`, following
`installments_book.dart`'s schedule/status shape):

```text
nextRenewal(sub)   = the next occurrence of startedOn's day-of-month/day-of-year
                     on or after today, following `cycle` — real date arithmetic,
                     not a hand-typed literal (the reference's own fatal gap, §3)
daysUntil(sub)     = nextRenewal(sub) − today, in days
monthlyEquivalent(sub) = amount if monthly; amount / 12 if yearly; amount × 30 / customDays if custom
monthlyTotal       = Σ monthlyEquivalent(sub) across active subscriptions, per currency
                     (refuse to sum mixed currencies in one figure — bucket by currency,
                     matching FINANCIAL_RECORD_FAMILIES.md's mixed-currency rule)
yearlyTotal        = monthlyTotal × 12
next               = the active subscription with the smallest daysUntil
byCategory         = Σ monthlyEquivalent grouped by category, for the donut
upcoming           = active subscriptions sorted by daysUntil, first 4, for the timeline
```

This directly replaces the reference's independently hand-typed `renews`
display string and `days` integer (§3) with one real computation from a
single stored anchor date — the honest version of what the reference's
own summary-card and donut arithmetic already assume is possible.

## 3. What the reference fabricates, and the correction

| reference behaviour | evidence | Flutter correction |
|---|---|---|
| `renews` (a display string, e.g. `"14 Sep"`) and `days` (an integer) are **two independently hand-typed literals per record** — nothing derives one from the other or from today's date | `tool-data.js:763–769`, confirmed no recurrence engine exists anywhere in the codebase | One stored `startedOn` + `cycle`; `nextRenewal`/`daysUntil` computed for real, every time, from the actual clock |
| Row-level "per month" label is shown unconditionally, including on the one Yearly item (`Domain renewal`, $14/yr shown as if $14/mo) | `subs.tool.js:49`, the value/label pair has no cycle-aware branch | The row shows the stored amount with its own cycle label ("$14/yr"), and the monthly-equivalent only in the aggregate figures, never mislabelling a yearly price as monthly |
| Catalogue badge says "6 active"; the seed has 5 subscriptions | `catalogue.js:187` vs `tool-data.js:763–769` | Tools tile states a purpose, not a count (matches Goals D-G10, Installments D-I14) |
| `tool-specs.js` claims `supports: 'filters ... history'`; neither exists in the tool | `tool-specs.js:284–286` vs `subs.tool.js` (no filter chips, no history view beyond the timeline) | Capability flags corrected to match what's actually built — filters not claimed unless added (see D-S6); "history" satisfied by the real cancelled-subscriptions list (§5), not invented separately |
| No `id`, no active/cancelled concept at all — "active" count is simply `list.length` | `tool-data.js` fields, `subs.tool.js:28` | Stable `LumeRecordId`; a real `SubscriptionState` so cancelling one doesn't require deleting its history |
| Tapping a row does nothing but toast the name | `subs.tool.js:50` | Real tap → detail view, matching every other list-family tool |
| No add/edit/cancel affordance of any kind | whole file | Real forms — see §5 |
| Strings are English-only | `i18n/tools.js`, no `subs.*`/`n.sub.*` in `ur`/`ar` | Full translation, all three languages |

## 4. Screen composition — proposed, in the reference's order

1. **Summary card** — "Every month" / monthly total (per currency, see §2),
   "{amount} a year" caption, three stats: active count, next renewal
   name, days until it renews.
2. **Search bar** — kept, filters by name + category, exactly as the
   reference does.
3. **Sort bar** — kept, three options: renewal (default), amount, name.
4. **Subscription list** — one row per subscription: logo/initial, name,
   category, cycle + "renews {date}" (computed, not typed), a warn badge
   when `daysUntil ≤ 7`, trailing amount with its own cycle label.
   **New: tappable**, opening a detail view (the reference's row tap is a
   dead toast).
5. **Subscription detail** (new — the reference has none): the same
   figures for one subscription, edit and cancel actions.
6. **"By category" donut** — kept, now fed by `byCategory` computed over
   real records instead of the fixed five-item array.
7. **"Coming up" timeline** — kept, now the real `upcoming` derivation.
8. **Button row**: "Add a subscription" (new — the reference has no
   creation affordance whatsoever, live or stubbed).
9. **Empty state** (new — the reference has none; with zero subscriptions
   `s.next` would throw in the original JS, confirming it was never
   exercised): the standard `LumeToolState` empty pattern, "Add a
   subscription" as its action.
10. **On-screen disclosure** (Option B): "Subscriptions are cleared when
    you close Lume", visible on the summary card, matching Goals.

## 5. CRUD — proposed

- **Add**: name, category (free text, optional), amount + currency,
  cycle (monthly/yearly/custom + day count), start date (defaults to
  today). Starts `active`.
- **Edit**: any field, at any time — no locked-after-use rule; a
  subscription's price or cycle genuinely can change (a plan changes
  price), and nothing in the reference suggests otherwise.
- **Cancel**: `active → cancelled`, keeps history, excluded from
  `monthlyTotal`/`upcoming`/donut but still visible in a "Cancelled"
  filter (see D-S6) — never a delete.
- **Delete**: removes the subscription entirely, with Undo.

## 6. Persistence, privacy, localisation, coverage

- **Option B, unchanged** — the same `LumeMemoryRecordRepository` wrapped
  in a typed `SubscriptionsRepository`. No persistence package. The
  on-screen disclosure in §4.10 is not optional.
- **Sensitive**: `sens: 1` kept — off Home despite the reference's
  `home: 1` (D-S1), out of notifications by default.
- **Localisation**: full `en`/`ur`/`ar`, correcting the reference's
  English-only gap. RTL mirroring for the donut, timeline and rows.
- **Coverage**: dark mode, phone/landscape/wide, 200% text, keyboard and
  screen-reader labelling for the donut and warn badges — same bar as
  every shipped family, verified the same way.

## 7. Decisions requiring approval

| id | decision | recommendation |
|---|---|---|
| D-S1 | Home eligibility | **no** — sensitive financial record stays off Home, despite the reference's `home: 1` |
| D-S2 | Renewal computation | **derive `nextRenewal`/`daysUntil` from a stored anchor date + cycle**, never hand-typed literals — this is the tool's central correction (§3) |
| D-S3 | Mixed currencies | **per-currency summaries**, never summed across currencies in one figure, matching `FINANCIAL_RECORD_FAMILIES.md`'s rule and Installments D-I10 |
| D-S4 | Cycle types in v1 | **monthly, yearly, and a typed custom-day-count option** — the reference only shows monthly/yearly, but a subscription with neither is common enough (weekly trials, 90-day passes) to type now rather than force into the wrong bucket |
| D-S5 | Row "per month" mislabel (Yearly items) | **corrected** — show the stored cycle's own label; monthly-equivalent appears only in aggregates (§3) |
| D-S6 | Cancelled-subscriptions visibility | **a filter, not a separate screen** — "Active" (default) / "Cancelled" / "All", satisfying the capability spec's "history" claim honestly instead of dropping it silently |
| D-S7 | Export | **yes**, JSON + CSV, reusing the existing transfer pattern |
| D-S8 | Notifications | **not in v1** — a Dayroz obligation, matching Installments D-I11 and Goals D-G9 |
| D-S9 | Tools tile status | **states a purpose** ("Track recurring subscriptions"), never a count |

## 8. Approved model (final)

Sections 0–7 are the proposal and stand as the approved model — no
further correction round before implementation, per this wave's
authorisation. §9 is what implementation must produce.

## 9. Evidence to produce

- `subscriptions_domain_test.dart` — model/codec round-trip, renewal-date
  arithmetic across monthly/yearly/custom cycles (including month-end
  clamping, matching Installments' own due-date rule), `byCategory`/
  `monthlyTotal`/`upcoming` derivations, currency-mixing refusal.
- `subscriptions_screen_test.dart` — add/edit/cancel/delete, search,
  sort, the Cancelled filter, empty state, Undo, validation.
- `subscriptions_catalogue_test.dart` — sensitive, off Home,
  `outbound: none`, fixture starts empty, tile status is static text in
  all three languages.
- `test/goldens/subscriptions_golden_test.dart` — the standard cell
  matrix, plus state goldens (empty, several active, one overdue/warn,
  mixed currencies, cancelled filter).
- A web-reference capture set for `subscriptions_parity_test.dart`
  mirroring `installments_parity_test.dart`'s structure, holding the
  reference's own header/summary/list figures to the corrected values in
  §3.
