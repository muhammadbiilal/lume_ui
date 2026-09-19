# Lending Ledger — approval package

**Approved and implemented — the authoritative Ledger specification.**
This revision incorporates the approved decisions (D1–D13), the corrections
to repayment allocations, overdue derivation, the party lifecycle, display
precision, reminders, export and the multi-currency People count, and the
five final decisions (§18). It supersedes the Ledger section of
`FINANCIAL_RECORD_FAMILIES.md`. The implementation is `lib/features/ledger/`
over `lib/core/values/` and the record layer's transactions; what it draws
differently from the reference is C90.

**How the reference was read.** `assets/js/tools/money/ledger.tool.js`,
`context.js` `ledger()`, the engine's header actions and `exportRows`, the
tool spec, the catalogue entry and the i18n tables, then the running page
driven through 16 states: default in PK, US, GB and AE; the Lent, Borrowed
and Overdue filters; row press, Add and Remind; dark; Urdu and Arabic; and
the 700×900, 1100×900 and 852×393 viewports. Every reference figure below
comes from those captures (fixture instant 7 September 2026).

## 1. Composition inventory

Header: title "Lending Ledger", subtitle "Records manager", actions Export
and "Search this tool". Then, top to bottom:

| # | section | contents (PK, en) |
|---|---|---|
| 1 | Summary card | kicker "Net position"; value **Rs 38,200**; caption "owed to you overall" (or "you owe overall" below zero); three stats: **Rs 50,900** Lent, **Rs 12,700** Borrowed, **3** People |
| 2 | Filter bar | All · Lent · Borrowed · Overdue (single choice) |
| 3 | People | one rich row per person: initials disc with a tone, name, note, meta "since · due {date}", an "! Overdue" badge, the absolute balance and "owes you" / "you owe" |
| 4 | Recent | one compact row per person: name, date, signed amount, the same arrow icon for both signs |
| 5 | Buttons | "Add an entry", "Send a reminder" |
| 6 | Source line | "Stored on this device" · "On device" |
| 7 | Related | Expenses, Installments, Committee |

The fixture rows:

| person | note | since | due | PK | US | GB | AE |
|---|---|---|---|---|---|---|---|
| Ahmed | Car repair | 11 Aug | 19 Sept | owes you Rs 34,000 | $120 | £95 | AED 440 |
| Sara | Dinner | 1 Sept | — | you owe Rs 12,700 | $45 | £36 | AED 165 |
| Bilal | Rent share | 17 Jul | 31 Aug, overdue | owes you Rs 17,000 | $60 | £48 | AED 220 |

Summaries: PK Rs 38,200 / 50,900 / 12,700; US $135 / $180 / $45; GB £107 /
£142 / £36; AE AED 495 / 661 / 165.

Filters: Lent keeps Ahmed and Bilal, Borrowed keeps Sara, Overdue keeps
Bilal. The summary and Recent do not change under a filter. The filter's
empty state ("No match", with an "All" action) exists in code but no fixture
reaches it. Urdu and Arabic set the page RTL but every Ledger string stays
English. The layout is the same at every captured viewport.

Lume's screen keeps this order and these blocks; §16 lists where it
differs.

## 2. Domain language

| term | meaning | not |
|---|---|---|
| **Person** (party) | someone the reader lends to or borrows from, typed by the reader | a contact looked up, an account |
| **Principal entry** | money that creates an obligation: `lent` (they owe the reader) or `borrowed` (the reader owes them) | a balance |
| **Repayment entry** | money that discharges one: `repaidToMe` (against `lent`) or `repaidByMe` (against `borrowed`) | a negative principal |
| **Allocation** | the part of one repayment applied to one principal | a guess made at display time |
| **Remaining** | what is still open on a principal: its amount less its allocations | a stored figure |
| **Credit** | the part of a repayment the reader confirmed as more than was owed, not applied to any principal | a hidden remainder |
| **Balance** | the net of a person's entries in one currency, derived | a stored figure |
| **Owes you / You owe** | the balance's direction | a sign on a number |
| **Due date** | the calendar day a principal is expected back | an instant |
| **Overdue** | a principal due before the reader's today with something still remaining | a stored flag |
| **Settled** | nothing remaining and no credit in any currency, derived | a status the reader sets |
| **Void** | an entry withdrawn from every sum but kept, with its id | a deletion |
| **Archived** | a person hidden from the default lists, kept in history and export | a deleted person |

