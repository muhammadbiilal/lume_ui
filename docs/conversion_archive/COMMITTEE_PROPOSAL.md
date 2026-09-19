# Committee — proposal for approval

**Status: proposal. Nothing here is implemented.** Everything below is
read from the reference source and the running reference, or is marked
**Proposed**. No financial rule is taken from the tool's name. Every
proposed rule is listed as a decision in §17.

## 0. Sources inspected

| file | what it holds |
|---|---|
| `assets/js/tools/money/committee.tool.js` (47 lines) | the whole screen: `build(c)` |
| `assets/js/tools/context.js` `committee()` (l. 1007–1027) | the data: one fixture committee |
| `assets/js/tools/context.js` `relDate` (l. 198–202) | dates relative to the device's wall clock |
| `assets/js/tools/context.js` `exportRows` (l. 1905–) | the per-tool export table — **no case for Committee** |
| `assets/js/services/locale.js` `RATES` (l. 21–44), `tidy` (l. 47–54), `money` | USD fixtures, converted and rounded per figure |
| `assets/js/data/catalogue.js` l. 144 | `{ id: 'committee', n: 'Committee', i: 'i-users', c: 'money', g: 'money', ints: ['savings'], m: 'Month 4 of 10', act: '', kw: 'bisi rosca kameti pool circle' }`, not `sens` |
| `assets/js/data/tool-specs.js` l. 192 | `a: 'manager', d: 'high', aware: 'currency locale', supports: 'notifications history export'`, `src: 'On device'`, `fresh: 'local'`, `rel: ['ledger', 'goals', 'expenses']` |
| `assets/js/tools/registry.js` l. 66, 158 | registration |
| `assets/js/tools/engine.js` `headerActions` (l. 284–294) | draws Export because the spec declares it |
| `assets/js/screens/tool.screen.js` `exportTool` (l. 525–561) | what Export does (§12) |
| `assets/js/i18n/tools.js` l. 243–244, 696–702 | the 15 `committee.*` strings, **English only** |
| `assets/js/i18n/core.js` l. 407, 587 | the tool's name only: `کمیٹی`, `الجمعية` |
| `assets/js/data/record-schemas.js`, `assets/js/services/notify-engine.js` | **no Committee entry** in either |
| `assets/css/tools/shared.css` | `.summary`, `.rrow`, `.tline`, `.bars`, `.crow` (shared components; §15); the ring is `.pring` from `assets/js/ui/components.js` `progressRing` |
| Flutter today | the catalogue entry, the name and the tile status string (§14) |

The reference has **no action of its own**. There is no add, edit, pay,
payout, member press, committee press, cancel, delete, share or reminder.
Its rows have no `data-act`. The only control is the frame's Export
(§12).

## 1. Reference states exercised

Driven with `measure_destinations.mjs --tool committee`, frozen at 7
September 2026 16:41. The captures and measurement JSON are kept outside
the repository, in the session's scratchpad.

| cell | viewport | theme | language | market |
|---|---|---|---|---|
| default | 390×844 | light | en | PK |
| dark | 390×844 | dark | en | PK |
| Urdu | 390×844 | light | ur | PK |
| Arabic | 390×844 | light | ar | PK |
| medium | 700×900 | light | en | PK |
| expanded | 1100×900 | light | en | PK |
| landscape | 852×393 | light | en | PK |
| scrolled 500, 1000, 1500 | 390×844 | light | en | PK |
| US, GB, AE, JP | 390×844 | light | en | US, GB, AE, JP |
| Export pressed | 390×844 | light | en | PK |

These states **do not exist** in the reference and could not be driven:

- filters and sorts;
- search;
- a list of committees;
- a committee or member detail;
- an empty or zero-member state;
- a zero-cycle state;
- a completed or overdue committee.

There is exactly one hard-coded committee. 200% text cannot be set in the
browser.

## 2. What the reference actually presents

A **rotating savings committee** (ROSCA — *committee*, *kameti*, *bisi*;
the catalogue keywords say "bisi rosca kameti pool circle"). The pool is
said to be paid to one member per month. The reader is a **member**: "Your
contribution", "Your turn". Nothing says the reader organises it.

### 2.1 The fixture (USD, before conversion)

```text
members:      You (turn 7, paid), Ahmed (turn 1, paid), Sara (turn 4, unpaid),
              Bilal (turn 2, paid), Hina (turn 9, unpaid)
contribution: 100    pool: 500    month: 4    months: 10    yourTurn: 7
collected:    [500, 500, 400, 300, 0, 0, 0, 0, 0, 0]
history:      the three paid members this month, 100 each
order:        members by turn; turn < 4 "done", turn = 4 "now"
```

### 2.2 The screen, in order (390×844, PK)

