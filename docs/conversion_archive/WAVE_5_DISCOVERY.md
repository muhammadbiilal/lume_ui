# Wave 5 discovery — provisional, gate not lifted

**Status: discovery only. Not an approved wave.** `ROLLOUT_WAVE_4.md` §8
reads: *"Stop after wave 4 closure. Do not begin a fifth wave... Stop
earlier only for a genuine blocker."* That condition stands. Nothing in
this document authorises implementation, and there is deliberately no
`ROLLOUT_WAVE_5.md` — that name is reserved for the day someone reopens
§8 on the record. This is the research the reopening decision would be
made from, produced because it was asked for, not because the gate moved.

If §8 is reopened, the candidate order in §7 is the recommendation. Until
then, treat every "clears" and "unblocked" verdict below as *would clear*,
not *clears*.

**2026-09-23 — persistence path decided: Option B (session-only, with
disclosure).** The owner picked B over A/C in §2.1: no new storage
dependency is adopted now; Goals and Subscriptions, if and when §8 is
reopened, ship with an explicit on-screen "cleared when you close Lume"
state rather than a claim of durability the current repository cannot
back. This decision does **not** reopen §8 by itself — it only settles
which of the three §2.1 paths a future Wave 5 would use. Habits and
Streak remain excluded under this path for the reason §1 already gives:
their gap is the data model, not only storage, and Option B does not
touch that.

## 0. Where wave 4 left the count

| | |
|---|---:|
| tools in `feature_catalogue.dart` / `catalogue.js` | **85** |
| registered after wave 4 | **37** (34 + `converter`, `birthdays`, `water`) |
| unbuilt | **48** |

Wave 4's own blocker survey (`ROLLOUT_WAVE_4.md` §5) already covers all 48
by reading each one's actual source, schema and translations — not its
catalogue metadata. This document does not re-derive that survey; it
narrows to the tools the brief that prompted this discovery named
(Habits, Streak, Goals, Subscriptions, Meal Plan, plus four smaller
candidates) and adds one finding that survey did not need to state
explicitly, because no prior wave had reached a Blocker-8 tool yet.

## 1. The finding that changes the brief's proposed order

The brief's "Core record wave" (Habits, Streak, Goals, Subscriptions) reads
as four tools blocked only by missing UI. They are not. Wave 4 §5 already
places all four under **Blocker 8 — product/data-model decision** — but
Habits and Streak specifically fail for a *deeper* reason than Goals and
Subscriptions do, and the difference matters for sequencing:

| tool | what the record schema actually holds | what the reference shows | gap |
|---|---|---|---|
| `habits` | `name`, frequency, a **reader-typed** `streak`, notes (nothing else) | `doneToday`, `best: 28`, `rate: 0.82`, a 7-day grid, a 35-day heatmap seeded by PRNG, two insights | 5 of 6 sections have no data behind them at all — this is not a missing screen, it is a missing model |
| `streak` | **no schema exists** | `current: 12, best: 28, thisMonth: 21, rate: 0.78`, PRNG heatmap | the whole tool is currently a view with nothing to view |
| `goals` | needs a typed goal + contribution family — none exists yet, but the *shape* is known (the reference even ships the empty state) | contributions chart | one chart cannot survive; the rest can be modelled cleanly |
| `subs` | needs a typed subscription family — none exists yet, shape is known | renewal projections, price history | modellable in full; storage is the only real gap (see §2) |

Practical read: **Goals and Subscriptions are a data-model-and-storage
problem. Habits and Streak are a data-model-and-storage-and-honesty
problem** — an honest Habits build drops five of its six sections, "past
the point where it is still the tool" (wave 4 §5's own words). Streak
should not be built as a separate tool at all: with no schema of its own,
it is a second view over whatever completion model Habits ends up with,
not an independent record family. Building it separately would create the
exact "duplicate storage, separate streak truth" the brief already warned
against.

