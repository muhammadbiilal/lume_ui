# Known differences, contradictions and corrections

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Three separate things live here, and they are kept apart on purpose:

- **§1 Permitted native differences** — where Flutter is allowed not to
  reproduce the browser literally.
- **§2 Contradictions found in the sources** — where two authorities disagreed,
  how it was resolved from the source, and what was corrected.
- **§3 Open questions** — decisions that need an answer before the phase that
  depends on them.

Anything visible or behavioural that is not in §1 must be corrected, or added
to §2 with explicit approval. "The test passes" is not a resolution.

---

## 1. Permitted native differences

These seven are approved by the brief. Nothing else joins this list without a
written decision.

| # | Difference | Why |
|---|---|---|
| P1 | Native status bar and navigation bar | The OS owns them |
| P2 | Native keyboard | The OS owns it |
| P3 | OS permission dialogs | The OS owns them |
| P4 | Platform accessibility requirements | TalkBack/VoiceOver conventions override a web ARIA shape where they conflict |
| P5 | Safe-area handling | `SafeArea` rather than `env(safe-area-inset-*)` |
| P6 | Compact-height adaptation | See D1 below |
| P7 | Font rasterisation and anti-aliasing | Skia is not Blink |

### Consequences of P1 and P5 — the simulated chrome

The web prototype draws its own status bar (`.statusbar`: a Lume mark, a `9:41`
clock, signal/wifi/battery glyphs). At **compact** width this is a stand-in for
the device's own bar and is replaced by the real one plus `SafeArea`.

At **medium and expanded** width it is not a stand-in — `responsive.css` turns
it into the top of the application, gives it a `card` background, a bottom
border, 12 px block padding and the brand mark, and moves the clock to `order: 2`.
That strip is application chrome and **is** reproduced.

### Consequence of the same reasoning — the stage and the device frame

`base.css` renders the shell as a device on a desk once the window passes
600 px: 24 px of stage padding, a radial-gradient ground, and the app given
`border-radius: 26px`, a 1 px border, `--shadow-lg` and a height of
`min(100dvh - 48px, 980px)`. Below 600 px it caps the app at 560 px wide and
centres it.

**None of this is reproduced.** It exists so a prototype viewed on a monitor
reads as a device; in Flutter the app *is* the device. The stage, the frame, the
560 px cap and the 980 px height clamp are dropped. Everything *inside* the
frame is the real layout and is reproduced exactly.

This means a web capture at 1100 px and a Flutter capture at 1100 px will differ
by the frame and its surround. The comparison tool therefore measures the
**shell** in both, not the window — see
[VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md).

### D1 — the compact-height override

**Status: approved by the brief (§9), and already implemented in Dayroz.**

The web prototype's three width classes are width-only. It never met a phone
held sideways. A landscape iPhone is 852 × 393 or 926 × 428 logical pixels,
which crosses the 840 px expanded boundary on width alone — so on the web rule
a phone on its side would be handed a 244 px persistent sidebar and a two-pane
master-detail layout on a surface 393 px tall.

The Flutter reference therefore adds one rule the web does not have: **below
480 logical pixels of height the shell is compact whatever its width.** 480 is
Material's own compact-height boundary and it separates the two populations
cleanly:

| Surface | Size | Height class | Presentation |
|---|---|---|---|
| iPhone SE, landscape | 667 × 375 | compact | compact |
| iPhone 14 Pro, landscape | 852 × 393 | compact | compact |
| iPhone 14 Pro Max, landscape | 926 × 428 | compact | compact |
| iPad mini, portrait | 744 × 1133 | tall | medium |
| iPad mini, landscape | 1133 × 744 | tall | expanded |
| iPad Pro, landscape | 1366 × 1024 | tall | expanded |

No tablet loses its rail or sidebar in either orientation; no phone gains one.

The **content measure** keeps the width-only class. Navigation and panes are
about room; the reading cap is about line length, and a 900 px line of body text
is too long to read whatever the height. So the shell publishes a height-aware
`widthClass` for navigation and panes, and a width-only `measureClass` for the
reading cap.