| # | section | content |
|---|---|---|
| — | header | "Committee" / "Records manager"; one action, Export |
| 1 | summary card | kicker "Pool each month", **Rs 142,000**; caption "Month 4 of 10"; ring "4/10"; stats "Rs 28,300 · Your contribution", "5 · Members", "Month 7 · Your turn" |
| 2 | "This month" | five rich rows: initials disc, name, "paid 31 Aug" or "Not yet paid", "turn in month N", Paid or Pending badge, Rs 28,300 |
| 3 | "Payout order" | timeline: Month 1 Ahmed, Month 2 Bilal (done), **Month 4 Sara (now)**, Month 7 You ("That's you"), Month 9 Hina — each Rs 142,000 |
| 4 | "Collected each month" | ten-bar chart 1–10, bar 4 highlighted; caption "Everyone contributes; one member is paid out." |
| 5 | "History" | You 31 Aug, Ahmed 1 Sept, Bilal 31 Aug — Rs 28,300 each |
| — | source bar | "Stored on this device" · "On device" |
| — | related | Lending Ledger · Savings Goals · Expenses |

### 2.3 Values measured in five markets

| market | pool shown | contribution shown | 5 × contribution | reconciles |
|---|---:|---:|---:|---|
| PK | Rs 142,000 | Rs 28,300 | Rs 141,500 | **no** (off by 500) |
| US | $500 | $100 | $500 | yes |
| GB | £395 | £79 | £395 | yes |
| AE | AED 1,840 | AED 367 | AED 1,835 | **no** (off by 5) |
| JP | ¥78,500 | ¥15,700 | ¥78,500 | yes |

The reason: every figure is USD × `RATES`, then `tidy` rounds each one
separately. For PK, 500 × 283 = 141,500, rounded to the nearest 1,000
gives 142,000, while 100 × 283 = 28,300 stays exact. For AE, 500 × 3.67
= 1,835 rounds to 1,840.

### 2.4 The questions the brief asks, answered from the source

| question | answer in the reference |
|---|---|
| who creates or manages it | nobody; there is no organiser field or action |
| members and their identities | five names with fixture initials; "You" carries the initials **ZK**, which are not the reader's |
| contribution amount and currency | one amount (100 USD), in the reader's display currency |
| frequency | monthly ("Month {n}", "Pool each month") |
| start date and cycle dates | **none**; months are ordinals only |
| payout order and recipients | a `turn` per member: 1, 2, 4, 7, 9 |
| multiple positions per member | **no**; one turn each |
| organiser participation | not modelled |
| paid, unpaid, late, skipped, upcoming | a `paid` flag for **this month only**; no late or skipped state; the timeline marks turn < 4 "done" |
| payouts separate from contributions | **no payout record**; "done" is only `turn < 4`, a literal |
| completion, cancellation, archival | none |
| fees, profit, interest, penalties, exchange | none |
| stored versus derived | nothing is stored; everything is a fixture literal |
| buttons | Export only (§12) |
| real versus fixture | all fixture; the source line claims "Stored on this device" |

## 3. Reconciliation — the reference cannot balance

In USD, as the fixture writes it:

1. **Ten months, five members, one turn each.** Months 3, 5, 6, 8 and 10
   have no recipient. Over ten months each member pays 10 × 100 = 1,000
   and receives one pool of 500. Across five members, 5,000 is paid in and
   2,500 paid out. **2,500 disappears.** A committee balances only when the
   number of cycles equals the number of payout positions.
2. **Month 3 collected 400 of 500.** Someone missed a contribution. No row,
   late state or outstanding figure shows it, and month 3 has no recipient
   to have been short-paid.
3. **Month 4 is "now" for Sara**, who has not paid, when only 300 of 500
   is collected. The timeline shows her receiving the full pool
   (Rs 142,000) regardless.
4. **History is not history.** It lists this month's three payments
   (300), where the chart says 500 + 500 + 400 + 300 = 1,700 was
   collected. It lists no payout.
5. **"Done" is arithmetic, not a record.** Months 1 and 2 are "done"
   because 1 < 4 and 2 < 4, not because a payout was recorded.
6. **Converted figures disagree** (§2.3): in PKR the pool is not five
   contributions.
7. **Dates move with the wall clock.** `relDate(-7)` and `relDate(-6)` are
   computed from the device's time, not the reader's zone, and are not
   tied to the cycle.

**Conclusion.** The reference is a picture of a committee, not a model
of one. Its fixture cannot be entered as a reader would enter a real
committee without changing it. The corrected fixture (§16) has five
positions over five cycles.

## 4. What Committee should model — Proposed

A reader-kept record of a **rotating savings committee they take part
in**:

- a fixed contribution per position per cycle;
- one payout recipient position per cycle;
- as many cycles as positions;
- monthly.

The reader is usually a member and may also be the organiser. Lume keeps
the reader's own record of what was contributed and paid out. It is not
a bank, a wallet, a ledger of debts, or a guarantee. No money moves
through Lume.

It is **not**:

