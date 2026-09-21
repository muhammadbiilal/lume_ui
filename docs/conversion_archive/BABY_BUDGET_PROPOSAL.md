# Baby Budget — proposal for approval

**Status: approved.** Decisions D-B1 to D-B17 were approved as proposed
in `9929160`, subject to six corrections, which this revision applies:

| correction | what changed | where |
|---|---|---|
| 1 | `spentOn` is **nullable**: planned has no spent day, spent has no expected day; marking bought is one atomic write, and reverting is its own confirmed action | §5, §6 E, §7 (3), D-B18 |
| 2 | a plan is **greater than zero**; a category plan needs a budget plan, is positive, may total less than it but never more; removing the budget plan clears them in the same confirmed write | §7 (8), §9 |
| 3 | `startedOn` **means something**: nothing predates it, moving it is refused with a typed conflict naming the earliest record, and a budget that has not started says so instead of showing a zero month | §7 (9), §8, D-B19 |
| 4 | `archivedOn` is **never future-dated** when the day is known; archived takes no ordinary write; archive, un-archive and Undo preserve everything | §7 (12), §8 |
| 5 | every percentage is **integer arithmetic** with fixed tie-breaks, and uncategorised is a real slice | §6, §7 (7) |
| 6 | "Coming up" is ordered by **when things need attention**, not newest first | §8, §15, D-B20 |

Everything else below is read from the reference source and the running
reference. No figure is taken from the tool's name, and no spending rule
is invented.

## 0. Sources inspected

| file | what it holds |
|---|---|
| `assets/js/tools/personal/babybudget.tool.js` (37 lines) | the whole screen: `build(c)`, five sections |
| `assets/js/tools/context.js` `babyBudget()` (l. 1691–1712) | the data: one fixture month |
| `assets/js/tools/context.js` `dayName` (l. 204–208) | weekday names off the device's wall clock |
| `assets/js/tools/context.js` `exportRows` (l. 1905–1983) | the per-tool export table — **no case for babybudget** |
| `assets/js/services/locale.js` `RATES` (l. 21–44), `tidy` (l. 47–54), `money` (l. 132–142) | USD fixtures converted and rounded, then rounded again by `Intl` |
| `assets/js/data/catalogue.js` l. 179 | `{ id: 'babybudget', n: 'Baby Budget', i: 'i-baby', c: 'personal', g: 'personal', ints: ['expenses'], m: 'Plan costs', act: '' }`, not `sens` |
| `assets/js/data/tool-specs.js` l. 266–267 | `a: 'dashboard', d: 'high', aware: 'currency locale', supports: 'history export offline', src: 'On device', fresh: 'local', rel: ['expenses', 'goals', 'pregnancy']` |
| `assets/js/tools/registry.js` l. 104, 192 | registration |
| `assets/js/i18n/tools.js` l. 265–267, 1004–1007 | the 17 `baby.*` strings, **English only**; `common.perMonth` (l. 28) likewise |
| `assets/js/i18n/core.js` l. 417, 597 | the tool's name only: `بچے کا بجٹ`, `ميزانية الطفل` |
| `assets/js/data/record-schemas.js`, `assets/js/services/notify-engine.js` | **no babybudget entry** in either |
| `lib/features/expenses/**` | the built finance dashboard this one is related to (§14) |
| `docs/conversion_archive/FINANCIAL_RECORD_FAMILIES.md` l. 85–98 | the earlier draft design (§14) |

The reference has **no action of its own**. Its rows are plain `div`s —
`compactRow` only becomes a button when given an `act`, and none is given.
There is no add, edit, delete, press or reminder. The single control is
the frame's Export (§12).

## 1. Reference states exercised

Driven with `measure_destinations.mjs --tool babybudget`, on
21 September 2026. Eleven cells, each 66 measured elements.

| cell | viewport | theme | language | market |
|---|---|---|---|---|
| default | 390×844 | light | en | PK |
| dark | 390×844 | dark | en | PK |
| Urdu | 390×844 | light | ur | PK |
| Arabic | 390×844 | light | ar | PK |
| medium | 700×900 | light | en | PK |
| expanded | 1100×900 | light | en | PK |
| landscape | 852×393 | light | en | PK |
| US, AE, JP | 390×844 | light | en | US, AE, JP |
| GB | 390×844 | light | en | GB, on the `muslim_gb` profile |

These states **do not exist** and could not be driven: empty, adding,
editing, a month other than the fixture's, a category detail, a year
other than the fixture's, any error, and any loading state. There is one
hard-coded month.

## 2. What the reference presents

A **dashboard of what a baby costs a month**: what was spent, where it
went, how six months compare, what is coming up, and what large
purchases are planned. The reader is the parent; nothing names a child.

### 2.1 The fixture (USD, before conversion)

```text
monthly: 320        ratio: 0.82
trend:   [280, 305, 290, 340, 310, 320]   labels ['Apr','May','Jun','Jul','Aug','Sep']
categories: Nappies & wipes 120 · Formula & food 80 · Clothing 70 · Health 50
upcoming:   Nappy restock 65  (dayName(+6))   ·  Cot mattress 140 (dayName(+14))
oneOff:     Cot and mattress 420 ("Planned")  ·  Pram 260 ("Planned")
```

### 2.2 The screen, in order (390×844, PK)