### D2 — `text-wrap: balance` and `text-wrap: pretty`

`.onb__title` uses `text-wrap: balance` and `.onb__text` uses `text-wrap: pretty`.
Flutter has no equivalent; its line breaker is greedy. Expect the last line of a
long onboarding title to break at a different word than the browser does.

**Approved with a condition (Q1, F1).** A shaping difference is accepted only
when the line count matches, the same text stays visible, no truncation changes,
the text measure and hierarchy match, and the component height and surrounding
layout stay materially equivalent. Where the line count or the layout differs,
the Flutter constraints and typography are adjusted until they do not. Anything
left after that is rasterisation-only and is listed per screen.

### D3 — network-fetched fonts

**Resolved in F1.** The web loads Plus Jakarta Sans and Noto Naskh Arabic from
the Google Fonts CDN; Flutter bundles both locally with their OFL licences, so
it renders offline and on the first frame. All five Plus Jakarta weights (400,
500, 600, 700, 800) ship real files, verified from each binary's
`OS/2.usWeightClass` rather than from its filename, so nothing is synthesised.
Checksums and provenance: `assets/fonts/PROVENANCE.md`. A build difference with
no visual consequence.

### D4 — Urdu is set in Naskh, not Nastaliq

**New in F1, needs a decision (Q6).**

Plus Jakarta Sans has no Arabic glyphs, and Flutter — unlike a browser — does
not fall back to a system face on its own. Without a declared fallback every
Urdu and Arabic interface string renders as tofu. `LumeType` therefore falls
back to **Noto Naskh Arabic**, which is the face the reference loads and the
only Arabic-script face the design asks for.

Urdu is conventionally set in **Nastaliq**, which is a different face with a
very different look. The reference does not ship it, so bundling one would be
the conversion inventing a design decision. Dayroz separately bundles
`NotoNastaliqUrdu-Medium.ttf`, which is evidence the production app considers
Naskh wrong for Urdu.

Recorded rather than decided. See §3, Q6.

### D5 — numeric runs are direction-isolated

**Resolved in F1, and worth recording because it is invisible until it is
wrong.** `rtl.css` gives `.num`, `.locrow__code` and `.trainno`
`direction: ltr; unicode-bidi: isolate`. Without the equivalent in Flutter, a
line holding two numeric runs reorders them: `1,240.50  16:41` renders as
`16:41 1,240.50` in an Urdu page. The digits are right; their *sequence* is not,
so a price and a time silently swap places. `LumeNumerals` / `LumeLtr` supply
both the direction and the isolation.

---

## 2. Contradictions found in the sources

### C1 — the onboarding country step: list or grid?

**Resolved. No design change. A stale rule to delete.**

The brief's §13 says the country screen must be a *vertical country list* with
the code on the left, the name in the middle and the currency code on the
right, and explicitly forbids a *flag grid*, *large country cards* and
*three-column tiles*.

`assets/css/onboarding.css` ends with:

```css
.onb-country { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
@media (max-width: 359px) { .onb-country { grid-template-columns: repeat(2, 1fr); } }
```

which is exactly the three-column tile layout the brief forbids.

**What the interface actually renders.** Step 3 of
`assets/js/screens/onboarding.screen.js` is:

```html
<div class="locpicker" id="onbCountry"></div>
```

filled by `makeLocationPicker` in `assets/js/ui/pickers.js`, which builds a
search field over a `.loclist` of `.locrow` buttons, each carrying
`.locrow__code`, `.locrow__name` and `.locrow__meta` (the currency), grouped
into **Recent**, **Popular** and **All countries** over the full 194-country
database.

`.onb-country` appears **nowhere** in `assets/js/`, `index.html` or `tests/` —
verified by full-tree grep. It is dead CSS from a superseded implementation.

**Resolution.** The brief and the rendered interface agree; only the stale rule
disagreed, and it had no effect because no element ever carried the class.

**Deleted in F1**, in its own commit, against the evidence asked for:

* a repository-wide search found `.onb-country` only in its own definition and
  in this document — the JavaScript's `#onbCountry` is an element *id*, the
  host the location picker renders into, and is unrelated;