- a loan or credit line — that is Ledger;
- a purchase plan — that is Installments;
- a savings target — that is Savings Goals;
- an investment. There is no profit, interest, bid or discount auction.
  Auctioned or bidding committees are a known variant and a future
  decision; none is modelled.

## 5. Proposed records

Five collections through the record envelope and the transaction layer.
Schema `lume.committee/1`.

```text
Committee            committee.committee
  id                  LumeRecordId
  name                String 1–80              (reader's own label, e.g. "Office committee")
  note                String? ≤500
  currency            LumeCurrency             (one per committee; current at creation)
  contribution        LumeMoney                (per position, per cycle; > 0)
  frequency           monthly                  (typed; others refused as unsupported)
  positions           int 2–120                (N; also the number of cycles)
  firstDue            LumeDate                 (cycle 1's due date; the anchor)
  readerRole          member | organiser | organiserMember
  state               active | cancelled
  createdAt, version

CommitteeMember      committee.member
  id, committee       LumeRecordId, → Committee
  name                String 1–80
  isReader            bool                     (at most one per committee)
  note                String? ≤500
  createdAt, version

CommitteePosition    committee.position        (a payout slot)
  id, committee       LumeRecordId, → Committee
  member              → CommitteeMember
  cycle               int 1..N                 (unique per committee: the payout order)
  createdAt, version

CommitteeCycle       committee.cycle           (the stored schedule)
  id, committee       LumeRecordId, → Committee
  n                   int 1..N
  due                 LumeDate
  createdAt, version

CommitteeContribution committee.contribution
  id, committee       LumeRecordId, → Committee
  cycle               → CommitteeCycle
  position            → CommitteePosition      (the share contributing)
  amount              LumeMoney                (= Committee.contribution)
  paidOn              LumeDate
  state               active | voided
  createdAt, version

CommitteePayout      committee.payout
  id, committee       LumeRecordId, → Committee
  cycle               → CommitteeCycle
  position            → CommitteePosition      (must be the position whose cycle this is)
  amount              LumeMoney                (= contribution × N)
  paidOn              LumeDate
  state               active | voided
  createdAt, version
```

**Why positions are separate from members.** A member may hold more than
one share: two positions means two contributions a cycle and two payouts.
People count distinct members; shares count positions. The member's name
is stored once, however many positions they hold. So "5 members" and "6
shares" can both be true without duplicating a person.

**Why contributions attach to a position, not a member.** Each share owes
one contribution per cycle. A member with two shares owes two records a
cycle. The form can record both in one transaction, so the reader acts
once.

**Why the schedule is stored.** Cycle rows give contributions and payouts
a stable target: a cycle id, not a date or an index. As in Installments,
the due dates are computed once, at creation, from the anchor, with
month-end clamping (31 Jan → 28/29 Feb → 31 Mar). They are never
recomputed. Whether to store them is decision **D-C1**.

**Codecs.** Each type decodes strictly from its record. A failure is a
typed defect, listed and shown, and never dropped or repaired. An unknown
frequency or role is reported as `unsupported`. A committee whose records
break a rule is **damaged**. Its figures leave the totals, and nothing is
written over it except deletion, as in Installments.

**Transactions.**

- Creating a committee writes its members, positions and cycles in one
  transaction (5 + 5 + 5 + 1 = 16 records for the corrected fixture).
- Recording a member's contributions for a cycle is one transaction,
  whatever the number of shares.
- A payout, a void, a restore, a cancellation, a reinstatement, an edit
  and a deletion are each one transaction.
- Every write is verified against §7 before it is published. A failed
  check rolls back the whole write.
- A retried create or contribution carries an idempotency key.

**Projections, never stored.** These are derived on read into a disposable
`CommitteeBook`, per committee and per currency:

- collected, outstanding, late, the current cycle, and the reader's next
  turn;
- the reader's paid-in, received and net;
- the payout order's states.

## 6. Figures — definitions and worked examples

Notation: `c` is the contribution in minor units and `N` is the number of
positions (and of cycles). PKR has two minor digits, so Rs 28,300 is
`2,830,000`.

| figure | definition |
|---|---|
| pool per cycle | `c × N` |
| expected per position, over the committee | `c × N` (N cycles), which equals one payout |
| expected per member | `c × N × sharesOf(member)` |
| expected for the committee | `c × N × N` |
| collected | Σ active contributions |
| collected in cycle k | Σ active contributions whose cycle is k |
| due to date | `c × N × (cycles due ≤ reader's day)` |
| outstanding | due to date − collected in those cycles (never negative) |
| paid out | Σ active payouts |
| payout amount | exactly `c × N` |
| reader paid in / received / net | Σ over the reader's positions; net = received − paid in |

**No fee, profit, interest, penalty or exchange rate exists.** A payout
equals contribution × positions, exactly.

### Example A — the corrected reference, normal operation