| # | section | content |
|---|---|---|
| — | header | "Baby Budget" / "Dashboard"; one action, Export |
| 1 | summary card | kicker "This month", **Rs 90,600**; caption "82% of plan"; a progress ring at 82% labelled "Plan" |
| 2 | "Where it goes" | donut: Nappies & wipes 38%, Formula & food 25%, Clothing 22%, Health 16%; centre Rs 90,600 · "a month" |
| 3 | "Six months" | six bars Apr–Sep, the last highlighted; caption "Monthly spend, excluding one-off purchases" |
| 4 | "Coming up" | Nappy restock · **Sunday** · Rs 18,400; Cot mattress · **Monday** · Rs 39,600 |
| 5 | "One-off purchases" | Cot and mattress · Planned · Rs 119,000; Pram · Planned · Rs 73,600 |
| — | source bar | "Stored on this device" · "On device" |
| — | related | Expenses · Savings Goals · Pregnancy |

### 2.3 Values measured in five markets

"This month" is the capture's `composition.summary.value`; the four item
figures are the captured text of the two row sections,
`bounds.sect4.text` and `bounds.sect5.text`. The capture's
`composition.rows` is empty for this tool, because its rows are
`compactRow`s rather than the rich rows that key fills.

| market | this month | nappy restock | cot mattress | cot and mattress | pram |
|---|---:|---:|---:|---:|---:|
| PK | Rs 90,600 | Rs 18,400 | Rs 39,600 | Rs 119,000 | Rs 73,600 |
| US | $320 | $65 | $140 | $420 | $260 |
| GB | £253 | £52 | £111 | £332 | £205 |
| AE | AED 1,170 | AED 239 | AED 514 | AED 1,540 | AED 954 |
| JP | ¥50,200 | ¥10,200 | ¥22,000 | ¥65,900 | ¥40,800 |

Each figure is USD × `RATES`, then `tidy`, then `Intl` at zero decimals —
**two roundings**. In GBP, 65 × 0.79 = 51.35, which `tidy` snaps to 51.5
and `Intl` then rounds to 52.

### 2.4 The questions this raises, answered from the source

| question | answer in the reference |
|---|---|
| whose money is this | unstated; one fixture, no reader, no child |
| what is the plan | **never given**. "82% of plan" is the literal `ratio: 0.82` |
| how is the month's figure made | `monthly: 320`, a literal; the categories happen to sum to it |
| what is a category | a label, a value and a colour; no budget of its own |
| what is "Coming up" | two items with an amount and a **weekday name** from the device clock |
| what is a one-off | two items with an amount and the word "Planned"; no date |
| are one-offs in the month's figure | no, says the trend's caption; nothing says where they are counted |
| is there any total | no: neither month + one-off, nor a year |
| history | `supports` declares it; nothing stores anything |
| buttons | Export only (§12) |
| real versus fixture | all fixture. `LumeDataCapability.fixture('babybudget').isSample` is true today |

## 3. Reconciliation — what the reference cannot support

1. **The plan does not exist.** The ring and the caption both read 82%,
   from a constant. Implied, the plan would be 320 ÷ 0.82 = **390.24** —
   a figure that appears nowhere and is not a plausible budget. Nothing
   on the screen can be checked against it.
2. **The donut's percentages add to 101%.** 120, 80, 70 and 50 of 320 are
   37.5%, 25%, 21.875% and 15.625%; each is rounded on its own, giving
   38 + 25 + 22 + 16.
3. **"Six months" is not six months.** The labels are the hard-coded
   English strings `Apr`…`Sep` — in every language, and whatever today's
   date is. They align with the current month only by the accident of
   when the fixture was written.
4. **The chart says one currency and the page says another.** Each bar's
   accessible title is raw USD — "Apr: 280" — while the page shows
   Rs 90,600. The bars are also 3 points tall whatever their value
   (the same defect as C64).
5. **"Coming up" has no dates.** `dayName(+6)` and `dayName(+14)` render
   bare weekday names from the device's clock: "Sunday", "Monday". They
   change every day the page is opened, and no year, month or day is
   shown. The spec's `aware` list does not even mention the timezone.
6. **A one-off has no date at all** — the word "Planned", for both.
7. **Nothing adds up to anything.** 320 a month, 205 coming up and 680
   of planned purchases never meet in a figure. There is no total spent,
   no total planned, and no year.
8. **Export writes a stub.** `exportRows` has no case, so the reader
   downloads `{ tool, exported, locale, currency }` and is told "Saved".
9. **`history` is declared and does not exist**, and there is no store.
10. **It is not marked sensitive**, though it is a record of what a
    family spends on an infant, and its own related tool `pregnancy`
    *is* marked sensitive.
11. **Nothing can be added, edited or deleted.**

**Conclusion.** The reference is a picture of a month, not a record of
one. Its own fixture cannot be entered as a reader would enter it: there
is no plan to enter, no dates to enter, and nowhere to put a spend.

## 4. What Baby Budget should model — Proposed

The reader's own record of **what the baby costs**, month by month:

- a **plan**: what they mean to spend a month, in one currency, split
  into categories they name;
- **spends**: what was actually spent, each on a day, in a category;
- **planned purchases**: things they intend to buy, with an amount and
  an optional expected day, which become a spend when bought.

It is **not**:

- a second copy of Expenses (§14);
- a savings target — that is Savings Goals;
- anything about a pregnancy, a child's health or a due date — that is
  Pregnancy, and it stays there;
