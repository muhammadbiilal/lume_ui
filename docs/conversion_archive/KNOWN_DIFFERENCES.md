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

**The costume is not reproduced.** It exists so a prototype viewed on a monitor
reads as a device; in Flutter the app *is* the device. The stage padding, the
radial ground, the rounded frame, the border, the shadow and the 980 px height
clamp are dropped. Everything *inside* the frame is the real layout and is
reproduced exactly.

**The two width caps are kept** (corrected at F3, when the shell was built). A
cap is a measure rather than a costume: `max-width: 1366px`, and `560px` below
600. `LumeShell.capFor` applies them and `LumeBreakpointScope` measures inside
the result, so on a very wide window the shell is 1366 and centred rather than
stretched to an unreadable measure the design has never described. The two never
argue — the 560 cap is gated on a *window* under 600, where the shell is compact
anyway.

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

### D6 — two controls in the reference are under its own touch-target floor

**New in F2. A defect found in the reference, fixed in Flutter without changing
what is drawn.**

The Design System's §9 sets a 44 × 44 minimum touch target, and
`tests/design.js` asserts it for rows, fields and navigation. Two controls do
not meet it, measured from the rendered page:

| Control | Measured target | §9 floor |
|---|---:|---:|
| `.cnotice__act` — Retry, Review, Reload | **36 px** | 44 |
| `.stepper__btn` — the − and + in a stepper | **26 px** | 44 |

These are the actions on a save failure and a version conflict, and the way a
quantity is changed. They are not rare paths.

**Resolved in Flutter by separating the box from the target**, which is the
pattern `.iconbtn` already uses (a 38 px box in a 44 px target). The notice
action still *draws* at 36 and the stepper's buttons still draw at 26; both now
*accept touch* across 44. Nothing visible moved — the component goldens before
and after the fix differ only where the notice's actions stopped wrapping, which
was a separate bug.

**The stepper was corrected properly in F3** rather than left at 44 × 32. Each
button now has a real 44 × 44 target, laid over the pill and reaching 6 px past
each end so the target's centre lands exactly on its circle's centre:

```text
 0        44          60         104     the widget's box, 104 × 44
 ├── decrement ──┤    ├── increment ──┤  two 44 × 44 targets, 16 px apart
     ╭───────────────────────────╮
  6  │ (–)   26   value   26  (+) │  6   the pill, 92 × 32, unchanged
     ╰───────────────────────────╯
```

The targets cannot overlap — the gap between them is the value column plus both
inner gaps, and the value has a 26 px floor — and they stay inside the widget's
own bounds, so nothing is clipped and nothing reaches into a neighbour.

What changed visibly: **nothing, and one thing that was already wrong.** The
pill is now 92 × 32, which is the measured width; the previous implementation
had a 28 px value column where the measurement says 26, so it was 94. The two
`selection` goldens moved by 0.44 % of their pixels, all of it inside the
stepper, and the new image is the one that matches the reference.

`test/core/widgets/stepper_target_test.dart` holds all of it: the pill's
measured size, each circle's size, each target centred on its own circle,
44 × 44 on both axes, no overlap (including at a single-digit value), staying
inside bounds, activation by pointer, by a thumb landing outside the circle, by
Enter, by Space and by a screen reader's tap action, disabled semantics that
still announce and still refuse, and all of it again at 200 % text, at 359 px,
in RTL, and beside another control.

### D7 — a collapsed disclosure does not render its body

**New in F2. Flutter is stricter than the reference, deliberately.**

The reference's `.xrow` is a `<details>`, which does not render a closed body.
The obvious Flutter equivalent, `AnimatedCrossFade`, keeps both children in the
tree at all times — so a collapsed section would be read aloud by a screen
reader while being invisible to everyone else.

`LumeExpandRow` builds the body only when open. The animation is an
`AnimatedSize`, which is skipped entirely under reduced motion rather than given
a zero duration: at zero it re-dirties itself inside its own `performLayout` and
asserts.

### D5 — numeric runs are direction-isolated

**Resolved in F1, and worth recording because it is invisible until it is
wrong.** `rtl.css` gives `.num`, `.locrow__code` and `.trainno`
`direction: ltr; unicode-bidi: isolate`. Without the equivalent in Flutter, a
line holding two numeric runs reorders them: `1,240.50  16:41` renders as
`16:41 1,240.50` in an Urdu page. The digits are right; their *sequence* is not,
so a price and a time silently swap places. `LumeNumerals` / `LumeLtr` supply
both the direction and the isolation.

