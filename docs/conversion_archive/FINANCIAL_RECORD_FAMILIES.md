# Financial record families — design before implementation

**F6B closure. Written before any of these were built; Ledger (C90),
Installments (C94), Committee (C96) and Baby Budget (C97) have since
shipped, each with the deviations its own proposal records.** Ledger,
Installments, Committee and Baby Budget pass every wave rule but the last:
the reference
keeps them in tool state (`c.ledger()`, `c.installments()`, `c.committee()`,
`c.babyBudget()` over fixtures), not in its record layer. Putting them on
Lume's record layer is a data-model decision, and this is that design.

**The rule this document exists for:** these records are money owed between
people. They are never a generic `Map<String, Object?>` and never display
strings. `LumeRecord` (`record_model.dart`) stays what it is — an envelope
with identity, version and timestamps — and each family is a typed model
with a codec that reads and writes that envelope. Nothing outside the codec
sees the map.

## Shared foundations

| concern | design |
|---|---|
| **Identity** | `LumeRecordId`: a UUID v4 made on the device at creation, never reused, never derived from a name, amount or position. Children (entries, payments, members) carry their own ids and their parent's. |
| **Money** | `LumeMoney(int minor, LumeCurrency currency)`: integer minor units and an ISO 4217 code with its exponent (PKR 2 as ISO states it, even where Lume *displays* none; JPY 0; KWD 3). No `double` anywhere a sum is kept. Arithmetic refuses mixed currencies with a typed error; conversion is a separate, dated, sourced operation that is never implicit. |
| **Signs** | Direction is a field (`lent`/`borrowed`, `paid`/`due`), not the sign of an amount. Amounts are non-negative. |
| **Dates** | Due and payment dates are calendar dates (`LumeDate` year-month-day) in the record's own time zone id, which is stored; instants (`createdAt`, `paidAt`) are UTC. A due date is never an instant. |
| **Derived totals** | Balances, remaining, pool and progress are computed from entries every time, never stored — so they cannot disagree with what they sum. A stored cache, if Dayroz needs one, is rebuildable and versioned. |
| **Status** | Each family has a closed enum and a transition table; a write that would make an illegal transition is refused with a typed failure, not coerced. |
| **Validation** | In the model's constructor and in the codec: required fields, non-negative money, one currency per aggregate, dates in range, counts ≥ 1. A record that fails reads as a typed `LumeRecordDefect`, shown as damaged, never silently dropped or "fixed". |
| **Privacy** | All four are personal financial records: `sensitive` in the catalogue, off Home and Today, out of notifications unless the reader opts in, never in a share card by default, and redacted in exports unless the reader chooses "include names". People named in them are the reader's contacts, typed by the reader; nothing is looked up. |
| **Conflict** | The envelope's `version` is the optimistic lock the record layer already has (`LumeWriteFailure.conflict`). Children are appended with their own ids, so two devices adding payments merge; editing the same field conflicts and is shown to the reader, never last-write-wins on money. |
| **Import / export** | Exports carry `schema: "lume.<family>/1"`, every id, ISO currency codes and minor units, and dates as ISO 8601; importing an id that exists is an update subject to the version check, never a duplicate. |
| **Migration** | Each family's codec has a schema version. Today's in-memory store (C74, not durable) is migrated into Dayroz's durable store by the codec's `fromEnvelope`/`toEnvelope`, never by copying maps; seeds are marked `seeded` and are not migrated as the reader's data. |

## Ledger (lending between people)

- **Types.** `LedgerParty { id, name, note?, currencyDefault }`;
  `LedgerEntry { id, partyId, direction: lent | borrowed | repaidToMe |
  repaidByMe, amount: LumeMoney, on: LumeDate, due: LumeDate?, note? }`.
- **Derived.** Per party: net = lent − repaidToMe − (borrowed − repaidByMe),
  per currency; overall lent, borrowed, net and people count; overdue = a
  due date passed with a non-zero net in that direction.
- **Status.** A party is `open` or `settled` (net zero in every currency);
  settled is derived, not written. An entry is `active` or `voided` (a void
  keeps the entry and its id for the record, and is excluded from sums).