- a forecast. Lume projects nothing and predicts no cost.

## 5. Proposed records

Three collections through the record envelope and the transaction layer,
as Ledger, Installments and Committee use. Schema `lume.babybudget/1`.

```text
BabyBudget           babybudget.budget
  id                  LumeRecordId
  name                String 1–80        (the reader's label: "Ayaan", "The baby")
  note                String? ≤500
  currency            LumeCurrency       (one per budget; current at creation)
  monthlyPlan         LumeMoney?         (what they mean to spend a month; may be absent)
  startedOn           LumeDate           (the first month this budget covers)
  archivedOn          LumeDate?          (null while it is in use)
  createdAt, version

BabyCategory         babybudget.category
  id, budget          LumeRecordId, → BabyBudget
  name                String 1–80        ("Nappies & wipes")
  monthlyPlan         LumeMoney?         (its own share of the plan, or absent)
  order               int 0..49          (the order the reader put them in)
  colour              int 0..4           (a slice tone, chosen not derived)
  createdAt, version

BabySpend            babybudget.spend
  id, budget          LumeRecordId, → BabyBudget
  category            → BabyCategory?    (absent means uncategorised)
  label               String? ≤80
  amount              LumeMoney          (> 0, the budget's currency)
  planned             bool               (false: it happened; true: it is intended)
  spentOn             LumeDate?          (the day the money went; null while planned)
  expectedOn          LumeDate?          (the day it is expected; only while planned)
  state               active | voided
  createdAt, version
```

**A spend is either spent or planned, never half of each** (correction 1):

| `planned` | `spentOn` | `expectedOn` | what it is |
|---|---|---|---|
| `false` | **required** | **must be null** | money that went |
| `true` | **must be null** | optional | money the reader means to spend |

A planned purchase has no `spentOn`, because nothing was spent. That is
not a detail of presentation: a nullable `spentOn` is what stops a
planned item ever being counted as a month's spending by a query that
forgets to check the flag.

**Why one record type for spends and plans.** The reference draws
"Coming up" and "One-off purchases" as two lists, but they are the same
thing twice: something the reader means to buy. The only difference is
whether a day is expected. One record with `planned` and an optional
`expectedOn` gives both lists, and — more importantly — lets a planned
purchase **become** a spend without a second record and without double
counting (D-B4).

**Marking one bought is one atomic write** (correction 1). It sets
`planned` false, sets `spentOn` to the day the money actually went,
clears `expectedOn`, and — where the reader says so — replaces the
estimate with what was actually paid. All of that is one transaction:
there is no moment at which the record is bought with no date, or
planned with one.

**Going back is a decision, not a slip.** Turning a spend back into a
plan is its own action, confirmed, which clears `spentOn` and may set
`expectedOn` again. It is never a side effect of editing an amount or a
label, and the edit form cannot do it (D-B18).

**Why a category is a record, not an enum.** The reference's four
categories are fixture labels. A reader's categories are their own:
Expenses' fixed enum would be wrong here, and an enum cannot carry a
per-category plan.

**Why the plan may be absent.** A reader may keep the record without
setting a budget. Then there is no ratio and no ring, and the screen says
so rather than showing a percentage of nothing (D-B2).

**Codecs.** Each type decodes strictly from its record; a failure is a
typed defect, listed and shown, never dropped or repaired. A budget whose
records break a rule is **damaged**: its figures leave the totals, and
nothing is written over it except deletion.

**Transactions.**

- Creating a budget writes it and its categories in one transaction.
- Recording, editing, voiding, restoring, archiving, un-archiving and
  deleting are each one transaction.
- Every write is checked against §7 before it is published; a failed
  check rolls the whole write back.
- A retried create or spend carries an idempotency key.

**Projections, never stored.** A disposable `BabyBudgetBook` derives:
the month's spend, per category, the ratio to plan, the six-month trend,
what is planned, and the whole-budget totals.

## 6. Figures — definitions and worked examples

PKR has two minor digits, so Rs 12,000 is `1,200,000`.

| figure | definition |
|---|---|
| spent in a month | Σ active, unplanned spends whose `spentOn` is in that calendar month |
| spent per category, in a month | the same, per category |
| spent to date | Σ active, unplanned spends |
| plan for a month | the budget's `monthlyPlan` |
| ratio | spent in the month ÷ plan, as a whole percentage, worked out in integers (correction 5), or **none** when there is no plan |
| over by | spent − plan, when spent exceeds plan |
| planned total | Σ active spends with `planned` true |
| category share | its month's spend ÷ the month's spend, by largest remainder in integers (D-B3, correction 5) |
| six months | the month's spend for this month and the five before it |

**No forecast, no average, no projection.** Every figure is a sum of
stored amounts in one currency.

**Every percentage is integer arithmetic** (correction 5). No `double`
appears anywhere in these figures — a rounding that depends on binary
floating point is a rounding nobody can predict or test.

- **The ratio** is `(spent × 100 + plan ~/ 2) ~/ plan` on minor units:
  the percentage rounded half up, from two integers.
- **A share** is worked out by largest remainder on integers. For each
  category, `floor = spent × 100 ~/ month` and
  `remainder = spent × 100 − floor × month`. The floors are handed out
  first; the `100 − Σ floors` points left over go to the largest
  remainders.
- **Ties are broken in a fixed order**, so the same records always give
  the same picture:
  1. the larger remainder;
  2. then the category's display order;
  3. then the category's id.