### D8 — nested destinations ride a branch stack

**Raised and resolved in F3.** The reference has no navigation stack, so a
destination that is not a tab remembers where it came from in a variable:

> The centre is a destination rather than a tab, so it remembers where the user
> was and its back control returns them there.
> — `assets/js/shell.js`, and `var notifReturnTab = 'home'`

The Flutter shell reaches the same outcome with a stack: the notification
centre, search, account, a tool and a tool's records are sub-routes of whichever
branch they were opened from, so `/home/notifications` and `/today/notifications`
are the same screen on two stacks and Back lands where the user actually was.

This is not a re-interpretation of the behaviour — it is the same behaviour with
one fewer thing to keep in step. A single variable cannot survive the centre
being open on two branches at once, and the reference cannot reach that state
because it has only one screen container. Flutter can, and a stack answers it.

The bare `/notifications`, `/search` and `/account` still resolve, for a push
notification or an external link, and redirect onto the branch the reference's
own fallback names.

### D9 — the floating bar hides while the keyboard is up

**Raised and resolved in F3.** `.tabbar` is `position: absolute` inside a
`100dvh` shell, and `dvh` does not track the keyboard — it tracks browser
chrome. So in the browser the bar ends up *behind* the keyboard: present in the
layout, invisible to the user.

Hiding it is the same outcome drawn honestly. The alternative, Material's
default, is to shrink the shell and park the bar on top of the keyboard, which
the reference never does and which puts five destinations between the user and
the field they are typing into.

The shell also refuses to let the keyboard change its width class. A 1024-point
tablet with a 600-point keyboard has 424 points left — under D1's compact-height
floor — so measuring after the keyboard would take the sidebar away
mid-sentence. `resizeToAvoidBottomInset` is therefore off and the outlet absorbs
the inset as bottom padding instead, which is where a form needs it.

### D10 — a master-detail selection is not written into the location

**Raised and resolved in F3.** The CRUD guide requires that selecting a record
at expanded width updates the pane and does not push a route, so the list keeps
its scroll, its filters and its sort. A location per selection is exactly the
rebuild that rule forbids.

So the selection lives in the collection screen's state. A deep link to a record
(`…/records/7`) lands as the *opening* selection and the location then stays
put. Nothing is lost: the reference has no locations at all, and no behaviour
described anywhere depends on one.

A consequence worth stating: at compact, the first Back clears the selection and
the second leaves the collection. The record is over the list, not after it.

### D11 — the tablet status strip drops the device glyphs

**Raised and resolved in F3**, and a narrowing of the P1 consequence already
recorded above. At medium and expanded the strip is application chrome and is
reproduced — the `card` ground, the bottom border, the 12 px block padding, the
brand mark and the clock. The signal, wifi and battery glyphs beside them are a
*drawing of a device*, and on a device the device draws them. They are dropped;
nothing else in the strip is.

### D12 — three sets of string the reference never translates

**Raised and resolved in F4A.** `INTEREST_GROUPS` hard-codes English labels in
`data/catalogue.js` and `pickBtn` renders them with `esc(it.label)` — no `t()`,
no `data-i18n`. The interests step's supporting copy and the `{n} of {min}
minimum` counter are the same: English in the markup, English in Urdu, English
in Arabic.

The side-by-side capture at 390 × 844 in Urdu shows it plainly: the reference's
chips read "Weather", "Tasks & to-dos", "Rates & gold" on an otherwise
right-to-left page.

**Not reproduced.** All 31 interest labels, the six group labels, the step's
copy and the counter are translated into all three languages, and
`interests_catalogue_test.dart` fails if any id has no label — the fallback
returns the id, so a missing translation shows up as a chip called `weather`
rather than as a blank.

This is the same call as the `aria-label="Main"` one in F3: a string the
reference forgot to route through its own translator is a defect in the
reference, not a design decision to carry across. It is recorded rather than
silently improved because it makes the Urdu and Arabic captures differ from the
prototype by design.

### D13 — the onboarding back chevron mirrors

**Raised and resolved in F4A.** `rtl.css` and its siblings mirror exactly four
glyphs, and two of them are the authentication flow's own back chevron and
forward arrow:

```css
.is-rtl .auth__nav--back svg  { transform: scaleX(-1); }
.is-rtl .btn--auth .btn__arrow { transform: scaleX(-1); }
```

`.onb__nav svg` has no such rule, so the *onboarding* back control points left
in a right-to-left page while the identical control in authentication points
right.

Flutter mirrors both, because `LumeIcons.mirrors` is a property of the glyph
rather than of the screen it appears on, and because §17 requires that
"back/forward/next/previous icons must remain semantically correct". The
reference already agrees with that everywhere it thought about it; onboarding is
where it did not.

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


### C11 — the market session is wrong four ways

**Found and corrected in F5A.** `marketSession()` in `tools/context.js:734`:

```js
var now = new Date();
var h = now.getHours() + now.getMinutes() / 60;          // the DEVICE's clock
var open = h >= o && h <= cl                             // close is INCLUSIVE
           && now.getDay() > 0 && now.getDay() < 6;      // one weekend for all