Localised names: the catalogue already has "ادھار کھاتہ" (ur) and "دفتر
الديون" (ar) for the tool; the terms above need ur/ar strings (§15).

## 3. Typed models

```
LedgerParty {
  id: LumeRecordId, name: String, note: String?,
  state: active | archived,
  createdAt: UTC instant, version: int
}

LedgerEntry {
  id: LumeRecordId, partyId: LumeRecordId,
  kind: lent | borrowed | repaidToMe | repaidByMe,
  amount: LumeMoney (> 0),
  on: LumeDate, due: LumeDate?          // due: principal entries only
  note: String?,
  state: active | voided,
  excessConfirmed: bool                 // repayment entries only (§5.4)
  createdAt: UTC instant, version: int
}

LedgerAllocation {
  id: LumeRecordId,
  partyId: LumeRecordId,
  repaymentId: LumeRecordId, principalId: LumeRecordId,
  amount: LumeMoney (> 0),              // its currency is the pair's
  origin: automatic | manual,
  scopeRevision: int,                   // the reconciliation it belongs to
  createdAt: UTC instant, version: int
}

// Derived only — never stored as authoritative data (D1):
LedgerPrincipalState { entry, remaining: LumeMoney, overdue: bool }
LedgerBalance {
  party, currency, amount: LumeMoney (≥ 0),
  direction: owesYou | youOwe | even | settled,   // even: net zero, open
  credit: LumeMoney, overdue: bool, shownDue: LumeDate?
}
LedgerSummary {
  perCurrency: { currency → (owedToYou, youOwe, net, direction) },
  people: int                           // global, §6
}
```

Each stored type is a Dart class with a codec to and from the `LumeRecord`
envelope; nothing outside the codec sees a map. Construction validates; a
record that fails reads as a typed `LumeRecordDefect`, shown as damaged,
never dropped or repaired silently. A cache of the derived types, if one is
ever kept, is a disposable projection: rebuilt from entries and allocations,
and checked against them by the invariants in §6.

## 4. Money and display

**Stored (D2).** `LumeMoney(int minor, LumeCurrency currency)`:

- integer minor units; `LumeCurrency` is an ISO 4217 code with its known
  exponent (PKR 2, USD 2, JPY 0, KWD 3). An unknown code is refused at
  construction.
- entry amounts are positive; direction is the entry's `kind`, never a sign.
- arithmetic is checked. Amounts are bounded at 10^15 minor units per entry
  and sums at 2^53 − 1 (the largest integer Dart represents exactly on every
  platform, the web included); passing either is a typed `overflow`
  failure, never a wrapped or rounded value.
- mixing currencies is a typed `currencyMismatch` failure. No implicit
  exchange rate exists anywhere in Ledger. No fixture is converted from
  USD, and no amount is ever reconstructed from a formatted string.
- a person may have balances in several currencies; every summary is per
  currency.

**Displayed (D3).** The currency's ISO exponent is the precision.

| where | rule |
|---|---|
| entry form, detail, export, accessibility value | always the full exponent: `Rs 34,000.00`, `¥5,000`, `KWD 1.250` |
| summary card, compact and rich rows | the fraction may be dropped **only when every dropped digit is zero**: 3,400,000 minor PKR shows `Rs 34,000`; 3,400,050 shows `Rs 34,000.50` |
| parsing | accepts at most the exponent's digits; `12.345` in PKR is a validation error ("PKR takes two decimal places"), never rounded |
| separators and symbol placement | the locale's (`NumberFormat.currency`); the digits are the locale's where Lume already localises digits |
| identity | the ISO code is the identity; a symbol alone never is (`$` is USD, CAD, AUD …): wherever two currencies share a symbol on one screen, the code is shown |

Rounding happens nowhere: display drops only zeros.

## 5. Repayment allocation

### 5.1 The contract

A repayment discharges principals through allocations. Rules, each enforced
by the repository and each a test:

1. An allocation joins one repayment to one principal of the **same party**
   and the **same currency**.
2. `repaidToMe` allocates only to `lent`; `repaidByMe` only to `borrowed`.
3. A repayment's allocations total **at most its amount**.
4. A principal's allocations total **at most its amount**: remaining never
   goes below zero.
5. Only active entries hold allocations that count. A voided entry's
   allocations are kept but count for nothing until it is restored.
