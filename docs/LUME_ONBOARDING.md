# Lume onboarding

The first run. Nine steps that take someone from a cold install to a home
screen that already knows where they are, what language they read, what they
came for, and — only if they say so — that they would like the Islamic
experience.

This is the maintenance document for the Flutter application. It describes what
the flow *is*, not what it was converted from.

---

## 1. The nine steps

| # | Step | Widget | What it collects |
|---|---|---|---|
| 0 | Welcome | `WelcomeStep` | nothing — brand, promise, and a way into sign-in |
| 1 | Plan | `ValueSlideStep` | nothing |
| 2 | Tools | `ValueSlideStep` | nothing |
| 3 | Where are you based? | `CountryStep` | country |
| 4 | Which city are you in? | `CityStep` | city, and the region it sits in |
| 5 | What are you here for? | `InterestsStep` | interests, and whether the Islamic experience is on |
| 6 | Set it up once | `SetUpStep` | location and reminder permissions, prayer calculation method |
| 7 | What should we call you? | `NameStep` | display name (optional) |
| 8 | All set | `DoneStep` | nothing — it reports |

`LumeOnboardingStep` names all nine. No step writes its own index, and the
progress bar has nine segments because `LumeOnboardingStep.count` is nine.

**Country and religion never touch.** Nothing on step 3 or 4 turns the Islamic
experience on, and nothing on step 5 changes the country. The only thing that
enables Islamic content is the switch on step 5, or an Islamic interest chosen
under it.

---

## 2. Routes and state

```
                       ┌──────────────────────────────────────────┐
  /onboarding  ───────▶│ LumeOnboardingFlowLoader                 │
                       │   loads the country and interest tables  │
                       │        │                                 │
                       │        ▼                                 │
                       │ LumeOnboardingFlow ── holds _step        │
                       │                    ── holds _draft       │
                       │                    ── holds _interests   │
                       └───────────┬──────────────────────────────┘
                                   │ onDone(outcome, record)
             ┌─────────────────────┼─────────────────────┐
             ▼                     ▼                     ▼
        finished               skipped                signIn
             │                     │                     │
             └────────▶  /  ◀──────┘                     ▼
                                                       /auth
```

Back moves one step. Back on step 0 leaves the flow — the system gesture and
the header control do the same thing, through `LumeBackIntercept`.

### Who owns what

| State | Owner | Lives for |
|---|---|---|
| Which step | `LumeOnboardingFlowState._step` | the flow |
| Everything collected | `LumeOnboardingFlowState._draft` | the flow |
| The interest selection | `LumeOnboardingFlowState._interests` | the flow |
| The search text on steps 3 and 4 | the step's own controller | the step |
| What is saved | `LumeOnboardingStore` | the install |

A step never writes to the store. It reports upward, the flow folds the report
into the draft, and the flow decides when a draft becomes a record. That is why
walking back to the city step and forward again finds the same five interests
still chosen: they were never in the step to begin with.

---

## 3. What is written, and when

| After | What lands in the store |
|---|---|
| step 4 · Continue | country, region, city — the interests step filters on location, so it needs them before it opens |
| step 5 · Continue | interests, and `islamic` |
| step 7 · Continue | display name, only when it differs from what was there |
| step 8 · Enter Lume | the whole draft, and `onboarded` |
| **Skip**, at any step | the defaults for what was not answered, and `onboarded` |
| **Sign in**, step 0 | the same defaults, and `onboarded` |

Skip is a first-class outcome, not an abandonment: someone who skips gets a
working app with sensible defaults, not an empty one. Step 7's own "Skip for
now" is narrower still — it advances and writes *nothing*, because an untouched
name field is not an instruction to erase the name that was already there.

### Migration

An installation from before the Islamic preference existed has no answer for
it. `LumeOnboardingState.migrateIslamicDefault` runs once, before the flow
reads anything:

* `islamic == null` becomes `false`. **Absence is not consent** — §3 says never
  infer religion, and a missing value is a missing value, not a yes.
* The migration is recorded in `LumeProfileRecord.migrations`, so it runs once
  and can be told apart from a user who chose `false`.