## 2. Blocker ranking (per your direction: storage first)

### 2.1 Persistence — blocks all four "core record" candidates equally

Confirmed by direct inspection, not inference:

- `pubspec.yaml` has no persistence package — no `sqlite3`/`sqflite`,
  `hive`, `isar`, `drift`, or even `shared_preferences`.
- `lib/features/records/data/memory_record_repository.dart` is the only
  `LumeRecordRepository` implementation, and its own doc comment states
  the reference state is fixtures, not persistence — records last "as
  long as the app runs," and Dayroz is what "supplies the durable,
  encrypted store behind this same interface."
- `DAYROZ_ARCHITECTURE_MAPPING.md:112` records `shared_preferences` as
  **explicitly rejected** already, not merely absent.

This means a "12-day streak" or "2 active goals" cannot honestly survive
an app restart under the architecture as it stands today. Wave 4 shipped
Water and Birthdays *without* hitting this wall only because both are
list-of-events records where "empty on a fresh launch, real once you log
something" is an honest in-session story — no one reads a Water screen as
implying yesterday's glasses are remembered forever. A streak counter's
entire semantic content is "this survived time"; a session-only streak
is not a smaller version of the feature, it is a different, false claim
every time the app restarts and shows 0.

**This is the actual first blocker for all four core-record candidates,
ahead of the data-model work in §3.** Three honest paths, not mutually
exclusive:

| path | what it means | cost | who decides |
|---|---|---|---|
| A — adopt a persistence package now | pick `drift` or `isar` (both already fit `LumeRecord`'s typed-codec pattern from `FINANCIAL_RECORD_FAMILIES.md`), wire one durable `LumeRecordRepository` implementation, migrate nothing else | a real architecture decision + migration path for the four already-shipped in-memory families (Ledger, Installments, Committee, Baby Budget) once it exists | the reader/owner, not this document |
| **B — scope Wave 5 to session-only, and say so on screen (chosen 2026-09-23)** | ship Goals/Subscriptions (not Habits/Streak — see §1) with an explicit "cleared when you close Lume" state, matching the language `FINANCIAL_RECORD_FAMILIES.md` already uses for the current in-memory families | zero new dependencies, but the honesty rule then forces the same on-screen disclosure Water/Birthdays already carry (C100 precedent) — and it makes a "2 active goals" or "next renewal" claim that resets nightly, which is a materially weaker product than the brief describes | the reader/owner |
| C — wait for Dayroz integration | matches wave 4 §8's own list of what stays stopped ("Dayroz integration") | zero work now, but defers all four candidates indefinitely | the reader/owner |

**Decided: Option B.** No new persistence dependency is adopted. This
settles *which* session-only story a future Wave 5 would ship, not
*whether* one starts — §8 still governs that separately. Goals and
Subscriptions carry an explicit non-durability disclosure; Habits and
Streak stay excluded regardless, per §1's separate data-model gap.

### 2.2 Data-model decisions (second, and only for the tools that clear §2.1)

Per `FINANCIAL_RECORD_FAMILIES.md`'s own shared-foundations table
(identity, money, signs, dates, derived totals never stored, status as a
closed enum with a transition table, validation, privacy, conflict,
import/export, migration) — that document explicitly designed **four**
families (Ledger, Installments, Committee, Baby Budget) and named the gap:
Goals and Subscriptions are not among them. A Wave 5 that includes them
needs a sibling document extending the same shared foundations, not a new
pattern:

- **Goals** — `LumeGoal { id, name, target: LumeMoney, targetDate?,
  currency }` + `LumeGoalContribution { id, goalId, amount, on: LumeDate
  }`. Derived: total contributed, remaining, percent complete, projected
  completion date from contribution cadence (only if that projection is
  computable from real entries — no invented trend lines). Status:
  `active → completed` when contributed ≥ target, `active → abandoned` by
  the reader. This is the cleanest of the four: the reference's own empty
  state is reusable, and nothing about it needs a chart that can't be
  derived. **Under the chosen Option B, the tool also carries an explicit
  "cleared when you close Lume" state** — visible on the same screen the
  goal list appears on, not buried in settings, matching the C100
  disclosure precedent Water and Birthdays already ship.
- **Subscriptions** — `LumeSubscription { id, name, amount: LumeMoney,
  cycle: monthly | yearly | custom(days), startedOn: LumeDate, cancelledOn:
  LumeDate? }` + a derived (never stored) next-renewal date and a
  currency-safe monthly-equivalent total across active subscriptions (sum
  within one currency; refuse or bucket-by-currency across several, per
  the shared foundations' "arithmetic refuses mixed currencies" rule).
  Status: `active → cancelled`, never reversed except by re-adding. Same
  Option B disclosure requirement as Goals.
- **Habits** (excluded under the chosen Option B — session-only storage
  does not close the data-model gap §1 describes; listed here only so the
  model is on record if a future persistence decision revisits Option A) —
  `LumeHabit { id, name, frequency:
  daily | weekly | custom }` + `LumeHabitCheckIn { id, habitId, on:
  LumeDate }`. Everything the reference shows beyond a check-in list —
  streak, best, rate, grid, heatmap, insights — becomes a *derived* view
  over the check-in records, computed the same way Wave 4 computed
  Birthdays' ages and countdowns from a stored date rather than reading
  them as constants. No PRNG, no seeded heatmap, ever.
- **Meal Plan** — needs a product decision before a model, not the other
  way round: reader-entered meal scheduling (a calendar of
  meal-slot → free-text or linked-recipe entries, no nutrition claims) or
  a verified food/nutrition database integration (a Blocker-3/4 problem,
  not Blocker 8). The reference's five headline figures
  (`planned: 18, slots: 21, kcal: 1980, shopItems: 24, cost: 96`) are bare
  constants with no schema behind any of them — `kcal` in particular
  cannot be honestly produced without either the reader typing it or a
  real nutrition source, so "reader-entered scheduling only, no kcal/cost
  claims" is the only path that clears without new sourcing. That scoping
  choice belongs to whoever reopens the gate, not to this document.

### 2.3 The four smaller candidates — a different kind of blocker entirely

Passport, National Savings, Mobile Packages and Mosques are **not**
data-model or storage problems. Wave 4 §5 already places all four under
**Blocker 3 — needs a licensed or verified static source**:

| tool | the specific missing thing | note |
|---|---|---|
| Passport | per-country photo specifications — the reference's "US = 2×2in, everywhere else = 35×45mm" rule is false for several markets | otherwise the cleanest of the four: no invented personal data, capture/import can reuse the Play `toast:`-stub precedent |
| National Savings | the National Savings schedule, which changes over time | needs an owned, refreshable source, not a one-time lookup |
| Mobile Packages | operator tariffs, which change | same shape of problem as National Savings |
| Mosques | a places directory | also faith-gated, so it inherits Islamic-feature visibility rules on top of the sourcing gap |

These four are a **research/licensing task**, not implementation or even
visual-parity work — there is nothing to draw until a source is chosen and
verified. They should not be scheduled alongside the record-family tools
in the same commit sequence; they're blocked on a completely different
kind of decision and can proceed independently once someone owns sourcing
them.

## 3. Visual parity audit — before adding anything new

The brief is right that this has to happen first, and the repo already has
the machinery for it: `VISUAL_VERIFICATION.md`'s capture protocol (9
viewports, 4 "core," across light/dark × en/ur/ar × personalisation state
× text scale 1.0/2.0), `GOLDEN_INVENTORY.md`'s tracked goldens (660 test
cases, 462 committed images), and `COMPONENT_MATRIX.md`'s per-component
conversion status. What's missing is a **screen-level** re-audit table like
the brief asked for, distinct from the per-tool parity files that already
exist for individual tools.