```

1. **The device's timezone, not the exchange's.** `ex.tz` is stored and never
   read. A phone in London says the Karachi exchange opens at 09:32 London
   time.
2. **An inclusive close.** At exactly 15:30 the Pakistan Stock Exchange reads
   as open.
3. **No holidays at all.** `MARKET_HOLIDAYS` and `isMarketHoliday()` are both
   defined in `tool-data.js:264` and neither is called from here. And the one
   floating entry — US Thanksgiving — is pinned to 28 November, which is the
   wrong Thursday in about six years in seven.
4. **One weekend for every market.** Monday-to-Friday is hard-coded, and the
   Saudi Exchange trades Sunday to Thursday.

Corrected in `lib/features/markets/`, with the clock injected and every
boundary tested: a minute before the open, the opening minute, a minute after,
a minute before the close, the close, a minute after, the weekend, a fixed
holiday, a floating one, Easter, a device in another zone, and both halves of
the daylight-saving year.

### C12 — Home's Discover strip leaks content the user switched off

**Found and corrected in F5A.** See D30.

### C13 — the "local service" marker never renders

**Found and corrected in F5A.** See D28.

### C14 — a tile marker overwrites a count instead of ranking against it

**Found and corrected in F5A.** See D28.

### C15 — the progress bar never renders

**Found and corrected in F5A.** See D26.

### C16 — the notification badge is a dot given a number

**Found and corrected in F5A.** See D27.

### C17 — the outage card names a slot that has already ended

**Found and corrected in F5A.** See D23.

### C18 — search indexes the name the reader cannot see

**Found and corrected in F5A.** `data-hay` is
`(f.n + ' ' + f.kw).toLowerCase()` — the *English* name from the catalogue — so
an Urdu reader cannot find a tool by the name on its tile. Flutter indexes the
localised name, the English name and the keywords, because somebody who learned
a tool's English name should not lose it by switching language.

### C19 — the quick-action strip cancels its own padding

**Found and corrected in F5A.** See D24.

### C20 — a live card overflows its column

**Found and corrected in F5A.** See D25.

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
| ~~Q8~~ | ~~**The stepper's buttons are 44 tall but 32 wide.** Making them 44 wide would widen the pill from 64 to 96 and change the control's proportions. Accept the residual, or change the design? | F6, where steppers are actually used | **Accept**, and record it. The height is the axis a thumb misses on in a vertical list, and it is recovered. Changing the pill would be the conversion redesigning a control it was asked to reproduce — better raised against the reference~~ · **Superseded.** Rejected, and corrected properly in F3 — see D6 |
| Q9 | **A country row is 41 points tall — three under §9's own 44 px floor.** Unlike the stepper's 26 × 26 (D6) and the onboarding chrome's 34 and 32, there is nowhere to overhang: the rows are adjacent, so a taller target would either overlap its neighbour's or change the list's rhythm, which is the thing this phase measures. The target is 350 points *wide*, so the miss the floor guards against — a thin control you jab past — is not the miss on offer. Reproduced at 41 and raised rather than decided | F4B, before the city step reuses the same row | Options: (a) keep 41 and record it as a permitted difference, (b) raise every row to 44 and accept a taller list than the design draws, (c) raise the floor only where a list is short enough to afford it. I recommend (a) |

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
| 2026-09-11 (F2) | Q7 settled by policy — goldens, reports and measurements committed; bulk raw captures ignored | The measurements are the durable evidence; the pixels are reproducible |
| 2026-09-11 (F2) | **D6 raised and resolved** — `.cnotice__act` (36) and `.stepper__btn` (26) are under §9's own 44 px floor | Found by the touch-target sweep across every interactive component |
| 2026-09-11 (F2) | **D7 raised** — a collapsed disclosure must not render its body | Found when `AnimatedCrossFade` kept hidden content in the semantics tree |
| 2026-09-11 (F2) | Seven measurement findings recorded in [COMPONENT_MATRIX.md §2](COMPONENT_MATRIX.md#2-what-the-measurement-caught-that-reading-would-not) | Each is a value a stylesheet read gets wrong |
| 2026-09-11 (F3) | **Q8 rejected; D6 completed.** The stepper's targets are 44 × 44, non-overlapping, in-bounds, and centred on their circles | A 44 × 32 target was accepted too easily the first time |
| 2026-09-11 (F3) | **`LumePressable` gained keyboard and screen-reader activation.** It was pointer-only: Enter, Space and an assistive tap all did nothing | Found while proving the stepper's four activation paths |
| 2026-09-11 (F3) | Stepper pill corrected from 94 to the measured 92 px | The value column was 28 where the measurement says 26 |
| 2026-09-11 (F3) | **D8 raised and resolved** — nested destinations ride a branch stack rather than a remembered return tab | A single variable cannot hold the centre being open on two branches |
| 2026-09-11 (F3) | **D9 raised and resolved** — the floating bar hides while the keyboard is up, and the keyboard does not change the width class | `100dvh` does not track the keyboard, so the reference's bar ends up behind it |
| 2026-09-12 (F5A) | **C11 / D29 raised and resolved** — the market session read the device's clock, closed inclusively, ignored the holiday table it ships and gave every exchange the same week | Found by asking what "is the market open" means on a phone in another country |
| 2026-09-12 (F5A) | **C12 / D30 raised and resolved** — Home's Discover strip is gated by attribute, so a switched-off content type still appeared | Measured: the `prefs_off_pk` capture still lists a cricket score |
| 2026-09-12 (F5A) | **C13, C14 / D28 raised and resolved** — the "local service" marker tests a renamed field and never renders; a marker overwrites a count rather than ranking against it | Measured: `.cat-tool__pin` absent in every captured state |
| 2026-09-12 (F5A) | **C15 / D26 raised and resolved** — the progress bar is a `<span>` with no `display` and collapses to nothing | Measured 0 × 0, with its fill 78.39 × 0 |
| 2026-09-12 (F5A) | **C16 / D27 raised and resolved** — the notification badge is a 7-point dot given `'99+'` | Measured: the control reports the text "13" |
| 2026-09-12 (F5A) | **C17 / D23 raised and resolved** — the outage card names a slot that ended 41 minutes earlier, in a clock format the user did not choose | Found by freezing the page's clock and reading the schedule beside the card |
| 2026-09-12 (F5A) | **C18 raised and resolved** — search indexes the English name, so an Urdu reader cannot find a tool by the name on the tile | Found while building the localised haystack |
| 2026-09-12 (F5A) | **C19 / D24 raised and resolved** — `.qactions` cancels its own padding with a negative margin | Measured: the strip at x −20 with width 430, the first pill at x 0 |
| 2026-09-12 (F5A) | **C20 / D25 raised and resolved** — a live card overflows its column by 22.31 | Measured: x 20 plus width 372.31 in a 390 viewport |
| 2026-09-12 (F5A) | **D22 raised and resolved** — the status line under every tool is English in all three languages | 85 keys added, in three languages, behind one resolver |
| 2026-09-12 (F5A) | **P2 raised** — the greeting's emoji has no face in a test capture | Found in the first Home golden |
| 2026-09-12 (F5A) | **`LumeDelta` corrected** — it read `accent-700` and `rose-ink`; the rendered `.delta--up` is rgb(23, 145, 111) and `.delta--down` rgb(198, 72, 92), which are their own tokens | Found when the live row needed them |
| 2026-09-12 (F5A) | **`LumeCompactRow` corrected** — its subtitle sat beside the label; `.crow__label i` is a block and sits under it | Found when "Coming up" came out twelve points too tall |
| 2026-09-12 (F5A) | **`LumeType.natural` added** — most of the prototype's small text leaves `line-height: normal`, which is the font's own line and not the `--t-*` token's | Found when five section heads drifted 44 points down a page |
| 2026-09-11 (F3) | **D10 raised and resolved** — a master-detail selection stays out of the location | A route per selection is the rebuild the CRUD guide forbids |
| 2026-09-11 (F3) | **D11 raised and resolved** — the tablet status strip keeps the wordmark and the clock, drops the device glyphs | The strip is application chrome; the glyphs are a drawing of a device |
| 2026-09-11 (F3) | **Correction:** the shell's two width caps (1366, and 560 below 600) are **kept**, not dropped | F0 recorded them with the device frame; a cap is a measure, not a costume |
| 2026-09-11 (F4A) | **The interest catalogue settled** — 31 ids, 6 groups, 29 rendered; the "57" was a document-wide `.pick` count across two mounted pickers | [INTERESTS_CATALOGUE.md](INTERESTS_CATALOGUE.md) |
| 2026-09-11 (F4A) | **`sleep` and `quotes` found unreachable** — declared in a group, referenced by no feature, so never rendered. Recorded, not deleted | The prototype is the source of truth while the conversion runs |
| 2026-09-11 (F4A) | **D12 raised and resolved** — interest labels, the interests copy and the counter are translated | The reference leaves all three in English in every language |
| 2026-09-11 (F4A) | **D13 raised and resolved** — the onboarding back chevron mirrors in RTL | The reference mirrors the identical control in auth but not here |
| 2026-09-11 (F4A) | **Q9 raised** — a 41 px country row, three under §9's floor, with nowhere to overhang | Recommendation given; not decided unilaterally |
| 2026-09-11 (F4A) | **D6 extended to the onboarding chrome** — the 34 circle and the 32 Skip carry 44 px targets that overhang rather than grow the row | Growing it moved the whole flow five pixels, which the bounds comparison caught |
| 2026-09-11 (F4A) | Four line boxes corrected against the running flow — kicker 13, Skip 32, row name 18, group label 12 | A type role's own height is not the reference's `line-height: normal` |
| 2026-09-11 (F3) | **`LumeMasterDetail` extended** into a shell that survives rotation, with `GlobalKey`s carrying the list and the detail between the two layouts | The row and the stack put them at different depths, so a rotation would otherwise reset both |
| 2026-09-12 (F4C) | **D18 raised and resolved** — authentication covers the shell | The floating bar covers a whole footer line and walks out of two screens that declare nothing dismisses them |
| 2026-09-12 (F4C) | **D19 raised and resolved** — a tall screen scrolls rather than compressing its header | The reference's header shrinks 60 → 48 and slides the back control 6 up when the page below it is long |
| 2026-09-12 (F4C) | **D20 recorded** — the legal line's inline link has no padded box | Two points of height on one line of one screen |
| 2026-09-12 (F4C) | **D21 recorded** — the seal fades and scales rather than drawing its stroke | A `stroke-dashoffset` animation is a technique, not a requirement |
| 2026-09-12 (F4C) | **`.auth__top`'s `min-height` read as border-box** | It includes the 16 above it: a header with a control is 60 and one without is 48, and reading it the other way moved every screen 4 down |
| 2026-09-12 (F4C) | **`max-width` in `ch` measured from the font** | An estimated `ch` wrapped `.auth__text` a line early on four screens |
| 2026-09-12 (F4C) | **A capped block fills the width it is capped to** | A shrink-wrapped paragraph sits at its own natural width, which moves centred copy off the centre |
| 2026-09-12 (F4C) | **`LumeMaxWidth` promoted out of the onboarding chrome** | Authentication needs the same honest intrinsic height, and two copies drift |
| 2026-09-12 (F4C) | **The recovery token is fixed width** | Neutrality that leaks through a string length is not neutrality |
| 2026-09-11 (F4B) | **D14 raised and resolved** — a short screen hands the lead and the search field to the list; the reference squeezes the list to zero and draws the field over the action | Measured at 852 × 393: `.locscroll` `clientHeight` 0 against `scrollHeight` 8830 |
| 2026-09-11 (F4B) | **D15 raised and resolved** — method pills 10 apart rather than 7 | Two 44-point targets cannot sit 7 apart without overlapping |
| 2026-09-11 (F4B) | **D16 raised and resolved** — the secondary link's target is 44 and the text does not move | The extra 8 comes out of the gaps around it |
| 2026-09-11 (F4B) | **D17 raised and resolved** — the calculation method is read and written | The reference's pills neither read the profile nor write it |
| 2026-09-11 (F4B) | **`.switch` corrected from 44 × 26 to the measured 42 × 25** | Two points of width is the difference between a permission row's body being 212 and 210 |
| 2026-09-11 (F4B) | **`text-wrap: balance` reproduced** as `LumeBalancedText` | Every onboarding heading broke at a different word from the reference's |
| 2026-09-11 (F4B) | **`.field__label` found uppercase**; the name step uses `.field`, not `.cfield` | The two labelled fields differ in every measurement |
| 2026-09-11 (F4B) | **`.field__box:focus-within` added to `LumeToolField`** | It had no focus state at all, which §9 and §60 both require |
| 2026-09-11 (F4B) | **Skip reserved on the last step** rather than removed | `.onb__skip[disabled]` is `opacity: 0`; removing it would let the progress bar jump 47 points at the finish |
| 2026-09-11 (F4B) | **The onboarding step yields to the keyboard** | There is no `Scaffold` under the flow, so nothing was shrinking |
| 2026-09-11 (F4B) | **Asset tables load without `compute`** | `loadString` hands anything over 50 KB to an isolate, which never finishes inside a widget test — the flow rendered an empty box for ever |
| 2026-09-11 (F4B) | Line-box rounding recorded as a P7 consequence — Skia rounds a line box to whole pixels where Blink keeps 1/64ths | Two two-line subtitles come to 1.56 short of the reference's pair |

### D14 — a short screen scrolls the whole list step, head and all

**Raised and resolved in F4B.** `.locpicker` is a flex column with the search
field at the top and `.locscroll` flexing beneath it, which needs a step tall
enough to hold a lead, a field and a list at once. A phone held sideways is not.

Measured at 852 × 393, on the country step:

| | measured |
|---|---|
| `.onb-step` | `clientHeight` 263, `scrollHeight` 263 — it does **not** scroll |
| `.locscroll` | `clientHeight` **0**, `scrollHeight` 8830 — squeezed to nothing |
| `.search--sm` | y 260.42, height 38 |
| `.onb__foot` | y 278 |

The field is drawn **over** the Continue button and the list has no height at
all. Both steps are unusable at that cell, and the same is true of the city
step, where `.locscroll` measures 0 against a 1087-point list.

The correction: below the compact-height floor, the lead and the search field
are handed to the list and everything above the footer scrolls as one piece, in
the order the markup already has it. Nothing is covered, nothing is zero, and
the footer stays where it is. Above the floor, nothing changes.

The same cell also makes `.onb__art` overflow its own stage — the illustration
is 268 tall inside a 200-tall grid item and is drawn over the brand. Flutter
keeps the drawing inside the stage and lets the step scroll, which is the same
answer without the overlap.

### D15 — method pills sit ten apart rather than seven

**Raised and resolved in F4B.** `.onb-choice button` is 34 tall and the block
wraps with a 7 px gap between runs; measured at 390, the five pills fall into
two runs and the block is 75 tall.

§9's floor makes each target 44, so each already reaches 5 past its pill. A
7-point run gap on top of that would make neighbouring targets **overlap**,
which is worse than a gap three points wider than the reference's. The runs
therefore sit 0 apart as boxes and 10 apart as pills, and the block is 88 rather
than 75. Every pill's own geometry — 34 tall, 13 of side padding, 12 / 600 /
−.015em — is unchanged.

### D16 — the secondary link's box is 44 where the reference draws 36

**Raised and resolved in F4B.** `.onb__link` is 13 px of text in 10 of padding,
measured 36 tall on steps 0 and 7. The floor makes the target 44.

The extra 8 comes out of the 10-point gaps on either side of it and, where the
link is last, out of the step's own 22 of bottom padding. So the **text** is
exactly where the reference puts it, the gap is still 6, and nothing overlaps.
Only the box differs, and a box is not a thing anyone sees.

### D17 — the calculation method the user picks is the method that is stored

**Raised and resolved in F4B.** The reference's method block is decorative. Its
click handler moves `is-active` between the five buttons and writes nothing:

```js
var method = $('#onbMethod');
if (method) {
  method.addEventListener('click', function (e) {
    var b = e.target.closest('button');
    if (!b) return;
    $$('button', method).forEach(function (x) { x.classList.remove('is-active'); });
    b.classList.add('is-active');
  });
}
```

Nothing reads the stored preference either: the markup marks *University of
Karachi* active while `app-store.js` defaults the profile to `MWL`, so the step
shows one answer and the app holds another.

Reproducing that would mean shipping a control that lies. The Flutter step
opens on the stored method and writes the one the user chooses, which is what
§36 requires of a personalisation setting and what "Set it up once" promises.

### The market session defect, and what Flutter will do instead

Found in F4A and recorded here because the correction belongs to a later phase.
`marketSession` in `context.js` decides whether the NASDAQ is open using the
**device's** clock rather than the exchange's, treats the closing minute as
open, and compares against a hard-coded `MARKET_HOLIDAYS` table containing
floating dates — Thanksgiving among them — that are correct for one year only.

A device in Karachi therefore reads the New York session from Karachi time.

The Flutter implementation is authoritative and must: resolve the session in
the exchange's own zone, open on the minute, close *exclusively*, take weekends
from that zone's calendar, and derive the floating holidays rather than listing
them. The prototype is left as it is — it is the comparison source while the
conversion runs, not the product.


### D18 — authentication covers the shell

**Raised and resolved in F4C.** `.onb` is `position: absolute; inset: 0;
z-index: 65` and covers the shell. `.screen--auth` is an ordinary screen, and
`padding-bottom: 0` removes the clearance every other screen keeps for the
floating navigation bar. Measured on the neutral confirmation at 390 × 844:

| | y | height | bottom |
|---|---|---|---|
| `#tabbar` | 770 | 62 | 832 |
| `.auth__foot` | 731.88 | 88.13 | 820.01 |
| `.auth__link` "Back to sign in" | 731.88 | 46 | 777.88 |
| `.auth__link--quiet` | 785.88 | 34.13 | 820.01 |

