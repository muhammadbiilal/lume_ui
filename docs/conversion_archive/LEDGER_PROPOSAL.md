# Lending Ledger — approval package

**Proposal only. Nothing here is implemented.** Ledger stays out of the app
until this package is approved. It refines the Ledger section of
`FINANCIAL_RECORD_FAMILIES.md` against the running reference, and where the
two differ this file is the newer word.

**How the reference was read.** `assets/js/tools/money/ledger.tool.js`,
`context.js` `ledger()`, the engine's header actions and `exportRows`, the
tool spec, the catalogue entry and the i18n tables, then the running page
driven through 16 states: default in PK, US, GB and AE; the Lent, Borrowed
and Overdue filters; row press, Add and Remind; dark; Urdu and Arabic; and
the 700×900, 1100×900 and 852×393 viewports. Every figure below comes from
those captures (fixture instant 7 September 2026).

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

## 2. Domain language

| term | meaning | not |
|---|---|---|
| **Person** (party) | someone the reader lends to or borrows from, typed by the reader | a contact looked up, an account |
| **Entry** | one movement of money with one person: lent, borrowed, repaid to me, repaid by me | a balance |
| **Balance** | the sum of a person's active entries in one currency, derived | a stored figure |
| **Owes you / You owe** | the balance's direction | a sign on a number |
| **Due date** | the calendar day a balance is expected back | an instant |
| **Overdue** | a due date before today, in the reader's zone, on a balance still open in that direction | a stored flag |
| **Settled** | every currency's balance with the person is zero, derived | a status the reader sets |
| **Void** | an entry withdrawn but kept, excluded from sums | a deletion |

Localised names: the catalogue already has "ادھار کھاتہ" (ur) and "دفتر
الديون" (ar) for the tool; the terms above need ur/ar strings (§15).

## 3. Typed models

```
LedgerParty  { id: LumeRecordId, name: String, note: String?,
               createdAt: instant (UTC), version }
LedgerEntry  { id: LumeRecordId, partyId: LumeRecordId,
               direction: lent | borrowed | repaidToMe | repaidByMe,
               amount: LumeMoney, on: LumeDate, due: LumeDate?,
               note: String?, state: active | voided,
               createdAt: instant (UTC), version }
LedgerBalance{ party, currency, amount: LumeMoney (non-negative),
               direction: owesYou | youOwe | settled,
               due: LumeDate?, overdue: bool }          — derived only
LedgerSummary{ perCurrency: { lent, borrowed, net, direction },
               people: int, overdue: int }              — derived only
```

Each is a Dart class with a codec to and from the `LumeRecord` envelope;
nothing outside the codec sees a map. Construction validates; a record that
fails reads as a typed `LumeRecordDefect`, shown as damaged, never dropped
or repaired silently.

## 4. Money representation

- `LumeMoney(int minor, LumeCurrency currency)`: integer minor units with the
  ISO 4217 exponent (PKR 2, JPY 0, KWD 3), even where Lume displays none.
- Amounts are non-negative; direction is the entry's field, not a sign.
- Arithmetic across currencies is refused with a typed error. A person with
  entries in two currencies has two balances; the summary is per currency,
  and a mixed ledger shows one summary per currency rather than a converted
  total.
- **No USD fixtures.** The reference stores dollars and multiplies by a rate
  table, then rounds each figure on its own (`tidy()`); that is a display
  device for sample data, not a model. Ledger records hold the currency the
  reader typed. Sample seeds, if any, are written in the reader's currency
  and marked sample data (C85).
- Display: `NumberFormat.currency` for the reader's locale, the currency's
  own symbol, and the number of decimals the product decides (§18).

## 5. Identity

- `LumeRecordId` (UUID v4) made on the device at creation, never reused,
  never derived from a name, amount or position.
- A person is identified by id, not by name: two people called Ahmed are two
  parties; renaming does not break their entries.
- Entries carry their own id and their party's id. Deleting a party is
  refused while it has active entries (§8).
- The reference has no identities at all: its rows are array positions and
  its Recent list is keyed by name.

## 6. Calculations and invariants

