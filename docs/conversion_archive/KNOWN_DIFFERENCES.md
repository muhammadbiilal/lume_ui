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

**Found in F5A. Flutter does not draw one either.** `tools.screen.js:73` tests
`f.loc` and no catalogue entry declares it; a live probe of
`#toolCats .cat-tool__pin` returns `{ found: 0 }`. Either the branch is stale
or the catalogue is missing a field — the prototype cannot say which, so the
rendered result stands and the question is recorded for Dayroz integration.
See D28.

### C14 — a tile marker overwrites a count instead of ranking against it

**Found in F5A; the order is reproduced, not the overwrite's mechanism.**
`toolCard` assigns rather than ranks, so the lock and the pin each destroy a
count. `LumeCatalogueTile.markerFor` declares the same order — privacy, then
locality, then the number — and draws exactly one marker. Only the first step
is observable in the reference (`documents` is countable *and* sensitive, and
shows its lock); the rest is held by a unit test on synthetic inputs. See D28.

### C15 — the progress bar never renders

**Found in F5A, and settled: dead, incomplete markup.** `.bar` is a `<span>`
that `components.css` leaves out of the rule block blockifying `.bar__fill`, so
`height` does not apply to it: measured 0 × 0, with its fill 74.47 × 0. The
data is valid and `animateBars` runs, but the card reserves no room for a bar
and nothing in the tests or the specifications asks for a visible one. Flutter
renders the card the prototype renders. Full evidence in D26.

### C21 — the Discover weather card is a literal, and contradicts the weather

**Found in the F5A closure pass. Reproduced, not repaired.**
`home.screen.js:834–839` writes the whole card as fixed markup:

```html
<span class="minicard__title">34° and hazy</span>
<span class="minicard__meta">Feels like 38°</span>
```

with no `data-loc` gate, so it renders unchanged in every market. Measured in
all nine captured states — Pakistan, the United Kingdom and the United States
included — the card says the same thing every time, while the live row a
section above reads the real `WEATHER_BY_COUNTRY` entry and disagrees with it
everywhere but Pakistan. A reader in London is shown 34° and hazy over a row
that says 21° and mostly clear.

It is also not a measurement: the literal never passes through `L.temp()`, so
the reference shows `34°` in New York rather than the 93° a Fahrenheit market
would convert it to.

Flutter renders the same card, from three display fields of its own
(`discoverTemperature`, `discoverFeelsLike`, `discoverConditionKey`), fixed
once in `_referenceDiscover` so the defect lives in one place. The raw
condition stays on the model and keeps feeding the live row, which is the half
that is not broken.

**Dayroz obligation.** The production weather adapter must supply a real
location-specific display condition for this card. These constants are a
reference fixture reproducing a prototype's bug; shipping them would show
every user Karachi's weather.

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