The last 7.88 points of "Back to sign in" and the **whole** of the quiet line
beneath it are underneath the bar. The bar is also live, so `created` and
`expired` — both declared `dismissible: false, back: false` — can be walked
straight out of by tapping Home. Three screens declare that nothing dismisses
them and the navigation dismisses them anyway.

The correction: the flow covers the shell, exactly as onboarding does. The
consequence the comparison has to allow for is that the Flutter panel is 28
taller — the prototype's simulated status bar (P1) — so a bottom-anchored
action sits 28 lower in absolute terms and in the same place relative to the
panel it is in. The bounds comparison measures those elements from the bottom
for that reason.

The same capture also caught a delay notification drawn over the header,
covering the back control: the prototype's notification timers are not stopped
for the flow. Flutter's flow is not interrupted by the shell's timers because
the shell is not running underneath it.

### D19 — a screen that overflows scrolls rather than compressing its header

**Raised and resolved in F4C.** `.auth__panel` is a flex column and
`.auth__top` is a flex item with `flex-shrink: 1` and `min-height: 48`. On a
screen whose content exceeds the viewport, the header **shrinks**: measured on
the reset screen at 390 × 844, where `scrollHeight` is 892 against a
`clientHeight` of 816.

| | short screen | tall screen |
|---|---|---|
| `.auth__top` height | 60 | **48** |
| `.auth__nav` y, from the panel | 16 | **10** |
| everything below | — | **12 higher** |