Per person, per currency:
`balance = (lent − repaidToMe) − (borrowed − repaidByMe)`, over active
entries; positive → owes you, negative → you owe, zero → settled.

Summary per currency: **Lent** = Σ positive balances; **Borrowed** = Σ
|negative balances|; **Net** = Lent − Borrowed; **People** = parties with a
non-settled balance.

Invariants, each a test:

1. Net = Lent − Borrowed exactly, in minor units.
2. Lent = Σ the "owes you" rows shown; Borrowed = Σ the "you owe" rows.
3. No sum mixes currencies.
4. A voided entry changes no figure; un-voiding restores them.
5. A repayment beyond the open balance is refused unless the reader confirms
   the over-payment, which is then recorded as an entry in the other
   direction.
6. Filters and search never change the summary (the reference's behaviour,
   kept, and labelled as the whole ledger).

Rounding happens once, at display. The reference breaks invariants 1 and 2
because each figure is rounded separately (§17).

## 7. Ordering and time

- `on` and `due` are `LumeDate` (year-month-day), never instants; the
  reader's day comes from `LumeTimeZoneService.reader()` (C88).
- **Overdue** = `due < today` in the reader's zone, on a balance still open
  in the direction the due date belongs to. When the day cannot be worked
  out (an unknown or malformed zone), no row is marked overdue or not: the
  Overdue filter shows the same typed day-unknown state To-dos shows, and
  dates are written out.
- People order: overdue first (oldest due first), then open balances by
  largest amount, then settled, then name; ties by id. Recent: by `on`
  descending, then `createdAt` descending, then id.
- `createdAt` and `version` are UTC instants from the injected clock.

## 8. CRUD