* the web suite was 10 suites / 697 assertions / 0 failures both before and
  after;
* the country step was captured at 390 × 844 before and after, and the two PNGs
  are **byte-identical** (SHA-256 `81c4b116…`).

That capture is also the definitive answer to the contradiction: the step shows
a circular Back button, a nine-segment progress indicator, Skip, the
"MAKE IT LOCAL" kicker, the title and supporting copy, a search field, a
"POPULAR" heading, and a vertical list of rows carrying the country code on the
left, the name in the middle and the currency code on the right, with dividers
and a tinted selected row — exactly what §13 asks for, and nothing the §13
"do not use" list forbids.

### C2 — "individual screens must not invent their own breakpoints"

**Resolved. The brief's intent holds; the literal statement does not match the
source.**

The brief's §9 asks for one centralised breakpoint system and says individual
screens must not invent their own unrelated breakpoints. The stylesheets carry
four rules beyond `data-bp`:

| Rule | Files |
|---|---|
| `@media (max-width: 359px)` | `auth.css`, `account.css`, `onboarding.css`, `screens/home.css`, `screens/tools.css`, `tools/markets.css` |
| `@media (min-width: 1180px)` on `.app--wide` | `auth.css`, `account.css`, `tools/shared.css`, `tools/markets.css` |
| `@media (min-width: 1380px)` on `.app--wide` | `auth.css` |
| `@media (840px–1100px)` + `[data-split="1"]` | `responsive.css` |

These are real and visible: below 360 px the tools category grid drops to two
columns, the Home greeting drops to 20 px and the auth title to 28 px; above
1180 px the metric grid goes to four columns and the tiles grid to five.

**Resolution.** They are not *unrelated* breakpoints — they are refinements
inside a width class, and they are not per-screen inventions either, since the
same two numbers recur across six files. They become **named constants on the
centralised system** (`LumeBreakpoints.narrow = 360`,
`LumeBreakpoints.wide = 1180`, `LumeBreakpoints.ultrawide = 1380`) and the
owning widget measures its own constraints against them. No screen writes a
literal. The brief's intent — one place that owns the numbers — is satisfied;
its literal wording is corrected here.

### C3 — the compact-height override does not exist in the source

**Resolved as D1 above.**

The brief's §9 requires a compact-height override below 480 px. A grep for
height-based media queries across all 19 stylesheets returns **none**, and the
Design System `.docx` §1/§6/§10 defines the three classes by width only. The
override is therefore a native addition with no web counterpart, not a
reproduction of something in the source. It is approved by the brief and is
recorded as a permitted difference rather than silently implemented as if the
web specified it.

### C4 — "the tablet status bar is a browser artifact"

**Resolved. It is both, at different widths.** See §1 above. Dropping it
everywhere would lose real application chrome at medium and expanded; keeping it
everywhere would draw a fake clock over the real one on a phone.

### C5 — declared languages vs shipped languages

**Not a contradiction; a recorded gap.**

`assets/js/i18n/core.js` declares eight languages (en, ur, ar, fr, es, tr, id,
hi) in `ALL_LANGS` but exports only the three that have a dictionary
(`SHIPPED = LANGS.filter(l => DICTS[l.code])`). Urdu and Arabic are ~25 %
translated and fall back to English for the rest.

The Flutter reference ships **en, ur, ar** with the same coverage and the same
English fallback. It does not invent translations to fill the gap, and it does
not add fr/es/tr/id/hi, because the web — the source of truth for this
conversion — does not have them. Dayroz separately has 16 fully-populated
locales; reconciling the two is an F9 item, not a conversion decision.

### C6 — `feature_registry.dart` has 72 tools, the Lume catalogue has 85

**Not a conversion contradiction.** Dayroz's registry is production state; the
Lume catalogue is the design. The reference follows the catalogue's 85. The
id-reconciliation table is an F6 deliverable. Recorded in
[DAYROZ_ARCHITECTURE_MAPPING.md](DAYROZ_ARCHITECTURE_MAPPING.md) risk 2.

---

## 3. Open questions

### Resolved in F1