So the back control's position depends on how much text is further down the
page, and the same header is two different heights on two screens of the same
design. Flutter keeps the header at 60 and scrolls the panel, which is what
`overflow-y: auto` was already asking for. The reset comparison records the
12-point difference rather than asserting it.

### D20 — the legal line's inline link has no padded box

**Raised and resolved in F4C.** `.auth__legal button` is an inline element with
`padding: 2px`, which grows the line box it sits in; the paragraph measures
38.78 for two lines where two plain lines would be 34.8. A Dart `TextSpan` has
no box to pad, so the paragraph is two points shorter and the link is in the
same place.

Recorded rather than reproduced because reproducing it would mean a
`WidgetSpan` with its own baseline arithmetic for two points of height on one
line of one screen.

### D21 — the seal arrives by fading and scaling

**Raised and resolved in F4C, and the same call F4B made for the onboarding
seal.** The reference draws the check by animating `stroke-dasharray` and
`stroke-dashoffset` on a glyph referenced through `<use>`. That is a CSS
technique for "it arrives", not a design requirement, and it cannot be reached
through an SVG asset in Flutter. The seal fades and scales in over the same
640 ms, and under reduced motion it is simply there.

### D22 — the tile status line is translated

**Raised and resolved in F5A.** `f.m` — "Standard", "12 saved", "Asr 15:53" —
is a catalogue string, and no dictionary overrides it, so every one of the
eighty-five tiles reads English in Urdu and in Arabic. §10 makes localisation a
first-class requirement and §11 forbids hard-coding user-facing strings, so the
line is a **key** here and the ARBs carry all three languages.