6. Any write that touches an entry — create, edit, void, restore, delete,
   undo — **reconciles the allocations of that party and currency in the
   same transaction**. If reconciliation fails, the whole write fails and
   nothing changes; the failure is typed.
7. A repayment larger than what is open (§5.4) needs the reader's explicit
   confirmation; its excess is **credit**, shown, never hidden.

### 5.2 Automatic FIFO-by-obligation

When the reader does not choose the principals, allocation is automatic.
Within one party and currency, principals are taken in this order:

1. oldest overdue due date first;
2. then oldest non-null due date;
3. then oldest entry date (`on`);
4. then creation instant;
5. then stable id (the canonical lowercase UUID string, compared by code
   unit).

Because every overdue due date is earlier than every due date that is not
yet overdue, steps 1 and 2 together are "ascending due date, undated last".
The order therefore never depends on the clock or the reader's zone:
reconciling today and tomorrow gives the same allocations.

Repayments are applied in their own order — `on`, then creation instant,
then id — each filling the principals in the order above until it is spent.

### 5.3 Reconciliation

Reconciliation is a pure function of one party's entries in one currency:

1. Keep every **manual** allocation whose repayment and principal are
   active and still compatible, and which still fits rules 3 and 4.
2. Recompute every **automatic** allocation from scratch by §5.2 over what
   the manual ones leave.
3. A manual allocation that no longer fits (its principal was edited below
   it, or voided) makes the write fail with `allocationConflict(ids)`; the
   reader reallocates or chooses automatic, and writes again.
4. Stamp every allocation in the scope with the next `scopeRevision`.

On read, allocations whose `scopeRevision` is not the scope's latest, or
that break any rule in §5.1, mark the scope as needing reconciliation; the
screen shows the damaged state for that person and currency, and nothing is
recomputed silently behind the reader's back.

### 5.4 Overpayment and credit