Ran the actual search for the brief's claimed defects first, rather than
assume them: no repo document names "category selection replacing
individual interests," "radio rows replacing multi-select chips," or a
"missing clear action" as findings against *this* codebase. What the repo
does record, at F4A, is a real and comparable correction: the interests
step was found rendering hard-coded English labels with no `data-i18n`
(`KNOWN_DIFFERENCES.md` D12, `INTERESTS_CATALOGUE.md` — 31 ids, 6 groups,
29 rendered, all now translated and chip-based multi-select with a live
`{n} of {min}` counter). That is the right template for how a re-audit
entry should read — a specific defect, a file:line citation, a resolution
— not a claim carried over from elsewhere without checking it against
this repo's own history first.

### 3.1 Filled table

**Method note.** This table was produced by reading the already-regenerated
(2026-09-23) `*_PARITY.md` measured-bounds reports and cross-checking each
against its `*_VISUAL.md` narrative and `KNOWN_DIFFERENCES.md`, not by
re-running `capture_web.mjs`/`compare.mjs` from scratch. A prior tooling
check confirmed the pipeline is fully runnable in this environment (Node,
Chrome and Flutter all present, no missing dependency) but that the
measured-bounds data for all six screens was already current as of the
same day as the latest commits — re-driving Chrome would have regenerated
numbers that already exist. Where a defect is stale or unconfirmed rather
than resolved, the table says so; "—" means checked and clean.

