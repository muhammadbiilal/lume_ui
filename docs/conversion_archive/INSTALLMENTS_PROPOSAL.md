# Installments — proposal, and the approved model

**Status: approved, 19 September 2026.** Sections 0–39 are the source audit
and the proposal as submitted. They are kept as written, because they record
what the reference does and why. **§40 is the approved model and overrides
anything earlier it contradicts** — search, the filters and sorts, deposit
dates, payment voiding, locked fields, redaction on export, and the
day-unavailable state. §41 lists the reference defects the build corrects,
and §42 the obligations left for later. No financial formula is taken from
outside the source, and none is invented.

## 0. Source inventory

| file | what it holds for Installments |
|---|---|
| `assets/js/tools/money/installments.tool.js` (72 lines) | the whole screen: `build(c)`, the only function |
| `assets/js/tools/context.js` `installments()` (l. 976–1010) | the data: three fixture plans and every derived figure |
| `assets/js/tools/context.js` `relDate`, `filter`, `sortState`, `sortBy`, `sortItems`, `money` | the date, filter, sort and money helpers the screen calls |
| `assets/js/services/locale.js` `money`, `tidy`, `RATES`, `currencyCode` | USD-authored figures converted at an approximate rate and rounded for display |
| `assets/js/data/catalogue.js` l. 143 | `{ id: 'installments', n: 'Installments', i: 'i-calendar', c: 'money', g: 'money', ints: ['expenses'], m: '3 running' }`; not `sens` |
| `assets/js/data/tool-specs.js` l. 190 | `a: 'manager', d: 'high', aware: 'currency locale', supports: 'filters sorting notifications history', src: 'On device', fresh: 'local', rel: ['loan', 'expenses', 'subs']` |
| `assets/js/tools/registry.js` l. 71, 163 | registration |
| `assets/js/i18n/tools.js` l. 236–241, 691–694 | the 18 `inst.*` strings, in **English only** |
| `assets/js/data/record-schemas.js` | **no Installments schema**; no family, no fields, no validation |
| `assets/js/services/notify-engine.js` | **no Installments source**; the `notifications` support flag is drawn only on archetype fallback screens (`engine.js` `contractCard`), which Installments never uses |
| `assets/js/tools/engine.js` | frame: source bar, related tools; privacy note only for `sens` tools (not this one) |
| `assets/css/tools/shared.css` | `.rrow*`, `.rowmeter` (l. 306), `.tline*` (l. 766–797), `.bars*` (l. 680–689) |
| Flutter today | `feature_catalogue.dart` entry (as above, generated); `featureInstallments`, `toolStatusInstallments` ("3 running"); SCREEN_MATRIX row "not started" |

There are **no actions** in the source: no add, edit, pay, delete, share,
export or import. The only interactions are the filter chips, the sort chips
and the empty state's "All" action (`toolstate:installments:state:all`).

**Reference states driven** (`measure_destinations.mjs --tool installments`,
frozen at 7 September 2026, 16:41; the captures are kept outside the
repository with the closure report):

- default (Running, sort Remaining ↑);
- Finished, the empty state;
- All;
- sort by Amount ↓ and by Progress ↑;
- scrolled to 600 and to 1100;
- Urdu and Arabic;
- dark;
- US, GB and JP;
- 1100×900 and 852×393.

A 200% text cell cannot be driven in the browser.

## 1. Screen composition and section order

Measured at 390×844, light, English, default_pk:

| # | section | y | content |
|---|---|---:|---|
| — | header | — | "Installments", subtitle "Records manager", **no header actions** |
| 1 | summary card | 114 (h 185) | kicker "Monthly commitment"; value Rs 58,000; caption "3 plans running"; stats "Rs 427,000 · Remaining", "Rs 298,000 · Paid so far", "14 Sept · Next payment" |
| 2 | filter bar | 323 (h 33) | Running 3 · Finished 0 · All 3 |
| 3 | sort bar | 380 (h 23) | Sort: Remaining ↑ (on) · Amount · Progress |
| 4 | "Active plans" | 427 (h 288) | one rich row per plan (tinted initials disc, item, merchant, meta "instalment {paid} of {total} · next {date}", value "{monthly}" over "a month"), each with a progress meter beneath (`.rowmeter`) |
| 5 | "Schedule" | 739 (h 162) | timeline, one item per plan: its next date, item, merchant, monthly; the first fixture item is `is-now` |
| 6 | "Monthly commitment" | 925 (h 204) | six-bar chart, month initials (S O N D J F), first bar highlighted; caption "Currently Rs 58,000 a month, falling as each plan finishes." |
| 7 | "History" | 1153 (h 197) | compact rows: item, "{n} payments made", monthly × paid |
| — | source bar | — | "Stored on this device" · "On device" |
| — | related tools | — | Loan / EMI · Expenses · Subscriptions |

No privacy note: the catalogue does not mark Installments sensitive. There is
no "add" button anywhere.

