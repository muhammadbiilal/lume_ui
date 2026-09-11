# Onboarding: the chrome, and the two reference screens

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Written at Phase F4A, which converts **two** of the nine onboarding steps —
country and interests — plus the chrome all nine share. The rest of the flow is
F4B; authentication is later still.

Two screens rather than nine on purpose: they are the two that exercise
everything the method has to survive. The country step is a 194-row localised
list with search; the interests step is a wrapping chip picker with a cap, a
minimum and a switch that rewrites the selection. If the method holds for those
two it holds for the welcome slide.

---

## 1. The nine steps

| # | Step | F4A |
|---|---|---|
| 0 | Welcome | |
| 1 | Plan | |
| 2 | Tools | |
| 3 | **Where are you based?** | ✔ |
| 4 | Which city are you in? | |
| 5 | **What are you here for?** | ✔ |
| 6 | Set up | |
| 7 | One last thing (name) | |
| 8 | All set | |

Nine steps is why the progress bar has nine segments. `LumeOnboardingStep` names
all nine so a step never writes its own index, and the two built here assert
theirs against the reference's own `data-step`.

---

## 2. The shared chrome

[`onboarding_chrome.dart`](../../lib/features/onboarding/presentation/onboarding_chrome.dart).
Every value below is measured — either from a fixture specimen
(`measure_components.mjs`) or from the running flow
(`measure_onboarding.mjs`), and the second is what
[ONBOARDING_PARITY.md](ONBOARDING_PARITY.md) compares against.

| Part | Measured |
|---|---|
| `.onb__top` | 80 tall: `max(46, safe-top + 34)` of padding over a 34 row, 12 gaps |
| `.onb__nav` | 34 × 34, full radius, `card` on a 1 px border, `shadow-xs`, 17 glyph |
| `.onb__progress` | nine 3-tall segments, 5 apart, `border2` track, `accent` fill |
| `.onb__skip` | 32 tall, 13 / 700 / −0.02em, `text3` |
| `.onb-step` | 0 / gutter / `max(22, safe-bottom)` padding |
| `.onb__kicker` | 13 tall, 11 / 800 / +0.1em, uppercase, `accent`, 10 below |
| `.onb__title` | 28 / 800 / −0.04em on a 1.12 line |
| `.onb__text` | 14 / 500 / 1.55, `text2`, 10 above, **capped at 30ch** |
| `.onb__foot` | 22 above (18 sticky), 10 between, 4 below |
| Continue | 46 tall, 12 radius, trailing arrow, 0.38 opacity disabled |

### Three things the chrome does that are not a number

**The back control disappears rather than greys.** `.onb__nav[disabled]` is
`opacity: 0`, `pointer-events: none`, `scale(.8)`. It keeps its 34 points of
space so the progress bar does not shift between steps, and it leaves the
semantics tree so a screen reader is not offered a control that cannot be
pressed.

**The progress fill is the one value a measurement cannot give.**
`.onb__seg::after` is a pseudo-element and `getComputedStyle` on the segment
reports the track. Its rule is unambiguous in the stylesheet, so that one is
read rather than measured — and said so, rather than left looking measured.

**`30ch` is reproduced, not approximated.** CSS's `ch` is the advance width of
the `0` glyph in the element's own font, so the cap moves with the family, the
weight and the text scale. `LumeTextMeasure` measures the glyph; a constant
would freeze one of the three. It lands on the prototype's 304.08 at 390.

### The touch targets

Both chrome controls are under §9's 44 px floor in the reference — the circle is
34 and Skip is 32 — which is D6 again: a defect to correct, not a design to
copy. Growing the row to 44 was the obvious fix and it moved the entire flow
five pixels down, which the bounds comparison caught immediately.

So the row stays 34 and the targets **overhang** it by five each way: up into
the bar's own 46 of padding, down into the step's first five pixels, which are
empty because its content starts ten below. Reaching below the bar is why the
bar and the step are *stacked* rather than stacked in a column — a sibling in a
`Column` cannot hit-test past its own bounds.

The same technique puts a 44 px target on the interests step's 23 px Clear: the
18 above it and the 11 below are reduced by the overhang, so the bar's contents
land exactly where the prototype puts them and the target is whole.

---

## 3. The country step

[`country_screen.dart`](../../lib/features/onboarding/presentation/country_screen.dart),
driven by [`country_picker_model.dart`](../../lib/features/onboarding/domain/country_picker_model.dart).

### Composition

```
MAKE IT LOCAL
Where are you based?
This helps us personalise local information and services.
It says nothing about who you are.

[ 🔍 Search countries                    ]

POPULAR
┌────────────────────────────────────────┐
│ PK  Pakistan                       PKR │  ← tinted, selected
│ IN  India                          INR │
└────────────────────────────────────────┘
ALL COUNTRIES
…

[ Continue → ]
```

| Rule | Source |
|---|---|
| Recent, at most four, only codes that resolve | `.slice(0, 4)` + `GEO.get` filter |
| Popular, the 20 in `GEO.POPULAR`, declared order | not re-sorted |
| All countries, sorted by localised name | `localeCompare(a, b, L.lang())` |
| A search is one flat list, at most sixty | `.slice(0, 60)` |
| A match is name-**contains**, code-**equals**, currency-**equals** | |
| No match is a named state, not an empty list | `.locempty` |
| An empty section is not rendered | which is why Recent is absent on a first run |