- Five members, one share each, N = 5, c = 2,830,000 (Rs 28,300).
- Monthly, first due 7 June 2026. Order: Ahmed 1, Bilal 2, Sara 3, You 4,
  Hina 5.
- Pool per cycle: 2,830,000 × 5 = **14,150,000** (Rs 141,500), not the
  reference's 142,000.
- Expected for the committee: 2,830,000 × 5 × 5 = **70,750,000**.
- On 7 September 2026, cycles 1–4 are due (7 Jun, 7 Jul, 7 Aug, 7 Sep):
  - due to date: 14,150,000 × 4 = 56,600,000;
  - with every contribution recorded, collected = 56,600,000 and
    outstanding = 0;
  - with payouts for cycles 1–3 recorded, paid out = 14,150,000 × 3 =
    42,450,000.
- Each position pays in 5 × 2,830,000 = 14,150,000 and receives
  14,150,000. Every position nets to 0, and the committee nets to 0.

### Example B — one missed contribution

- As in A, but Hina has no contribution for cycle 3 (due 7 Aug).
- On 7 September: collected = 56,600,000 − 2,830,000 = 53,770,000.
- Outstanding = 2,830,000, which is one late contribution: Hina, cycle 3.
- Sara's cycle-3 payout is refused while cycle 3 is short, under the same
  rule as Example D. Nothing is written.

### Example C — one member holding two positions

- Four members: Ahmed, Bilal, You, Hina. You hold cycles 2 and 4, so
  N = 5 positions over 5 cycles.
- People = 4, shares = 5. Pool = 2,830,000 × 5 = 14,150,000.
- You owe 2 × 2,830,000 = 5,660,000 each cycle, recorded as two
  contributions in one transaction.
- Over the committee you pay in 5 × 5,660,000 = 28,300,000 and receive two
  payouts of 14,150,000 = 28,300,000. Your net is 0.

### Example D — payout attempted before collection is complete

- Cycle 4 has 3 of 5 contributions: collected 8,490,000, pool 14,150,000.
- **Proposed (D-C3):** refused with a typed failure `incomplete`, shortfall
  5,660,000. Nothing is written.
- Lume never records a payout larger than what was collected for that
  cycle. It invents no organiser advance and no loan to cover the gap.

### Example E — partial contribution (not proposed)

- Sara pays Rs 20,000 (2,000,000) of Rs 28,300 for cycle 4.
- **Proposed (D-C2): refused** as `amount ≠ contribution`. A contribution
  record is one whole share.
- Allowing partial payments would need a remainder rule and a "part-paid"
  state. The reference has neither.

### Example F — cancelled committee with history

- Example A is cancelled on 8 September after cycles 1–3 were paid out
  and 4 cycles collected.
- Everything is kept. Collected stays 56,600,000 and paid out stays
  42,450,000.
- Held in the pot: 14,150,000, which is cycle 4's collection, never paid
  out. It is shown as "collected, not paid out". No refund is invented.
- No figure is due and nothing is late after cancellation.

### Example G — void and restore

- Voiding Bilal's cycle-4 contribution: collected in cycle 4 falls from
  14,150,000 to 11,320,000, and outstanding rises by 2,830,000.
- Restoring it brings every figure back exactly.
- A restore is refused if a second active contribution for the same cycle
  and position was recorded meanwhile.
- **Payouts are independent.** Voiding one makes only its own cycle "not
  paid out" again, whatever later cycles hold.
- A contribution in a cycle whose payout is active **cannot be voided**
  until that payout is voided. Otherwise the payout would exceed what was
  collected (invariant 7).

### Example H — import with an invalid relationship

- A file's payout for cycle 3 names Ahmed's position, which holds cycle 1.
- The import check reports `payouts.<id>.position: notRecipient`, and
  nothing is written.
- Likewise:
  - a contribution naming a cycle of another committee gives
    `contributions.<id>.cycle: reference`;
  - two positions claiming cycle 2 give `positions: duplicateCycle`.

### Example I — transaction failure midway

- Creating Example A writes 16 records.
- If the store fails at the 9th, the transaction publishes nothing: no
  committee, no members, no positions, no cycles.
- A failure part-way through deleting the committee (1 + 5 + 5 + 5 + 20
  contributions + 3 payouts = 39 records) likewise leaves every record as
  it was.

## 7. Invariants — Proposed

Checked on the staged state after every write. Any failure rolls the
whole write back.

1. Positions = cycles = N. Each cycle 1..N appears exactly once in
   positions and exactly once in cycles.
2. Every position, cycle, contribution and payout belongs to exactly one
   committee. Every position's member belongs to the same committee.
3. At most one member per committee has `isReader`.
4. Contribution amount = the committee's contribution. Payout amount =
   contribution × N. Both are in the committee's currency.
5. At most one active contribution per (cycle, position). At most one
   active payout per cycle.