**Proposed composition (C-entry on build):** the same order, with an
"Add a plan" primary action where the reference has none (the Ledger's
placement, under the plans list), a plan detail view, forms, and the
states in §37.

## 2. Domain terminology

| term | source | meaning |
|---|---|---|
| plan | `plans[]`, "Active plans" | one purchase paid off in instalments |
| item / merchant | `item`, `merchant` | what was bought, and from whom |
| instalment | "instalment {a} of {b}" | one scheduled payment |
| monthly | `monthly`, "a month" | the amount of each instalment |
| total | `total` | **the number of instalments**, not an amount |
| paidCount | `paidCount` | how many instalments are paid |
| next | `next` | the next instalment's date |
| monthly commitment | summary kicker | the sum of every plan's instalment amount |
| remaining / paid so far | stats | amount still to pay / already paid |
| running / finished | filters | `paidCount < total` / `paidCount >= total` |

The source spells "Installments" (tool name) and "instalment" (the unit).
**Proposed:** keep the catalogue name and use "instalment" for the unit, as
the source does. Both are British English, which `en` already uses
elsewhere.

## 3. What it models

**Purchases paid in equal instalments to a merchant: the reader is the
payer.** The evidence is the fields (item, merchant, logo), the direction
(only "paid so far"), "a month" and the related tools (Loan / EMI,
Expenses, Subscriptions).

It is **not**:

- a loan: there is no principal, rate, lender or disbursement;
- a receivable: nothing is owed to the reader;
- a generic payment plan: the frequency is always monthly.

**Proposed:** model reader-payable purchase plans only. Receivables stay
in Ledger, and loans (EMI calculation) stay in Loan / EMI.

## 4. Typed plan model — Proposed

```
InstallmentPlan {
  id: LumeRecordId
  item: String (1–80, trimmed)            // source: item
  merchant: String? (≤80)                 // source: merchant
  currency: LumeCurrency (active)         // one currency per plan
  instalment: LumeMoney                   // source: monthly — the regular amount
  count: int (1–600)                      // source: total
  frequency: monthly                      // source: "a month" only (§14)
  firstDue: LumeDate                      // not in source; needed to derive every `next`
  deposit: LumeMoney?                     // not in source (§9) — decision D-I4
  note: String? (≤500)
  status: active | cancelled              // completed is derived (§11)
  cancelledOn: LumeDate?
  createdAt / updatedAt / version         // record envelope
}
```

Tone and initials are presentation, derived as in Ledger (the fixture's
`logo: 'TM'` and `tone` are fixture fields).

## 5. Typed instalment and payment model — Proposed

The source has only a count, `paidCount`, and treats instalments as paid
strictly in order. The smallest model that keeps that meaning and gives
each instalment a stable identity:

```
ScheduledInstalment {                     // generated once, stored (§8)
  id: LumeRecordId, planId, n: 1..count,
  due: LumeDate, amount: LumeMoney
}
InstalmentPayment {
  id: LumeRecordId, planId, instalmentId,  // pays exactly one instalment
  paidOn: LumeDate, amount: LumeMoney,     // = the instalment's amount (§11)
  voided: bool, note: String?
}
```

`paidCount` is then *derived*: the number of instalments with a live
payment.

Partial payments, one payment spanning several instalments, and credit
are **not** in the source (§11, §12, §17, §18).

## 6. Money and currency

- Integer minor units via `LumeMoney` and `LumeCurrency`, as Ledger does,
  with the same bounds: 10¹⁵ per amount and 2⁵³−1 per sum, with typed
  overflow.
- **One currency per plan** (Proposed). Summaries are per currency, never
  converted. The reference authors amounts in USD and converts them at
  `RATES`; nothing of that survives into stored data.
- New plans default to the reader's currency through `LumeCountryCurrency`,
  so a Bulgarian reader gets EUR. Withdrawn codes decode but are never
  offered.

## 7. Principal, markup, fees and total payable

**The source contains none of these.** It has one amount per plan, the
instalment, and a count. Everything it shows is arithmetic on those two:

- remaining = instalment × (count − paidCount)
- paid = instalment × paidCount
- implied total payable = instalment × count, which is never displayed.

**Determination: the calculations are fixtures pretending to calculate a
fixed equal payment.** In the reference:

- There is **no zero-interest division**: no principal is divided.
- There is **no flat markup** and **no reducing-balance interest**: there
  is no rate.
- There is **no variable final payment**: every instalment equals
  `monthly`.
- Each plan is a **fixed payment**, in the sense that every instalment is
  the same stored figure.

The figures are USD fixtures, converted and rounded separately for display
(§38).

**Proposed:** store what the reader is quoted, the instalment and the
count, exactly as the source does. Optionally also store the price as
**informational** fields:

- `cashPrice`;
- `fees`, as a single amount.

Lume would show the difference between instalment × count and the cash
price as "Cost of paying in instalments". That is a subtraction of the
reader's own numbers, not a rate. No interest or markup formula is
introduced. Decision D-I2.

## 8. Schedule generation — Proposed

