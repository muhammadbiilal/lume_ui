# Rollout wave 6 — the gate reopened, on the record

`ROLLOUT_WAVE_5.md` §5: *"Closure does not reopen §8 further than the
scope in §0 — a sixth wave is a new decision, not an inference from this
one."* This document is that decision, dated 2026-09-24, following
`WAVE_6_DISCOVERY.md`'s research.

## 0. The decision

Reopened for exactly one tool: **`mealplan`**, scoped to reader-entered
scheduling only — no kcal, shopping-item or cost claims, per the owner's
explicit choice between the two paths `WAVE_6_DISCOVERY.md` §1.4 named.
The owner's direction: implement matching the reference web UI's own
composition, the same way Goals and Subscriptions were built in wave 5.

## 1. The wave

**One tool: `mealplan`.** Not widened to include Reminders, Alarms, or
anything else — `WAVE_6_DISCOVERY.md` §2 re-checked every other blocker
category directly against the current repo and found none of them
changed: Reminders' schema is unchanged and no notification/permission
infrastructure exists yet; Alarms has no schema at all; every other
category needs a sourcing, licensing, medical or religious decision this
wave does not make.

## 2. What "reader-entered scheduling only" means

Kept from the reference: the exact composition and order — a summary
card, then the week as seven expandable days each holding a
breakfast/lunch/dinner slot, then the two navigation buttons to Shopping
and Recipes. What changes: every slot's content is the reader's own text,
entered by the reader, not a rotation through a fixed recipe fixture; the
summary card's real number is how many of the 21 slots are filled, not
`planned: 18` typed into the reference; the calorie chart and the
`kcal`/`shopItems`/`cost` stats are dropped entirely — none of them can be
honestly produced without either the reader typing a value the reference
never asks for, or a nutrition source this repo does not have.

## 3. Persistence

Option B, unchanged — no persistence package. `mealplan` joins
`readerRecords`, the same as every other wave-5-and-earlier record
family: a reader's build opens it empty, and the reference's own fixture
was never real data to reproduce.

## 4. Process

Same as wave 5: `MEALPLAN_PROPOSAL.md` (design before implementation) →
implementation → the integrated gate → a coherent commit, no attribution
trailers.

## 5. Closure

Closes when `mealplan` is registered, tested and reported against
`MEALPLAN_PROPOSAL.md`'s own criteria. Closure does not reopen §8 further
than this scope — a seventh wave is its own decision.