6. A payout's position holds that cycle.
7. A payout is recorded only when its cycle is fully collected (if D-C3 is
   approved as proposed).
8. Collected in cycle k ≤ c × N. Paid out ≤ collected over the cycles paid
   out.
9. Σ over cycles of collected = total collected. Σ over members = total
   collected. The summary equals the rows.
10. Expected, collected, outstanding and paid out are each within 2⁵³ − 1
    minor units, and c ≤ 10¹⁵.
    - c ≤ 10¹⁵ with N ≤ 120 alone could reach 1.44 × 10¹⁹. That exceeds
      2⁵³ − 1 and even a 64-bit integer, which would wrap.
    - So creation also requires:
      - the pool, as a `LumeMoney.entry`: c × N ≤ 10¹⁵;
      - the committee total: c × N × N ≤ 2⁵³ − 1.
    - Both are tested **by division**, never by multiplying first:
      `c ≤ 10¹⁵ ~/ N` and `c ≤ (2⁵³ − 1) ~/ (N × N)`. For N = 120, c ≤
      625,499,948,245 minor units. A breach refuses with `overflow`.
    - Every later figure is bounded by the committee total, so no later
      write can overflow.
11. No arithmetic crosses currencies. Summaries are per currency.
12. Due dates are non-decreasing in n. A stored schedule is never
    regenerated silently.
13. Once any contribution or payout exists (active or voided), the
    following are locked:
    - contribution;
    - currency;
    - N;
    - firstDue;
    - frequency;
    - the payout order.
14. Void then restore reproduces every projection exactly.
15. Completed means every cycle has an active payout. Cancelled is not
    completed.
16. Import writes everything or nothing.
17. No observer sees a partial transaction.

## 8. States, dates and the reader's day — Proposed

| state | rule |
|---|---|
| contribution: paid | an active contribution exists for (cycle, position) |
| contribution: due today | none, and the cycle is due today |
| contribution: late | none, and the cycle was due before today |
| contribution: upcoming | none, and the cycle is due after today |
| payout: done | an active payout exists for the cycle |
| payout: ready | none, the cycle is fully collected, and the committee is active |
| payout: waiting | none, and the cycle is not fully collected |
| committee: active, completed, cancelled | cancelled by the reader; completed when every cycle is paid out; active otherwise |

- "Today" is the reader's calendar date in their resolved zone, as in
  Ledger and Installments.
- The **current cycle** is the latest cycle due on or before today, or
  cycle 1 before it starts.
- **Day unavailable:** no late, due or upcoming state, and no current
  cycle. Dates are shown, and "outstanding to date" says the day cannot be
  worked out. Nothing is guessed.
- There is no grace period (D-C8).
- **Backdated entries are allowed.** A contribution's `paidOn` may be any
  valid date; a real committee is often entered after the fact.
  **Advance entries** (a future cycle) are allowed too; they are simply
  paid early.
- **One record covers one cycle.** There are no multi-cycle payments,
  overpayments or credit (D-C2).

## 9. Editing, cancellation, deletion — Proposed

- **Before any financial record:** every field is editable. Changing N,
  firstDue or the order replaces positions and cycles with new ids, in one
  transaction.
- **After the first contribution or payout:** names and notes stay
  editable. Reader flags and role stay editable, unless marking a different
  member as the reader would break invariant 3. Everything in invariant 13
  is locked; the reader cancels the committee and starts a new one to
  change terms.
- **Cancel:**
  - asks for confirmation first;
  - keeps every record and invents no refund;
  - shows what was collected and not paid out;
  - can be undone, and Reinstate brings the same records back.
- **Delete:** for a committee added by mistake.
  - The destructive confirmation lists the counts: the committee, n
    members, n positions, n cycles, n contributions, n payouts.
  - Everything is removed in one transaction.
  - Undo restores the same ids and versions, and leaves no orphans.
- **Members:** a member is added and removed only while no financial
  record exists. After that, a person leaving is represented by cancelling
  the committee. Changing hands of a position is decision D-C6.

## 10. Currency and money — Proposed

- One currency per committee, chosen at creation. New committees default
  to the reader's currency through `LumeCountryCurrency` (a Bulgarian
  reader gets EUR).
- A withdrawn currency is refused for a new committee. An existing one
  keeps its currency, and contributions and payouts follow it as records
  serving an existing obligation (`LumeCurrencyPolicy`).
- Integer minor units throughout (`LumeMoney`), with Ledger's and
  Installments' bounds.
- Amounts are formatted for the reader (`LumeFormatting.amount`), isolated
  in sentences, and in Arabic order in Arabic (C95).

## 11. Privacy and honesty — Proposed

- **Sensitive: yes (D-C9).** It holds named people's finances and whether
  they paid. `sensitive: true`, `outbound: none`, set through the catalogue
  generator's `DECISIONS`. It is kept off:
  - Home and Today;
  - the hero;
  - recommendations and quick tools.

  The frame shows "Private to you" in the flavor-correct wording.