- **Uncategorised is a real slice**, not a remainder bucket: it takes its
  floor and competes for the leftover points like any other. It sorts
  **last** in a tie, after every named category, which is its stable
  final position.
- The shares total exactly 100 whenever the month's spend is not zero.
  When it is zero there are no slices and no percentages at all.

### Example A — the reference's month, as a reader would enter it

A budget with a plan of Rs 39,000 (`3,900,000`) and four categories.
This month's spends:

| category | amount | minor |
|---|---:|---:|
| Nappies & wipes | Rs 12,000 | 1,200,000 |
| Formula & food | Rs 8,000 | 800,000 |
| Clothing | Rs 7,000 | 700,000 |
| Health | Rs 5,000 | 500,000 |
| **spent this month** | **Rs 32,000** | **3,200,000** |

- ratio: 3,200,000 ÷ 3,900,000 = 0.8205… → **82%**, the reference's
  figure, this time from two amounts the reader entered. The percentage
  is shown as a whole number, as the reference's ring is; the amounts
  beside it are exact.
- The parts add to the whole exactly: 1,200,000 + 800,000 + 700,000 +
  500,000 = 3,200,000.

### Example B — the donut adds to 100

Exact shares of Example A are 37.5%, 25%, 21.875% and 15.625%. Rounded
each on its own they make 101% (§3.2). By largest remainder:

| category | exact | floor | remainder | shown |
|---|---:|---:|---:|---:|
| Nappies & wipes | 37.5 | 37 | .500 | **37%** |
| Formula & food | 25.0 | 25 | .000 | **25%** |
| Clothing | 21.875 | 21 | .875 | **22%** |
| Health | 15.625 | 15 | .625 | **16%** |
| | | 98 | | **100%** |

The two largest remainders take the two points left over. The amounts
themselves are always shown exactly; the percentage is a reading aid.

In integers, with the month at `3,200,000`: nappies
`1,200,000 × 100 ~/ 3,200,000 = 37` remainder `120,000,000 − 118,400,000
= 1,600,000`; formula `25` remainder `0`; clothing `21` remainder
`2,800,000`; health `15` remainder `2,000,000`. The floors make 98, and
the two points go to clothing and health, the two largest remainders. No
division to a `double` happens anywhere.

Were two remainders equal — say two categories each at `1,600,000` — the
earlier display order takes the point, and if the reader somehow gave
them the same order, the smaller id does. Uncategorised, with the same
remainder as a named category, yields to it.

### Example C — over the plan

The plan is Rs 39,000; the month's spends come to Rs 44,850
(`4,485,000`).

- ratio: 4,485,000 ÷ 3,900,000 = 1.1500 → **115%**.
- over by: 4,485,000 − 3,900,000 = **585,000** (Rs 5,850).
- The ring is drawn full and the figure says 115%: it is not clamped to
  100, and the caption says over, not "of plan" (D-B2).

### Example D — no plan at all

The same spends, `monthlyPlan` absent.

- spent this month: Rs 44,850.
- ratio: **none**. The card shows the amount and says a plan has not
  been set; the ring is not drawn. Nothing is divided by zero and no
  percentage is invented.

### Example E — a planned purchase becomes a spend

A pram is planned at Rs 73,600 (`7,360,000`), expected 10 October.

- planned total: 7,360,000. Spent this month: unchanged.
- It is **not** in the month's spend, the trend or the donut, and it has
  **no `spentOn` at all** (correction 1) — nothing was spent.
- On 3 October the reader buys it for Rs 71,000 (`7,100,000`). Marking it
  bought is **one write** that sets `planned` false, sets `spentOn` to
  3 October, clears `expectedOn`, and replaces the estimate with what was
  actually paid. There is no instant in between at which the record is
  half one thing and half the other.
- Planned total falls to 0; October's spend rises by 7,100,000. Nothing
  is counted twice, and September is untouched.
- Were the reader to have marked it bought by mistake, turning it back
  into a plan is its own confirmed action: it clears `spentOn` and may
  set `expectedOn` again. Editing the amount or the label can never do
  it (D-B18).

### Example F — six months, with a month that has nothing

Today is 21 September. The trend is April…September. The reader has no
records for June.

- June shows **Rs 0**, not a gap and not an average.
- The bars are drawn to the largest month, and each bar's accessible
  label says the month and its amount **in the budget's currency**.

### Example G — a spend voided and restored

Voiding the Rs 8,000 formula spend: the month falls to `2,400,000`, the
ratio to 62% (0.6154), and the donut's shares are recomputed (the category
disappears when its month's spend is zero). Restoring it returns every
figure exactly.

If the budget was archived in between, the restore is refused: an
archived budget takes no writes, and a restore is a write (D-B6). The
reader un-archives it first.

### Example H — two budgets, two currencies

A second budget in USD. Nothing is added across them: the list shows one
card per budget, and a summary per currency. `LumeMoney` refuses a
cross-currency sum, and the screens never ask for one.

### Example I — a month boundary and the reader's day

A spend dated 30 September belongs to September whatever the device's
zone says, because `spentOn` is a calendar date, not an instant. Which
month is "this month" is the reader's own day (§8). Without that day,
"this month" is not claimed at all.

### Example J — import with an invalid relationship

A file's spend names a category of another budget:
`spends.<id>.categoryId: budget`. Nothing is written. Likewise a
category whose budget is absent gives `categories.<id>.budgetId:
reference`.