The architecture matters as much as the translation: a status line is a
property of the tool's own data, not of the registry. `LumeToolStatuses`
carries the two the device can answer without opening anything — the next
prayer and the weather — and Home and the hub read the same resolver so they
cannot name two different prayers. The rest arrive with their tools at F6.

### D23 — the Discover strip is 16 points taller

**Raised in F5A, and a consequence of C17.** The prototype's outage card is
fixed markup reading "Next outage 14:00" while the schedule it comes from ends
that slot at 16:00 — so at 16:41 it named an outage that was already over, in a
24-hour format the user had not chosen. Derived, the card reads "Next outage
7:00 PM", which takes two lines in a 126-point card and makes the strip 16
taller.

Recorded rather than avoided: a card that names a time in the past is worse
than a strip that is sixteen points taller.

### D24 — the quick-action strip starts at the gutter

**Raised in F5A.** `.qactions` sets `padding: 0 var(--pad)` *and*
`margin: 0 calc(var(--pad) * -1)`, and its `.section` parent has no padding of
its own — so the negative margin cancels the padding exactly and the first pill
sits flush against the screen edge while every other element on Home is at 20.
Measured: `.qactions` at x −20 with width 430, the first `.qaction` at x 0.

The intent is plain — a scroller that bleeds so a pill can scroll to the edge,
with its content inset to the gutter — and the container was already full-bleed
before the margin was added. Flutter keeps the bleeding scroller and starts the
content at 20, which is what every other strip on the screen does.

