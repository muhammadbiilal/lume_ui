# Rollout wave 5 — the gate reopened, on the record

`ROLLOUT_WAVE_4.md` §8 reads: *"Stop after wave 4 closure. Do not begin a
fifth wave, Dayroz integration, an Expenses migration, backend work, Fuel
Cost, BMI or Public Holidays. Stop earlier only for a genuine blocker."*

**That condition is not silently superseded. It is explicitly reopened,
for the scope below, by the owner's own decision, dated 2026-09-24.** The
discovery that preceded this decision is `WAVE_5_DISCOVERY.md`, produced
before the gate moved and left unchanged as the record of what was known
before this wave was authorised. Where this document and that one
disagree about status, this document is the current one; the discovery
document's own findings about blockers, shared foundations and the
persistence decision still stand and are not repeated in full here.

## 0. The decision, verbatim

> Wave 4 is closed, and the six-screen visual-parity re-audit is
> complete. I am explicitly reopening the Wave 5 implementation gate in
> `ROLLOUT_WAVE_4.md` §8 for the scope below. Record that decision in
> `ROLLOUT_WAVE_5.md`; do not treat the old stop condition as silently
> superseded.
>
> The mission remains conversion of the existing Lume HTML/CSS/JS
> experience to Flutter. Use the web prototype as the authority for
> layout, typography, components, interactions, states, responsive
> behavior and visual language. Do not redesign Lume or begin Dayroz
> integration.
>
> Wave 5 scope: Goals and Subscriptions. Use the already chosen Option B
> from `WAVE_5_DISCOVERY.md`: the existing session-only repository, with
> a clear on-screen disclosure that records are cleared when Lume
> closes. Do not add a persistence package or imply durable storage.
> Derive displayed figures from typed, reader-created records; never
> present prototype fixtures as live user data.

## 1. The wave

**Two tools: `goals`, `subs`.** Not four, not the whole "core record"
candidate list `WAVE_5_DISCOVERY.md` §7 sketched. Habits and Streak are
explicitly excluded — their gap is the data model, not only storage (§1 of
the discovery), and Option B does not close it. Meal Plan needs a product
decision this wave does not make. The wave is not inflated to hit a tool
count.

### 1.1 `goals` — Savings Goals

Design-before-implementation happens in `GOALS_PROPOSAL.md`, following
`FINANCIAL_RECORD_FAMILIES.md`'s own pattern (that document designed four
families and named Goals and Subscriptions as the gap). Read against the
reference's actual source, not the catalogue's metadata, per this wave's
own rule and every prior wave's.

### 1.2 `subs` — Subscriptions

Same discipline, in `SUBSCRIPTIONS_PROPOSAL.md`.

## 2. Persistence: Option B, unchanged from the discovery

No persistence package is adopted. Both tools build on the existing
in-memory `LumeRecordRepository` implementation the four shipped financial
families already use. Each carries an explicit, visible disclosure that
its records are cleared when Lume closes — not a settings-page footnote,
on the same screen the records themselves appear on, matching the
disclosure precedent Water and Birthdays already carry (C100). Habits and
Streak stay out of this wave precisely because Option B does not solve
their separate data-model gap; nothing in this wave should be read as
extending Option B's suitability to them.

## 3. What this wave does not touch

Per the owner's decision and `ROLLOUT_WAVE_4.md` §8's surviving scope:

- No redesign of Lume's visual language, information architecture or
  interaction model. The web prototype remains the authority for both
  tools' layout, typography, components, states and responsive behaviour,
  exactly as every prior wave has treated it.
- No Dayroz integration, no backend work, no persistence package.
- No Habits, Streak, Meal Plan, Passport, National Savings, Mobile
  Packages, Mosques, live-feed tools, medical or religious-domain tools.
- No re-litigating Fuel Cost, BMI or Public Holidays — those holds stand
  from wave 4 §6.

## 4. Process for this wave

1. **Proposal before code**, per tool: read the tool's full web source
   (JS, CSS, record schema if any, translations), map every visible state
   and interaction to Flutter, specify the typed record model and its
   derived calculations, name every reference defect or deliberate
   omission found, and define the parity captures and tests the tool will
   need. `GOALS_PROPOSAL.md` and `SUBSCRIPTIONS_PROPOSAL.md`.
2. **Implementation**, both tools, without a further approval pause
   unless a genuinely new decision surfaces that would materially affect
   stored data or safety — matching the owner's own instruction, so a
   defect found mid-implementation is fixed and recorded the way every
   prior wave's corrections were, not escalated as a fresh blocker.
3. **Coverage**: English, Urdu and Arabic; RTL; dark mode; phone,
   landscape and wide layouts; 200% text; keyboard and screen-reader
   behaviour; focused unit/widget tests; named web-to-Flutter visual
   comparisons, in the same shape `VISUAL_VERIFICATION.md` and the four
   shipped financial families already use.
4. **Integrated gate** run after both tools are stable — the full
   relevant test suite, not a per-tool subset, matching the bar every
   prior wave closed on.
5. **Commits** coherent, without attribution trailers, matching this
   project's standing convention.
6. **Report** exact evidence and any remaining differences, the way
   `ROLLOUT_WAVE_4.md` §2 and §7 do for its own three tools.

## 5. Closure

This wave closes when both tools are registered, tested, captured and
reported against the criteria above. Closure does not reopen §8 further
than the scope in §0 — a sixth wave is a new decision, not an inference
from this one.