### Example K — a transaction failure midway

Creating a budget with four categories writes five records. If the store
fails at the third, nothing is published: no budget, no categories.

## 7. Invariants — Proposed

Checked on the staged state before every write; a failure rolls the whole
write back.

1. Every category and spend belongs to exactly one budget; a spend's
   category belongs to the same budget.
2. Amounts are in the budget's currency, and every spend's amount is
   greater than zero.
3. **Spent or planned, never between** (correction 1). `planned` false
   requires `spentOn` and forbids `expectedOn`; `planned` true forbids
   `spentOn` and allows `expectedOn`. Marking bought and reverting to
   planned each move every one of those fields in a single write.
4. Category `order` is unique within a budget, and 0..49.
5. Σ per-category spend in a month, plus uncategorised, equals the
   month's spend. The donut equals the card.
6. Σ every month's spend equals spent to date.
7. Percentages by largest remainder sum to exactly 100 whenever the
   month's spend is not zero (correction 5).
8. **Plans are positive, and a category plan needs a budget plan**
   (correction 2):
   - `monthlyPlan`, where present, is **greater than zero**; a plan of
     nothing is no plan, and is stored as absent.
   - A category plan is allowed **only** while the budget has a monthly
     plan, and is itself greater than zero.
   - The categories' plans may total **less** than the monthly plan: what
     is left is unallocated, and the screens name it.
   - They may **never** total more than the monthly plan.
   - Removing the monthly plan clears every category plan **in the same
     transaction**, which the reader confirms; a removal that does not
     is refused. No category plan ever outlives the budget plan it was a
     share of.
9. **Nothing predates the start** (correction 3). Every spend's
   `spentOn`, and every planned purchase's `expectedOn`, is on or after
   the budget's `startedOn`.
10. No arithmetic crosses currencies; summaries are per currency.
11. Bounds: every amount ≤ 10¹⁵ minor units as an entry, and every sum
    ≤ 2⁵³ − 1. A budget's spends are summed with `LumeMoney.total`, which
    refuses an overflow; creation refuses a monthly plan that could not
    be compared against a year of spending (12 × plan ≤ 2⁵³ − 1, checked
    by division).
12. **Archiving is truthful** (correction 4). `archivedOn` is not after
    the reader's day when that day is known; an archived budget takes no
    ordinary write; un-archiving clears the date; and archiving,
    un-archiving and their Undo preserve every record, id, version and
    projection exactly.
13. Void then restore reproduces every projection exactly.
14. Import writes everything or nothing.
15. No observer sees a partial transaction.

## 8. States, dates and the reader's day — Proposed

| state | rule |
|---|---|
| spend: recorded | `planned` false, active |
| spend: voided | kept, out of every figure, shown as voided |
| planned: expected | `planned` true, `expectedOn` set and on or after today |
| planned: overdue | `planned` true, `expectedOn` before today |
| planned: undated | `planned` true, no `expectedOn` |
| budget: not started | `startedOn` is after today: no month figures, no trend |
| budget: in use | started, and `archivedOn` null |
| budget: archived | `archivedOn` set |
| budget: damaged | a record cannot be read, or an invariant is broken |
| day unavailable | the reader's day cannot be resolved |

- "Today" is the reader's calendar date in their resolved zone, as in
  Ledger, Installments and Committee. There is no fallback to a guessed
  device date.
- **Day unavailable:** no "this month", no trend, no overdue state, and
  no ratio. Spends and their dates are still listed, and the screen says
  the day could not be worked out. Nothing is guessed. This is the
  correction of §3.5, where the reference shows weekday names from the
  device clock with no date at all.
- A spend may be dated in the past freely, but never before the budget's
  `startedOn` (correction 3). A spend dated **after** the reader's day is
  refused: it has not happened yet, and that is what `planned` is for
  (D-B5).
- A planned purchase may be dated in the future; that is its purpose. It
  may not be expected before the budget starts either.

**The order of "Coming up"** (correction 6, D-B20). A list of things to
do is ordered by when they need doing, never by when they were typed:

1. **overdue first**, the one expected longest ago at the top;
2. then those still to come, the soonest first;
3. ties broken by when the record was created, then by its id, so the
   order never wobbles between reads.

Undated planned purchases are not in this list at all: they are the
"One-off purchases" section, which has no order to derive and keeps the
reader's own — newest first.

**Where the budget starts** (correction 3, D-B19).

- `startedOn` is the first day the budget covers. Before it, the budget
  has no month figures and no trend values at all — not zeroes.
- **A budget that has not started says so.** With `startedOn` in the
  future the dashboard reads "Starts 1 November" and shows the plan and
  the categories; it does not draw a month of zero, a ring at 0%, or six
  empty bars, because none of that has happened.
- The six-month trend covers only months from `startedOn` onward. A month
  inside that range with no records is a true zero (§6 F); a month before
  it is not shown.
- **Changing `startedOn`** is allowed only while every record stays
  valid. Moving it later than the earliest record is refused with a typed
  conflict that **names that record** — its date and its label — so the
  reader can correct or delete it first. Nothing is moved or deleted for
  them.

**Archiving on a day** (correction 4, D-B6).

- `archivedOn` is a day, and when the reader's day is known it may not be
  after it: a budget cannot have been archived tomorrow.
- An archived budget takes no ordinary write: no spend, no edit, no
  category change. Un-archiving clears the date and everything resumes.