### D25 — a live card fills its column

**Raised in F5A.** `#liveNow .livecard` measures 372.31 wide at x 20 in a 390
viewport: 2.31 points off the right-hand edge, in a grid column that is 350.
Flutter's card is 350. The width is recorded rather than asserted in the bounds
comparison.

### D26 — the progress bar is drawn

**Raised in F5A.** `.bar` is a `<span>` and the stylesheet never gives it a
`display`, so it stays inline and collapses: measured 0 × 0, with its fill
78.39 × 0. Everything else about it is specified — 5 tall, pill-shaped, a
neutral track, a jade gradient fill, animated over 1.1 s by `animateBars` — and
none of it renders.

Drawn here. The card's height is unchanged, because the 54-point artwork beside
it is what sets it.

### D27 — the notification badge is a pill with a number in it

**Raised in F5A.** §100.1 asks for *"one badge, in the app header, formatted
compactly"*, and the prototype computes exactly that — `n > 99 ? '99+' : n` —
then draws it into a 7-point dot with no room for a glyph, so the number spills
out beside the header. The `'99+'` is what settles it: nobody formats a dot
that way.

### D28 — the "local service" dot is drawn

**Raised in F5A.** `toolCard()` tests `f.loc`, a field the catalogue renamed to
`countries`, so the marker never renders anywhere. The same branch also
*overwrites* a count rather than taking precedence over it, so a tool with both
loses the count silently.

