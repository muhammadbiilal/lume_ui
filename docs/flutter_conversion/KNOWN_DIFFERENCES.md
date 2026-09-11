# Known differences, contradictions and corrections

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

**Not yet approved.** Where it changes the visible line count of a reference
screen it will be corrected by hand-tuning the measure, and the remaining cases
listed per screen in F4/F9. Raised in §3.

### D3 — network-fetched fonts

The web loads Plus Jakarta Sans and Noto Naskh Arabic from the Google Fonts CDN.
The Flutter reference bundles them locally with their OFL licence, so it renders
offline and on the first frame. This is a build difference with no visual
consequence provided all five weights (400, 500, 600, 700, 800) ship real
files — a missing weight makes Flutter synthesise a faux bold that is visibly
not Plus Jakarta.

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
disagrees, and it has no effect because no element ever carries the class. The
Flutter country step is the vertical list. The four dead lines in
`onboarding.css` are **proposed for deletion** in F1 — proposed rather than
done, so the F0 baseline stays byte-identical to what the tests measured.

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

| # | Question | Blocks | Recommendation |
|---|---|---|---|
| Q1 | Should D2 (`text-wrap: balance`) be accepted as a permitted difference, or hand-tuned per screen? | F4 sign-off | Accept as permitted where the line **count** matches; hand-tune where it does not. Decide when the first Country/Interests comparison is on screen |
| Q2 | Does the reference ship fr/es/tr/id/hi as empty ARBs so the language picker lists them, or only en/ur/ar? | F1 | Ship **only en/ur/ar**. The web's picker lists only shipped languages, so empty ARBs would make the Flutter picker show five options the web does not |
| Q3 | May the four dead `.onb-country` lines be deleted from `onboarding.css`? | F1 | Yes — proven unreferenced, zero visual effect. Held for approval because it edits the comparison source |
| Q4 | Icon assets: trace the 112 SVG symbols out of `index.html` mechanically, or hand-author? | F1 | Extract mechanically into individual SVG files, preserving the 1.75 px stroke; the sprite is already one consistent set |
| Q5 | Does the reference reproduce the web's simulated `9:41` status clock at medium/expanded, or show the real time? | F3 | Reproduce the strip; show **real** time. A frozen clock is a mockup artifact, and the capture harness can pin it for goldens |

---

## 4. Change log

| Date | Change | Reason |
|---|---|---|
| 2026-09-11 | Document created at Phase F0 | Baseline |
| 2026-09-11 | C1 recorded — `.onb-country` proven dead; brief §13 confirmed correct against the rendered interface | Full-tree grep found no reference in JS, HTML or tests |
| 2026-09-11 | C2 recorded — four sub-breakpoints found in the stylesheets; brief §9's literal wording corrected, intent preserved | Six files carry `max-width: 359px`; four carry `min-width: 1180px` |
| 2026-09-11 | C3 / D1 recorded — no height media query exists in any of the 19 stylesheets; the compact-height rule is a native addition | Grep across all stylesheets |
| 2026-09-11 | C5 recorded — 8 languages declared, 3 shipped, ur/ar at ~25 % | Measured from `LUME_I18N.DICTS` |

No Markdown or `.docx` specification has been edited yet. The corrections above
are recorded and proposed; they are applied in F1 once approved, and the `.docx`
files are re-rendered and visually inspected at that point.