- **Validation.** Amount > 0; a repayment cannot exceed what is open in that
  currency without the reader confirming an over-payment, which is then a
  new entry in the other direction.
- **Reference fixture behaviour kept honest.** The reference's "Remind"
  toasts that it reminded someone; Lume must not claim a message was sent.
  Any reminder is a share the reader sends, or a local notification — the
  delivery decision C79 raised.

## Installments (paying off a purchase)

- **Types.** `InstallmentPlan { id, item, merchant?, principal: LumeMoney,
  count, frequency: monthly | weekly | custom, firstDue: LumeDate, schedule:
  [ScheduledPayment { id, n, due: LumeDate, amount: LumeMoney }] }`;
  `InstallmentPayment { id, planId, scheduledId, amount, paidOn: LumeDate }`.
- **Schedule.** Generated once at creation from principal, count and
  frequency with an explicit rounding rule (remainder minor units on the last
  payment), then stored — a later rule change never rewrites an existing
  plan. Month-end dates clamp (31 Jan → 28/29 Feb) by a stated rule.
- **Derived.** Paid count, paid and remaining amount, next due, monthly total
  across active plans, payoff by month.
- **Status.** `active → completed` when every scheduled payment is paid;
  `active → cancelled` by the reader, keeping payments made. `completed`
  never returns to `active` except by voiding a payment.
- **Validation.** Count 1–600; amounts per plan in one currency; a payment
  matches one scheduled item and cannot be recorded twice.

## Committee (rotating savings circle, "ROSCA")

- **Types.** `CommitteeCircle { id, name, contribution: LumeMoney,
  cycleLength: months, startMonth: LumeYearMonth, members: [Member { id,
  name, turn }], youMemberId? }`; `Contribution { id, memberId, month,
  amount, paidOn: LumeDate? }`; `Payout { id, memberId, month, amount }`.
- **Derived.** Pool = contribution × members; current month; collected this
  month; who has paid; your turn; collection per month.
- **Status.** Circle `forming → running → finished`; a member's month
  contribution `due → paid`; a payout `scheduled → paid`. Turns are a
  permutation of 1…n — validated, never duplicated.
- **Validation.** Members ≥ 2; payout order a permutation; one currency per
  circle; a contribution cannot be recorded for a month outside the cycle.
- **Honesty.** A committee is informal credit between people; Lume records
  what the reader enters and says nothing about anyone's reliability.

## Baby Budget

**Built, and one thing below was decided against** — see
`BABY_BUDGET_PROPOSAL.md` and C97. What shipped:

- **Types.** `BabyBudget { id, name, note?, currency, monthlyPlan?,
  startedOn, archivedOn? }`; `BabyCategory { id, budgetId, name,
  monthlyPlan?, order, colour }`; `BabySpend { id, budgetId, categoryId?,
  label?, amount, planned, spentOn?, expectedOn?, state }`.
- **Derived.** Month spend by category, the ratio to the plan, the six
  months ending with the reader's own, the planned total and what the plan
  has not handed out. Nothing derived is stored.
- **Status.** A spend is `planned` or it is spent, and never half of each:
  while `planned` is true there is no `spentOn` and only `expectedOn` may
  be set; once false, the reverse. Both are stored, and a record holding
  both is read as damage. Marking something bought moves every one of
  those fields in one write.
- **The plan is optional.** Without one there is no ratio and no ring.
  With one it is never zero, a category plan needs it, and the category
  plans may total less than it but never more.
- **Relation to Expenses — decided against (D-B1).** The design above made
  Baby Budget a *view* over Expenses records tagged to it. Expenses is a
  generic record family with a fixed category enum that has no baby
  category and seeded rows, so the tag would have meant migrating Expenses
  before Baby Budget could exist. Baby Budget keeps its own spends in v1.
  Nothing claims a combined total with Expenses, so nothing is counted
  twice; sharing the two later is a migration with its own approval.

## What approval of this design unlocks

The four tools can then join a wave on their references (Documents for the
records manager, Expenses for the finance dashboard), each with: the typed
model and codec, codec round-trip and migration tests, transition-table
tests, currency-mixing refusal tests, deterministic seeds marked sample data
(C85), and the same parity, localisation and golden bar as wave 1.