A repayment is an overpayment when it exceeds everything compatible still
remaining for that person and currency. Saving it is refused with
`overpayment(excess)` unless the reader confirms, on a sheet that states the
excess ("Ahmed has repaid Rs 500 more than he owes you. Keep it as credit
to him?"). Confirmed, the entry carries `excessConfirmed: true` and the
excess is **credit**: shown on the person's row ("Rs 500 credit — you owe
Ahmed"), counted in the balance, and applied automatically to the next
compatible principal (a later `lent` to Ahmed), where it is an allocation
like any other. An unconfirmed excess can never exist: reconciliation that
would leave one (a principal deleted under a repayment) fails and asks.

### 5.5 Worked examples

Today is 7 September 2026 in the reader's zone. Amounts are PKR; minor
units in brackets.

**E1 — One loan, one partial repayment.** L1 `lent` Rs 10,000 (1,000,000)
on 1 Aug, due 1 Sept. R1 `repaidToMe` Rs 4,000 (400,000) on 20 Aug.
Automatic: A1 R1→L1 400,000. L1 remaining 600,000; due 1 Sept < 7 Sept and
remaining > 0: **overdue**. Row: owes you Rs 6,000, overdue, due 1 Sept.

**E2 — Two loans, different due dates.** L1 Rs 5,000 on 1 Jul, due 15 Sept;
L2 Rs 3,000 on 1 Aug, due 31 Aug. No repayment. L2 is overdue, L1 is not.
Row: owes you Rs 8,000, **overdue**, shown due 31 Aug (the oldest
unresolved overdue date).

**E3 — One repayment spanning two loans.** E2, then R1 Rs 4,000 on 5 Sept.
Order: L2 (due 31 Aug), then L1 (due 15 Sept). A1 R1→L2 300,000 (L2
remaining 0); A2 R1→L1 100,000 (L1 remaining 400,000). Nothing overdue.
Row: owes you Rs 4,000, shown due 15 Sept (the next unresolved date).

**E4 — Borrowed, repaid by the reader.** B1 `borrowed` Rs 2,000 from Sara
on 1 Sept, due 10 Sept. P1 `repaidByMe` Rs 500 on 5 Sept → A1 P1→B1 50,000.
Row: you owe Rs 1,500, due 10 Sept, not overdue. P1 could never allocate to
a `lent`, and a `repaidToMe` could never allocate to B1.

**E5 — Overpayment.** L1 Rs 1,000 lent to Bilal; R1 `repaidToMe` Rs 1,500.
Saving R1 is refused with `overpayment(50,000)`. Confirmed: A1 R1→L1
100,000; credit 50,000. Row: you owe Rs 500 (credit). Later L2 Rs 2,000
lent to Bilal: reconciliation allocates the credit, A2 R1→L2 50,000; row:
owes you Rs 1,500.

**E6 — Voided repayment.** E1, then R1 voided. A1 is kept but counts for
nothing: L1 remaining 1,000,000, overdue; row owes you Rs 10,000.
Restoring R1 reconciles again: back to E1 exactly.

**E7 — Edited repayment.** E1, then R1 edited to Rs 2,000: A1 becomes
200,000 (automatic), L1 remaining 800,000. Edited instead to Rs 12,000: an
overpayment of 200,000 — refused unless confirmed, then credit Rs 2,000.
Had A1 been manual at 400,000, editing R1 to Rs 2,000 fails with
`allocationConflict(A1)` and nothing changes until the reader reallocates.

**E8 — Deleted principal.** E1, then L1 hard-deleted as a mistake. R1's
400,000 would have nothing to discharge: the delete sheet says so and asks
whether R1's amount becomes credit or R1 is deleted too; nothing is
written until the reader chooses. Either way one transaction; Undo restores
L1 with the same id and A1 with it.

**E9 — Mixed currencies.** Ahmed: L1 Rs 10,000 (PKR); L2 $50 (USD, 5,000);
R1 $20 (USD, 2,000) → A1 R1→L2 2,000 only; it cannot touch L1. Rows:
Ahmed PKR owes you Rs 10,000; Ahmed USD owes you $30. Summary: PKR owed to
you Rs 10,000; USD owed to you $30; People **1**.

**E10 — Equal dates, deterministic order.** L1 Rs 3,000 and L2 Rs 2,000,
both on 1 Aug, both due 1 Sept; L1 created 10:00:00Z, L2 10:05:00Z. R1
Rs 3,500 → A1 R1→L1 300,000, A2 R1→L2 50,000 (creation instant decides).
Had both been created in the same instant, the lower id would go first.

## 6. Calculations and invariants

For one party and one currency, over active entries and their allocations:

```
remaining(p)  = p.amount − Σ allocations to p                (p principal)
credit(r)     = r.amount − Σ allocations from r              (r repayment)
owedToYou     = Σ remaining(lent)    + Σ credit(repaidByMe)
youOwe        = Σ remaining(borrowed) + Σ credit(repaidToMe)
balance       = owedToYou − youOwe
             ≡ (Σ lent − Σ repaidToMe) − (Σ borrowed − Σ repaidByMe)
```

Positive balance: owes you; negative: you owe; zero with nothing remaining
and no credit: settled. Net zero with anything still open (a `lent` and a
`borrowed` of equal size) is **even** — not settled.

Summary, per currency: **Owed to you** = Σ positive balances; **You owe**
= Σ |negative balances|; **Net** = Owed to you − You owe.

**People** is one global count: the distinct persons with at least one
non-settled balance in any currency. A person owing in two currencies is
counted once. A per-currency count, if ever shown, is labelled as such
("2 people in USD") and never replaces the global one.

Invariants — each a test, and each checked mechanically when a projection
is rebuilt:

1. The two forms of `balance` above are equal, in minor units.
2. Net = Owed to you − You owe exactly, per currency.
3. Owed to you = Σ of the "owes you" rows shown; You owe = Σ of the "you
   owe" rows shown.
4. Every allocation satisfies §5.1 rules 1–5; `remaining` and `credit` are
   never negative.
5. `credit(r) > 0` only when `r.excessConfirmed`.
6. No arithmetic crosses currencies; no sum overflows (typed failure).
7. A voided entry changes no figure; void then restore returns every figure
   and allocation to what it was.
8. Reconciliation is deterministic: the same entries give the same
   allocations regardless of the clock, the zone or insertion order.
9. People counts each person once, whatever their currencies.
10. Filters and search never change the summary, which is always the whole
    ledger and says so.
11. Display drops only zero digits (§4); it never rounds.

The reference breaks 1–3 because it rounds each figure on its own (§17).

## 7. Ordering and time

- `on` and `due` are `LumeDate` (year-month-day), never instants;
  `createdAt` and `version` come from the injected clock, in UTC.
- **The reader's today** comes from `LumeTimeZoneService.reader()` (C88,
  C89): the zone they named; else, under Follow my region, their city's zone
  or their country's one civil time; else, under Follow this device, the
  verified device zone. A country with several zones and no city, an
  unknown or malformed zone, and a missing device zone all give **no
  today**.