**Found in F5A. Not a defect — an intentional full-bleed pattern, and Flutter
reproduces it.** An earlier F5A implementation treated it as a defect and
started the strip at the gutter; that was unapproved and has been reverted. See
D24.

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
| 2026-09-12 (F5A) | **C13, C14 / D28 raised** — the "local service" marker tests a field the catalogue does not carry and never renders; a marker overwrites a count rather than ranking against it | Live probe: `#toolCats .cat-tool__pin` → `{ found: 0 }` |
| 2026-09-12 (F5A) | **C15 / D26 raised** — the progress bar is a `<span>` left out of the rule block that blockifies its own fill, so `height` does not apply | Measured 0 × 0, with its fill 74.47 × 0 |
| 2026-09-12 (F5A) | **C16 / D27 raised and resolved** — the notification badge is a 7-point dot given `'99+'` | Measured: the control reports the text "13" |
| 2026-09-12 (F5A) | **C17 / D23 raised and resolved** — the outage card names a slot that ended 41 minutes earlier, in a clock format the user did not choose | Found by freezing the page's clock and reading the schedule beside the card |
| 2026-09-12 (F5A) | **C18 raised and resolved** — search indexes the English name, so an Urdu reader cannot find a tool by the name on the tile | Found while building the localised haystack |
| 2026-09-12 (F5A) | **C19 / D24 raised** — `.qactions` cancels its own padding with a negative margin | Measured: the strip at x −20 with width 430, the first pill at x 0 |
| 2026-09-12 (F5A) | **C20 / D25 raised and resolved** — a live card overflows its column by 22.31 | Measured: x 20 plus width 372.31 in a 390 viewport |
| 2026-09-12 (F5A) | **D22 raised and resolved** — the status line under every tool is English in all three languages | 85 keys added, in three languages, behind one resolver |
| 2026-09-12 (F5A) | **P2 raised** — the greeting's emoji has no face in a test capture | Found in the first Home golden |
| 2026-09-12 (F5A) | **`LumeDelta` corrected** — it read `accent-700` and `rose-ink`; the rendered `.delta--up` is rgb(23, 145, 111) and `.delta--down` rgb(198, 72, 92), which are their own tokens | Found when the live row needed them |
| 2026-09-12 (F5A) | **`LumeCompactRow` corrected** — its subtitle sat beside the label; `.crow__label i` is a block and sits under it | Found when "Coming up" came out twelve points too tall |
| 2026-09-12 (F5A) | **`LumeType.natural` added** — most of the prototype's small text leaves `line-height: normal`, which is the font's own line and not the `--t-*` token's | Found when five section heads drifted 44 points down a page |
| 2026-09-12 (F5A · correction) | **D24 reverted.** The quick-action strip bleeds through the gutter again: first pill at x 0, asserted rather than excused | The negative margin is an intentional full-bleed pattern, not a defect |
| 2026-09-12 (F5A · correction) | **D26 reverted.** The progress bar is not drawn; the evidence is presented and a decision is pending | The rendered reference is the authority, and a proven defect still needs approval before departing from it |
| 2026-09-12 (F5A · correction) | **The horizontal strip stretches its children**, as `align-items: stretch` does | A `Row` centres, which left a ragged Discover strip of 140s around one 156 |
| 2026-09-12 (F5A · correction) | **The strip is capped to the measure.** It supplies its own gutters, so it is outside `LumeMeasure` — and was spanning the window rather than the content column at medium and expanded | Measured at 1100: `.hscroll` is the section's box, 269 by 806 |
| 2026-09-12 (F5A · correction) | **D31 raised and resolved** — `intl` has no `en_PK` and falls back to `en`, which *is* American English: a Karachi reader was getting "Mon, Sep 7" and "6:27 PM" | Measured against the reference: "Mon, 7 Sept" and "6:27 pm" |
| 2026-09-12 (F5A · correction) | **D32 raised and resolved** — `DateFormat.jm` carries the locale's own hour cycle, so asking `en_GB` for a 12-hour clock returned "18:27" | Found while proving D23's 12-hour case |
| 2026-09-12 (F5A · correction) | **The deep-link gate added.** The tool route consulted nothing; it now asks the same `LumeEligibility` the hub asks | §64 lists deep links among the surfaces a hidden feature must not be reachable through |
| 2026-09-12 (F5A · correction) | **The timezone adapter boundary added** — `LumeZone` / `LumeZoneDatabase`, with the rule table confined to one binding | The handmade table is reference infrastructure, not a production timezone authority |
| 2026-09-12 (F5A · correction) | **P2 settled on a device** — the greeting's emoji renders in full colour on Android from the platform fallback | `adb screencap` of the packaged debug application on a Pixel 6 Pro, Android 16 |
| 2026-09-12 (F5A · correction) | **The unread fixture set to 13** — the reference's engine produces 13 in Pakistan, 12 with the switches off, 10 abroad; Flutter was showing a flat 3 | Measured from `appbar.bell` across nine captured states |
| 2026-09-12 (F5A · closure) | **The 715 → 703 web count explained.** Nothing was lost: `tests/verify.js` prints `ok:` where the other nine print `ok␣`, and the count in the correction report used a pattern that required the space | `tests/` and `package.json` are byte-identical since `9c83023`, which predates F5A |
| 2026-09-12 (F5A · closure) | **D26 closed.** The invisible `.bar` is recorded as dead prototype markup rather than an unresolved difference; `LumeProgressCard.progress` and the two `fraction` getters removed as unused plumbing | Nothing consumed them once the bar was gone; `LumeProgressBar` (`.pbar`) is a different, live component and is untouched |
| 2026-09-12 (F5A · closure) | **D28 closed the other way.** The local-service marker is not drawn; the country gate, the marker capability and the precedence contract are kept | Semantic similarity is not proof of intent, and a missing dot is not a correctness repair |
| 2026-09-12 (F5A · closure) | **The unread count made state-specific** — 13 in Pakistan, 12 with the switches off, 10 abroad, as fixture data | Traced with `probe_notifications.mjs`: the badge counts the notification sources that survive a profile |
| 2026-09-12 (F5A · closure) | **D33 raised** — the Discover weather card read "34° and hazy sun" where Lume reads "34° and hazy" | The card's phrase is its own, not the live row's condition lower-cased |
| 2026-09-12 (F5A · final) | **D33 withdrawn; C21 recorded instead.** The whole card is a literal with no country gate, so the fixture reproduces all three of its values in every state — London included — rather than deriving a truthier one | A fixture that "fixed" it matched neither Lume nor the forecast. Dayroz's weather adapter must supply the real display condition |
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