| operation | behaviour |
|---|---|
| Add person | name required (trimmed, non-empty); note optional |
| Add entry | person (existing or new), direction, amount > 0, currency (default the reader's), date (default the reader's today; none when the day is unknown), due optional and not before `on` |
| Edit entry | every field; version-checked (`LumeWriteFailure.conflict` on a stale write) |
| Void / restore entry | kept with its id; excluded from sums while voided |
| Delete entry | a confirmed, undoable removal of a mistaken entry (same bar as the record layer's delete) |
| Rename person | keeps every entry |
| Delete person | refused while any active entry exists; allowed when settled, with confirmation |
| Settle up | a convenience creating the repayment entry for the open balance, previewed before it is written |

The reference has none of these: Add, Remind and a row press each show a
toast and change nothing.

## 9. Search, filter and sort

- **Filter** (kept from the reference): All · Owes you · You owe · Overdue.
  The reference names them Lent/Borrowed; "Lent" filters by balance
  direction, not by entry kind, so the proposal labels by direction (§18).
- **Search**: over person name and entry notes, case- and
  diacritic-insensitive, script-aware for Urdu and Arabic; composes with the
  filter.
- **Sort**: Due date (default), Amount, Name, Recent activity.
- An empty result shows the "No match" state with "Show all".
- The reference's search action does nothing (§17); Lume's would search.

## 10. Privacy

- Ledger is personal financial data about named third parties. The catalogue
  entry today is **not** `sensitive` (Expenses is); approval is sought to
  mark it sensitive.
- Off Home and Today; not in recommendations; not in the hero.
- Notifications: none by default. A due-date reminder is opt-in per ledger,
  and its text never names a person or an amount on the lock screen unless
  the reader chooses to.
- No share card. Sharing a balance with the person owed is a deliberate,
  previewed text the reader sends, never automatic.
- No lookups: names are typed, never matched against contacts.
- The source line must not say "Stored on this device" while the store is
  in-memory (C74): it says what the build does.

## 11. Import, export and share

- **Export**: `schema: "lume.ledger/1"`, every party and entry with ids, ISO
  currency codes, minor units, ISO 8601 dates, voided entries included and
  marked. Names are redacted unless the reader chooses "include names".
  CSV is a second, lossy view for spreadsheets (one row per entry).
- **Import**: the same schema; an existing id is an update under the version
  check, never a duplicate; a record failing validation is reported, not
  dropped.
- **Share**: §10.
- The reference's export writes `lume-ledger-YYYY-MM-DD.json` holding only
  tool, date, locale and currency: no data (§17).

## 12. Repository contract

```
abstract interface class LedgerRepository implements Listenable {
  LedgerView view();                          // parties, entries, loading/failure
  Result<LedgerParty>  addParty(LedgerPartyDraft d);
  Result<LedgerParty>  renameParty(id, name, {required int version});
  Result<void>         deleteParty(id, {required int version});   // refused if open
  Result<LedgerEntry>  addEntry(LedgerEntryDraft d);
  Result<LedgerEntry>  editEntry(id, LedgerEntryDraft d, {required int version});
  Result<LedgerEntry>  setVoided(id, bool voided, {required int version});
  Result<void>         deleteEntry(id, {required int version});
}
```

Implemented over `LumeRecordRepository` with two families (`ledger.party`,
`ledger.entry`) and their codecs, so the in-memory store now and Dayroz's
durable store later share one contract. Failures are typed
(`validation`, `conflict`, `notFound`, `refused(reason)`, `storage`); the
view carries loading and failure states, not only data.

## 13. Shared versus Ledger-specific

| shared (exists or belongs to the record layer) | Ledger-specific |
|---|---|
| `LumeRecord` envelope, versions, conflict failure | party/entry models and codecs |
| `LumeRecordId`, `LumeMoney`, `LumeDate` (financial foundations, shared with Installments and Committee) | balance and summary derivation |
| `LumeTimeZoneService`, the record context's reader day and day-unknown state | overdue rule |
| summary card, filter bar, sort bar, rich row, compact row, button row, states (records-manager archetype, wave 1) | direction chips, "owes you / you owe" value subtitle, settle-up preview |
| record form fields, delete confirmation and undo | entry form (direction, currency, due) |
| export envelope | `lume.ledger/1` schema and its redaction |

`LumeMoney`, `LumeRecordId` and `LumeDate` do not exist yet; they are
proposed once, for all four financial families, not inside Ledger.

**Host decision.** The generic records host (`record_tool.dart`) handles one
flat family per tool. Ledger has two related families and a derived view,
so it needs either a Ledger host that reuses the shared widgets, or an
extension of the generic host to parent/child families. The proposal is a
Ledger host (§18).

## 14. Migration obligations

- There is no reference data to migrate: the reference keeps Ledger in tool
  state over fixtures, and Lume has not shipped Ledger.
- Codecs carry a schema version from the first write (`lume.ledger/1`);
  every later change ships with an upgrade and a round-trip test.
- Moving from the in-memory store to Dayroz's durable store goes through the
  codecs, never by copying maps.
- Seeds, if kept, are marked `seeded` and are not migrated as the reader's
  data.
- Stored dates carry no zone; if one is ever stored, it is a canonical IANA
  id, and aliases are migrated only by the deliberate `plan()` operation
  (C88).
- A currency code withdrawn from ISO 4217 keeps reading; conversion is never
  implicit.

## 15. Localisation and bidi

- Every string in en, ur and ar: title, subtitle, section heads, filter
  labels, "owes you"/"you owe", "owed to you overall"/"you owe overall",
  overdue, the form, validation messages, states, confirmations, export
  labels. The reference has none of these in Urdu or Arabic.
- Names and notes are the reader's own text: each is bidi-isolated (FSI/PDI)
  where it sits inside a sentence ("Ahmed owes you Rs 34,000" in Arabic).
- Amounts are formatted for the locale, with the currency symbol placed by
  the locale; the sign is never the only cue for direction (words and an
  icon too, and a different icon for each direction).
- Dates formatted for the locale; "due {date}" is one message with a
  placeholder, not concatenation.
- Initials: taken from the first grapheme of up to two words, so Urdu and
  Arabic names produce a disc, and a name with no letters gets a neutral
  icon.
- RTL mirrors layout; the direction arrows keep their meaning (money in /
  money out), not their screen direction.
- Plurals ("3 people") use ICU plural forms, including Arabic's six.

## 16. Visual and state matrix

States each needing a golden (390×844, light and dark, en/ur/ar where text
differs):

| state | content |
|---|---|
| empty ledger | first-use state with "Add a person" |
| populated | summary, filters, people, recent |
| owes-you only / you-owe only | caption flips to "you owe overall" when net < 0 |
| settled person | row without a balance, sorted last |
| overdue | badge on the row, Overdue filter populated |
| filter with no match | "No match", "Show all" |
| search results / no results | |
| mixed currencies | one summary per currency |
| damaged record | typed defect row |
| day unknown | Overdue unavailable, dates written out (C88 state) |
| loading / storage failure | record layer states |
| add / edit entry form, with validation errors | |
| void and restore, delete with undo | |
| settle-up preview | |
| export chooser with redaction | |
| RTL (ur, ar) | populated and form |
| large text (200%) and 852×393 landscape | populated |

Parity with the reference is claimed only for the populated, filtered and
filter-empty states; every other state is Lume's own and documented as such.

## 17. Reference defects

Measured in the running reference; Lume would not reproduce them.

1. **Figures disagree with themselves.** Each is converted and rounded on
   its own: in PK the rows owed to the reader are Rs 34,000 + Rs 17,000 =
   Rs 51,000 while Lent says Rs 50,900; in GB £95 + £48 = £143 against
   £142; in AE the Net is AED 495 while Lent − Borrowed = 661 − 165 = 496.
2. **Negatives are not rounded by magnitude** (`tidy()` works on the signed
   value), so a debt and a loan of the same size can round differently.
3. **Overdue is a hard-coded flag** on Bilal, not derived from his due date;
   it would stay "Overdue" forever and never appear on anyone else.
4. **Recent is not history.** It repeats each person's balance at their
   "since" date; there are no transactions.
5. **Recent uses the same arrow for money in and money out**; the sign
   alone carries the direction.
6. **Add an entry, Send a reminder and row press only toast**; nothing is
   created, reminded or opened. "Reminder sent" claims a delivery that did
   not happen.
7. **Export writes a JSON file with no ledger data** (`exportRows` has no
   Ledger case).
8. **Search does nothing**: it focuses a `[data-tool-search]` element the
   tool never renders.
9. **No Urdu or Arabic strings** beyond the tool name; the page turns RTL
   around English text.
10. **"Stored on this device"** is claimed for fixture data held in memory.
11. **The filter's empty state is unreachable** with the fixtures.
12. **No identities, no record layer, no CRUD.**
13. **The Tools tile** shows a money figure (`moneyRaw(budget × 0.106)`) in
    the web shell, a share of the budget fixture unrelated to the ledger;
    Lume's tile says "3 people", from the catalogue.
14. **Not marked sensitive** in the catalogue, unlike Expenses.

## 18. Decisions requiring approval

1. **Model**: entries are the source of truth and balances are derived (as
   above), not the reference's one stored balance per person.
2. **Money**: integer minor units with an ISO currency per entry; per-currency
   summaries, no implicit conversion; no USD fixtures.
3. **Displayed decimals**: whole units for PKR as the reference shows, or
   the currency's ISO exponent.
4. **Filter labels**: "Owes you / You owe" by balance direction, or keep the
   reference's "Lent / Borrowed".
5. **Overdue**: derived in the reader's zone; unavailable when the day is
   unknown.
6. **Remind**: no delivery claim. Either a previewed message the reader
   sends through the share sheet, an opt-in local notification to the reader
   (the C79 delivery question), or dropped.
7. **Export**: `lume.ledger/1` JSON with names redacted by default, plus CSV.
8. **Privacy**: mark Ledger `sensitive`; no share card; notifications opt-in
   and anonymous on the lock screen.
9. **Delete semantics**: void by default, hard delete for mistakes with
   undo; a person cannot be deleted while a balance is open.
10. **Host**: a Ledger host reusing the shared record widgets, rather than
    stretching the generic one-family host.
11. **Sample data**: start empty, or seed sample people marked as sample
    data in the reader's currency.
12. **Financial foundations first**: `LumeMoney`, `LumeRecordId` and
    `LumeDate` land as one shared change before any of the four financial
    families.
13. **Reader day**: Ledger inherits C88's "Follow region" resolution, whose
    own approval is pending.