The schedule is generated once at creation from `firstDue`, `count`,
`frequency` and `instalment`, then stored. It is regenerated only by an
explicit edit before any payment (§20).

- Instalment n is due at `firstDue` plus n−1 months, with day clamping (§15).
- Every instalment's amount is `instalment`.
- If D-I2 allows entering a *total* instead of the instalment, the split is
  floor(total ÷ count) per instalment, with the whole remainder of minor
  units on the **last** instalment (§13). This is an option only; the
  source has no total.

## 9. Deposit / down payment

**Not in the source.** **Proposed:** an optional `deposit` amount recorded
on the plan and paid on `firstDue` or before it (its own date). It is shown
in "Paid so far" and is not a scheduled instalment. It never changes the
instalment amount. Decision D-I4: include it, or leave it out of v1.

## 10. Due dates

- The source's `next` is `relDate(days)`: an offset from the device's wall
  clock, formatted "14 Sept". Its "Next payment" stat is a **hard-coded
  `relDate(7)`**, not the minimum of the plans' dates. It agrees with the
  earliest plan only by coincidence.
- **Proposed:** each instalment has a stored `LumeDate`, a calendar date
  with no instant. "Next" for a plan is its earliest unpaid instalment.
  "Next payment" in the summary is the earliest unpaid due date across
  active plans, per currency.

## 11. States: paid, pending, late, missed, partial, overpaid

The source has two plan states, running and finished, from `paidCount`
against `total`. It has no per-instalment state, apart from the timeline's
`is-now`, which is set on the first fixture item regardless of date.

**Proposed** per-instalment states, derived and never stored:

| state | rule |
|---|---|
| paid | a live payment references it |
| upcoming | unpaid, due after today |
| due today | unpaid, due today |
| overdue | unpaid, due before today |
| unknown | the reader's day cannot be worked out (zone unresolved) — neither due nor overdue, as in Ledger |

- **Missed** is not a separate state: an overdue instalment *is* missed
  until paid. A grace period is decision D-I6, and none is proposed.
- **Partial** and **overpaid** do not exist in the proposed v1. A payment
  records one instalment at its amount, so neither can arise. Allowing a
  different amount is decision D-I5.
- A plan is **completed** when every instalment is paid, and **cancelled**
  by the reader (§21). "Running" means active and not completed.

## 12. Payment allocation

**The source has none.** `paidCount` implies instalments are paid in
order, with no amounts and no dates.

**Proposed:** "Mark paid" records a payment against **the earliest unpaid
instalment**. This is the source's in-order meaning. The payment's date
defaults to the reader's today and its amount to the instalment's.

There is no FIFO spanning, no allocation records and no credit. **Ledger's
allocation engine is not reused** (§31): nothing in the Installments
source calls for it.

## 13. Rounding and final-instalment reconciliation

- The source rounds only for display (`tidy` per figure, after currency
  conversion). That is why its sums disagree (§38).
- **Proposed:** no rounding in stored data.
  - Every figure is a sum of stored minor units, so every displayed total
    equals the sum of its rows.
  - The final instalment differs from the others only if D-I2 allows
    splitting a total (remainder on the last).
  - Display formatting is exact (`LumeFormatting.amount`).

## 14. Frequency

The source is **monthly only** ("a month", `perMonth`, the monthly chart).
**Proposed:** monthly only in v1, with `frequency` kept as a typed field so
that weekly or fortnightly can be added later without a migration. Decision
D-I7.

## 15. Calendar-month boundaries

- The source's month labels come from `d.setMonth(d.getMonth() + m)` on
  today's date. On the 29th–31st this overflows (31 Jan + 1 month lands on
  3 March), so a label can skip a month (§38).
- **Proposed rule:**
  - The anchor day is `firstDue.day`.
  - Instalment n falls on that day in month firstDue.month + n − 1, clamped
    to the month's last day. For example 31 Jan → 28 Feb (29 in a leap
    year) → 31 Mar → 30 Apr.
  - The anchor never drifts, and each date is computed from `firstDue`,
    never from the previous date.

## 16. Time zone

- The source uses the device's wall clock (`new Date()`), not the reader's
  zone.
- **Proposed:** due dates are calendar dates with no zone. "Today" is the
  reader's calendar date in their resolved zone, as in Ledger
  (`LumeZoneResolution`). With no resolved zone, no instalment is due or
  overdue, and the Overdue filter says why. No test reads the wall clock.

## 17. Early payment

**Not in the source.** **Proposed:** marking the earliest unpaid instalment
paid before its due date is allowed, with `paidOn` before `due`. It is the
same action as an on-time payment. No discount or interest rebate is
computed, because none exists in the source.

## 18. Extra payment

**Not in the source.** **Proposed:** not in v1. An amount above the
instalment would need a rule for which instalments it pays and what the
excess becomes, and the source gives none. Decision D-I5.

## 19. Rescheduling