- Archive, un-archive and Undo keep every record, id, version and derived
  figure exactly as they were.
- **When the reader's day cannot be resolved**, an explicitly entered,
  valid calendar date is accepted and stored as given. Lume does not then
  claim it is in the past or the future, and shows it without that
  judgement.

## 9. Editing, archiving and deletion — Proposed

- **Everything stays editable.** Unlike Installments and Committee there
  is no schedule and no counterparty, so nothing locks: the plan, the
  categories, a spend's amount, day, category and label can all be
  corrected. Corrections are how a household budget is kept.
- **Changing the currency** is refused once any spend exists; the reader
  archives the budget and starts another (D-B7).
- **Removing the monthly plan** takes every category plan with it, in one
  confirmed transaction (correction 2). The confirmation says how many
  category plans will go. A removal that would leave a category plan
  behind is refused: a share of nothing is not a plan.
- **Deleting a category** with spends asks what to do with them and does
  the chosen thing in one transaction: move them to another category, or
  leave them uncategorised. It never deletes a reader's spends silently.
- **Archive** is the ordinary end: the budget and every figure are kept,
  nothing new may be recorded, and it can be un-archived.
- **Delete** is for a budget added by mistake. The destructive
  confirmation names the counts — the budget, n categories, n spends —
  removes them in one transaction, and Undo restores the same ids and
  versions.
- Every void, restore, archive and delete offers Undo.

## 10. Currency and money — Proposed

- One currency per budget, chosen at creation, defaulting to the
  reader's through `LumeCountryCurrency`.
- A withdrawn currency is refused for a new budget; an existing budget
  keeps its own, and its spends follow it (`LumeCurrencyPolicy`).
- Integer minor units throughout. **No conversion anywhere**, and so
  none of the double rounding of §2.3.
- Amounts are formatted for the reader, isolated in sentences, and in
  Arabic order in Arabic (C95).

## 11. Privacy and honesty — Proposed

- **Sensitive: yes (D-B9).** It is a record of a household's spending on
  an infant, it names categories like Health, and its own related tool
  Pregnancy is already sensitive. `sensitive: true`, `outbound: none`
  through the catalogue generator's `DECISIONS`. It is kept off Home,
  Today, the hero, recommendations and quick tools, and the frame shows
  "Private to you".
- **The tile keeps its purpose text**, "Plan costs" — unlike Committee's,
  it is not a fixture figure, and it needs no correction.
- **Nothing is shared.** No share card, no reminder text in v1.
- **Source lines** follow the build-flavor policy: parity keeps the
  reference's "Stored on this device" announced as reference copy;
  development and release say "Kept until you close Lume" until Dayroz
  storage exists.
- **Never claimed:** that anything is encrypted or durable, that a figure
  is a forecast, or that a total covers money recorded in another tool.
- **`isSample` becomes false** by adding `babybudget` to
  `LumeDataCapability.readerRecords`, because the tool will show only
  what the reader wrote.

## 12. Notifications, import and export — Proposed

**Reminders.** None in v1 (D-B10). A planned purchase has a date, which
makes a due-soon reminder obvious — and obvious is not the same as
honest: Lume cannot deliver anything today. No notification control is
drawn, and nothing says "sent". Scheduled reminders are a Dayroz
delivery-adapter obligation (§18).

**Export and import (D-B11).**

- **JSON `lume.babybudget/1`**, lossless: every id, version, creation
  instant, the currency, minor units, the plan, the categories with
  their order and colour, and every spend with its day, category, state
  and planned flag.
- **Import** checks the whole file first — schema, version, uuids,
  duplicate ids, every relationship, every invariant in §7, bounds and
  currencies — reports each problem by stable path, and applies it in
  one transaction or not at all.
- **CSV**, export only: one row per spend, with the budget, category,
  day, amount in minor units and as a decimal, and whether it is planned
  or voided. Marked as not importable.
- **Redaction by default:** the budget's name becomes "Budget 1",
  category names become "Category 1…", spend labels and notes are left
  out. Names go in only on the reader's explicit choice, with a line
  saying what that means. A child's name is exactly the kind of thing
  that should not leave by accident.

## 13. Reuse and Baby-Budget-specific code

| reused | why |
|---|---|
| `LumeMoney`, `LumeCurrency`, `LumeCountryCurrency`, `LumeCurrencyPolicy`, `LumeFormatting.amount` | one currency per budget, exact minor units |
| `LumeDate`, `lumeMonthStart`, `lumeSameMonth` (core, D-C12) | months are the whole tool; the shared month helpers already exist |
| `LumeRecordId`, the record envelope and transaction layer, `revert` for Undo | several records written together |
| the strict-codec, `_Data`/`damagedBefore`/`_verify` and projection patterns of Committee and Installments | the same honesty rules; the pattern is copied, not the code |
| the transfer pattern (JSON envelope, check then apply, redaction, CSV view) | D-B11 |
| `LumeDonut` and `LumeBarChart` (`lume_chart.dart`) | both already exist, and the chart library's own doc (`lume_chart.dart` l. 7) names Baby Budget as one of the tools that proved the donut |
| `LumeSummaryCard`, `LumeProgressBar`/ring, `LumeCompactRow`, `LumeRichRow`, `LumeFormCard`, the sheets, the privacy note, the source lines, the scroll reset | shared presentation |

**Not reused:**