- **The Tools tile says what it is for:** "Track a savings committee" (in
  en, ur and ar), never "Month 4 of 10".
- **Nothing is shared in v1.** There is no reminder text and no share
  card. Export is the only way out, and it redacts by default (§12).
- **Source lines** follow the build-flavor policy:
  - parity keeps the reference's "Stored on this device", announced as
    reference copy;
  - development and release say "Kept until you close Lume" until Dayroz
    storage exists.
- **Never claimed:**
  - that money moved;
  - that a member was notified or a reminder sent or delivered;
  - that anything is encrypted or durable.

  The payout record is the reader's own note that a payout happened, and
  is worded "Payout recorded", not "Paid out" as if Lume did it.

## 12. Notifications, reminders, import and export — Proposed

**Reference.** It declares `notifications`, and no source or control
exists. It declares `export`, and `exportTool` finds no `exportRows` case
for Committee. So it downloads a JSON stub, `{ tool, exported, locale,
currency }`, containing no committee data, then toasts "Saved
lume-committee-YYYY-MM-DD.json" (`tool.exportedAs`). That is a false export.

**Reminders.**

- None in v1 (D-C10): no notification, no reminder composer, and no
  "send" wording.
- A later reviewed reminder would separate composition from delivery:
  - Lume composes a preview the reader reviews;
  - the platform share sheet hands it off, and Lume never says "sent".
- Scheduled due-soon notifications are a Dayroz delivery-adapter
  obligation (§13).

**Export and import (D-C11).**

- **JSON `lume.committee/1`**, lossless. It carries every id, version and
  creation instant, the ISO currency, minor units, N, the anchor, the
  stored due dates, the payout order, states and void states.
- **Import** checks the whole file first:
  - schema, version, uuids and duplicate ids;
  - every relationship: member→committee, position→member and committee,
    cycle→committee, contribution→cycle and position of the same
    committee, payout→cycle and the position that holds it;
  - every invariant in §7, and bounds and currencies.

  Each problem is listed by stable path, and the file is applied in one
  transaction or not at all. An orphan cannot be created.
- **CSV**, export only: one row per (cycle, position) with member label,
  due date, contributed, paid date and payout status. It is marked as not
  importable.
- **Redaction by default:**
  - committee name → "Committee 1";
  - member names → "Member 1…";
  - the reader → "You";
  - notes left out.

  Names and notes go into the file only when the reader explicitly turns
  them on, with a line saying what that means.

## 13. Reuse and Committee-specific code

The Flutter audit (§14) lists file-level facts. By need:

| reused | why Committee needs it |
|---|---|
| `LumeMoney`, `LumeCurrency`, `LumeCountryCurrency`, `LumeCurrencyPolicy`, `LumeFormatting.amount` | one currency per committee, integer minor units, and withdrawn codes serving existing records |
| `LumeDate` and the reader's-day resolution | due, late and current cycle need calendar dates and the reader's day |
| `LumeRecordId`, the record envelope, the transaction layer (`run`, `revert`, idempotency, `publishFault` in tests) | many records written together, with deletion and Undo |
| the strict-codec, `_Data`/`damagedBefore`/`_verify` and projection patterns | the same honesty rules as Ledger and Installments; the pattern is copied, not the code |
| the transfer pattern (JSON envelope, check then apply, redaction, CSV view) | D-C11 |
| `lumeInitials`, the privacy note, the build-flavor source lines, the header-action rules, the scroll reset | shared presentation rules |
| the sheets pattern (decide, destructive confirm, Undo toast) | cancel, delete and void need the same confirmations |
| the calendar-month anchoring in `installmentDue` | Committee cycles are monthly with the same month-end rule. **Proposed (D-C12):** move the pure date function to core (`LumeDate` monthly anchoring) and have both tools call it. It is calendar arithmetic, not Installments' payment logic |

**Not reused:**

- Ledger's FIFO allocation, credit and overpayment. Committee
  contributions target one (cycle, position), and nothing is allocated.
- Installments' in-order payment rule. Committee has no single payer
  sequence; members pay the same cycle side by side.
- Installments' plan, deposit and cash-price model.
- Ledger's people as parties. Committee members belong to one committee;
  whether to link them to Ledger people is a future decision, not v1.

**Committee-specific:**

- positions and payout order;
- cycle collection and payout eligibility;
- the per-member aggregation over shares;
- the current cycle;
- the reader's net;
- the collected-not-paid-out figure after cancellation.

## 14. Flutter today, and the earlier draft

**Flutter today.**

- The catalogue entry
  (`lib/features/catalogue/data/feature_catalogue.dart`, `id: 'committee'`)
  supports export, history and **notifications**. It has no `sensitive`
  and no `outbound`.