**Not in the source.** **Proposed:** there is no reschedule action in v1.
Before any payment, an edit may change `firstDue`, `count` or `instalment`,
and the schedule is regenerated with new instalment ids. After a payment,
§20 applies. A later "move the remaining dates" action is decision D-I8.

## 20. Editing after payments exist — Proposed

| field | before any payment | after a payment |
|---|---|---|
| item, merchant, note | editable | editable |
| instalment, count, firstDue, currency | editable (schedule regenerated) | **locked** — the reader voids the payments first, or cancels and starts a new plan |
| deposit | editable | editable only if the deposit itself is not yet recorded as paid |

A stale version is a typed conflict, and nothing is written.

## 21. Cancellation and deletion — Proposed

- **Cancel** keeps every payment and the schedule. The plan leaves
  "Running" and appears under a "Cancelled" filter. It no longer counts
  towards the monthly commitment, remaining or next payment, but its
  payments still count in "Paid so far". Cancellation can be undone.
- **Delete** removes the plan, its schedule and its payments in one
  transaction, after a destructive confirmation. Undo restores the same
  ids through `revert`.
- **Void** a payment: the instalment returns to unpaid. Restore brings back
  the same record.

## 22. Stable identity

Every plan, instalment and payment has a `LumeRecordId` and a version.

- Instalment ids survive every operation except a regeneration before any
  payment.
- Payments reference instalment ids, never an index or a date.
- Ids are never reused (the record layer's `_used`).

## 23. CRUD — Proposed

Actions:

- add a plan;
- view a plan (schedule, payments, figures);
- edit a plan (§20);
- mark the next instalment paid, which suggests Undo;
- void or restore a payment;
- cancel or reinstate a plan;
- delete a plan, with Undo.

Every write is one `LumeRecordTransactions.run`, with an idempotency key on
retries.

## 24. Validation and dirty state — Proposed

- **Plan fields:**
  - item: required, 1–80 characters;
  - merchant: at most 80 characters;
  - note: at most 500 characters;
  - count: 1–600;
  - instalment: above zero, within the currency's precision (never
    rounded), and no more than 10¹⁵ minor units;
  - the total (instalment × count) must stay within 2⁵³−1;
  - firstDue: a valid date;
  - deposit: at or above zero, in the plan's currency.
- **Digits:** Arabic and Urdu digits and separators are read exactly, as in
  Ledger.
- **Unsaved changes:** leaving a changed form asks Keep editing /
  Discard, as the record forms do. A failed save changes nothing and says
  so.

## 25. Search, filter and sort

- **Source:** filters Running / Finished / All, with counts. Sort by
  "Remaining" (key `next`, accessor `total − paidCount`: payments left,
  **not** the next date), Amount (monthly) and Progress (paid ÷ total).
  Tapping the active dimension flips its direction. The default is
  Remaining ↑. There is no search: the spec does not declare `search`, and
  the header has no search action.
- **Measured order:**
  - Remaining ↑ gives Sofa set (2 left), Laptop (7), Phone (15);
  - Amount ↓ gives Laptop, Sofa set, Phone;
  - Progress ↑ gives Phone, Laptop, Sofa set.
- **Proposed:**
  - Keep the three filters and add "Cancelled" (§21), counts included.
  - Rename the first sort "Payments left" and add "Next due" (earliest
    unpaid due date), which is what a reader expects "next" to mean.
    Decision D-I9.
  - The sort is stable, with ties broken by creation instant and then id.
  - No search in v1, because the spec does not declare one.

## 26. Summary calculations — Proposed, per currency

| figure | source | proposed |
|---|---|---|
| Monthly commitment | Σ monthly over **all** plans, finished included | Σ instalment over plans that are active and not completed |
| caption "{n} plans running" | `plans.length` — **all** plans | the count of running plans |
| Remaining | Σ monthly × (total − paid) | Σ unpaid instalment amounts of active plans |
| Paid so far | Σ monthly × paid | Σ live payments (+ deposits), every plan |
| Next payment | hard-coded `relDate(7)` | earliest unpaid due date across active plans |
| payoff chart | for m in 0..5: Σ monthly where paid + m < total | for each of the next six calendar months: Σ unpaid instalments due in that month |
| History | one row per plan: "{n} payments made", monthly × paid | the payments themselves, newest first, each with its date and amount |

With several currencies, the summary shows one block per currency, and the
chart shows the reader's currency with a note that other currencies are
listed separately. Decision D-I10.

## 27. Notifications and reminders — Proposed

- The source declares `notifications` but implements none: no notify-engine
  source and no reminder action.
- **Proposed v1:** no notifications. The Tools tile says what the tool is
  for, never a count ("3 running" is a fixture figure, like Ledger's old
  tile).
- An opt-in "due soon" notification is a Dayroz obligation. It needs a
  durable store and a scheduler, and it must never claim delivery: Lume
  schedules it, and the platform delivers it or does not. Decision D-I11.
- There is nothing to share. Unlike Ledger, a plan has no counterparty to
  remind.

## 28. Privacy and sensitivity