Flutter draws the dot, and declares the precedence: a sensitive tool's lock
wins over a count, because a lock is a promise and the count can wait for the
tool itself.

### D29 — the market session is correct

**Raised in F5A.** Four defects in six lines, each with its own test at each of
its boundaries. See `docs/LUME_DESTINATIONS.md` §5 and C11 below.

### D30 — the Discover strip honours the content switches

**Raised in F5A.** The strip is gated by `data-loc` and `data-faith` only, so a
user who switched cricket off in Personalisation still saw a cricket score on
Home. Measured: the `prefs_off_pk` capture still lists `PAK 214/4`. §64 says a
hidden feature must not be reachable indirectly, and the strip asks
`LumeEligibility` here like every other surface.

### P2 — the greeting's emoji has no face in a test capture

**Raised in F5A.** `flutter_test` loads only the fonts the application
declares, and Lume declares Plus Jakarta Sans and Noto Naskh Arabic. Neither
has `👋`, so the greeting's emoji renders as a box in a golden and in a
capture. On a device the platform's emoji face draws it. A capture artefact,
not a product difference, and not worth bundling a 10 MB emoji font to hide.


One correction has been applied to the web prototype: the four dead
`.onb-country` lines, deleted in F1 under the evidence gate in C1. Nothing else
in the prototype has been touched, and no Markdown or `.docx` specification has
been rewritten yet — that is Phase F8, where both `.docx` files are re-rendered
and visually inspected after every material revision.