- `docs/conversion_archive/tool/gen_catalogue.mjs` `DECISIONS` covers only `ledger` and
  `installments`.
- `LumeDataCapability.readerRecords` is `{ledger, installments}`, so
  Committee counts as sample data.
- `tool_registry.dart` wires no Committee host, so the tool opens the
  archetype fallback.
- ARB has only `featureCommittee` (en `Committee`, ur `کمیٹی`, ar
  `الجمعية`) and `toolStatusCommittee` ("Month 4 of 10" and its ur/ar
  translations).
- There are no tests, no notification fixture, and no known-difference
  entry.
- `SCREEN_MATRIX.md` lists Committee as "not started".

Implementation changes in the catalogue:

- add `sensitive`, `outbound: none` and the record capability through
  `DECISIONS`;
- remove the `notifications` support (D-C10);
- replace the tile status (§11).

**The earlier draft.** `FINANCIAL_RECORD_FAMILIES.md` sketched a
`CommitteeCircle` with:

- `members[{id, name, turn}]`, where each member holds one turn;
- `startMonth: LumeYearMonth`, a type that does not exist in `lib/`;
- statuses `forming → running → finished`.

This proposal supersedes it in three places:

- **Positions replace member turns.** A member can hold more than one
  share (D-C4).
- **A stored `LumeDate` anchor replaces a year-month.** Due dates are
  days, and late is judged by the day (D-C1, D-C8).
- **There is no "forming" state.** A committee exists once its terms are
  entered; until the first financial record everything is editable
  (§9), which is what "forming" meant.