- **A principal is overdue** only when it is active, has a due date earlier
  than the reader's today, and has something remaining.
- **A person's row in one currency is overdue** when at least one of its
  principals in the row's direction is overdue. **The due date it shows** is
  the oldest overdue due date; otherwise the next due date still open.
- With no today, nothing is marked overdue or not: the Overdue filter shows
  the typed day-unknown state To-dos shows ("Choose a time zone …" where
  the region has several), and dates are written out, never "in 2 days".
- People order: overdue first (oldest shown due first), then open balances
  by largest amount in the row's currency, then settled, then name; ties by
  id. Recent: by `on` descending, then `createdAt` descending, then id.

## 8. CRUD and the party lifecycle

| operation | behaviour |
|---|---|
| Add person | name required (trimmed, non-empty); note optional; `active` |
| Add entry | person (existing or new), kind, amount > 0 at the currency's precision, currency (default the reader's), date (default the reader's today; none when there is no today), due optional, principal only, not before `on`; repayments allocate automatically unless the reader picks principals |
| Edit entry | every field; version-checked (`conflict` on a stale write); reconciles its scope — and both scopes when its currency or person changes |
| Void / restore entry | **the normal correction**; kept with its id; reconciles |
| Hard delete entry | only for a genuine mistake: destructive confirmation, version check, reconciliation in the same transaction (§5.5 E8), then an Undo interval before final removal; Undo restores the same id and its allocations; no allocation is ever orphaned |
| Rename person | keeps every entry |
| **Archive person** | allowed whenever every balance is settled; hides the person from default lists; history, search ("include archived") and export keep them; **Unarchive** restores |
| **Delete person** | refused while **any** entry — active or voided — references the person. A settled balance is not enough. Permanent deletion is possible only after every referencing entry has been deliberately removed. An ordinary delete never cascades through financial history |
| Settle up | creates the repayment for what is open, previewed (amount, principals it discharges) before it is written |

The reference has none of these: Add, Remind and a row press each show a
toast and change nothing.

## 9. Search, filter and sort

- **Filter** (D4): **All · Owes you · You owe · Overdue**, by the balance a
  person has now, not by the kind of entry. Its accessibility label says so
  ("Show people by their current balance"). English, Urdu, Arabic.
- **Search**: person names and entry notes, case- and diacritic-insensitive,
  script-aware for Urdu and Arabic; composes with the filter; archived
  persons only when asked.
- **Sort**: Due date (default), Amount, Name, Recent activity. Amount sorts
  within a currency; across currencies it groups by currency code first.
- An empty result shows "No match" with "Show all".

## 10. Privacy (D8)

- Ledger is personal financial data about named third parties: the catalogue
  entry becomes **`sensitive`** (it is not today; Expenses is).
- Off Home, Today, the hero and recommendations. No automatic share card.
  No contact lookup: names are typed.
- Notifications: none by default. Any later reminder notification is
  opt-in, and its lock-screen text carries no name and no amount by default.
- Where the platform later supports it, values are masked in the app
  switcher; a masked value is hidden from accessibility too, and a visible
  one may be announced.
- Export and sharing happen only on an explicit action of the reader.
- Development fixtures say they are sample data (C85). An in-memory store
  claims neither durability nor encryption: the source line says what the
  build does (C74), not "Stored on this device".

## 11. Reminder (D6)

A previewed message the reader may send through the existing share
adapter — not a notification, and never a claim of delivery.

1. **Select** an eligible balance: one person, one currency, owes you, more
   than zero.
2. **Preview** the exact text, in the reader's language, the name
   bidi-isolated: "Hi Ahmed, a reminder about Rs 6,000 from 1 August, due
   1 September." (The date clause only where a due date is shown.)
3. **Fields** listed under the preview: name, amount and currency, date,
   due date. **Excluded**, and said to be: notes, other people, other
   currencies, internal ids.
4. The reader may edit the text before sharing.
5. A second, explicit **Share** hands the text to the injectable share
   adapter; no contact is looked up and no recipient is chosen by Lume.
6. The result reports only the handoff: "Handed to your share sheet". If
   the reader cancels, nothing is said to have happened. If no share adapter
   is available, an honest unavailable state ("Sharing isn't available on
   this device") — never a fallback.
7. Never shown: "reminder sent", "delivered", "received", "notification
   scheduled".

No local notification delivery is built as part of Ledger.

## 12. Export and import (D7)

**JSON, lossless — `lume.ledger/1`.**

```
{
  "schema": "lume.ledger/1",
  "exportVersion": 1,
  "exportedAt": "2026-09-07T11:41:00Z",
  "source": { "app": "Lume", "build": "…", "store": "memory" },
  "namesIncluded": false,
  "parties":     [{ "id", "name" | "label": "Person 1", "note"?, "state",
                    "createdAt", "version" }],
  "entries":     [{ "id", "partyId", "kind", "amountMinor", "currency",
                    "on", "due"?, "note"?, "state", "excessConfirmed",
                    "createdAt", "version" }],
  "allocations": [{ "id", "partyId", "repaymentId", "principalId",
                    "amountMinor", "currency", "origin", "scopeRevision",
                    "createdAt", "version" }]
}
```

Dates are `YYYY-MM-DD`; instants UTC ISO 8601; amounts integers in minor
units with the ISO code beside them; voided entries included and marked.
**Names are redacted by default**: a person becomes "Person 1", "Person 2"
(in id order, stable within the file) and notes are left out, because notes
name people too. Including them is an explicit option with its own line:
"This file will contain the names and notes you typed. Anyone you give it
to can read them."

**CSV, lossy — one row per entry.**

| property | rule |
|---|---|
| encoding | UTF-8 with a byte-order mark, so spreadsheet software reads Urdu and Arabic names |
| delimiter, quoting, lines | comma; RFC 4180 quoting; CRLF |
| header | fixed English machine names, whatever the app language |
| columns | `entry_id, party_id, party (name or label), kind, amount_minor, amount, currency, date, due, state, remaining_minor, credit_minor, created_utc, version` |
| amount | `amount_minor` integer; `amount` a machine decimal with `.` and no grouping (`34000.00`), at the currency's exponent |
| dates | `YYYY-MM-DD`; `created_utc` ISO 8601 UTC |
| localised fields | none; `kind` and `state` are machine words (`lent`, `voided`) |
| allocations | not representable pairwise: `remaining_minor` (principals) and `credit_minor` (repayments) summarise them; the file says CSV cannot be imported and names the JSON export for that |

**Import** reads JSON only. The whole document is validated before
anything is written — schema, every id, currency, precision, every
§5.1 rule, versions — and then applied in one staged, atomic transaction.
An id that exists is an update under the version check; a stale one is a
reported conflict. Invalid records are listed with their path and reason;
nothing is discarded silently, and nothing is written while any are listed.

## 13. Repository contract

```
abstract interface class LedgerRepository implements Listenable {
  LedgerView view();          // parties, entries, allocations; loading,
                              // failure, and per-scope damage
  Result<LedgerParty>  addParty(LedgerPartyDraft d);
  Result<LedgerParty>  renameParty(id, name, {required int version});
  Result<LedgerParty>  setArchived(id, bool archived, {required int version});
  Result<void>         deleteParty(id, {required int version});
                       // refused while any entry references the party
  Result<LedgerWrite>  addEntry(LedgerEntryDraft d,
                         {List<LedgerAllocationDraft>? manual,
                          bool confirmExcess = false});
  Result<LedgerWrite>  editEntry(id, LedgerEntryDraft d,
                         {required int version, …same options});
  Result<LedgerWrite>  setVoided(id, bool voided, {required int version});
  Result<LedgerPendingDelete> deleteEntry(id, {required int version,
                         LedgerOrphanChoice? orphans});   // E8
  Result<void>         undoDelete(LedgerPendingDelete p);
  Result<LedgerImportReport> importJson(String document);  // atomic
}
```

Every write reconciles its scope inside the transaction. Failures are
typed: `validation(field, reason)`, `conflict(id)`, `notFound(id)`,
`currencyMismatch`, `overflow`, `overpayment(excess)`,
`allocationConflict(ids)`, `partyReferenced(count)`,
`storage(cause)`. Implemented over `LumeRecordRepository` with three
families (`ledger.party`, `ledger.entry`, `ledger.allocation`) and their
codecs, so today's in-memory store and Dayroz's durable one share one
contract. The record layer's transaction must cover several records at
once; if it cannot, that is added to the record layer first, not faked in
Ledger.

## 14. Shared versus Ledger-specific (D10, D12)

| shared | Ledger-specific |
|---|---|
| `LumeRecord` envelope, versions, conflict failure, multi-record transaction | parties, entries, allocations and their codecs |
| `LumeMoney`, `LumeCurrency`, `LumeRecordId`, `LumeDate` — small immutable value types, landed and tested first (D12) | balances, credit, reconciliation, FIFO-by-obligation |
| `LumeTimeZoneService`, the reader's today and the day-unknown state | the overdue projection |
| form shells, summary, filter, sort, rows, confirmation and Undo, loading, error and private states, responsive framing | settle-up, the allocation picker, the credit sheet |
| export envelope and file handoff | `lume.ledger/1`, its redaction, the CSV view |
| the share adapter | the reminder preview |

**Host.** A dedicated Ledger host reusing the shared widgets and record
infrastructure; the flat one-family generic host is not stretched into a
parent/child financial system.

**Foundations first, and only primitives.** `LumeMoney`, `LumeCurrency`,
`LumeRecordId` and `LumeDate` land as one change before Ledger, with tests
for equality, serialisation, invalid construction, checked arithmetic,
overflow, currency mismatch, ISO exponents, date comparison, UUID
validation, bidi-safe formatting and codec round-trips. Display formatting
stays outside the stored types. No Installments, Committee or Baby Budget
abstraction is created before those families are inspected in their own
right.

## 15. Migration obligations

- There is no reference data to migrate: the reference keeps Ledger in tool
  state over fixtures, and Lume has not shipped Ledger.
- Codecs carry a schema version from the first write (`lume.ledger/1`);
  every later change ships with an upgrade and a round-trip test.
- Moving from the in-memory store to Dayroz's durable store goes through the
  codecs, never by copying maps; allocations move with their scope's
  revision and are re-checked on arrival.
- No sample data is ever seeded into a reader's repository (D11), so none is
  migrated.
- Stored dates carry no zone. If one is ever stored it is a canonical IANA
  id, and aliases move only by the deliberate `plan()` operation (C88).
- A currency code withdrawn from ISO 4217 keeps reading; conversion is never
  implicit.

## 16. Localisation, bidi, visual and state matrix

**Localisation and bidi.**

- Every string in en, ur and ar: the title, sections, the four filters and
  their accessibility label, "owes you" / "you owe" / "credit", overdue, the
  form, validation messages (including precision: "PKR takes two decimal
  places"), the allocation, credit and delete sheets, the reminder preview
  and its field list, archive, export options and the redaction line,
  states and confirmations. The reference has none of these in Urdu or
  Arabic.
- Names and notes are the reader's own text, bidi-isolated (first-strong
  isolate) wherever they sit inside a sentence.
- Amounts by the locale, with the currency's code wherever a symbol is
  ambiguous on the screen; direction is never carried by sign or colour
  alone — words, and a different icon for money in and money out, keep
  their meaning in RTL.
- "due {date}" and the reminder text are single messages with placeholders,
  never concatenated. Plurals ("3 people") use ICU plural forms, Arabic's
  six included.
- Initials from the first grapheme of up to two words, so Urdu and Arabic
  names get a disc; a name with no letters gets a neutral icon.

**States**, each with a golden at 390×844, light and dark, and en/ur/ar
where text differs:

| state | content |
|---|---|
| first use (D11) | what the Ledger does, and "Add a person" — no sample people |
| populated | summary, filters, people, recent |
| you owe overall | the caption flips below zero |
| settled person; archived list | settled last; archived only under its toggle |
| overdue | badge on the row, Overdue filter populated |
| credit | the credit line on a row |
| filter or search with no match | "No match", "Show all" |
| mixed currencies | one summary per currency; People counted once |
| damaged scope | a person and currency whose allocations need reconciling |
| day unknown / zone to choose | Overdue unavailable, dates written out (C88, C89) |
| loading / storage failure | record-layer states |
| add, edit, validation errors | including a precision error |
| allocation picker; overpayment sheet; delete-with-orphans sheet | E5, E7, E8 |
| void and restore; delete with Undo | |
| reminder preview; share unavailable | |
| export options with redaction | |
| RTL (ur, ar) | populated and form |
| 200% text; 852×393 landscape | populated |

Parity with the reference is claimed for the populated, filtered and
filter-empty states only; every other state is Lume's own and documented.

**Sample data (D11).** A reader's Ledger starts empty. Sample persons exist
only in tests, goldens, visual-reference mode and explicitly labelled
development fixtures, and are never presented as the reader's data.

## 17. Reference defects

Measured in the running reference; Lume does not reproduce them.

1. **Figures disagree with themselves.** Each is converted and rounded on
   its own: in PK the rows owed to the reader are Rs 34,000 + Rs 17,000 =
   Rs 51,000 while Lent says Rs 50,900; in GB £95 + £48 = £143 against
   £142; in AE the Net is AED 495 while Lent − Borrowed = 661 − 165 = 496.
2. **Negatives are not rounded by magnitude** (`tidy()` works on the signed
   value), so a debt and a loan of the same size can round differently.
3. **Overdue is a hard-coded flag** on Bilal, not derived from his due date.
4. **Recent is not history**: it repeats each person's balance at their
   "since" date; there are no transactions and no repayments.
5. **Recent uses the same arrow for money in and money out.**
6. **Add an entry, Send a reminder and row press only toast**; "Reminder
   sent" claims a delivery that did not happen.
7. **Export writes a JSON file with no ledger data** (`exportRows` has no
   Ledger case).
8. **Search does nothing**: it focuses a `[data-tool-search]` element the
   tool never renders.
9. **No Urdu or Arabic strings** beyond the tool name.
10. **"Stored on this device"** is claimed for fixture data held in memory.
11. **The filter's empty state is unreachable** with the fixtures.
12. **No identities, no record layer, no CRUD, no repayments.**
13. **The Tools tile** shows a money figure (`moneyRaw(budget × 0.106)`) in
    the web shell, unrelated to the ledger; Lume's tile says "3 people".
14. **Not marked sensitive** in the catalogue, unlike Expenses.
15. **"Lent" / "Borrowed" filter by balance** while naming entry kinds.

## 18. Decisions

**Approved** (this revision incorporates each): D1 entries are the source of
truth · D2 the money model · D3 ISO-exponent precision · D4 "Owes you / You
owe" · D5 overdue with an allocation contract (§5) · D6 previewed share,
no delivery claim · D7 `lume.ledger/1` and CSV · D8 sensitive · D9 void
first, hard delete with Undo, archive, no cascade · D10 a dedicated host ·
D11 empty by default · D12 primitives first · D13 Follow region as an
explicit preference (implemented in the time-zone service; `WORLD_CLOCK_TIMEZONE.md`, C89).

**Final decisions** (approved; implemented):

1. **Credit carried forward — automatic.** Credit exists only after the
   reader confirms an overpayment, stays visible while unapplied, and is
   applied to the next compatible principal (same person, same currency,
   the direction it discharges) by the ordinary FIFO order, as normal
   allocation records, in the same transaction as that principal. Voiding,
   restoring, editing or deleting the source repayment reconciles every
   allocation it made; historical entries are not rewritten.
2. **Opposite principals — never offset.** A `lent` and a `borrowed` with one
   person in one currency both stay open with their own due dates and
   overdue state; the net may be shown, and a net of zero is "even", not
   settled. **Settled** means every principal has nothing remaining and no
   unapplied credit remains, in every currency. There is no Offset action.
   A future explicit Offset would be its own product decision, with its own
   typed adjustment and audit model, and must never masquerade as a
   repayment.
3. **Import — all or nothing.** The whole document is decoded and checked
   (schema and version, every party, entry and allocation, ids and
   references, currencies and bounds, versions, every allocation scope,
   every invariant, conflicts with what the Ledger holds) and reported in
   full with stable paths; then applied in one transaction after
   confirmation, or not at all. No "valid records only" path; nothing is
   repaired, discarded or renumbered.
4. **Multi-record transactions** are in the record layer
   (`record_transaction.dart`): one snapshot, optimistic version checks,
   commit all or none, one notification, typed failures, idempotency keys,
   and `revert` for Undo by the same ids.
5. **Amount bounds.** 10^15 minor units per entry and 2^53 − 1 per sum —
   exact on every platform, the web included — enforced at construction,
   import, every projection and every reconciliation, as a typed overflow
   that rolls the whole write back. Never clamped, wrapped or rounded.