- Expenses' fixed category enum — a reader's categories are their own
  records here.
- Committee's cycles, positions and payouts; Installments' schedules;
  Ledger's allocation. Baby Budget has no schedule and no counterparty.

**Baby-Budget-specific:** the month projection, the largest-remainder
shares, the plan-and-ratio rules, the planned-becomes-spent edit, and the
six-month trend.

## 14. Flutter today, the earlier draft, and Expenses

**Flutter today.**

- The catalogue entry exists (`feature_catalogue.dart`, `id:
  'babybudget'`, dashboard, high, `supports: export, history, offline`),
  **without** `sensitive` or `outbound`.
- Two ARB keys exist in all three languages: `featureBabybudget` and
  `toolStatusBabybudget` ("Plan costs" / "اخراجات کا منصوبہ" /
  "خطّط التكاليف"). **No body strings exist.**
- `tool_registry.dart` does not register it, so it opens the archetype
  fallback.
- It is in none of the capability sets, so `isSample` is true.
- `SCREEN_MATRIX.md` lists it "not started"; `KNOWN_DIFFERENCES.md` and
  `RELEASE_HONESTY.md` do not mention it.
- `LumeDonut` and `LumeBarChart` already exist.

**The earlier draft** (`FINANCIAL_RECORD_FAMILIES.md` §Baby Budget)
proposed `BabyBudget { monthlyPlan, categories }` and `BabyExpense {
categoryId, amount, on, kind: recurring | oneOff, recurrence? }`. This
proposal keeps its shape and departs in three places:

- **No recurrence in v1.** `recurrence?` is a schedule, and a schedule is
  the largest thing in Installments and Committee. A planned purchase
  with an optional expected day covers both of the reference's lists
  (D-B4); recurring items are a named future decision.
- **Categories become records of their own**, rather than a list nested
  inside the budget. The draft already gave a `BudgetCategory` a name and
  its own plan; making each one a record is what lets a reader reorder,
  rename and retire them without rewriting the budget.
- **`kind: recurring | oneOff` becomes `planned` plus `expectedOn`**,
  which is what the two lists actually differ by.
- **A planned purchase is stored, not derived.** The draft says "only
  `spent` is stored" because it expected planned items to fall out of a
  recurrence rule. Without recurrence there is nothing to derive them
  from, and a reader's intention to buy a pram is a thing they wrote
  down: it is a record, kept out of every spent figure until it is
  marked bought (D-B4).

**The Expenses question — the one that needs deciding (D-B1).** The
draft says Baby Budget should be "a *view* over expense records tagged to
it, not a second ledger of the same money", and that the tag is "part of
the Expenses family's schema change, decided with this one". Two facts
make that unbuildable now:

- Expenses is built on the **generic** record layer
  (`collection: 'expenses'`, a `LumeRecordSchema` of fields, not a typed
  codec family), and its categories are a **fixed enum** — groceries,
  transport, bills, eating, health, other. There is no baby category and
  no free tag.
- Its records are seeded sample data. A view over them would show
  invented spending, which is what makes `isSample` true today.

Adding the tag means migrating Expenses, which is out of scope. So:

> **Proposed (D-B1):** Baby Budget keeps **its own spends**. It is not a
> view over Expenses in v1, and it says nothing about Expenses' totals.
> If a reader records the same nappies in both tools, each tool totals
> its own records and neither claims to be the household's whole
> spending — the screens never add across tools. When Expenses becomes a
> typed family, linking a Baby Budget spend to an Expenses record is a
> separate, additive decision; the schema leaves room for it by keeping
> the spend's identity its own.

## 15. Visual mapping — Proposed

| reference section | Flutter | matched or corrected |
|---|---|---|
| header "Baby Budget" / "Dashboard", Export | `LumeToolScreen` toolbar | matched. Export becomes real (redacted JSON/CSV) |
| summary card: "This month", amount, "82% of plan", ring | `LumeSummaryCard` with a ring aside | the amount is the month's spends; the caption is the ratio to the reader's own plan, "over by …" when it exceeds it, and "no plan set" when there is none. Stats added: spent to date, planned total |
| "Where it goes" donut | `LumeDonut` | slices are the reader's categories; shares by largest remainder so they total 100 (§6 B); the legend shows the exact amount beside the percentage; a screen reader hears amounts, not raw numbers |
| "Six months" bars | the corrected `LumeBarChart` (C64) | the six calendar months ending with the reader's current month, labelled in their language; a month with nothing reads Rs 0; bars grow with their values |
| "Coming up" | `LumeCompactRow` list | planned purchases with an expected day, **with a real date**, in the order they need attention (correction 6): overdue first, oldest first; then the rest, soonest first. Pressing one opens it |
| "One-off purchases" | the same list, undated | the same record type without a day (D-B4) |
| source bar, related, privacy note | the frame | per policy (§11) |
| **Added** | the budgets list and empty state; the budget form (name, currency, plan, categories); the category editor; a spend form; the spend list for a month with a month picker; a category's own view; void/restore; archive and un-archive; delete with Undo; import and export sheets; loading, failure, damaged and day-unknown states | documented product extensions |

**Layout.** Compact: one column in the reference's order. Medium and
expanded: the frame's centred column, with the month's spends in the
detail pane where the frame provides one. 200% text: rows wrap and stats
stack. RTL mirrors layout; amounts and names are isolated; the donut is
not mirrored.

