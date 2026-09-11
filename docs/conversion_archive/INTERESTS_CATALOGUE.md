# The interest catalogue: 31, 29, 57 and six

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Two figures had been reported for the same thing — **31 interests** in one place
and **57 chips** in another — and the group count had been given as both five and
six. A conversion cannot proceed on "about thirty", so this settles it against
the runtime and the catalogue, which are the only authorities.

Everything below is asserted by
`test/features/onboarding/interests_catalogue_test.dart` and derived by
`tool/gen_interests.mjs`. Neither number is typed anywhere by hand.

---

## 1. The answer

| Figure | Value | What it counts |
|---|---|---|
| Interest ids in the catalogue | **31** | `INTEREST_GROUPS` in `data/catalogue.js` |
| Groups | **6** | five ordinary, one faith |
| Chips the picker renders | **29** | the 31, less two no feature can reach |
| The "57" | **not a count of interests** | `.pick` elements in the whole document, with two pickers mounted |

---

## 2. The 31, by group

| Group | Count | Ids |
|---|---|---|
| `everyday` | 7 | weather, calendar, tasks, notes, convert, maths, alarms |
| `money` | 5 | expenses, rates, bills, savings, markets |
| `health` | 5 | habits, water, fitness, meds, **sleep** |
| `travel` | 4 | trains, flights, nearby, fuel |
| `news` | 4 | news, cricket, reading, **quotes** |
| `faith` | 6 | prayer, quran, hadith, duas, zakat, ramadan |
| | **31** | |

The two in bold are the difference between 31 and 29.

---

## 3. Why 29 render, not 31

`liveItems` in `ui/pickers.js` keeps an ordinary interest only when some
**visible** feature declares it:

```js
return g.items.filter(function (it) {
  return C.FEATURES.some(function (f) {
    return f.ints && f.ints.indexOf(it.id) !== -1 && visibleIn(f, ctx);
  });
});
```

Across all 85 features, `ints` references **29 distinct interest ids**. `sleep`
and `quotes` are referenced by none, so no context can make them visible and
the prototype never renders them.

Confirmed at runtime across four personalisation states — PK Muslim, PK
non-Muslim, GB non-Muslim, US non-Muslim — all of which render **29**:

```
weather calendar tasks notes convert maths alarms
expenses rates bills savings markets
habits water fitness meds
trains flights nearby fuel
news cricket reading
prayer quran hadith duas zakat ramadan
```

**This is a finding about the reference, not a decision about the conversion.**
Two dead entries in a catalogue are the same class of thing as the dead
`.onb-country` CSS in C1 — but unlike C1 they are *not* deleted here, because
deleting them changes the prototype, and the prototype is the source of truth
while the conversion runs. The Flutter catalogue carries all 31 and filters the
same two out by the same rule, so if a feature ever declares `sleep`, the chip
appears in both.

---

## 4. Where 57 came from

`ui/pickers.js` builds the picker **twice**, and both live in the document at
once:

| Host | Built by | Chips (PK, non-Muslim) |
|---|---|---|
| `#onbPicker` | onboarding step 6 | 29 |
| `#setPicker` | the personalisation sheet | 28 |
| | `document.querySelectorAll('.pick').length` | **57** |

Measured directly:

| State | `#onbPicker` | `#setPicker` | document |
|---|---|---|---|
| PK, non-Muslim | 29 | 28 | **57** |
| PK, Muslim | 29 | 29 | 58 |
| GB, non-Muslim | 29 | 27 | 56 |
| US, non-Muslim | 29 | 27 | 56 |

So 57 was a document-wide element count in one particular state, not a
catalogue figure. The onboarding picker is 29 in every state tested.

---

## 5. Five groups or six

**Six.** Five render a visible `.pickgroup__label`; the sixth — `faith` — has no
label because its heading *is* the switch:

```html
<div class="pickgroup pickgroup--faith">
  <button class="faithtoggle">…Islamic features…<span class="switch">…</span></button>
  <div class="picker picker--nested" hidden>…six chips…</div>
</div>
```

Counting headings gives five. Counting groups gives six. The Flutter model
carries six and marks one `faith: true`, so both questions have an answer and
neither is a guess.

---

## 6. What the faith group does

Kept apart on purpose, and **never preselected for anyone** (§3: the product
never asks whether someone is Muslim and never infers it). Choosing an Islamic
interest is what switches the experience on.

| | behaviour |
|---|---|
| Exempt from `liveItems` | it is the switch that makes its own features exist |
| Hidden until the switch is on | `.picker--nested[hidden]`; Flutter builds nothing |
| Turning it **on** | selects `prayer`, `quran`, `duas`, while under the cap |
| Turning it **off** | removes every id in `FAITH_INTERESTS` and nothing else |
| Inferred state | on when the restored selection holds any faith interest |

---

## 7. The bounds

`PICK_MIN = 5`, `PICK_MAX = 10`. Below five the counter reads
`{n} of 5 minimum` and Continue is disabled; at five and above it reads
`{n} of 10 selected`. At ten, unchosen chips drop to 0.42 opacity and a tap is
**refused with a message** rather than ignored.

---

## 8. Labels

The prototype hard-codes English labels in `INTEREST_GROUPS` and renders them
untranslated in every language — an Urdu user sees "Tasks & to-dos". The
generated asset therefore carries **no labels**, only ids and icons; the Flutter
app translates all 31 in all three languages and a test fails if one is missing.
Recorded as **D12** in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

---

## 9. How to re-derive any of this

```
node docs/conversion_archive/tool/gen_interests.mjs
flutter test test/features/onboarding/interests_catalogue_test.dart
```

The generator reads `assets/js/data/catalogue.js` and nothing else. The test
compares the generated asset back against that file, so the two cannot drift.