| # | Question | Decision |
|---|---|---|
| Q1 | Accept `text-wrap: balance` shaping differences? | **Conditionally.** Only when line count, visible text, truncation, measure, hierarchy and component height all match. Otherwise adjust the Flutter constraints and typography. See D2 |
| Q2 | Ship empty ARBs for fr/es/tr/id/hi? | **No.** Three languages — en, ur, ar — with full key parity enforced by test. An empty ARB would put a row in the picker that does nothing when chosen |
| Q3 | Delete the dead `.onb-country` lines? | **Done**, in its own commit, with a repository-wide search, the web suite before and after, and byte-identical captures. See C1 |
| Q4 | Extract the 112 icons mechanically? | **Done.** Path geometry, `viewBox` and the one per-symbol fill override copied byte-for-byte; the CSS presentation written onto each asset's root. Manifest, geometry and directionality tests added |
| Q5 | Reproduce the frozen `9:41` clock? | **No.** Real time at runtime through an injectable clock; pinned to a fixture instant in fixtures, captures and goldens. A frozen clock in a shipping app is a bug |

### Still open

| # | Question | Blocks | Recommendation |
|---|---|---|---|
| Q6 | **Should Urdu be set in Nastaliq rather than Naskh?** The reference ships only Noto Naskh Arabic, so Naskh is what the design asks for and what F1 implemented. But Urdu is conventionally Nastaliq, and Dayroz separately bundles `NotoNastaliqUrdu-Medium.ttf` — which is the production app judging Naskh wrong for Urdu | F4 onboarding sign-off in Urdu | Keep **Naskh**, because the reference is the source of truth and bundling a face the design has not asked for is the conversion inventing a design decision. Raise it as a *design* question against the reference instead. Decide before Urdu screens are signed off, since it changes how every Urdu screen looks |
| Q7 | Should capture artifacts be committed, or regenerated? | F2 | **Regenerated.** They are large, reproducible, and the findings live in the comparison reports rather than in the pixels. Currently gitignored |

## 4. Change log

| Date | Change | Reason |
|---|---|---|
| 2026-09-11 | Document created at Phase F0 | Baseline |
| 2026-09-11 | C1 recorded — `.onb-country` proven dead; brief §13 confirmed correct against the rendered interface | Full-tree grep found no reference in JS, HTML or tests |
| 2026-09-11 | C2 recorded — four sub-breakpoints found in the stylesheets; brief §9's literal wording corrected, intent preserved | Six files carry `max-width: 359px`; four carry `min-width: 1180px` |
| 2026-09-11 | C3 / D1 recorded — no height media query exists in any of the 19 stylesheets; the compact-height rule is a native addition | Grep across all stylesheets |
| 2026-09-11 | C5 recorded — 8 languages declared, 3 shipped, ur/ar at ~25 % | Measured from `LUME_I18N.DICTS` |
| 2026-09-11 (F1) | Q1–Q5 resolved; C1 closed by deletion with byte-identical captures | The evidence the cleanup was gated on |
| 2026-09-11 (F1) | D3 resolved — fonts bundled and verified from their binaries | `assets/fonts/PROVENANCE.md` |
| 2026-09-11 (F1) | **D4 raised** — Urdu falls back to Naskh because that is the only Arabic-script face the reference ships; Nastaliq is the convention and Dayroz bundles it | Found when the Urdu type golden rendered as tofu |
| 2026-09-11 (F1) | **D5 resolved** — numeric runs need direction isolation, not just an LTR direction | Found when the RTL type golden rendered `1,240.50  16:41` as `16:41 1,240.50` |
| 2026-09-11 (F1) | Evidence for D1 captured — at 852 × 393 the web reports `data-bp=medium`, Flutter resolves `compact` | The height override, demonstrated rather than asserted |

One correction has been applied to the web prototype: the four dead
`.onb-country` lines, deleted in F1 under the evidence gate in C1. Nothing else
in the prototype has been touched, and no Markdown or `.docx` specification has
been rewritten yet — that is Phase F8, where both `.docx` files are re-rendered
and visually inspected after every material revision.