* Turning the experience off later **hides** Islamic content. It does not
  delete anything: bookmarks, reading positions and tracked prayers survive, and
  come back if it is turned on again (§37).

---

## 4. Validation

| Step | Rule | What happens when it is not met |
|---|---|---|
| 3 | a country must be selected | Continue is inert; one is preselected, so this rarely bites |
| 4 | a city must be selected | Continue is inert |
| 5 | between 5 and 10 interests | Continue is inert below 5; an 11th is refused with a message, not silently dropped |
| 7 | the name is trimmed and capped at 40 | the cap is applied as it is typed, not on submit |

Nothing else validates. There is no field on this flow that can be wrong in a
way the user cannot see.

---

## 5. Adapting to the surface

| Surface | What changes |
|---|---|
| any width | the step is one column; there is no tablet variant of onboarding |
| **short** (under 480 points tall) | the two list steps hand their lead *and* their search field to the list, so everything above the footer scrolls as one piece |
| 200 per cent text | every step scrolls; nothing is clipped and nothing overlaps |
| keyboard open | the step region ends where the keyboard begins, so nothing is laid out underneath it |
| RTL | the whole flow mirrors; the back chevron mirrors with it, because it means "back", not "left" |

The illustration stage absorbs slack: on a tall phone the drawing sits lower
and the copy with it, rather than leaving a gap above the footer.

---

## 6. Accessibility

* Every control clears 44 points. Where the drawn box is smaller — the back
  circle at 34, Skip at 32, the secondary link at 36, a method pill at 34 — the
  *target* is still 44 and the extra is taken out of the space around it, so
  nothing moves and no two targets overlap.
* The one exception is a **location row**, which is 41. The rows are adjacent,
  so a taller target would overlap its neighbour's; the row is 350 points wide,
  so the miss the floor guards against is not the one on offer. Approved as a
  screen-specific exception and not a precedent for narrow controls.
* Uppercase labels are announced in the case they were written in, so a screen
  reader does not spell them out.
* The progress bar carries no semantics: it is decoration over a flow the
  headings already announce.
* The completion seal animates once and is simply *there* under reduced motion.
* Colour never carries a state alone — a selected row is tinted **and** its
  name changes weight and colour.

---

## 7. Localisation

English, Urdu and Arabic, with full key parity enforced by test. Country names
are localised and sorted by the reading locale's own collation, so an Urdu list
is in Urdu order rather than in code-point order.

**Known gap.** City and region names are held in one language. The model and
the adapter already take a language, so localising them is a data change rather
than a code change; it is not done because the table does not carry the names
yet.

---

## 8. Deliberate differences from the design source

Recorded in full in `docs/conversion_archive/KNOWN_DIFFERENCES.md`. The ones
that change what a user sees:

| # | Difference | Why |
|---|---|---|
| D14 | On a short screen the two list steps scroll as one piece | The source squeezes the list to nothing and draws the search field over the action |
| D15 | Method pills sit 10 apart rather than 7 | Two 44-point targets cannot sit 7 apart without overlapping |
| D16 | The secondary link's box is 44 rather than 36 | The same floor; the text does not move |
| D17 | The method the user picks is the method that is stored | The source's pills are decorative — they neither read nor write the preference |

---

## 9. Evidence

* `test/features/onboarding/onboarding_flow_test.dart` — the nine-step machine,
  every skip, every back, and a layout check for each step at five surfaces in
  three languages, in dark, at 200 per cent and with the keyboard up.
* `test/features/onboarding/onboarding_state_test.dart` — the draft, the record,
  the migration and `shouldShow`.
* `test/features/onboarding/onboarding_bounds_test.dart` — 327 element
  positions, each within a logical pixel of the design source.
* `test/goldens/onboarding_flow_golden_test.dart` — all nine steps at eight
  surfaces, plus the states that only appear under a condition.

---

## 10. Not done yet

The flow is complete and routed at `/onboarding`, and every outcome is written
through `LumeOnboardingStore`. The **first-run gate** — sending a new install
to `/onboarding` on launch — waits for a store that survives a restart;
`LumeOnboardingState.shouldShow` is the predicate it will call, and it is
already specified and tested. Until then the flow is reached by route.