| Screen | Logic status | Structure diff (file:line) | Typography diff | Interaction diff | Dark mode | Urdu/Arabic (RTL) | Action |
|---|---|---|---|---|---|---|---|
| Home | Pass — all diffs ≤1px or cross-referenced | `livecard` -22.31 (`DESTINATION_PARITY.md:86`, →D25/C20); `qactions` -40.00 (`DESTINATION_PARITY.md:56`, clip note) | Recorded, unasserted heading widths by design; D20 line-box rounding | — (dot tap-target and date-format bugs already fixed) | — (reviewed: "authored, not inverted") | — (reviewed: hero-slide overflow bug found and fixed) | None |
| Tools | Pass — no open `KNOWN_DIFFERENCES` refs needed | — (`DESTINATION_PARITY.md:156-238`, all `=`/sub-pixel) | Recorded, unasserted heading widths, same convention as Home | — (search + empty-state states pass; empty-state bug already fixed) | **GAP: captured but not confirmed reviewed** — `DESTINATION_VISUAL.md` §5 lists only "hub at primary cell, hub at 1100" | **GAP: same §5 limitation** — not confirmed eyeballed | Confirm the existing hub dark/Urdu/Arabic captures were actually reviewed, not just captured |
| Profile | **Resolved (2026-09-24)** — `phead.acts` Δ-55 is a measurement-scope artifact, confirmed with evidence, not a Flutter defect | — (`DESTINATION_PARITY.md:373`; the test measures `find.byType(LumeButton).first` while the prototype's box wraps both stacked buttons: 46+9+46=101, confirmed against the raw measurement JSON and the signed-in/expired states, which render one button and match exactly) | No narrative coverage previously existed; now added as `DESTINATION_VISUAL.md` §6 | — (both guest buttons render correctly with the right gap/margin, per `lume_settings.dart`) | **GAP, confirmed real: Profile has never been captured in dark mode** — only the primary light/English cell exists in `DESTINATION_PARITY.md` | **GAP, confirmed real: same single-cell limitation** — no Urdu/Arabic capture exists for Profile at all | Dark mode and RTL capture for Profile still needed before Wave 5 reuses its layout; the Δ-55 finding itself needs no further action (test note corrected, doc section added) |
| Onboarding (interests step) | Resolved — D12 (hard-coded English labels/copy/counter → 31 ids translated, enforced by `interests_catalogue_test.dart`) | — (`ONBOARDING_PARITY.md:201-211`, all within tolerance) | — | — (chip-based multi-select, min/max 5-10, live `{n} of {min}` counter confirmed) | **GAP: never measured or mentioned in any onboarding doc** | Only test-name coverage (`onboarding_screen_test.dart` claims "RTL"), no narrated verdict | **Fixed (2026-09-24):** `ONBOARDING_CONTRACT.md:254`'s stale "Open" label on Q9 corrected to closed, per `KNOWN_DIFFERENCES.md:3412` (F5C) |
| Onboarding (remaining steps) | Pass — 327/327 measured values within tolerance | — (all steps: nav/skip/progress/art/title/text/continue/note bounds) | — (sub-pixel deltas footnoted as CSS artifacts) | — | **GAP: measured only at light/English** — no dark-mode pass documented anywhere | **GAP: D13 back-chevron RTL mirror fix is documented, but no full RTL bounds/narrative verdict exists** | Close the dark-mode and RTL documentation gap; no functional fix needed |
| Account | **Resolved (2026-09-24)** — C89 is a real, intentional, already-documented consequence of commit `eb00909`'s timezone canonicalisation; `ACCOUNT_PARITY.md` is current and correct | C41 open-by-decision (`ACCOUNT_PARITY.md:62-65`, run-together option-row text); C43 open-by-decision (`ACCOUNT_PARITY.md:296-303`, list-moves-with-taller-form); C89 (`ACCOUNT_PARITY.md:182`, Δ-254 on the `time` route's notecard) confirmed via `git show eb00909` — the canonicalised zone list shortens the route's content above the notecard, and `KNOWN_DIFFERENCES.md` already predicted this exact 254pt figure | — (C50 resolved: toolbar subtitle line-height and margin fixed) | Not covered in either doc | **GAP, confirmed real: `ACCOUNT_VISUAL.md`'s golden matrix is light-only — dark mode was never captured for Account** | — (`ur`/`ar` goldens exist across 21 routes, `account_locale_test.dart` asserts no overflow, no defects noted) | **Done:** `ACCOUNT_VISUAL.md`'s stale D20 example (the pre-`eb00909` "2490→2496, six points" reading) corrected and cross-referenced to C89. Still needed: dark-mode golden coverage for Account |
| Authentication | Pass — both deltas are already accepted, deliberate deviations | D19 (accepted): `AUTH_PARITY.md:293-326`, 6-12px header compression on the reset/password-creation screen; D20 (accepted, cosmetic): `AUTH_PARITY.md:207-209`, 0.08px legal-link padding | — (resolved: uppercase-transform and max-width-estimate bugs already fixed) | — (16 states / 115 goldens measured, no open defects; D21 seal-animation swap is cosmetic-only) | — (390×844 dark cell tested, "authored not inverted") | — (Urdu and Arabic cells tested, "RTL, real translations") | None — periodically re-confirm P1/D18/D19/D20/D21 still match |

### 3.2 What this audit actually found, and what was done about it

Two items looked like genuine open questions and were investigated
directly against source (git history, measurement JSON, widget code, web
CSS) rather than left as documentation gaps:

1. **Account's C89** (`ACCOUNT_PARITY.md:182`) — a 254pt delta on the
   `time` route's notecard. **Verdict: real and correct, not a
   regression.** `git show eb00909` ("Follow my region is a preference,
   and never picks one of several zones", 2026-09-19) is the exact commit
   that changed this row from a +6pt D20 reading to the current -254pt
   C89 reading, by canonicalising the timezone list
   (`lib/core/time/lume_country_zones.dart`,
   `lib/core/time/lume_iana_zones.dart`) and shortening the route's
   content above the notecard. `KNOWN_DIFFERENCES.md`'s own C89 entry
   already predicted this exact figure. `ACCOUNT_VISUAL.md` was simply
   never regenerated after that commit landed six days later than the
   doc's own date — fixed by correcting its stale example and adding a
   dedicated C89 subsection.
2. **Profile's `phead.acts` delta** (`DESTINATION_PARITY.md:373`, Δ-55 in
   the guest state) — **Verdict: measurement-scope artifact, not a
   defect.** The prototype's `.phead__acts` box wraps both stacked guest
   buttons (46 + 9 gap + 46 = 101, confirmed against the raw measurement
   JSON's concatenated button-label text); the Flutter test measures only
   `find.byType(LumeButton).first` with `checkHeight: false`, a
   deliberate but previously unexplained scope choice — confirmed by the
   signed-in/expired states, which render one button and match exactly
   (46=46). Fixed: the test's `note:` field now says so explicitly
   (`test/features/destinations/destination_bounds_test.dart`), and
   `DESTINATION_PARITY.md` was regenerated to carry it. No widget code
   needed changing — `lib/core/widgets/lume/lume_settings.dart` already
   renders both buttons with the correct gap and margin.

**Genuinely still open, confirmed real by the same investigation:** Profile
has never been captured in dark mode or Urdu/Arabic at all — only the
primary light/English cell exists for any of its three states. This is
not resolved by the two verdicts above and should be closed before a Wave
5 tool reuses Profile's layout.

Everything else that surfaced is a documentation-coverage gap rather than
a visual defect: Tools' dark-mode/RTL captures exist but were never
confirmed as reviewed; Account has no dark-mode capture at all; Onboarding
has no dark-mode coverage anywhere and only test-name-level RTL coverage;
and the stale "Open" label in `ONBOARDING_CONTRACT.md` (Q9) has been
corrected. None of these block a persistence or data-model decision the
way §2 does, but per the brief's own rule — reuse a shared component only
after confirming it's currently Lume-visual — the remaining dark-mode/RTL
capture gaps for Account, Tools and Profile should close before
`lume_progress`/`LumeCrud` get reused near any of their layouts for a
Goals or Subscriptions build.

Home and Authentication need no action — both are fully reviewed across
structure, typography, interaction, dark mode and RTL, with every
non-zero delta already accepted and named.

## 4. Shared foundations already in place

Reusable today, confirmed by reading the files rather than the names:

- `lib/features/records/domain/{record_model,record_schema,record_repository}.dart`
  — the typed envelope, schema/field-kind system, and repository interface
  every prior record family (Events, Shopping, Documents, Ledger,
  Installments, Committee, Baby Budget) already builds on.
- `lib/features/records/presentation/{record_tool,record_family}.dart` —
  the generic `LumeRecordTool<T>` list/detail/form host.
- `lib/core/widgets/lume/lume_state.dart` — the documented empty / loading
  / error / offline / conflict state widgets a Habits or Goals empty state
  would use unmodified.
- `lib/core/widgets/lume/lume_progress.dart` — progress bar / meter row /
  ring, a direct fit for a goal's percent-complete or (if built) a habit's
  completion rate, once that rate is derived rather than asserted.
- `lib/core/widgets/lume/lume_crud.dart` — CRUD chrome (header, detail
  actions, form card, submit bar, delete confirm) already proven across
  four financial record families.
- `FINANCIAL_RECORD_FAMILIES.md`'s shared-foundations table — the pattern
  to extend for Goals/Subscriptions rather than re-derive, per §2.2.

Not in place, and not to be assumed into existence by reusing the above:
durable storage (§2.1), and a Habits/Streak-equivalent "personal record
families" design document — `FINANCIAL_RECORD_FAMILIES.md` covers money
between people, not habit check-ins, so a parallel short design note would
be needed for Habits alone, if and when it's judged worth building per §1.

## 5. Localisation cost

`l10n.yaml` uses one ARB file per locale (`app_en.arb`, `app_ur.arb`,
`app_ar.arb`), not per-feature sharding, and
`test/core/localization/arb_parity_test.dart` fails the build on any key
mismatch across the three. Every candidate tool's strings — labels, empty
states, form fields, error messages — must land in all three files in the
same change, matching the discipline `INTERESTS_CATALOGUE.md`/D12 already
established. No candidate in this discovery is exempt; none of Goals,
Subscriptions, Passport, National Savings, Mobile Packages or Mosques has
existing translation coverage to inherit.

## 6. One open item outside this discovery's scope

`README.md`'s phase table lists F6 ("Tool screens, in archetype batches")
and F7 ("CRUD across every record family") as **not started**, while
`ROLLOUT_WAVE_1.md`–`ROLLOUT_WAVE_4.md` document 37 tools already
registered and four record families already shipped. That table appears
stale against the rollout docs. Flagging it here because a Wave 5 decision
should probably be made against an accurate phase table — but correcting
it is a documentation-accuracy task independent of whether §8 is ever
reopened, and is not addressed by this document.

## 7. If §8 is reopened — recommended order (not authorised)

Sequencing purely by which decisions block which. §2.1's persistence path
is now decided (Option B), which removes one step from the order below
without reopening §8:

1. **Visual parity re-audit** (§3) — no new tool work should start before
   this table exists, per the brief's own rule.
2. **Goals** — cleanest data model, reuses `FINANCIAL_RECORD_FAMILIES.md`
   patterns almost directly, reference ships its own empty state, ships
   with the Option B "cleared when you close Lume" disclosure.
3. **Subscriptions** — same shared-foundations reuse and disclosure
   requirement, slightly more derivation work (renewal dates,
   monthly-equivalent totals).
4. **Habits** — stays excluded under Option B (§1, §2.2); would need a
   separate persistence decision to be revisited before it can be
   proposed again. No separate Streak tool either way: if Habits is ever
   built, Streak becomes a view over its check-in model, not an
   independent record family.
5. **Meal Plan** — only after the reader-entered-vs-verified-database
   decision in §2.2 is made; otherwise it stays where wave 4 left it.
6. **Passport, National Savings, Mobile Packages, Mosques** — independent
   sourcing/licensing track, not sequenced against 1–5; can start in
   parallel once someone owns finding each source.

## 8. Expected commit boundaries (if reopened)

Following the one-tool-per-commit-family discipline already visible in
`ROLLOUT_WAVE_1.md`–`ROLLOUT_WAVE_4.md` and the four `*_PROPOSAL.md`
precedents (`LEDGER_PROPOSAL.md`, `INSTALLMENTS_PROPOSAL.md`,
`COMMITTEE_PROPOSAL.md`, `BABY_BUDGET_PROPOSAL.md`):

- No persistence-package commit is needed under the chosen Option B —
  Goals and Subscriptions build on the existing
  `MemoryRecordRepository`, same as Ledger/Installments/Committee/Baby
  Budget do today.
- One `*_PROPOSAL.md` per new record family (Goals, Subscriptions) —
  design before implementation, matching `FINANCIAL_RECORD_FAMILIES.md`'s
  own pattern, each stating the Option B disclosure explicitly — reviewed
  independently before its implementation commit. Habits gets no proposal
  document until a persistence decision revisits Option A.
- One implementation commit per tool: typed model + codec, codec
  round-trip and migration tests, transition-table tests, the on-screen
  non-durability disclosure, l10n keys in all three ARB files, parity
  test, and captured goldens across the `VISUAL_VERIFICATION.md` matrix —
  the same bar wave 1–4 already hold every shipped tool to.
- Meal Plan and the four sourcing-blocked tools each get their own
  commit boundary, independent of the record-family sequence, once their
  respective blocking decision (§2.2 scope choice / §2.3 source) is made.

No commit in this list is authorised by this document. It exists so that,
if the gate is reopened, the work described here does not need to be
re-discovered.