The draft's rules are kept: at least two members, the payout order a
permutation, one currency, and the honesty line (Lume says nothing about
anyone's reliability).

## 15. Visual mapping — Proposed

| reference section | Flutter | matched or corrected |
|---|---|---|
| header "Committee" / "Records manager", Export | `LumeToolScreen` toolbar; Export via the header rules | matched. Export becomes real (redacted JSON/CSV). The title is translated in ur and ar |
| summary card: pool, "Month 4 of 10", ring, three stats | `LumeSummaryCard` with the progress-ring aside | the pool is `c × N`. The caption reads "Cycle 4 of 5" from the reader's day. The ring is cycles paid out ÷ N. The stats are the reader's contribution per cycle (× shares), People (distinct members) and your turn (the reader's next payout cycle, or "Received") |
| "This month" rows | `LumeRichRow` per member: disc (`lumeInitials`), name, "Paid 31 Aug" or "Not yet paid" or "Late", "Turn: cycle 3" (or "Turns: 2, 4"), badge in words and colour, amount × shares | the badge comes from the reader's day, never guessed. Pressing a row opens the member |
| "Payout order" timeline | `LumeTimeline`: each cycle with due date, recipient and payout state (done, ready, waiting, upcoming) | every cycle has exactly one recipient (N = cycles). "Done" only with a payout record. "Now" is the current cycle |
| "Collected each month" chart | the corrected `LumeBarChart` (C64): collected in each cycle, the pool as the maximum | the bars grow. A screen reader hears amounts in the committee's currency, not USD |
| "History" | `LumeCompactRow` list: contributions and payouts, newest first, with dates; voided ones marked | real records |
| source bar, related tools, privacy note | the frame | per policy (§11) |
| **Added** | the committees list (if D-C13); committee create and edit form; member and position editor; a member's detail (their shares, paid and late cycles); the record-contribution sheet (one member, one cycle, all their shares); the record-payout sheet (only when ready); cancel, delete and void confirmations with Undo; export and import sheets; empty, loading, storage-failure, damaged and day-unknown states | documented product extensions, not parity |

**Layout.**

- Compact: a single column in the reference's order.
- Medium and expanded: the frame's centred column. The member detail uses
  the master-detail pane where the frame provides one.
- 852×393: a single column that scrolls.
- 200% text: rows wrap, and stats stack.
- RTL mirrors layout. Amounts and names are isolated. The timeline's
  direction follows reading order, and the ring's is not mirrored.

**Keyboard and screen reader:**

- Order follows the composition.
- Each member row reads name, state, shares and amount.
- Badges say "Late", not only colour.
- The ring and chart have text alternatives.

## 16. Reference defects

| # | defect | proposed treatment | class |
|---|---|---|---|
| 1 | cycles ≠ positions (10 months, 5 turns); 2,500 USD unaccounted | cycles = positions, enforced | functional correction |
| 2 | months 3, 5, 6, 8, 10 have no recipient | one recipient per cycle | functional correction |
| 3 | month 3's missing 100 is invisible | late contributions derived and shown | functional correction |
| 4 | Sara shown receiving the pool while unpaid and 200 short | a payout only when collected (D-C3) | functional correction |
| 5 | "done" from `turn < month`, not a payout | payout records | functional correction |
| 6 | History shows only this month's payments | real contributions and payouts | functional correction |
| 7 | converted pool ≠ members × contribution (PK 142,000 vs 141,500; AE 1,840 vs 1,835) | exact minor units, no conversion | functional correction |
| 8 | dates from the device's wall clock, not tied to cycles | stored due dates; the reader's zone | functional correction |
| 9 | "You" wears fixture initials ZK | the reader's member marked by `isReader`; initials from the name | functional correction |
| 10 | Export writes a JSON stub with no data and says "Saved …" | a real redacted export, or none | safety/privacy correction |
| 11 | `notifications` declared, nothing implemented | removed from supports through `DECISIONS`; no control | functional correction (intentionally deferred capability) |
| 12 | financial data about named people not marked sensitive | sensitive, `outbound: none` | safety/privacy correction |
| 13 | tile says "Month 4 of 10" (fixture) | purpose text | functional correction |
| 14 | "Stored on this device" over no store | the build-flavor source line | safety/privacy correction |
| 15 | 15 `committee.*` strings English-only; English laid out right to left in ur/ar, including the title | every string in en, ur and ar | restored parity (the name exists in `core.js`) and functional correction |
| 16 | chart bars stuck at 3 pt (C64); accessible titles in raw USD ("1: 500") | the corrected chart; localised amounts | restored parity (C64) and functional correction |
| 17 | rows and the timeline are inert (no `act`, no chevron); nothing to press; no add, pay or payout | the forms and sheets in §15 | functional correction |
| 18 | ring "4/10" is the month ordinal, not progress in money or payouts | cycles paid out ÷ N | functional correction |

No `C` entry is added now. The final known-difference wording follows the
implementation evidence.

## 17. Decisions requiring approval

| # | decision | recommendation | consequence |
|---|---|---|---|
| D-C1 | Schedule stored or derived | **Stored** cycle rows, generated once from the anchor | contributions and payouts target a stable cycle id; dates never drift with a calendar library |
| D-C2 | Partial, over- and multi-cycle contributions | **Not in v1**: one record = one share for one cycle, at the exact amount | no remainder or credit rules; totals stay exact |
| D-C3 | Payout eligibility | **Only when the cycle is fully collected** | no payout invents money; a short cycle shows as waiting |
| D-C4 | Multiple positions per member | **Allowed**, as separate positions of one member | People ≠ shares; the member owes and receives per share |
| D-C5 | Organiser participation | **A `readerRole` field (member, organiser or both); no organiser fee** | the reader may track a committee they run without being a member; no fee maths |
| D-C6 | Edits after activity begins | **Lock** contribution, currency, N, firstDue, frequency and payout order; names and notes stay editable; no member swaps in v1 | history never rewritten; to change terms, cancel and start again |
| D-C7 | Cancellation | **Keeps everything**, shows collected-not-paid-out, no refund; Undo and Reinstate | honest record of an abandoned committee |
| D-C8 | Late and grace | **Late the day after due; no grace; nothing without the reader's day** | deterministic states |
| D-C9 | Sensitive | **Yes**, `outbound: none` | off Home, Today, hero and recommendations |
| D-C10 | Reminders in v1 | **None**; a reviewed text reminder or notifications later, through a delivery adapter | no false "sent" claims |
| D-C11 | JSON/CSV transfer | **Yes**: lossless JSON with all-or-nothing import; CSV export-only; names and notes redacted by default | the reader can back up and move data without leaking names |
| D-C12 | Shared month anchoring | **Move the pure month-anchoring date function to core** and use it from Installments and Committee | one calendar rule; Installments behaviour unchanged |
| D-C13 | Screen architecture | **Its own host**: a committees list (a reader can be in several), the committee view in the reference's composition, a member detail, forms and sheets | parity for the composition; real CRUD around it |
| D-C14 | Starting state | **Empty**; the corrected fixture (§3, Example A) only in tests, goldens and labelled development fixtures | nothing seeded as if it were the reader's |
| D-C15 | Frequency | **Monthly only**, typed so weekly can come later | matches the reference's "month" |
| D-C16 | Bidding or auction committees | **Not modelled** | no discount, profit or interest maths anywhere |
| D-C17 | Adding or removing members after start | **Refused once a financial record exists** | no retroactive change to who owed what |
| D-C18 | Visual parity cells | **Reference composition in 8 cells, compared against the corrected fixture**; values that must differ (pool 141,500, cycles 5) are named in the parity test, not hidden | evidence of correction rather than false parity |

## 18. Future Dayroz obligations

- A durable, encrypted store implementing the transaction contract for
  the six collections, through these codecs.
- Migration: none from the reference, which stores nothing. Records made
  in this build live in memory only, and a reader who wants to keep them
  exports JSON. Dayroz adoption reads `lume.committee/1` unchanged.
- A notification delivery adapter for opt-in due-soon and payout-ready
  reminders, which must never claim delivery.
- A share adapter, if a reviewed reminder is approved later.
