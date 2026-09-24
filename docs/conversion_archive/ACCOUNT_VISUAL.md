# The account routes: visual evidence audit

Twenty-one routes, four committed goldens each, and every measured
difference classified. This is conversion evidence and lives in the archive; the product
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
| committed goldens | `test/goldens/images/account_*.png` | that the pixels have not moved since somebody last looked |
| behavioural tests | `test/features/account/*_test.dart` | what the screen *means* |

The third is the acceptance evidence. The first two are regression evidence,
and neither can tell a correct screen from a consistently wrong one: a golden
of a route with a mislabelled row is a golden that will pass forever.

### The committed goldens

| cell | routes | what it is for |
|---|---|---|
| `390x844_light_en` | 21 (+1 guest) | the reference cell — the one the measurements were taken at |
| `390x844_light_ur` | 21 | right to left, Nasta'liq |
| `390x844_light_ar` | 21 | right to left, Arabic |
| `390x844_light_en_x2` | 21 | 200 % type |
| `390x844_dark_en` | 21 | dark mode — added 2026-09-24, see §5 |

106 committed goldens for the account section — 21 routes × 5 cells, plus
the guest refusal. `account_locale_test.dart` asserts that none of
the twenty-one overflows in any of those conditions, plus at 359 points and
as a guest; the goldens are what that assertion looks like.
[`GOLDEN_INVENTORY.md`](GOLDEN_INVENTORY.md) is the whole suite's
breakdown, and the words for each kind of image in it.

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

Largest still under D20: a single point on `sync`'s list.

**Not repairable, and not worth repairing.** Matching it would mean carrying
fractional line heights through every heading in the product to move a card
by a point or two.

**Correction (2026-09-24):** this section previously cited `time`'s note
card at y 2490 → 2496 (six points) as D20's largest example. That reading
predates commit `eb00909` ("Follow my region is a preference, and never
picks one of several zones", 2026-09-19), which canonicalised the
time-route's zone list and shortened the content above the note card. The
cell now measures 2490 → 2236 (−254 points) and is correctly reclassified
as **C89**, not D20 — see below. This document was not regenerated after
`eb00909` landed; `ACCOUNT_PARITY.md` (regenerated 2026-09-23) reflects
current reality and is the one to trust for this cell.

### C89 — the Time route's note card moves with a shorter zone list

**Open by decision, not a defect.** `KNOWN_DIFFERENCES.md` (C89) already
predicts this exact figure: *"The Time route's list is shorter, and its
note card sits higher (254 points on a 390-point phone in Pakistan); the
account bounds test marks it open against this entry."* The canonicalised,
deduplicated country/timezone list (`lib/core/time/lume_country_zones.dart`,
`lib/core/time/lume_iana_zones.dart`) is shorter than the prototype's flat
alias enumeration for a single-civil-time country like Pakistan, so
everything below it — including the note card — sits higher. `x`, `width`
and `height` for the note card are unaffected (exact matches); only its
`y` moves, and only because the content above it is intentionally shorter,
not because the card itself is mispositioned.

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

## 5. Dark mode (2026-09-24)

Not part of the original evidence above: dark mode had never been captured
for Account on either side, confirmed missing during the Wave 5
visual-parity re-audit ([WAVE_5_DISCOVERY.md](WAVE_5_DISCOVERY.md) §3).
Closed by:

- adding a `390x844_dark_en` golden for all twenty-one routes
  (`test/goldens/destination_golden_test.dart`, alongside the existing
  Urdu/Arabic/200% loop), so the eighty-five committed goldens in §1
  become **106**;
- capturing the matching web reference for all twenty-one routes at the
  same cell (`measure_destinations.mjs --screen profile --route <r> --cell
  account_<r> --theme dark`).

Reviewed with `compare.mjs` against two representative routes —
`appearance` (a route whose own subject is theme, so a dark-mode defect
here would be the most visible possible case) and `time` (the C89 route,
to confirm the finding above holds visually as well as in the measured
bounds). Both are clean: matching card structure, radio-row styling and
the teal selection treatment; `time`'s side-by-side visually confirms the
canonicalised zone list (§3, C89) rather than showing anything new. No
defect found in either; the remaining nineteen routes have goldens
committed but were not individually eyeballed beyond the golden-diff
check that `flutter test` itself performs.

## 6. What is not evidence

A golden that passes says the pixels are what they were. It does not say they
are right, and nothing in this audit treats a green golden run as parity.

A comparison percentage is worse: "96 per cent of values match" reads like a
grade, and the four values it hides are the whole of the finding. Every
difference above is listed with its number, its route and its class, and the
count of unexplained differences is zero — which is the claim, rather than the
ratio.