**Keyboard and screen reader.** Order follows the composition. Every
slice, bar and row has a text alternative naming the category or month
and its amount. States are said in words, not only colour.

## 16. Reference defects

| # | defect | proposed treatment | class |
|---|---|---|---|
| 1 | "82% of plan" from a constant; no plan exists | the reader's own plan, or no ratio at all | functional correction |
| 2 | donut percentages total 101% | largest remainder, totalling 100 | functional correction |
| 3 | "Six months" labelled with hard-coded English months | the six months ending today, in the reader's language | functional correction |
| 4 | bar titles in raw USD while the page shows another currency | amounts in the budget's currency | functional correction |
| 5 | bars 3 points tall whatever the value | the corrected chart | restored parity (C64) |
| 6 | "Coming up" shows weekday names off the device clock | stored dates, and the reader's own day | functional correction |
| 7 | one-off items have no date | an optional expected day | functional correction |
| 8 | no total anywhere: month, planned and one-off never meet | spent to date and planned total, per currency | functional correction |
| 9 | Export declares support and writes a stub, then says "Saved" | a real redacted export | safety/privacy correction |
| 10 | `history` declared, nothing stored | real records; the support stays because it becomes true | functional correction |
| 11 | a record of a family's spending is not marked sensitive | sensitive, `outbound: none` | safety/privacy correction |
| 12 | "Stored on this device" over no store | the build-flavor source line | safety/privacy correction |
| 13 | 17 strings English-only, laid out RTL in Urdu and Arabic | every string in en, ur and ar | restored parity (the name exists in `core.js`) and functional correction |
| 14 | nothing can be added, edited or deleted | the forms and sheets of §15 | functional correction |
| 15 | `baby.*` keys under a `babybudget` id | Lume's own keys are `babyBudget*`, one namespace | functional correction |
| 16 | the figures are invented spending shown as a reader's own | starts empty; the fixture only in tests and goldens | safety/privacy correction |

No `C` entry is added now; the wording follows the implementation
evidence. The next free number is C97.

## 17. Decisions requiring approval

| # | decision | recommendation | consequence |
|---|---|---|---|
| D-B1 | its relation to Expenses | **Its own spends.** Not a view over Expenses in v1; no Expenses migration; no claim about combined totals | the tool can be built now, and nothing is counted twice inside it |
| D-B2 | the plan and the ratio | **The plan is optional.** With one, the ratio is spent ÷ plan and may exceed 100%, said as "over by"; without one, no ratio and no ring | never a percentage of a number nobody entered |
| D-B3 | category shares | **Largest remainder**, so shares total exactly 100 | the donut agrees with itself |
| D-B4 | "Coming up" and "One-off" | **One record type**: `planned` with an optional `expectedOn`; buying it edits that record | no double counting when a plan becomes a purchase |
| D-B5 | dates | **A spend is never dated after the reader's day**; a planned purchase may be. Backdating is free | a record says what happened, not what might |
| D-B6 | archiving | **Archive keeps everything** and takes no new writes; un-archive restores | an ended budget stops moving |
| D-B7 | currency | **Locked once a spend exists**; archive and start another to change it | no mixed-currency budget |
| D-B8 | recurrence | **Not in v1.** Recurring items are a later, additive decision | no schedule to design, store or migrate |
| D-B9 | sensitive | **Yes**, `outbound: none` | off Home, Today, hero and recommendations |
| D-B10 | reminders in v1 | **None**; a delivery adapter later | no false "sent" |
| D-B11 | transfer | **Lossless JSON with all-or-nothing import; CSV export-only; names redacted by default** | a family's records can be moved without leaking names |
| D-B12 | screen architecture | **Its own host**: a budgets list, the budget dashboard in the reference's composition, a month's spends, a category, and the forms | parity for the composition, real CRUD around it |
| D-B13 | starting state | **Empty.** The reference's month only in tests, goldens and labelled development fixtures | nothing seeded as if it were the reader's |
| D-B14 | categories | **Records the reader names**, with an optional plan each, capped at 50 | their own words, not Expenses' enum |
| D-B15 | uncategorised spends | **Allowed**, and shown as their own slice | a reader is never forced to classify |
| D-B16 | the trend window | **Six calendar months ending with the reader's current month**; a month with nothing reads zero | the caption "Six months" becomes true |
| D-B17 | parity evidence | **The reference composition in 8 cells against the corrected fixture**, with the values that must differ named in the test | evidence of correction, not false parity |
| D-B18 | turning a spend back into a plan | **Its own confirmed action**, never an edit | a recorded spend cannot quietly stop being one |
| D-B19 | `startedOn` | **Binding**: nothing predates it; moving it is refused with a conflict naming the earliest record; before it there are no figures, and a future start says so | the start date means what it says |
| D-B20 | the order of "Coming up" | **Overdue first, oldest first; then soonest first**; undated stay in their own section | the list is ordered by what needs doing |

## 18. Future Dayroz obligations

- A durable, encrypted store implementing the transaction contract for
  the three collections, through these codecs.
- No migration: the reference stores nothing, and records made in this
  build live in memory only. A reader who wants to keep them exports
  JSON; Dayroz reads `lume.babybudget/1` unchanged.
- A notification delivery adapter, if reminders for planned purchases
  are approved later, which must never claim delivery.
- A link between a Baby Budget spend and an Expenses record, if and when
  Expenses becomes a typed family (D-B1).