**Raised in F5A. Approved on conditions, and the conditions are met.**

`home.screen.js:845` writes `<span class="minicard__title">Next outage 14:00`
into fixed markup — an untranslated literal, and one the schedule beside it
contradicts: that slot ends at 16:00, and at 16:41 the card was still naming it
(C17). Flutter names the next slot, in the user's own clock. The time is never
going back to a hard-coded `14:00`.

**Why it takes a second line, measured rather than assumed.** `.minicard` is
`flex: 0 0 148px` with a 1-point border and `.minicard__body { padding: 10px
11px 12px }`, so the title's region is exactly **124 points** — on both sides.
`.minicard__title` is 13/700/−0.024em on a 1.25 line, with no `line-clamp`, no
`white-space: nowrap` and no `text-overflow`, so the reference's own card wraps
freely too. In that region:

| string | width | lines |
|---|---|---|
| `Next outage 14:00` — the reference's literal | 111.97 | 1 |
| `Next outage 19:00` — truthful, 24-hour | 111.29 | 1 |
| `Next outage 7:00 pm` — truthful, 12-hour | **127.93** | 2 |

**Three points ninety-three over.** Not a narrow Flutter text region, not
oversized trailing content, not a flex that refuses to shrink, and not a
missing wrapping rule: the region is the reference's own, and the string is
four points longer than it. Where the truthful value fits — any 24-hour clock —
the card is 140.25, exactly the reference's. It grows only where it must.

**Where it must, exactly.** Pakistan is the only market with Loadshedding, and
Pakistan is a 12-hour market, so in practice the card is always two lines in
English. `discover_outage_test.dart` measures all six combinations of
{en, ur, ar} × {12h, 24h}, caps the title at two lines, proves the time is
never ellipsised, and proves that at 200 % the card grows rather than clipping.

**And the strip grows with it, because the reference's does.** `.hscroll` is a
flex with the default `align-items: stretch`: one two-line card raises every
card beside it. Flutter's `Row` was centring instead, which left a ragged strip
of 140s around one 156 — a real defect, corrected. The strip is now 164 where
the reference is 148.25, and every card in it is the same height.

Related: the same strip's weather card reads "34° and hazy" in fixed markup
while `WEATHER_BY_COUNTRY.PK` says `'Hazy sun · humid'`. Flutter derives it from
the same weather the live row uses, so the card and the row agree.