### The data

194 countries, generated by `tool/gen_countries.mjs` from the reference's own
table. Two things travel with them that the prototype gets from the platform:

- **Names**, read from the same ICU `Intl.DisplayNames('region')` the browser
  reads, for all three languages. Flutter's `intl` has no `DisplayNames`, so an
  Urdu list would otherwise be 194 English names.
- **Order**, precomputed per language. `localeCompare` is ICU collation;
  `String.compareTo` is code units, which gets Urdu and Arabic subtly wrong.

### What it is not

The brief rules out a flag grid, country tiles, large cards, a three-column
layout, Material progress dots, a generic back arrow and a generic green button.
None of those is in the reference and none is here: it is a vertical list of
rows over a search field, and a test asserts that a row fills the list's width
and that there is no `GridView` on the screen.

### One oddity, reproduced

`.search` carries `margin: 0 var(--pad)` so it can sit directly in a screen.
Inside the picker, which already has a gutter, that insets it a second time —
the field is 310 wide where the list below it is 350. Odd, and what the
prototype draws.

---

## 4. The interests step

[`interests_screen.dart`](../../lib/features/onboarding/presentation/interests_screen.dart),
driven by [`interests_model.dart`](../../lib/features/onboarding/domain/interests_model.dart).
The catalogue question — 31, 29, 57, five or six — is settled in
[INTERESTS_CATALOGUE.md](INTERESTS_CATALOGUE.md).

| Rule | Value |
|---|---|
| Minimum / maximum | 5 / 10 |
| Groups | 6 — five labelled, one switch |
| Chips offered | 29 of 31; `sleep` and `quotes` are unreachable |
| Below the minimum | `{n} of 5 minimum`, Continue disabled |
| At or above | `{n} of 10 selected`, Continue enabled |
| At the cap | unchosen chips at 0.42; a tap is **refused with a message** |
| Clear | empties the selection, leaves the switch alone |
| Faith on | selects prayer, Qur'an, duas, while under the cap |
| Faith off | removes every faith interest and nothing else |

**The step scrolls as one piece.** It has no `--list` modifier, so `.onb-step`
is the scroller and everything but the sticky footer moves with it — including
the kicker, title and supporting copy. Pinning the lead instead left 46 points
for a region needing 52 on a landscape phone, and the column overflowed; the
structure is the fix, not a smaller gap.

---

## 5. The presentation architecture

The same four pieces for both screens, so neither is a mock:

| Piece | Country | Interests |
|---|---|---|
| Presentation widget | `LumeCountryPickerView` | `LumeInterestsView` |
| Typed view model | `LumeCountryPickerModel` | `LumeInterestsModel` |
| Rules, as a pure function | `LumeCountryPicker.build` | `LumeInterests.offer` |
| Controller | `LumeCountryPickerController` | `LumeInterestsController` |
| Fixture adapter | `LumeCountryFixture` | `LumeInterestsFixture` |
| Wiring | `CountryStep` | `InterestsStep` |

The view renders and reports; it does not sort, filter, cap or decide. The
adapter is the only thing that knows the data is bundled JSON. Swapping it for
a Dayroz provider changes the two `build` bodies in `onboarding_steps.dart` and
nothing else — which is the whole point of the split, and why the view takes a
model rather than a repository.

**Dayroz preference migration is documented and not implemented.** No backend,
no persistence: `onContinue` hands the chosen country, the chosen interests and
whether the Islamic experience is on to its caller, and the caller is F4B.

---

## 6. Localisation

52 keys added across `en`, `ur`, `ar`, at full parity — the ARB test fails on
any key English has and the other two do not, and
`l10n_untranslated.json` is empty.

Three groups of string are translated here that the **reference leaves in
English in every language**: the 31 interest labels, the interests step's
supporting copy, and the `{n} of {min} minimum` counter. An untranslated chip in
an Urdu page is a defect, not a design decision. Recorded as **D12**.

---

## 7. Where the promises are tested

| Promise | Test |
|---|---|
| 31 ids, 6 groups, 29 offered, every label in every language, every icon resolves | `interests_catalogue_test.dart` |
| Sections, search, caps, the faith switch, the cap's refusal | `onboarding_model_test.dart` |
| Measured geometry, every required state, RTL, 200 %, accessibility | `onboarding_screen_test.dart` |
| Every element's **position** against the running flow | `onboarding_bounds_test.dart` → [ONBOARDING_PARITY.md](ONBOARDING_PARITY.md) |
| The six cells, plus search, no-results, recent, minimum, cap, faith-open, 200 % | `test/goldens/onboarding_golden_test.dart` |

---

## 8. Differences introduced at F4A

| # | Difference |
|---|---|
| D12 | Interest labels, the interests copy and the counter are translated; the reference leaves them English |
| D13 | The onboarding back chevron mirrors in RTL; the reference mirrors it in auth but not here |
| Q9 | A country row is 41 tall — three under §9's floor, with nowhere to overhang. **Open.** |

All three are in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).