- The source does not mark Installments sensitive.
- CLAUDE.md §61 lists financial records as sensitive, and Ledger was made
  sensitive for that reason (D8).
- **Proposed:** `sensitive: true` and `outbound: none`, set through the
  catalogue generator's `DECISIONS`, as for Ledger.
  - It is kept off Home, Today, the hero and recommendations.
  - The privacy note reads "Private to you … never included in shared
    content". This is true: Installments shares nothing.
- Decision D-I1.

## 29. Import and export — Proposed

- The source supports neither: `export` is not in its supports, and there
  is no action.
- **Proposed v1:** export JSON `lume.installments/1`, lossless, and CSV
  with one row per instalment. Import is JSON, checked in full and applied
  all or nothing, in one transaction.
- These reuse Ledger's transfer pattern (§31). Adding `export` to the
  header is a departure from the reference. Decision D-I12.

## 30. Repository and transactions

- **Collections** (one scope): `installment_plans`,
  `installment_schedule`, `installment_payments`.
- **One transaction for each of:**
  - creating a plan with its schedule;
  - editing it, with regeneration;
  - a payment;
  - a void;
  - cancelling;
  - a delete, with Undo by `revert`.
- **Invariants,** checked on the staged state before commit:
  - every instalment belongs to a plan;
  - n is 1..count and contiguous;
  - dues are non-decreasing;
  - each instalment has at most one live payment;
  - a payment's plan, instalment and currency agree;
  - the paid amount equals the instalment amount (v1);
  - no sum overflows;
  - a completed plan has no unpaid instalment.
- A failed invariant rolls the whole write back. A record that can't be
  read becomes a listed defect, never dropped or repaired.

## 31. Reused from Ledger

These are proven by what the Installments source needs, not by "both
involve money":

| reused | why the Installments source needs it |
|---|---|
| `LumeMoney`, `LumeCurrency`, `LumeCountryCurrency`, `LumeFormatting.amount` | every figure is an amount in the reader's currency (`c.money`) |
| `LumeDate` | every `next` is a calendar date |
| `LumeRecordId`, the record envelope, the strict codec with defects | plans and instalments need stable identity once they are the reader's |
| `LumeRecordTransactions` (run, revert, idempotency) | a plan and its schedule are written together |
| projection-with-invariants (`LedgerBook` pattern) | the summary, chart and filters are all derived |
| reader's day from `LumeZoneResolution` | "next" and any due state are relative to today |
| filter bar, sort bar, rich row, progress bar, timeline, bar chart (C64-corrected), compact row, empty state | the composition's own widgets, all already converted |
| digit and separator parsing (`ledger_text` parse) | amount entry in en, ur and ar |
| transfer pattern: JSON envelope, CSV, all-or-nothing import | only if D-I12 is approved |
| `LumePrivacyNote` (`outbound: none`) | only if D-I1 is approved |
| deep link plus restoration through the session | the frame's contract for every tool |

**Not reused:**

- FIFO-by-obligation reconciliation, allocations, credit and
  overpayments;
- parties, direction and opposite principals;
- settle preview;
- the reminder and text sharer.

None of these appears in the Installments source.

## 32. Installments-specific behaviour