### D24 — the quick-action strip bleeds through the page gutter

**Raised in F5A, resolved the wrong way, and corrected.**

The first implementation started the strip's content at the 20-point gutter and
called the reference's negative margin a defect. **That was wrong, and it was
not approved.** `.qactions` sets `padding: 0 var(--pad) 2px` *and*
`margin: 0 calc(var(--pad) * -1)`: an intentional full-bleed pattern, not dead
or defective behaviour. The strip has been restored to it.

Measured in the reference, and now matched:

| | reference | Flutter |
|---|---|---|
| first `.qaction`, x | 0.00 | **0.00** |
| `.qactions` port, 390 wide | x −20, w 430 | x 0, w 390 |
| first `.qaction`, x at 1100 | 269 (the section's own edge) | the section's own edge |
| `.chips`, for contrast | first chip at x 20 | first chip at x 20 |

The port is the one place the two differ, and it is invisible: the reference's
extends one gutter past each side and the page clips it; Flutter's is clipped at
the page edge instead. The pills land identically, the last one scrolls to the
same place, and nothing can scroll the page sideways. RTL mirrors it — the
Arabic golden has the first pill flush against the right edge.

The bounds comparison now **asserts** `qaction` x rather than excusing it, and
the goldens that encoded the guttered version have been replaced.

### D25 — a live card fills its column

**Raised in F5A. Approved as a responsive correction.** `#liveNow .livecard`
measures 372.31 wide at x 20 in a 390 viewport: 2.31 points off the right-hand
edge of the screen, and 22.31 wider than the 350-point column it sits in. The
trailing figure and the market pill cannot shrink, so the row grows instead of
wrapping.

Lume's hierarchy, density and geometry are kept — 70 tall, 20 in from the edge,
`14 15` padding, a 40-point disc, the same type — and only the overflow is
removed. `live_card_test.dart` checks the card against its column at **359,
360, 390, 600, 700, 840 and 1100**, in Urdu and Arabic, and at 200 % text,
including 200 % in both RTL languages. Recorded here as an approved overflow
correction.

### D26 — there is no progress bar, on either side. **Closed.**

**Raised in F5A, drawn without approval, reverted, and now settled: the web
element is dead markup, and Flutter's card is not a difference.**

The evidence, which is what the decision rests on:

* **It is emitted.** `home.screen.js:772` and `:796`, both inside
  `.progress-card`, with `data-fill="38"` and `data-fill="40"`. Those are the
  only two `class="bar"` in `assets/js/`.
* **The data is valid and the script runs.** A live probe of
  `#screen-home .progress-card:not([hidden]) .bar__fill` shows the inline
  `width: 38%` that `animateBars` writes from `data-fill`, a computed width of
  74.47 px, the specified `linear-gradient(90deg, rgb(52,179,157),
  rgb(16,153,138))`, and a finished transition. The probe waits 2.5 s, past the
  entry animation and the 1.1 s bar transition, so a zero cannot be "it had not
  started".
* **Nothing is hidden, empty, clipped or transparent.** `.bar` reports
  `opacity: 1`, `visibility: visible`, `hidden: false`, `clipPath: none`,
  `transform: none`, its `--tint-neutral` background, and an ancestor
  `.progress-card__body` that is a healthy 196 × 34.
* **`display` is the whole of it.** `.bar` computes to `display: inline`.
  `height` does not apply to a non-replaced inline box, so the declared 5
  becomes nothing: `rect` 0 × 0, `offsetHeight` 0, `clientHeight` 0 — while
  `offsetWidth` is 196. `.bar__fill` *is* in `components.css`'s "Block-level
  spans" rule block; `.bar` is not.
* **The card reserves no room for one.** `.progress-card__body` measures
  196 × **34** — title 19, gap 2, meta 13. A bar in flow would make it 43.
* **Nothing asks for a visible one.** `.bar`, `data-fill` and `animateBars`
  appear nowhere in `tests/*.js` or the design specifications, and `.bar`
  appears nowhere else in the prototype either.

**Classification: dead, incomplete prototype markup.** Not an intentional
composition that Flutter is departing from, and not a difference — Flutter
renders the card Lume renders. The bounds comparison confirms it at 350 × 86
with its title at x 105, matching the reference exactly.

**The plumbing went with it.** `LumeProgressCard.progress` had no consumer
once the bar was gone, and neither did the two `fraction` getters that fed it;
both are removed rather than left looking wired. They are one-line derived
values that Today's ring card can restate when it needs one.

**`LumeProgressBar` is untouched.** That is `.pbar` — `display: block`, 6 tall,
its fill a real block — a different component that really renders, used by the
gallery and covered by F2's component tests. Removing a dead `.bar` is not a
reason to touch a live `.pbar`.

A progress bar may arrive later as a product decision. It is not part of the
current Flutter reference, and nothing is plumbed toward one.

### D27 — the notification badge is a pill with a number in it

**Raised in F5A. Approved as a correctness and accessibility repair.**

§100.1 asks for *"one badge, in the app header, formatted compactly"*, and
`renderNotifBadge` computes exactly that — `n > 99 ? '99+' : n` — then writes it
into `.iconbtn__badge`, which is
`width: 7px; height: 7px; border-radius: 50%; overflow: visible`. The digits
render *outside* the disc, in the button's own inherited text, across the bell:
the reference's header reads "13" in near-black over the icon. The `'99+'` is
what settles the intent — nobody formats a dot that way.

What was kept, and what changed:

| | reference | Flutter |
|---|---|---|
| centre | 10.5 down, 11.5 in from the trailing edge | **the same** |
| fill | `var(--accent)` | the same |
| ring | `box-shadow: 0 0 0 2px var(--card)` | the same, as a spread shadow |
| shape with no number | a 7-point disc | a 7-point disc |
| shape with a number | a 7-point disc, digits outside it | the smallest pill the digits fit |

The pill is measured, not guessed: a `TextPainter` lays the string out in the
badge's own style and scale, and the shape is the text plus four points each
side and one above and below, never smaller than 14, never narrower than tall —
so one digit is a disc and two are a pill. The control's accessible name
carries the count ("Notifications, 13") and the badge itself is excluded from
semantics, so it is announced once.

**At a large text scale the number is dropped for the reference's dot.** A pill
that would sit more than four points past the control's edge — the header
leaves ten between its controls — stops being a badge and becomes a lid over
the bell. At 200 % the header shows the plain dot and the count stays in the
accessible name, which is where a screen reader was reading it from anyway.
`header_badge_test.dart` covers zero, one digit, two digits and `99+`, at
1.0/1.15/1.3/1.6/2.0, in English and Arabic, and asserts that no badge is ever
clipped or outside the control's reach.

### D28 — the "local service" marker is **not** drawn. **Closed.**

**Raised in F5A, drawn on a conditional approval, and removed.**

`tools.screen.js:73` draws `.cat-tool__pin` when `f.loc` is truthy, and
`grep "loc:" assets/js/data/catalogue.js` returns nothing. A live probe of
`#toolCats .cat-tool__pin` returns `{ found: 0 }`: the reference renders no pin
anywhere, in any state, for any profile.

**The case for drawing it, which was made and is not enough.** `loc` is a live
word in the reference with one meaning: `shell.js:229–239` gates `[data-loc]`
by `want.split(',').indexOf(profile.country) !== -1` with `'global'` as the
sentinel, and `search.js:46` drops an `EXTRA_INDEX` entry when
`x.loc && x.loc !== getProfile().country`. The catalogue's own field table
defines `countries` as *"markets this feature has actually launched in; absent
means global"*, and `core/eligibility.js:39` tests it identically. Same
definition, same membership test, same sentinel.

**Why that does not carry.** No source history records a rename —
`catalogue.js` never had a `loc` field to lose, so the screen and the catalogue
simply speak two vocabularies and the branch reads the wrong one. The
production catalogue never exposes `loc`. The rendered screen shows no marker.
And a missing decorative dot is not a security, privacy, data-accuracy or
accessibility failure, which is the only kind of reason that licenses a visual
departure. Semantic similarity is not proof of intent, and the rendered
interface is the authority.

**What was kept.**

* **The country gate, unchanged.** It reads `countries` and always did; the
  marker never fed it. `local_marker_test.dart` opens with that half — the
  seven restricted ids, the gate hiding exactly those abroad, absent still
  meaning global — so removing the pin cannot have weakened gating without
  failing a test.
* **The marker capability.** `LumeTileMarker.local` and its painting stay:
  another rendered screen may need it, and the precedence contract has to
  remain expressible.
* **The precedence contract**, as `LumeCatalogueTile.markerFor` — privacy,
  then locality, then the number, which is the order `toolCard` produces by
  overwriting. Verified on synthetic inputs at unit level. No production
  fixture is manufactured to make the pin appear; the rendered fixtures stay
  faithful to states Lume can actually reach.

**Recorded for Dayroz integration:** `tools.screen.js:73` reads a field the
catalogue does not carry. Either the branch is stale or the catalogue is
missing a field; the prototype cannot say which, and the conversion is not the
place to decide. Worth resolving when the catalogue is next authored.

### D29 — the market session is correct, behind a replaceable zone

**Raised in F5A. Approved, with the timezone table confined.**

Four defects in six lines — the device's clock rather than the exchange's, an
inclusive close, an ignored holiday table, one week for every exchange — each
corrected and each tested at its boundary. See `docs/LUME_DESTINATIONS.md` §5
and C11.

**The rule table is reference infrastructure and nothing more.** `LumeTimeZone`
is six zones and two daylight-saving families, chosen so the fixtures are
deterministic and the tests run the same in Karachi and Auckland. It is also a
poor database: no history, no future beyond today's legislation, six zones
where there are hundreds, and no concept of a zone being renamed, split or
redefined. **It is not fit to be Dayroz's production timezone authority, and
copying it there would be a separate decision this phase has not taken.**

**The adapter boundary.** `lib/core/time/lume_zone.dart` declares `LumeZone`
(`id`, `offsetAt`, `wallClockAt`) and `LumeZoneDatabase` (`zoneFor`, `ids`).
`LumeExchangeHours` takes a `LumeZone`; `LumeRuleTableZones` is the one binding
that hands it the conversion's table, and `exchange_fixtures.dart` is the only
file under `lib/` that names it. Dayroz installs a maintained IANA database
behind the same interface and nothing above changes.

`market_zone_boundary_test.dart` proves it three ways: the calculator answers
correctly for a `+05:45` zone implemented inside the test file that the table
has never heard of; the calculator's source contains neither `lume_time_zone`
nor `LumeTimeZones` nor `LumeDstRule`; and a three-line database with no rules
at all satisfies the interface.

### D30 — every entry surface asks the same eligibility question

**Raised in F5A. Approved, required, and verified surface by surface.**

The reference gates its Discover strip by `data-loc` and `data-faith` markup
attributes rather than by the eligibility selector, so a user who switched
cricket off in Personalisation still saw a cricket score on Home. Measured: the
`prefs_off_pk` capture still lists `PAK 214/4`.

§64 lists the surfaces a hidden feature must not be reachable through, and
`eligibility_surfaces_test.dart` walks them with five users — not Muslim in
Pakistan, Muslim in Pakistan, Muslim in the United Kingdom, not Muslim in the
United States, and a user with the content switches off:

| surface | what is asserted |
|---|---|
| the selector | faith, country and preference gate separately, with distinct reasons |
| sensitive | visible in the catalogue, never promoted on Home (§61) |
| the hub | every tile drawn ⇔ the selector allows it, for all 85 features |
| search | four queries; nothing the hub would hide ever appears |
| Home | every quick tool, quick action, hero slide, glance card and Discover card is allowed |
| Discover | a switched-off content type loses its card; a faith-gated one never gets one |
| recents | a history containing a now-ineligible tool cannot bring it back |
| deep links | the route consults the catalogue |

**The deep-link gate is new code, not a new assertion.** The tool route opened
`FixtureToolScreen` without consulting anything; it now resolves the id against
the same `LumeEligibility` reading the same profile, and hands the verdict to
the frame. A refused tool and an unknown id produce an *identical* frame —
same title, same subtitle, same copy — because "you may not have this" and
"there is no such thing" must not be distinguishable, or the refusal is itself
the disclosure. A tool the user may have is named; a refused one is not.

### D31 — dates and clocks are world English, not American

**Raised and resolved in the F5A correction pass. This is a parity repair, not
a departure.** `intl` ships a subset of CLDR and falls back from a tag it does
not have straight to the bare language — and its bare `en` *is* `en_US`. It has
no `en_PK`, so a reader in Karachi was getting "Mon, Sep 7" and "6:27 PM" where
the reference, running against a browser's whole CLDR, renders "Mon, 7 Sept"
and "6:27 pm".

CLDR does not inherit that way: every English locale outside the United States
and its territories inherits `en-001`, world English. `intl` has no `en_001`,
so `LumeFormatting.dateLocale` resolves to the nearest shipped locale on that
branch, which produces `en-001`'s forms exactly. §13 asks for locale-aware
formatting and says not to hard-code English/US formatting globally; this is
that, and the reference agrees with it.

Numbers keep the unresolved tag. Grouping and separators are a different CLDR
dimension, and borrowing a stand-in for them would import its digit grouping
along with its month names.

### D32 — a 12-hour clock is a 12-hour clock in every locale

**Raised and resolved in the F5A correction pass.** `DateFormat.jm` is a
*skeleton*, and a skeleton carries the locale's own hour cycle: `jm` in `en_GB`
is 24-hour, so asking for a 12-hour clock there quietly returned "18:27". The
pattern is now spelled out — `h:mm a` or `HH:mm` — so the choice is the user's
and only the day-period marker comes from the locale. The reference makes the
same choice explicitly, with `hour12: clock() === 12`.

### P2 — the greeting's emoji has no face in a test capture

**A capture-environment limitation. Confirmed on a device, and it is not a
runtime difference.**

**In a capture:** `flutter_test` loads only the fonts the application declares,
and Lume declares Plus Jakarta Sans and Noto Naskh Arabic. Neither has `👋`, so
the greeting's emoji renders as a box in every golden and every side-by-side.

**At runtime:** it does not. Verified on an Android emulator — Pixel 6 Pro,
Android 16 (API 36) — running the **packaged debug application**, built from
`docs/conversion_archive/tool/android_home_probe.dart`, which is `LumeApp` with
one override so the non-durable profile repository (F4C) starts onboarded and
the launch reaches Home. `adb exec-out screencap` at 1440 × 3120 shows the
greeting as **"Good afternoon 👋" with the emoji in full colour**, drawn by the
platform's own font fallback. No tofu, no notdef box, no missing advance.

So no asset is bundled. The platform fallback is reliable, it produces Lume's
visual result, and shipping a 10 MB emoji font to fix a screenshot would be the
conversion solving its own tooling's problem in the product.

The same run confirmed, on a real Android device, what the widget tests assert:
the badge pill, the full-bleed quick-action strip, the progress card with no
bar, the stretched Discover strip, and "Sat, 12 Sept · 3:53 pm" in
world-English rather than American formats.


One correction has been applied to the web prototype: the four dead
`.onb-country` lines, deleted in F1 under the evidence gate in C1. Nothing else
in the prototype has been touched, and no Markdown or `.docx` specification has
been rewritten yet — that is Phase F8, where both `.docx` files are re-rendered
and visually inspected after every material revision.
