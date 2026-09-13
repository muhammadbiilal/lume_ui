# The account routes: visual evidence audit

Twenty-one routes, four captures each, and every measured difference
classified. This is conversion evidence and lives in the archive; the product
documentation is [`../LUME_ACCOUNT.md`](../LUME_ACCOUNT.md).

The numbers below come from
[`ACCOUNT_PARITY.md`](ACCOUNT_PARITY.md), which
`account_bounds_test.dart` regenerates on every run. Nothing here is typed by
hand, and nothing here is a percentage: a percentage would say "96 per cent
of values match" and hide which four did not.

---

## 1. What the evidence is

| kind | where | what it can show |
|---|---|---|
| measured bounds | `ACCOUNT_PARITY.md` | that a block is the size and in the place the prototype puts it |
| golden captures | `test/goldens/images/account_*.png` | that the pixels have not moved since somebody last looked |
| behavioural tests | `test/features/account/*_test.dart` | what the screen *means* |

The third is the acceptance evidence. The first two are regression evidence,
and neither can tell a correct screen from a consistently wrong one: a golden
of a route with a mislabelled row is a golden that will pass forever.

### The captures

| cell | routes | what it is for |
|---|---|---|
| `390x844_light_en` | 21 (+1 guest) | the reference cell — the one the measurements were taken at |
| `390x844_light_ur` | 21 | right to left, Nasta'liq |
| `390x844_light_ar` | 21 | right to left, Arabic |
| `390x844_light_en_x2` | 21 | 200 % type |

Eighty-five account captures. `account_locale_test.dart` asserts that none of
the twenty-one overflows in any of those conditions, plus at 359 points and
as a guest; the captures are what that assertion looks like.

---

## 2. Every difference, classified

372 values compared across the twenty-one routes. **316 are exact.**

| | count | class |
|---|---|---|
| exact | 316 | — |
| D20 | 28 | cumulative line-box rounding, within the 3-point drift allowance |
| C41 | 15 | open by decision — the run-together option row |
| C43 | 8 | open by decision — a list under a form moves with the form |
| not compared | 5 | the two sides do not bound the same element |
| **unexplained** | **0** | |

Seventy-five further rows read "not measured": a block the route does not have
— a radio group on a form, a field on a list. They are not gaps in the
comparison.

### Per route

| route | compared | exact | D20 | C41 | C43 | not compared |
|---|---|---|---|---|---|---|
| `prefs` | 16 | **16** | — | — | — | — |
| `language` | 24 | 17 | 4 | 3 | — | — |
| `region` | 20 | 17 | 3 | — | — | — |
| `currency` | 20 | 15 | 2 | 3 | — | — |
| `units` | 20 | 15 | 2 | 3 | — | — |
| `time` | 24 | 15 | 6 | 3 | — | — |
| `appearance` | 20 | 15 | 2 | 3 | — | — |
| `notifications` | 16 | 14 | 2 | — | — | — |
| `library` | 8 | **8** | — | — | — | — |
| `account` | 16 | **16** | — | — | — | — |
| `edit` | 20 | 16 | — | — | 3 | 1 |
| `email` | 20 | 19 | — | — | — | 1 |
| `phone` | 16 | 13 | — | — | 2 | 1 |
| `security` | 20 | 19 | 1 | — | — | — |
| `password` | 12 | 11 | — | — | — | 1 |
| `sessions` | 16 | **16** | — | — | — | — |
| `privacy` | 20 | 19 | 1 | — | — | — |
| `sync` | 16 | 14 | 2 | — | — | — |
| `help` | 20 | 17 | 3 | — | — | — |
| `about` | 16 | 14 | — | — | 2 | — |
| `delete` | 12 | 10 | — | — | 1 | 1 |
| **total** | **372** | **316** | **28** | **15** | **8** | **5** |

Four routes — `prefs`, `library`, `account` and `sessions` — match the
prototype on every measured value.

---

## 3. The classes

### D20 — cumulative line-box rounding (28 values)

Chrome keeps a line box's fractional height; Flutter rounds it to whole
logical pixels. Each heading is a fifth of a point shorter and the difference
accumulates down a route, which is why the allowance is three points for a
block below the first and one point for a block at the top.

Largest: `time`'s note card at y 2490 → 2496, six points down a route that is
two and a half thousand points tall. Smallest: a single point on `sync`'s
list.

**Not repairable, and not worth repairing.** Matching it would mean carrying
fractional line heights through every heading in the product to move a card
six points on one screen.

### C41 — the run-together option row (15 values)

**Open by decision. Reproduced.** `.optrow__title` and `.optrow__sub` are
inline `<span>`s and nothing blockifies them, so the prototype renders
"Follow my regionAutomatic" and "Metrickm · °C · kg" on one line. Flutter
reproduces the run-together line — one `Text.rich`, two spans, no separator —
which is why the numbers here are ±2 rather than the 11 points a
description-on-its-own-line would cost.

Affects five routes: `language`, `currency`, `units`, `time`, `appearance`.
The residue is the ring's inset: the prototype's option row starts at x 21 and
Flutter's at 22, two points narrower.

### C43 — a list under a form moves with the form (8 values)

**Open by decision.** The blocks are in the right order and the right shape;
the form above them is taller, so everything below it moves. `edit`'s list
sits 87 points lower, `about`'s 8, `phone`'s note card 25.

The cause is C48's field shape combined with the label and message lines the
route owns. It is measured, and it is a question about the form, not about the
list.

### Not compared (5 values)

`.field` in the prototype bounds the input alone. `LumeInputField` bounds its
label and its message with it. The two are not the same box, so the height is
reported and not asserted — and the row now says that rather than inheriting
"cumulative line-box rounding", which is what it used to say and which was
wrong by twenty-five points (C51).

---

## 4. What this audit found

Three things, none of which a percentage would have surfaced.

**The toolbar was a point too tall on all twenty-one routes.** The table read
Δ 1.00 on `toolbar` height and `toolbar.back` y for every route, and the prose
in C46 beside it said "Exact parity, restored… reads `=` … for all twenty-one
routes". The prose was written when the routes then in hand were right and was
never re-read against the generated file. `.toolbar` carries `border-bottom:
1px solid transparent`; Flutter had no border and a `minHeight` of 62, so the
38-point back control centred itself in a 40-point content box. Corrected:
C46 rewritten, C50 recorded.

**The toolbar's subtitle took a token's line.** Hidden behind the missing
hairline — the bar read 63 against 62 and passed inside the one-point
tolerance. With the hairline in place the real number appeared: 64 against 62,
because `.toolbar__sub` has no `line-height` and Flutter was using
`--t-meta-small`'s 16 instead of the font's natural 13, and had dropped the
`margin-top: 1px`. Corrected: C50.

**A reported difference was wearing another difference's explanation.** Five
`field` height rows labelled "cumulative line-box rounding (D20)" carried
numbers of 11 and 25 points. Corrected: C51.

Exact values went from **249 of 372** to **316 of 372**.

---

## 5. What is not evidence

A golden that passes says the pixels are what they were. It does not say they
are right, and nothing in this audit treats a green golden run as parity.

A comparison percentage is worse: "96 per cent of values match" reads like a
grade, and the four values it hides are the whole of the finding. Every
difference above is listed with its number, its route and its class, and the
count of unexplained differences is zero — which is the claim, rather than the
ratio.