- Schedule generation with month-end clamping (§8, §15).
- In-order instalment payment (§12).
- Completion derived from the schedule.
- Cancellation that keeps its history (§21).
- The payoff projection by calendar month (§26).
- "Payments left" and "Next due" sorts.
- Per-plan progress by count (the source's `paidCount / total`).

**Proposed:** keep progress by count, as the source does. By amount is
identical in v1, because all instalments are equal.

## 33. Migration obligations

- **Nothing to migrate.** The reference stores no Installments data, and a
  Flutter reader has none: the tool is not started, and D11 applies (no
  seeding).
- The three fixture plans exist only as a test fixture, entered through
  the repository.
- **Dayroz:**
  - a durable, encrypted store implementing the transaction contract;
  - the three collections through the codecs;
  - a notification scheduler, if D-I11 is approved.

## 34. Localization and bidi

- The source has 18 `inst.*` strings, in English only. The Urdu and
  Arabic captures render them in English, laid out right to left. The
  caption then reads "plans running 3" and the meta items reverse order
  (§38).
- **Proposed:** every string in en, ur and ar, with Arabic's six plural
  forms for counts ("{n} plans running", "{n} payments left"). Estimate:
  roughly 90–110 strings including forms and errors.
- Amounts, dates and item names are bidi-isolated. Dates use the locale's
  format and digits.
- The sort direction arrow stays semantic: ascending is ascending in RTL.

## 35. Accessibility — Proposed

- Each plan row reads: item, merchant, "5 of 12 paid, next 14 September",
  "Rs 26,900 a month".
- Progress has a value ("42 percent paid").
- Filter chips announce their counts.
- The chart has a text alternative listing each month's commitment in the
  **reader's currency**. The source's titles are the raw USD numbers
  ("S: 205"; §38).
- Overdue is marked by an icon and a word, not colour alone.
- Every target is at least 44 points. The layout holds at 200% text.
- Focus order follows the composition.

## 36. Responsive layouts

Captured at 390×844, 1100×900 and 852×393; 700×900 is to be captured with
the build:

| width | layout |
|---|---|
| 390×844 | single column |
| 700×900 | the frame's medium layout (not yet captured) |
| 1100×900 | the frame's centred column |
| 852×393 | landscape phone, single column |

The captured widths draw the same sections in the same order. **Proposed:** the
plan detail uses the master-detail pane at expanded width, as Ledger
does.

## 37. Visual and state matrix — Proposed evidence

- **Reference composition: 8 cells,** with side-by-sides against the web.
  Parity is claimed only for the populated, filtered and empty-filter
  states.
  - 390×844: light, dark, ur, ar, and 200% text (no web capture: the
    browser cannot set text scale);
  - 700×900;
  - 1100×900;
  - 852×393.
- **States, Lume's own (about 26):**
  - first use (en, ur);
  - each of Running, Finished, Cancelled and All;
  - Finished empty;
  - each sort in both directions;
  - a plan's detail;
  - the schedule with paid, upcoming, due-today and overdue instalments;
  - a completed plan;
  - a cancelled plan;
  - several currencies;
  - add-plan form;
  - validation failure;
  - keyboard open;
  - mark-paid with Undo;
  - void payment;
  - edit locked after payment;
  - delete confirmation;
  - day unknown;
  - damaged scope;
  - loading;
  - storage failure;
  - export, and the import check (if D-I12).
- No pixel percentage is claimed as parity.

## 38. Reference defects

Measured or read in the source:

1. **Sums that disagree.** Every figure is USD × approximate rate, rounded
   on its own (`tidy`):
   - PKR: History rows add to Rs 297,800 but "Paid so far" says Rs 298,000.
     The three plans' remaining amounts add to Rs 427,100 but
     "Remaining" says Rs 427,000.
   - JPY: the rows add to ¥32,170 but "Monthly commitment" says ¥32,200.
   - USD: History adds to $1,053 but "Paid so far" says $1,050.
2. **"Next payment" is a constant,** `relDate(7)`, not derived from the
   plans.
3. **The "Remaining" sort orders by payments left,** under the key `next`.
4. **The caption counts every plan as running** (`plans.length`), and the
   monthly commitment includes finished plans.
5. **"Active plans"** stays the section title under Finished and All.
6. **"instalment 7 of 9" beside "next 19 Sept"** reads as if the 7th is
   next. Seven are paid, so the 8th is next.
7. **The schedule is one row per plan** (its next payment only). Its
   `is-now` marks the first fixture item whatever its date.
8. **History is not history:** per-plan totals with "{n} payments made",
   and no dates.
9. **Month labels overflow** at month end (`setMonth` on the 29th–31st),
   and "today" is the device clock, not the reader's zone.
10. **Chart bars never grow** (C64): all six bars draw at the 3-point
    minimum.
11. **The chart's accessible titles use raw USD figures** ("S: 205") while
    the caption shows Rs 58,000.
12. **English only in Urdu and Arabic:** 18 strings untranslated.
    Right-to-left layout of English text reorders it ("plans running 3").
13. **No way to add, pay, edit or delete.** A reader cannot record a plan.
14. **`notifications` is declared but not implemented.** The Tools tile's
    "3 running" is a fixture figure.
15. **Financial records not marked sensitive,** against CLAUDE.md §61.
16. **"Stored on this device"** over no store at all (C74; the parity
    flavor keeps it, and development and release say "Kept until you close
    Lume").

## 39. Decisions requiring approval

| id | decision | recommendation |
|---|---|---|
| D-I1 | Sensitive, with `outbound: none` | **yes** (§28) |
| D-I2 | Amount entry: instalment × count (source) · optionally a total split with remainder on the last · informational cash price and fees with "cost of paying in instalments" | **instalment × count, plus the informational cash price**; no rate of any kind |
| D-I3 | Model: reader-payable purchase plans only | **yes** (§3) |
| D-I4 | Deposit / down payment in v1 | **yes, optional, recorded not scheduled** |
| D-I5 | Partial, extra and over-payments | **not in v1**: one payment pays one instalment at its amount |
| D-I6 | Grace period before overdue | **none** |
| D-I7 | Frequency | **monthly only in v1**, typed for later |
| D-I8 | Rescheduling after a payment | **not in v1**; locked fields (§20) |
| D-I9 | Sorts: rename "Remaining" to "Payments left", add "Next due" | **yes** |
| D-I10 | Several currencies: per-currency summaries; the chart in the reader's currency | **yes** |
| D-I11 | Due-soon notifications | **not in v1**; a Dayroz obligation, opt-in, with no delivery claim |
| D-I12 | Export (JSON + CSV) and all-or-nothing JSON import | **yes**, reusing Ledger's transfer pattern |
| D-I13 | Cancellation keeps history; delete removes everything with Undo | **yes** (§21) |
| D-I14 | Tools tile status: purpose text, not "3 running" | **yes**, as for Ledger |
| D-I15 | Composition: add "Add a plan", a plan detail and a Cancelled filter to the reference's order | **yes**, recorded as a C-entry on build |

## 40. Approved model (final)

### 40.1 Classification

- **Sensitive**, with `outbound: none`: off Home, Today, the hero,
  recommendations and sensitive activity previews. No merchant, item,
  payment or balance leaves the tool. Set through the catalogue generator's
  `DECISIONS`, not a hand edit.
- The Tools tile states a purpose, "Track fixed payment plans", never a
  count.
- It starts empty. Sample plans exist only in tests, goldens, the
  visual-reference cells, and explicitly labelled development fixtures.

### 40.2 What a plan is

A fixed-payment plan quoted to the reader. Nothing is invented: no interest
rate, APR, flat markup, reducing balance, amortisation, penalty or exchange
rate.

**Stored:** the instalment amount, the count, the currency, the first due
date, the frequency (monthly only), an optional deposit with its date, and
an optional cash price.

**Derived:**

```text
scheduledTotal = instalmentAmount × instalmentCount
totalPayable   = deposit + scheduledTotal
paidToDate     = deposit + Σ active scheduled payments
remaining      = totalPayable − paidToDate
```

The cash price is informational. Its difference from the total payable is
shown as "Difference from cash price", never as interest or markup.

### 40.3 Stored records

Three collections through the record envelope and the transaction layer,
schema `lume.installments/1`:

| record | collection | fields |
|---|---|---|
| `InstallmentPlan` | `installments.plan` | id, item (1–80), merchant (≤80, optional), note (≤500, optional), currency, amountMinor, count (1–600), frequency `monthly`, firstDue, depositMinor + depositOn (both or neither), cashPriceMinor (optional), state `active`/`cancelled`, createdAt, version |
| `ScheduledInstallment` | `installments.schedule` | id, plan, seq (1..count), due, amountMinor, currency, createdAt, version |
| `InstallmentPayment` | `installments.payment` | id, plan, installment, amountMinor, currency, paidOn, state `active`/`voided`, createdAt, version |

Each decodes strictly. A record that fails is a typed defect, listed and
shown. It is never dropped or repaired. An unsupported frequency is reported
as `frequency:unsupported`, not read as monthly.

### 40.4 Deposit

Optional. It is money already paid, with its own date. It counts in total
payable and in paid to date. It is never instalment zero and never spread
across the schedule. A deposit larger than the total payable is refused.
Once any payment exists, the deposit is locked.

### 40.5 The schedule

It is generated once, when the plan is created, and stored. Every row has a
stable id.

- The due date of row n is the first due date's day, in the month n − 1
  months after the first due month, clamped to the month's last day. It is
  computed from the anchor each time, never from the previous row. For
  example, 31 Jan → 28/29 Feb → 31 Mar, and 30 Jan → end of Feb → 30 Mar.
- It uses `LumeDate` calendar arithmetic, with no durations and no clock.
- The count of rows equals the count, every amount equals the instalment
  amount, and there is no variable last row.
- A stored schedule is never recomputed. A calendar library that later
  changes cannot move a stored due date.
- Before any payment exists, an explicit edit of the terms replaces the
  schedule with new ids, in one transaction. That is the reader's edit, not
  a silent regeneration.

### 40.6 Payments

- One payment pays exactly one scheduled instalment, in full, at its amount.
- Payments are made in order. An earlier unpaid instalment is paid first,
  and the form names it.
- At most one active payment exists per instalment.
- A payment can be voided and restored. A restore is refused if the
  instalment has been paid again since.
- None of these exist: partial, extra or multiple-instalment payments,
  overpayment, a grace period, penalties, interest accrual or Ledger
  allocation.

### 40.7 Derived states

| state | rule |
|---|---|
| paid | one active payment references it |
| due today | unpaid, and due on the reader's local date |
| late | unpaid, and due before the reader's local date |
| upcoming | unpaid, and due after the reader's local date |
| completed (plan) | every instalment is paid |
| cancelled (plan) | the reader cancelled it; its history is kept |

Without the reader's day, no relative state is guessed. Rows show their
dates, the Late filter and "due this month" say the day is unavailable, and
nothing is marked late.

### 40.8 Locked fields

Once any payment exists, active or voided, the following are locked:

- the amount;
- the count;
- the currency;
- the first due date;
- the frequency;
- the deposit amount and date.

Item, merchant and note stay editable. To change locked terms, the reader
cancels the plan and adds a new one. Earlier payments are never rewritten.

### 40.9 The list

- **Filters:** Active, Late, Completed, Cancelled and All. All is the
  reference's own chip and its empty state's action. Each chip carries its
  count.
- **Sorts:**
  - Next due;
  - Payments left (the reference's mislabelled "Remaining");
  - Monthly amount;
  - Name;
  - Recent activity, from the plan's and its payments' creation instants.
- **Search** covers the item, the merchant and the note.
- Search, filter and sort never change the summaries.

### 40.10 Summaries

One summary per currency. Currencies are never added together. Each shows:

- due this month;
- paid to date;
- remaining;
- active plans;
- late instalments.

"Due this month" is the sum of the scheduled instalments of plans that are
not cancelled, due in the reader's calendar month, paid or not. It is not
each plan's amount added up. The plan count counts each plan once.

The reference's "Monthly commitment" chart becomes "Due by month": for each
of the next six calendar months, the instalments of plans that are not
cancelled that fall due in that month, in the reader's currency first. Its
screen-reader text names each month and amount in that currency.

### 40.11 Notifications

None in v1, in any flavor. The reference draws no notification control for
this tool, so nothing is reproduced. The `notifications` support flag is
removed through the generator's `DECISIONS`. A due-soon reminder is a
future typed delivery-adapter obligation (§42).

### 40.12 Cancellation and deletion

- **Cancel:** a confirmation first. The plan, its schedule and its payments
  are kept. The plan leaves Active, appears under Cancelled, and fabricates
  no refund. Undo is offered, and Reinstate brings it back.
- **Delete:** only for a plan made by mistake. The destructive confirmation
  lists what goes (the plan, n scheduled instalments, m payments). It is
  removed in one transaction. Undo restores identical ids and versions. It
  leaves no orphans and rolls back whole on failure.

### 40.13 Import and export

- **JSON** `lume.installments/1`: lossless. It carries every id, the ISO
  code, integer minor units, the deposit, the cash price, the anchor, due
  dates, state, void state, versions and creation instants.
- **Import** checks the whole file first. Every error is listed by stable
  path. References and every invariant are checked. The file is applied in
  one transaction, or not at all.
- **CSV** is export only, one row per scheduled instalment. It is marked not
  importable, because it cannot carry the relationships.
- **Item and merchant names are redacted by default**, because a purchase can
  reveal health, family or debt. They are written as "Plan 1". Notes are left
  out. Names are written only on the reader's explicit choice.

### 40.14 Invariants

These are checked on the staged state after every write. Any failure rolls
back the whole transaction.

1. schedule rows = count;
2. every row belongs to exactly one plan;
3. every payment to one row and one plan;
4. at most one active payment per row;
5. payment amount = row amount;
6. schedule total = amount × count;
7. total payable = deposit + schedule total;
8. paid to date = deposit + active payments;
9. remaining = total payable − paid to date;
10. remaining ≥ 0;
11. no arithmetic across currencies;
12. completed ⇔ every row paid;
13. cancelled is not completed;
14. void then restore reproduces every projection;
15. search, filter and sort leave the summaries unchanged;
16. import is all or nothing;
17. every amount and sum within 10¹⁵ and 2⁵³ − 1;
18. no stored schedule regenerates silently;
19. no locked field changes once payments exist;
20. no observer sees a partial transaction.

### 40.15 The screens

The reference's composition, kept where it defines one, in this order:

1. the summary card (one per currency);
2. the filter bar;
3. the sort bar;
4. the plans, each a rich row with its progress meter;
5. the schedule timeline;
6. the chart;
7. History;
8. the frame's source line and related tools.

Added as documented product extensions, not reference parity:

- the first-use state;
- "Add a plan";
- the plan detail;
- the payment sheet;
- the metadata and terms forms;
- the cancel and delete confirmations with Undo;
- search;
- the Cancelled and Late filters;
- export and import;
- validation;
- the day-unavailable, damaged, loading and storage-failure states;
- deep links (`?plan=<id>`) and session restoration.

## 41. Reference defects corrected

| defect (§38) | correction |
|---|---|
| sums that disagree | every figure is a sum of stored minor units; totals equal their rows |
| "Next payment" always `relDate(7)` | the earliest unpaid due date of an active plan |
| "Remaining" sorting payments left | named "Payments left"; "Next due" added |
| every plan counted as running | counts by derived state |
| "instalment 7 of 9" | "7 of 9 paid", and "next: instalment 8" |
| schedule and history as summary rows | real rows: every instalment and every payment |
| month-end drift and skipped months | anchored clamping; labels from `LumeDate` months |
| bars that never grow | the corrected chart (C64) |
| raw USD chart titles | amounts in the plan's currency, formatted for the reader |
| English in Urdu and Arabic | every string in en, ur and ar |
| no CRUD | add, pay, void, edit, cancel, delete, import, export |
| declared notifications with nothing behind them | removed; no control is drawn |
| not sensitive | sensitive, `outbound: none` |
| "Stored on this device" over no store | the build-flavor source line (C90) |

## 42. Obligations left

- **Dayroz:**
  - a durable, encrypted store implementing the transaction contract;
  - the three collections through these codecs;
  - a typed delivery adapter for opt-in due-soon reminders. It must never
    claim delivery.
- **Product decisions, not scheduled:**
  - weekly or fortnightly frequency;
  - partial and extra payments;
  - rescheduling after a payment;
  - a grace period.
