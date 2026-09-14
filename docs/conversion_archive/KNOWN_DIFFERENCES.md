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

### C22 — Nearby names three Karachi venues to every reader on earth

**Found in F5B. Reproduced, not repaired, by decision.**
`explore.screen.js:376–407` writes three `.list-row`s as static markup —
Masjid-e-Tooba · 650 m, Chai Shai · 1.1 km, Hill Park · 1.4 km — with no
`data-loc`, no city read, no source attribution and no unavailable state. The
section renders identically in Islamabad, London and New York.

It is the one place on Explore that breaks the screen's own stated standard
(*"this screen must never show a market, a unit or a venue from somewhere the
user is not"*), and the distance makes the falsehood specific: a reader in
London is told a Karachi mosque is 650 metres away.

Traced, classified as a data-accuracy failure and **put to a decision rather
than settled**. The decision was to reproduce Lume exactly, so Flutter renders
the same three rows in every market, faith-gating the first exactly as Lume
does.

**Dayroz obligation.** Nearby must be backed by a real places source keyed to
the user's city, with distances computed from a real location, or it must not
ship.

### C23 — Today's task counts are literals that contradict the list below them

**Found in F5B. Reproduced, not repaired, by decision.** Two figures on Today
are written down rather than counted:

* the ring card's sentence, static markup reading "2 of 5 tasks done. One
  meeting left this afternoon.", never rewritten (T1);
* the tasks statistic, pushed as `L.num(2) + '<span>/' + L.num(5)` (T2).

Neither follows the task list. A reader outside the Islamic experience has four
tasks — Al-Kahf is faith-gated — and still reads five; ticking a task moves the
list and not the sentence above it.

An earlier F5B implementation derived both from the list. That was a
correction, not a reproduction, and it was **not approved**: it made the
Pakistani Muslim cell agree by coincidence and every other cell disagree with
the reference. Put to a decision, and the decision was to reproduce Lume
exactly. The figures are now `kReferenceTasksDone`, `kReferenceTaskCount` and
`kReferenceMeetingsLeft`, carried as numbers so the sentence is still a
translated template.

**Dayroz obligation.** Both must be derived from the task store.

### C24 — "updated 4 min ago" is a freshness claim with nothing behind it

**Found in F5B. Reproduced, not repaired, by decision (E1).** Explore's weather
head writes `L.num(4)` — the same claim in every state, never changing, with no
fetch behind it. The values *around* it are honest: temperature, condition,
rain, wind and sunset are all per-country and per-city. This is the one part of
the card that lies. `kReferenceWeatherAgeMinutes` names it.

**Dayroz obligation.** The weather adapter must supply a real fetch timestamp
and the label must follow it.

### C25 — the ayah is cited twice, and the two citations are different

**Found in F5B by the side-by-side comparison, and corrected.**
`today.screen.js` writes `Ar-Ra’d · 13:28` as the section subtitle and
`Ar-Ra’d 13:28` at the foot of the card — with a separator and without. An
earlier F5B implementation carried one finished `reference` string and used it
in both places, so the subtitle lost its dot.

Corrected by carrying the surah, the chapter and the verse as three fields and
composing each form through its own localisable key. A single finished string
could only ever have been right in one of the two places.

### C26 — a card's border is drawn but takes no room

**Found in F5B against the measured bounds, and corrected in the shared
component.** `LumeCard` painted its 1-point border with a `DecoratedBox`, which
paints without reserving layout space — so every card was two points shorter
than the prototype's, and a list card holding six rows measured 365 against the
reference's 367.

Corrected by adding the border width to the card's inset. `Home`, the Tools
hub, Today and Explore all moved, and all four now match their measured bounds;
the goldens were regenerated and no measured-parity assertion loosened.

### C27 — the page head's subtitle took a reading line, not the font's

**Found in F5B, and corrected.** `.page-head__sub` sets `font-size: 13px` and
no line height, so the line is the font's own — 16. `LumePageHead` was asking
for the `meta` role's reading height and rendering 17, which put every page
head one point out and masked a separate two-point error below the Tools hub's
chips. Both are fixed; the three page heads now match to the point.

### C28 — a 20-point line is 25, not 26

**Found in F5B, and corrected.** `LumeType.naturalLine` carried `20 => 26`.
Two independent measurements on Today — `.ring__value` and `.stat__value`, both
20/800 with `line-height: normal` — render 25, and 26 appears nowhere in any
captured measurement. Corrected to 25.

### C29 — Today's ring card has a sparkle, and it was not drawn

**Found in F5B by the side-by-side comparison, and corrected.**
`today.screen.js` hangs a 46-point `<span class="sticker sticker--slow">` off
the ring card at `top: -12px; right: -6px`. The artwork had been extracted by
`gen_destination_art.mjs` and never placed. It is now drawn, overhanging two of
the card's edges, taking no layout room, no touch and no semantics.

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

### C30 — "From Karachi Cantt" heads a list that is not from Karachi Cantt

**Found in F5C. Reproduced, not repaired, by decision (R1).**
`tools/trains.js` builds the departures section's subtitle from the origin
field — it reads "From Karachi Cantt", and follows the field when the field
changes — while the list under it is the module's whole five-service roster,
emitted in declaration order. Four of the five call at Karachi Cantt; the
Shalimar Express is a Lahore departure, and it appears under the Karachi
heading unchanged. Searching, swapping the ends and choosing a different day
all leave the same five rows in the same order.

The heading is therefore a claim the list does not support, and it is the same
class of finding as C22 and C23: a caption written against data that was never
filtered.

**Preserved deliberately.** `LumeTrainsComposer.departures` takes the origin
and the service date and returns the roster regardless of both, and
`trains_query_test.dart` asserts that it does — the test is written so that
filtering the roster would fail it, which makes the preservation visible
instead of accidental. The heading still follows the query, because that is
what the reference does.

**Dayroz obligation.** Departures must be a real query against a real
timetable: filtered by origin, resolved for the selected service date, and
ordered by departure time. Until it is, the heading is the honest half and the
list is the half that has to change.

### C31 — two currency notations on one screen

**Found in F5C. Reproduced, not repaired, by decision (R4).** Trains prints
money two ways, five rows apart:

| Where | Source | Renders |
|---|---|---|
| `.routecard` fare | `tools/trains.js` route table | `₨ 2,400` — the rupee **sign**, U+20A8 |
| `.train__meta` fare | the same module's service rows | `Rs 8,900` — the letters, with a non-breaking space |

Both are Pakistani rupees, both on the same card stack, both from the same
file. Neither goes through the prototype's own money formatter.

**Preserved deliberately.** Flutter renders `₨` on route cards and `Rs` +
NBSP in departures, from two fixture fields rather than one, and
`trains_composition_test.dart` reads both strings back. Collapsing them to one
notation would have been a product decision made silently on a screen the
brief asked to be reproduced.

**Dayroz obligation.** One notation, chosen once, resolved through the
locale's own currency rules — CLDR gives `Rs` + NBSP for `en-PK`, and `₨`
for nothing — and applied to every fare on the screen. The choice belongs to
product and localisation together, not to whichever table the fare came from.

### C32 — `.railsearch__foot` does not shrink, it overflows

**Found in F5C. Reproduced.** The foot is a flex row holding the day chips and
the Search button, and every item in it keeps its content width: `min-width:
auto` is the default for a flex item, and nothing in `tools.css` overrides it.
Measured on `trains_muslim_pk`, the chips are **61.19** wide at 390 *and* at
359, and at 359 the Search button is pushed to x **243.11** with a width of
**94.64** — a right edge of 337.75 against a content box that ends at 323. The
card's `overflow: hidden` trims the remainder.

This is recorded because the obvious Flutter translation is wrong in a way
that looks right. `Flexible` divides free space by flex factor whether or not
the child needs it, so a row of `Flexible` chips allots each an equal share and
ellipsises the longer label — "Tomorrow" rendered as "Tom…" at 390, a width
where the reference has 16 points to spare. CSS `flex-shrink` only engages on
overflow; Flutter's `Flexible` engages always.

Flutter lays the foot out at `max(natural, available)` and clips what does not
fit, which reproduces both halves: the button holds the trailing edge at 390
(`margin-left: auto`) and is trimmed at 359. `destination_bounds_test.dart`
now measures `railsearch.foot` and `railsearch.go` as well as the first chip,
so the same mistake cannot pass again — measuring one chip was what let it
through.

### C33 — the Search button's tracking was not applied

**Found and corrected in F5C.** `.btn { letter-spacing: -.022em }` reaches
`.railsearch__go` like every other button; the prototype reports the computed
value as `-0.286px` on its 13-point label. Flutter built the label from
`LumeType.natural` without `LumeType.tracked`, so all six characters were set
loose and the button measured **96.36** against the reference's **94.64** —
1.72 points, which is exactly six times 0.286.

**Exact parity, restored.** An implementation defect, not a difference. It went
unseen because the button had never been measured: the Trains bounds comparison
checked the card, the fields, the swap and the first chip, and stopped there.
It is on the list with C32 because the same omission hid both.

### C34 — the notification count and the notification list disagree about faith

**Found in F5C. Corrected.** Profile's Notifications row says "{n} of {total}
on", and `notifValue()` computes both figures from the whole `CATEGORIES`
table — eleven, always. The screen that row leads to filters the same table
twice before drawing it: once by the reader's faith preference, and once by
whether any *visible* feature feeds the category.

So a reader who has not switched the Islamic experience on is told about
eleven categories and shown ten. The figure is not wrong about the table; it
is wrong about the screen it is a summary of, which is the same class as C23.

**Corrected rather than reproduced**, because the faith gate is the one rule
§64 asks to be applied everywhere rather than at the entry point:
`LumeNotificationPrefs.visible(islamic:)` is asked once and answers both the
count and the list, so they cannot disagree. A Muslim reader still sees
eleven; a non-Muslim reader is told ten of ten.

**Dayroz obligation.** The second filter — whether a category has any visible
source behind it — belongs here too once there is a notification engine to
ask. Until then the count would over-report for a reader whose country has no
Pakistani services, and that is recorded rather than fixed against data that
does not exist yet.

### C35 — the settings row was a point or two out in five places

**Found and corrected in F5C.** `.list-row` is `padding: 13px 15px; gap: 13px`
with a 34-point icon tile and a 17-point glyph in it. Flutter had 14/12, a
36-point tile, a 12-point gap after the icon and an 8-point gap before the
row's end.

None of it was visible on its own, and all of it moved the description: the
Notifications row's "Push alerts, in-app updates and quiet hours" took three
lines where the reference takes two, which is eleven points on one row and
compounds down a list of eight. Measured: `srow` 348 × 61, `srow.icon` 34 ×
34 at x 36, `srow.title` and `srow.sub` 242 wide at x 83.

**Exact parity, restored.** An implementation defect, found by adding Profile
to the bounds comparison and then measuring the row's *parts* rather than the
row — which is the same lesson C32 taught about the first chip.

### C36 — a row promised "Not set" and rendered nothing

**Found and corrected in F5C.** `srow` distinguishes two things the product
must not confuse: an empty string is *a value the product holds and knows to
be empty*, and `undefined` is a value it does not have. The reference renders
`a.notSet` for the first. `LumeSettingsRow`'s documentation said so, and its
code rendered nothing at all — so a guest's Display name row showed a bare
title where the reference shows "Not set", and the row was eleven points
shorter for it.

The row now takes a `notSetLabel` and asserts it is given wherever the value
can be empty. A core widget does not reach for the localisations, so the
caller supplies the string; the *rule* stays in the widget.

**Exact parity, restored**, and a gap §125 forbids closed with it.

### C37 — `.list-row__end`'s gap falls between its children

**Found and corrected in F5C.** `.list-row__end { gap: 8px }` separates a
value from its chevron. A row that has no value has nothing to separate, so
the eight points do not exist and its description has them instead. Flutter
put the gap in unconditionally and every valueless row's text column was eight
points narrower than the reference's 242.

**Exact parity, restored.** The same class as C35, found by the same
measurement.

### C38 — `.tag` was as wide as whatever it was put in

**Found and corrected in F5C.** `Container` wraps an aligned child in an
`Align`, which expands to the width it is offered. `LumeTag` set
`alignment: Alignment.center`, so the guest badge — a 45-point pill reading
"Guest" — rendered as a 312-point bar across the identity card.

It had never shown before because Today's and Explore's market tags sit in
rows that constrain them. The row inside centres itself in the 21 points
without the `Align`, and the tag is its words wide again.

While it was open: `.tag`'s glyph is the base `.ico`'s **20**, not 13, and its
gap is 4, not 5 — which is the six points between a 178.78-wide membership tag
and a 172.78-wide one.

### C39 — the status badge stood 19 where the reference draws 16

**Found and corrected in F5C.** `.badge` sets `font-size: 10px` and leaves
`line-height` alone, so its line is the font's natural 12 and the pill is
2 + 12 + 2 = **16**. `LumeBadge` took the `--t-metasm` token's line instead,
which is taller, and stood 19. Its glyph is `font-size: 11px; line-height: 1`
— set on its own box so it never decides the pill's height, which Flutter's
did.

Found on the expired identity card, where the badge is the only thing in the
meta row and its three points moved everything below it. It affects every
badge in the product; the five destination comparisons were re-scored
afterwards and none moved.

### C40 — the identity card's gap belongs between the blocks, not the lines

**Found and corrected in F5C.** `.phead__id` is a flex column with
`gap: 10px`, and its three children are the avatar, a `<div>` holding the name
*and* the address, and the meta row. The gap therefore falls twice, not three
times: the two lines inside the div sit against each other.

Flutter put ten points between the name and the address as well, which made
the card ten points taller in every state that has both. Measured: `phead.name`
at y 198 and `phead.mail` at 222, with 24 points of name between them.

The same block is also *shrink-to-fit* — `align-items: center` on the column
means the div is as wide as the wider of its two lines, and each `<p>` fills
it. At 390 the guest's address wraps and takes the full 312; the holder's name
is 132.3 and the address sits centred under it.

### C41 — an option row's title and its description run together

**Found in F5C. Put to a decision, and the decision was to reproduce.**

`.optrow__title` and `.optrow__sub` are inline `<span>`s, and nothing
blockifies them. `components.css` has a rule that turns `.list-row__title`,
`.list-row__sub` and a dozen other spans into blocks; `.optrow__*` is not in
it. So the prototype renders an option row as one line with the two strings
jammed against each other:

| route | what the reference draws |
|---|---|
| Units | `Follow my regionAutomatic`, `Metrickm · °C · kg`, `Imperialmi · °F · lb` |
| Currency | `Follow my regionAutomatic (PKR)` |
| Language | `Englishenglish` |

Measured: the row is **46** in the prototype and 57 in Flutter, which draws
the description on its own line as every other row in the product does. Five
routes carry option rows — language, region, currency, units, time,
appearance — and the difference is eleven points a row on all of them.

**Why it was a decision.** The visual-authority rule says the rendered Lume
interface wins and reserves *a visible departure from Lume* for a decision.
Reproducing it means shipping "Follow my regionAutomatic"; not reproducing it
is a visible departure on five screens. Neither was ours to choose.

**Decided: reproduce.** `LumeOptionRow` draws one `Text.rich` with two spans
and no separator, on the line height the spans inherit — `--t-body`'s 1.5,
which is 21 at 14 and is what makes the row **46** rather than the 43 the
font's own line would give. `account_bounds_test.dart` asserts it, and
`optrow` reads `=` on all five routes.

**Dayroz obligation.** Add `.optrow__title` and `.optrow__sub` to the rule in
`components.css` that already blockifies `.list-row__title` and
`.list-row__sub`. Until then every option in the account section reads as one
run-on word.

### C42 — an option row's mark was a bare check

**Found and corrected in F5C.** `.optrow__mark` is a 20-point ring with a
1.5-point border on **every** row, filled with the accent and a 12-point check
on the chosen one — and `.optrow.is-on .optrow__title` takes the accent ink.
Flutter drew a bare check on the chosen row and nothing at all on the others,
so an unchosen option had nothing at its end to say it was one.

Also corrected while it was open: `.optrow`'s padding is `--pad-row` —
`12px 16px`, "one value for nine row types" — where Flutter had 14/12.

**Exact parity, restored**, and §60's "colour-independent status indicators"
kept: the ring, the fill, the check and the title's colour all move together.

### C43 — a list under a form moves with the form. **Open.**

**Found in F5C. Measured, and put to a decision.** On Edit and Delete the
blocks are in the reference's order and the reference's shape, and the list
*below* the form sits lower than the prototype's: six points a field on Edit
(88 over the whole form), thirty-four on Delete's two consequence lists.

It is an accumulation rather than a structural difference — no block is
missing, misplaced or the wrong size — but it is larger than D20's three
points and is therefore named rather than absorbed into a tolerance.

### C44 — the Notifications screen filters twice, and the route was half built

**Found in F5C. Put to a decision, and the decision was to carry the
reference's own table.**

Two things, and the first was mine. `ROUTES.notifications` delegates to
`renderNotifPrefs`, which draws **five** sections — General, Categories, By
tool, Quiet hours, Privacy — and a control that restores every dismissed
notification. Flutter had built two of them. That is not a difference; it is a
route that was not finished, and it is finished now.

The second is the filter. `services/notifications.js` narrows the category
list by two questions before it draws a switch:

1. the reader's faith preference, and
2. whether any **visible feature** feeds the category —
   `NOTIFY.SOURCES.some(src => src.cat === c.id && visible(feature(src.tool)))`.

**Decided: carry `SOURCES` as a fixture.** `kNotificationSources` is the
engine's own fifteen rows — id, tool, category, type — and nothing else from
it: no build function, no schedule, no delivery. With the table in hand
`LumeNotificationPrefs.visible` can ask both questions in one place, so the
count on Profile and the list on this route cannot disagree (C34), and the By
tool section has something true to group by.

**No icons.** `toggle()` emits a title, an optional description and a switch
and no `.list-row__icon` at all, so every row on this route is 59 where the
icon'd rows elsewhere in the section are 61. The categories carry glyphs in
the engine's table and the screen does not draw them.

**Dayroz obligation.** When there is an engine, `SOURCES` moves behind it and
this table goes away; `visible` keeps asking the same two questions.

### C45 — `--pad-row` is 12/16

Recorded as part of C42.

### C46 — the toolbar's back control, and its target

**Found and corrected in F5C.** Two things at once. The drawn circle is
`.toolbar .iconbtn`'s **38**, not onboarding's `.onb__nav` 34 —
`LumeBackButton` had one size and the product has two. And its 44-point
accessible target was growing the bar: a `.toolbar` is measured at **61** and
Flutter's stood at 66, because `10 + 44 + 12` is 66.

The target now overhangs into the bar's own 10/12 padding instead of pushing
it out, which is the separation D35 made on a card action, in a second place.
The circle carries a key so a measurement can tell it from the target.

**Corrected again in F5C-D, and this time it is true.** The claim above was
written when the bar was right on the routes that were being looked at, and
the generated table said otherwise on all twenty-one: `toolbar` height 61 → 62
and `toolbar.back` y 10 → 11, every route, a point each. Both came from one
missing point — `.toolbar` carries `border-bottom: 1px solid transparent`,
which `.toolbar.is-stuck` turns to `--border` when the bar sticks, and
transparent is not the same as absent. Without it the bar was 60 of content
against a `minHeight` of 62, so the 38-point back control centred itself in a
40-point box and sat a point low.

Flutter draws the hairline, transparent, and takes its height constant down to
**61**. `ACCOUNT_PARITY.md` now reads `=` on `toolbar` and `toolbar.back` for
all twenty-one routes — checked against the generated file rather than
asserted.

**The lesson recorded with it:** a parity claim written in prose beside a
generated table is a claim nobody re-reads. The table is the evidence; the
prose has to be checked against it whenever the table changes.

### C47 — the toolbar's title took a token's line

**Found and corrected in F5C.** `.toolbar__title` is 20 / 800 / −0.034em with
`line-height: normal`, which is the font's natural **25**. Flutter took the
`--t-title` token's line instead, which is taller — enough to make the bar two
points deep and to push the 38-point back control two points off the padding
it should sit on.

The same class as C27 and C28: a role token used where the stylesheet is not
using one.

### C48 — the account's forms are the product's field, not authentication's

**Found and corrected in F5C.** `tools/shared.css` and `auth.css` define two
shapes for the same element, and the account section wears the first:

| | `.field` | `.auth .field` |
|---|---|---|
| label | 11 / 700, `.02em`, **uppercase**, `text-3` | 13 / 600, `-.005em`, sentence case, `text-2` |
| box | `padding: 10px 12px`, `card-2`, `--r-xs` | `min-height: 52`, `padding: 0 18`, card |
| input | 14 / 700 / −.026em | 16 / 600 / −.192px |

`LumeInputField` — the authentication flow's field, moved into core this
phase — was drawing the auth shape everywhere. It now takes a
`LumeFieldVariant`, so one widget draws the two shapes the stylesheets have
and a third copy is not needed for the next form.

### C49 — the reference tells a phone user about their browser

**Found and corrected in F5C.** The prototype is a web page and says so in
five strings. `acct.err.storage` tells a reader to "check your browser's
storage settings"; `n.push.denied`, `n.push.deniedHelp` and `n.push.granted`
describe a browser's permission prompt; `acct.device.browser` labels the
current session "This browser".

A Flutter build has no browser. Each of the first four is an instruction the
reader cannot follow, so each names the device instead. The fifth keeps the
word and is the only one that may: it is one of five platform labels a session
row can carry — beside Android phone, iPhone, Mac and Windows PC — so it says
"Web browser", which is a fact about a platform rather than a claim about the
reader's own device.

`arb_parity_test.dart` holds the line: no English value may contain the word
"browser", with `acctDeviceBrowser` named as the single exception.

### C50 — the toolbar's subtitle took a token's line too

**Found and corrected in F5C-D.** C47 fixed the title and stopped one line
short. `.toolbar__sub` is `font-size: 11px; font-weight: 500; margin-top: 1px`
with no `line-height`, so its line is the font's natural **13** and the block
is 25 + 1 + 13 = **39**. Flutter took `--t-meta-small`'s explicit 16 and
dropped the margin, making the text block 41 and the bar 64 where every route
carrying a subtitle measures 62.

It stayed hidden because the bar's own `minHeight` of 62 absorbed it: the
route read 63 against 62 and passed inside the one-point tolerance. Fixing the
hairline removed the cushion and the real number appeared.

The same class as C27, C28 and C47 — a role token used where the stylesheet is
not using one — and the third time it has been the toolbar. Every text style
in `LumeToolbar` now comes from `LumeType.natural`, which is what
`line-height: normal` means.

### C51 — a reported difference wearing another difference's explanation

**Found and corrected in F5C-D.** `ACCOUNT_PARITY.md` labelled the `field`
height rows "cumulative line-box rounding (D20)" on five routes, where the
numbers are 81 → 92 and 67 → 92. Eleven and twenty-five points are not
rounding, and the rows are not asserted at all: `checkHeight: false`, because
`.field` bounds the input and `LumeInputField` bounds its label and message
with it (C48). The number was real, the claim beside it was not, and a reader
scanning the table would have taken it for a difference already accounted for.

An axis that is reported but not asserted now says so, with the reason, and
the note it would otherwise inherit is suppressed. Of the fifty-six remaining
differences in the table, twenty-eight are D20, fifteen are C41, eight are C43
and five are not compared. None is unexplained.

### C52 — the reference counts one habit in the plural

**Found in F5D. Reproduced.** `n.habit.title` is `'{n} habits left today'`,
`n.tasks.title` `'{n} tasks left today'` and `n.bill.title`
`'{n} bill needs attention'` — none has a one/other form, so the running
reference renders **"1 habits left today"** beside **"1 bill needs
attention"**. `probe_notifications.mjs` reads both off the screen.

The fixture's counts are the reference's own and fixed, so `nHabitTitle`,
`nTasksLeft` and `nBillTitle` are carried as the rendered, non-plural strings.
**Dayroz obligation:** the moment a count is live, each becomes an ICU plural
in all three languages.

### C53 — in Urdu and Arabic the reference's notifications are English

**Found in F5D. Corrected in Flutter.** `probe_notifications.mjs --lang ur`
and `--lang ar` render every row title, body, meta line, badge, action and the
header in English: `assets/js/i18n/tools.js` carries the `n.*` keys for
English only, and the one translated fragment on screen is `weather.rain`.

Flutter translates all of them — the 43 centre keys, the 29 row keys, the
sheets' strings — because §11 and §48 make a notification's language the
reader's, and a missing dictionary is not a design. Direction, fonts and line
breaking follow the language. **Classification:** permitted correction.
**Evidence:** the centre's "every language, and twice the type size" tests and
the `390x844_light_ur` / `_ar` goldens.

### C54 — a low notification ranks as a normal one

**Found in F5D. Reproduced.** `priorityRank: PRIORITY[src.priority] || 1`
— `low` is `0`, which is falsy, so it ranks `1`. The consequence is visible:
tomorrow's forecast (low, 300 minutes) sits **above** the electricity bill
(normal, 640 minutes) because rank ties and age decides.

`lumeReferenceRank` reproduces it for ordering only; `LumeNotificationPriority`
keeps its true rank for everything else. **Evidence:** "rank outranks recency,
with low ranked as normal (C54)" and the thirteen-title order test.

### C55 — the notification fixture was written, not read

**Found and corrected in F5D.** The partial checkpoint's samples — a heavy-rain
warning, Metformin, the Green Line, three KSE rows to fold, a note card saying
there was no notification server — were composed by hand. None is what the
reference renders at the fixture instant, and the note card is a surface the
reference does not have. That is a visible departure, not a fixture detail.

They are now the rows the running reference renders, read with
`probe_notifications.mjs`:

* **thirteen** for Pakistan (`muslim_pk` and `default_pk` alike — no prayer is
  within 45 minutes and there is no weather alert), **ten** for London and New
  York;
* the **market row is per exchange**: `EXCHANGES[country].indices[0]`, and only
  past half a percent — Pakistan (+0.82 %) and Saudi Arabia (+0.53 %) build a
  row; London (0.38 %), New York (0.42 %), Dubai (0.40 %) and Mumbai (0.49 %)
  do not;
* **tomorrow's forecast is per market**, in its units — Islamabad 36° / 27° /
  1 %, London 25° / 17° / 10 %, New York 84° / 68° / 50 %. A market the probe
  has no state for reads Pakistan's, labelled fixture-only;
* **sensitivity is the source's** (`src.sensitive`), not the category's: a bill
  in Money withholds its amount, and `LumeNotificationSource.sensitive` now
  says so;
* **folding is unreachable**: `groupId` is the source id and each source builds
  one row. The rule is kept as a contract and tested as a function.

The invented note card is removed. **Evidence:**
`notification_centre_test.dart` — the reference order, the London and New York
feeds, withheld bodies.

### C56 — search was laid out from its markup, not measured

**Found and corrected in F5D.** Measured with `measure_destinations.mjs --after
search_*` over Home, and corrected:

| part | was | reference |
|---|---|---|
| suggestions | filter chips, flush | `.chip` (`LumeChoiceChip`), inset 20, 2 below |
| recents and hits | rich rows in a lifted card | `.list.list--flat` — a shadowless card of 61-point `.list-row`s; hits end in `#i-arrow-ur` |
| nothing found | a tool state | `.empty` with the sheet's own lens drawing |
| scrim | colour only | `backdrop-filter: blur(3px)`, fading in with the colour — every sheet |
| the field | no focus treatment | `.search:focus-within` — a half-accent border and a 3-point tint ring, replacing `shadow-xs`; every search field, onboarding's country picker included |
| a recent's line | the catalogue's static status | the live tile status — "34° Hazy sun" |
| medium and expanded | a dialog centred in the window | rising from the bottom, 24 clear, at most 520 wide, rounded, grab kept |

**Evidence:** `search_bounds_test.dart` — sheet, field, both labels, first chip,
recents card, first row, first hit, empty drawing and its title, each within
one point; the same sheet over Explore, raised by Explore's page head, at the
same geometry the reference measures there (`search_explore`), with Back
returning to `/explore`; and with a 336-point keyboard up, the sheet riding
above it. The keyboard cell is Flutter's alone — headless Chrome raises no
keyboard, and the reference's `100dvh` would not track one. The idle goldens pump past the sheet's 320 ms focus delay: at
medium the transition settles sooner, and a capture without it would show a
field the reference never shows unfocused.

### C57 — the centre's composition and row, measured

**Found and corrected in F5D.** Measured with `measure_destinations.mjs --screen
notifications`:

* **sections** are `.sect`, 24 apart (`--gap-section`) — the partial checkpoint
  used 14;
* **tabs** are `.ttabs` edge to edge with a 20 inset, 4 between tabs, each
  count in a tinted pill, and the selected tab's **accent** bar inset 8 and
  hanging 1 — not a full-width text-coloured underline. This is the shared
  `LumeTabs`, so the component gallery's tabs changed with it;
* the **category bar** spaces chips 7 apart with 2 below. Its chips' 44-point
  targets reach 6.5 past each 31-point chip, and the gaps around the bar give
  those points back — the rule D6 and D35 keep — so the chips and the list land
  where the reference's do;
* the **list clips** (`.nlist { overflow: hidden }`);
* **the row**, from `.nrow`: 12 × 16 padding, a 36-point icon on `--r-icon`
  with a 17-point glyph, health tinted rose, a 14 / 700 / −.026em title on 1.3,
  a 12 / 400 body on 1.45 three below it, an 11 / 600 meta line of 13 five
  below that, an 8-point dot; the unread tint across the **whole** row with a
  3-point accent bar; a 44-point action strip holding a 7 × 14 tinted pill and
  a 32-point dismiss whose 44-point target is the strip's own height; expired
  rows at 58 %.

**Evidence:** `notification_bounds_test.dart` — toolbar, tabs, category bar,
list, first row, its title line, badge, title, body, meta, dot and dismiss
within one point. The second row's pill and the fifth row are within three: each
row is about 0.7 shorter, 18.19 and 17.39 rounded to whole points (D20), which
also makes the thirteen-row list 8.88 shorter — reported, not asserted.

### C58 — the banner was built, and never shown

**Found and corrected in F5D.** `LumeNotificationBannerHost` existed and was
tested on its own; nothing in the app mounted it or decided when it should be
up. The reference's shell ticks: `setTimeout(notifyTick, 2500)` and
`setInterval(notifyTick, 45000)`.

`LumeNotificationPresenter` wraps the shell and reproduces the tick exactly:

* `nextToPresent` — the first unread, unexpired row not yet presented — and
  `markPresented` whatever surface it goes to, so an event reaches one surface;
* `mayInterrupt` — never with in-app off; important and above, or only critical
  inside quiet hours;
* nothing at all while in-app and push are both off;
* no banner on the centre, where the event is still marked;
* no banner while the app is away — there is no push in this build, so the
  event waits.

One addition the reference leaves to chance: never over a sheet or a dialog.
The banner sits in the shell's own slot (top at compact, the trailing corner at
medium and expanded), blurs what is behind it by 20, and brings its own
material. The presented set is nondurable, so a restart presents the first
banner again where the reference remembers it in the profile — fixture-only.
**Evidence:** `notification_presenter_test.dart`, eleven tests.

### C59 — the notification sheets were not the reference's

**Found and corrected in F5D.**

**`#sheet-notifpush`.** A 56-point art tile on `--r-lg` with `#i-bell-ring` at
26; a 20 / 800 title; the text at 13 on 1.5, no wider than 32 of the font's own
zeros; the categories as centred pills; an accent button carrying its words
alone; and "Not now" as bare text, its 44-point target taken from the margins
around it. It still grants nothing.

**`#sheet-notifprefs`.** A head with the reference's subtitle — "What Lume may
tell you, and when" — and `.closebtn`, a 30-point tinted circle, which every
titled sheet now carries. The body is `renderNotifPrefs`: General (Push, "Not
asked yet"; In-app; Sound; Vibration; Badge count), Categories, By tool, Quiet
hours with its **from** and **Until** steppers — an hour at a time, round the
clock, "from" lowercase as the reference renders it — Privacy, and **Restore
dismissed**, which now restores (`restoreAll`) and says so.

It also listened to nothing. The preference store is a `ChangeNotifier` behind
a plain provider, so a flipped switch stayed where it was and a second step
started from the hour the sheet opened on. It now listens to the store.

The account's own Notifications route (F5C) drew the same five sections
without the two stepper rows. **Resolved after F5D:** both doors now build
quiet hours from `lumeQuietHoursRows` over the one store, step through
`LumeNotificationPrefs.quietStepped`, and the account host listens to that
store, so a window stepped in the sheet is the window the route shows when the
sheet closes. The sheet's private stepper row is gone. **Evidence:**
`notification_overlays_test.dart`, `account_quiet_hours_test.dart` — wrapping
both ways, each door seeing the other's step, live steppers with quiet hours
off, per-button semantics, Urdu reading order, 200 %, and the "from" row
(59), its pill (125.19 × 32) and the pill's end measured against the
reference's route.

### C60 — Home's hero title collapsed in every capture (closed)

**Found in F5D, in the side-by-sides behind the sheets. Approved and
corrected after F5D.** The reference sets "Plan your day before it starts" in
two full lines 235.55 wide. Flutter drew **"Plan / your …"**:
`LumeBalancedText` narrows its box until the line count changes, and a `Text`
clamped to two lines with an ellipsis never reports a third, so the search
narrowed to the longest word.

**Corrected in `LumeBalancedText` itself**, so onboarding and authentication
keep the behaviour already proven there. A clamped paragraph's lines are
counted on an unclamped copy of the same text — balance first, clamp after,
which is the order CSS applies them in. Text that overflows its clamp even at
full width is left unbalanced, because a narrower box would change which
words the ellipsis leaves on screen. The string is unchanged; semantics carry
the whole title at every scale.

**Evidence.** The Home side-by-side at 390 × 844 now reads "Plan your day /
before it starts" on both sides. `lume_balanced_text_test.dart`: a clamped
heading balances exactly as an unclamped one; one that overflows its clamp
keeps the full width; Home's hero paints two 26.88-point lines; at 200 % the
full title is still announced. `destination_bounds_test.dart`,
`onboarding_bounds_test.dart` and the authentication suite are unchanged, so
nothing else on Home, onboarding or sign-in moved. Regenerated: the eight
Home goldens whose hero shows that title, and the cross-cutting cells drawn
over Home; the Muslim-state Homes, whose prayer title fits one line, are
byte-identical.

### C61 — weather that nobody had generated

**Found and corrected in the F5D closure audit.** Home, Explore and the
notification feed each carried their own weather table, and three of the
tables made weather up:

* Home's today and tomorrow were typed by hand for five of its six markets —
  the UK's tomorrow "overcast, 20° / 12°, 55 %", New York's today 26° / 17° —
  and Pakistan's tomorrow read a low of 25 where the reference renders 27.
  India's live row said "Hazy sun" where its own phrase begins "Humid".
  Every other market got an invented overcast climate with invented days.
* Explore gave every market outside six Germany's reading, and gave India,
  the UAE and Saudi Arabia a sunset at 18:30 that no calculation produced.
* The notification feed gave every market but Pakistan, London and New York
  Pakistan's tomorrow.

**Corrected by porting rather than transcribing.** `lume_reference_weather.dart`
is the reference's `WEATHER_BY_COUNTRY`, `WEATHER_BY_ZONE`, `weatherFor` and
`daily()` — its Park–Miller generator seeded by the country code — and all
three surfaces read it. The reference itself was run in Node to produce the
expected values, and `lume_reference_weather_test.dart` asserts all twenty
markets exactly. A market the reference does not define, or that this build
cannot derive, is `null` through the contract: no live row, no Explore card,
no forecast row. Nothing is drawn in its place, because the reference has no
such state. Sixteen condition phrases the tables had narrowed away are ARB keys
in all three languages.

**Classification and the full market-to-source map:**
`WEATHER_SOURCE_MAP.md`. **Dayroz obligation:** replace the port with the
weather adapter, keeping provenance, observation time and sunset in the same
nullable contracts.

### C62 — tool foundations that had never met a tool (F6A)

**Found in F6A**, the first time a real tool screen was measured
(`tool_tax_*` cells). The F2/F3 widgets had been measured against isolated
specimens, and on a composed screen seven of them disagreed with the reference.
All are corrected, and every one is held by `tax_bounds_test.dart`:

| widget | was | reference, measured |
|---|---|---|
| `LumeToolFrame` | freshness chip above the body, bare source line below, gutters around everything, toolbar that scrolled away | body sections, then a `.srcbar` card, privacy and related each in their own `.sect`; a sticky translucent toolbar that takes its hairline once content is under it |
| `LumeSummaryCard` | kicker 8 above the value, caption 8 below, no rule above the stats, no border on a gradient | 6 / 7 / 16 + hairline + 14; a transparent one-point border on gradients; `shadow-sm` on both |
| `LumeTable` | fixed 120-point columns, radius 16, no shadow, border painted over the rows | automatic-layout column widths, radius 20, `shadow-sm`, the border outside the rows |
| `LumeRelatedTools` | horizontal chips | 78-wide stacked tiles in a scrolling row |
| `LumeFreshness` | four qualities, live in `accent-700`, a 7-point dot | six qualities; live `--up`, delayed `--amber`, computed `--sky`; 6-point dot whose *shape* also carries the quality |
| `LumeSegmented` | segments as wide as their labels | segments share the track (`flex: 1`) |
| `LumeToolbar` / `LumeContextBar` | icon actions grew the bar to 67; strip 26 tall on a 16-point line; gutter fixed at 20 | icon targets overhang the padding (bar stays 62, D6); strip 22 on the font's 13; gutter follows the width class |

**Context-strip target — corrected after F6A review, an invisible
accessibility adaptation.** A pressable context-strip item is 18 tall in the
layout and the reference widens its target to 32 with negative margins. A
Flutter hit test does not reach outside the box it lands in, so at first the
touchable height was the 18. `LumeTargetRegion` (the tool body) now hands a tap
that lands on nothing to the nearest `LumeTargetSlop` whose widened box holds
it: the item's target is **44 tall** — 13 above and below, inside the 24-point
section gaps and clear of the tool bar — and 4 wider each side, half the
8-point gap, so neighbours never share a point. Geometry, paint and semantics
are unchanged (semantic rect 18); no golden moved. Beyond the reference's 32,
so this is an adaptation, not parity. **Evidence:** `lume_target_test.dart` —
taps 12 above and below open Personalise, 15 above does nothing, a fact in the
strip keeps its own tap, neighbours split the gap in both directions, Urdu at
200 %.

**Found on Learning (reference tool 2), corrected the same way:**

| widget | was | reference, measured |
|---|---|---|
| `LumeRows` | the card's hairline painted over its rows (two insights 121 tall); a divider indented 16 | the border outside the rows (123); the row's own full-width bottom edge |
| `LumeRichRow` | a 72-point minimum; title and subtitle on the type roles' 22 and 16; a 20-point glyph; one tile colour | no minimum (60 for title and subtitle); the font's 18 and 13, 1 apart, meta 3 below; a 17-point glyph; tile fill and ink separately (`--accent`) |
| `LumeProgressRing` | 76 points, a track in 10 % of the text colour, no text centre | 66 (92 large), ring radius 30 and stroke 7 on a 72 view box, track in 16 % of the ring's colour; `.pring__mid` |
| `LumeSummaryCard` | tabular figures in the value and the stats; no `<small>` | proportional figures, as the stylesheet sets none; `.summary__value small` at 17 / 700 / .6 on the baseline |

**Found on Timer (reference tool 3):**

| widget | was | reference, measured |
|---|---|---|
| `LumeButton` | a 20-point glyph beside the label (Start 99.6 wide) | `.btn svg` 17 (Start 96.63, Reset 101.42) |
| `LumeCompactRow` | a 20-point glyph | `.crow svg` 16 at 16 in from the card edge |

**Found on Emergency (reference tool 4):**

| widget | was | reference, measured |
|---|---|---|
| `LumeCompactRow` | the chevron 6 after the value | `.crow { gap: 12px }` puts it 12 after (value at 291.05) |

**Adaptation kept, not parity:** `button.crow` is 41 tall with its hairline,
and a pressable Flutter row stays 44 (`component_responsive_test.dart` "every
interactive component clears 44 px"). A stack of rows has no gap a widened
target could reach into, so the row grows instead: Emergency's three rows add
12 in total, and everything under them sits that much lower. The words inside
each row stay centred (within 2 of the reference), and `emergency_test.dart`
holds the note, source and related sections to the reference's own geometry
shifted by exactly that amount.
| `LumeNoteCard` | a 20-point glyph; title on the card-title role (20 tall); text on the 11-point role, 2 below | `.notecard svg` 17, 1 down; `b` 13 / 700 / −.024em (16 tall); `p` 12 on a 1.5 line (18), 3 below |
| `LumeGradient` | one approximate 150° alignment for every surface | `css(degrees, size)` lays `linear-gradient(<deg>)` as the browser does on a box of that size; `.sos` is 140° |

### C64 — a bar chart whose bars never grow

**Found in F6A on Learning; corrected, for ratification.** `shell.js`
`animateBars` writes `style.width = data-fill + '%'` to every `[data-fill]`
element. A progress bar wants exactly that; a `.bars__bar` is written with
`style="height:0"` and a `transition: height`, so its width changes and its
height never does, and every bar in every bar chart in the running reference
sits at its 3-point `min-height` — thirteen tools draw a row of flat stubs
(`tool_learning_default_pk_390x844_light_en` measures all seven at 3).

The intent is unambiguous in the source, so the chart is built as the
stylesheet is written, and the geometry was taken from the reference's own
engine rather than inferred: `measure_destinations.mjs --fixbars 1` applies
`height: data-fill%` in Chrome and measures the result
(`…_fixbars_…`). A bar is `fill %` of the 116-point figure, capped at the 97
its column has above the label, never under 3, never wider than 30.
`learning_test.dart` holds every bar's height and fill against that capture;
the as-rendered capture is committed beside it as the evidence.

### C65 — every week starts on Monday in the running reference

**Found in F6A on Learning; reproduced.** `locale.js` `weekStart()` reads
`new Intl.Locale(locale()).weekInfo.firstDay` and falls back to 1. The Chrome
the reference runs in exposes no `weekInfo` property (only the newer
`getWeekInfo()`), so the fallback always applies: Pakistan and the United
States, whose CLDR weeks start on Sunday, both draw Monday first. Node's ICU
would say otherwise — the browser is the oracle, so Flutter draws Monday
first everywhere (`LumeFormatting.weekdayNarrowFromMonday`). **Dayroz
obligation:** decide the product's week start per locale, and change this one
method.

### C66 — a running timer's button still says Start

**Found in F6A on Timer; reproduced, for ratification.** `clock.js`
`clockScreen` writes the primary action once, as `t('common.start')` with the
play icon, and `tool.screen.js` `runClock` toggles on it: pressing it while
the clock runs pauses. Nothing rewrites the label or the icon, so a running
countdown offers "Start" to stop it
(`tool_timer_default_pk_running_390x844_light_en` measures `00:57` beside
"Start" and "Reset"). Flutter reproduces the label and the behaviour
(`timer_test.dart` "start again pauses, on the same control"). **Product
decision:** a Pause label and icon while running, which `LumeTimerController`
already knows (`running`); the change is one conditional in `timer_tool.dart`.

The source line under a timer also reads "Live · On device · Updated 30 sec
ago" — a literal, not a clock; it is reproduced as written (C61's honesty rule
applies when Dayroz supplies a real source).

### C67 — Emergency: a toast that claims a copy, and numbers that go nowhere

**Found in F6A on Emergency; corrected, for ratification.**

- **"Location copied to share" copies nothing.** The reference's row is
  `data-act="toast:…"`: it shows the sentence and touches no clipboard.
  Production must not pretend (D7), so Flutter puts the reader's city and
  country — the words on the context strip, nothing finer — on the clipboard
  and says the sentence only after the copy returns. No coordinates, no
  permission, no share sheet.
- **A number is a `tel:` link, and nothing reports a failure.** In a browser
  without a handler the link silently does nothing. Flutter hands the number
  to `LumeDialer` (D6): the dialer opens with the number filled in and never
  calls; the number dialled, drawn and announced are one string
  (`LumeDialNumber` refuses anything but digits, spaces, hyphens and a leading
  `+`); an unavailable or failed dialer is said in a toast
  (`emergencyDialUnavailable`, `emergencyDialFailed` — new strings, the
  reference has none), an opened or dismissed one says nothing, as the
  reference says nothing. Each call is announced "Call {service} at {number}"
  with the number isolated left to right.
- **Service names are written in the reader's language.** `tool-data.js`
  keeps them in English in every language; they are keyed here (§11), proper
  nouns transliterated. The web `ur`/`ar` cells keep the profile's English, so
  only the English cell is compared word for word.

**Platform services task:** `url_launcher` is the one new dependency, used
only by `lume_dialer_platform.dart`; Android declares a `tel:` `VIEW` query
for `canLaunchUrl` and no permission. A device smoke test of the hand-off on
Android and iOS belongs to Dayroz integration — no test here opens a dialer.

**Dayroz obligations:** the directory is the prototype's reference data, not a
verified source; it needs an owned, dated directory per country, the
region-level numbers the catalogue's `reqCity` promises, and a review of each
number before release.

### C68 — Share and Export that tell the truth (D7)

**Found in F6A building the share-card system on Tax; corrected, for
ratification.**

- **"Shared" and "Image saved" whatever happened.** `share-cards.js` toasts
  "Shared" when `navigator.share` is missing, and "Image saved" when the
  canvas produced no image. Flutter says each only when the platform reports
  it: the share sheet's `success` is "Shared", `dismissed` says nothing,
  `unavailable` and a platform error say so (`shareUnavailable`,
  `shareFailed`). Export's "Saved {name}" is said only when the reader chose a
  destination; cancelled says nothing; a failure is "Couldn’t write the file".
- **Save image has nowhere honest to go yet.** Writing to the photo library
  needs Android's storage permission below API 30 and iOS's photo-library
  usage strings — a permission and user-data decision this phase does not
  take. The production `LumeImageSaver` answers `unavailable` and the sheet
  says "Saving images isn’t available yet — use Share to save it"; the
  platform share sheet offers its own save destination. **Platform services
  task:** decide the permission, then put a saver (the cached `gal` is the
  candidate) behind the same contract.
- **Export leaves through the share sheet.** A browser download has no phone
  equivalent a reader can find again; `LumePlatformExporter` hands the file
  (from memory, no temporary file of Lume's) to the share sheet, where Save to
  Files, Drive and mail are the destinations. Same file name, MIME type, BOM,
  CRLF and quoting as `exportTool` (`lume_share_export_test.dart`).
- **A tool with nothing to share gets the habits quote.** `openShare` falls
  back to `SHARE_CONTENT.quote` ("Small things done consistently…") for any
  tool `shareForTool` does not know, and for Tax in a market with no income
  tax. A card that says something unrelated to the screen is not honest
  content: Tax there shares "No personal income tax · Take-home: …" with its
  authority and year, and a tool that declares sharing but supplies no card
  gets a disabled Share, not an unrelated one.
- **Toasts over the sheet.** The reference's toast sits above the open sheet
  (z-index 70 over 55); the sheet's own toasts are drawn in the overlay above
  it, and the sheet stays open, as the reference's does.

**Privacy rule:** `LumeShareCard.forFeature` makes no card for a sensitive
tool, whatever the tool asks for.

**Dependency:** `share_plus` (cached 11.1.0), used only by
`lume_share_platform.dart`; no permission.

### C69 — Recipes: a chosen cuisine that looks unchosen, a field set in twice

**Found in F6A on Recipes.**

- **The chosen cuisine chip is unmarked — corrected, for ratification.**
  `recipes.tool.js` writes `class="chip is-on"`; the stylesheet styles a chosen
  chip as `.chip.is-active` (near-black fill), and `.chip.is-on` has no rule,
  so every cuisine chip draws the same white pill whichever is chosen, and
  none says `aria-pressed` (`tool_recipes_default_pk_cuisine-Pakistani_…`
  measures "Pakistani" in the unchosen fill). The intent is unambiguous —
  the module marks one chip as chosen — so Flutter draws it as `.is-active`
  and announces it selected (`recipes_test.dart`).
- **The search field sits a second gutter in — reproduced.** `.search { margin:
  0 var(--pad) }` is written for a full-bleed field; inside a section that
  already has its gutter it lands 40 in at 390 (157 at 700, 333 at 1100) and
  310 wide. Reproduced as rendered.
- **The favourites strip starts at the page edge on a phone — reproduced.**
  `.sect--flush` removes the section's gutter and `.hstrip`'s negative margin
  cancels its own, so the first card sits at x 0 at 390 and at the content
  column's edge above compact, exactly the measured `bleed` geometry.

**Found on Recipes (reference tool 5), corrected the way C62's were:**

| widget | was | reference, measured |
|---|---|---|
| `LumeSearchField` | a 20-point glyph | `.search svg` 17 (input at +26) |
| `LumeToolState` | a bare 24-point glyph, a solid outline, 4 between title and text, the 12-point role's 16 line | `.state__art` 46 tile (radius 16, card fill, hairline) with a 21-point glyph; `1px dashed border-2`; 10 between every part; text 12 on 18, at most 30ch |
| `LumeRichRow` | no illustration lead; chevron 6 after; meta on one line, truncated | `.rrow__thumb` 52 × 40, radius 12; chevron 12 after; `.rrow__meta` wraps, 5 apart both ways (two lines, 29 tall) |
| `LumeImageCard` | a 108-point gradient panel with its own shapes, the text under it on the card-title and caption roles, no card | `.imgcard`: 168 wide, bordered, radius 16, `shadow-sm`; 96-point `LumeArt` (`artimg`: `ART_TONES`, the seeded circles, `xMidYMid slice`); body `10 12 12`; kicker 10 / 700 / .04em, title 13 / 700 on 1.28, meta 10 / 500 |
| `LumeBadge` (`ok`) | accent at 14 % with accent-700 ink | `.badge--ok`: `--up` at 14 %, `--up` ink |
| two `LumeHorizontalStrip`s, and Timer's `LumeChipRow` | an unmeasured strip in `lume_table.dart` beside the measured one, and a third copy of `.chips` in the Timer tool | one strip (`lume_destination.dart`): `.chips` for Timer and Recipes, `bleed` with gap 11 for `.hstrip` |

### C70 — News: "Top" is everything, and a search is told about a category

**Found in F6A on News; reproduced.**

- **"Top" is not a category.** `news.tool.js` treats the chip as "all": with
  Top chosen every story shows, including those filed under Business or Sport;
  the one story filed under Top appears only there. Reproduced as written
  (`news_test.dart` "Top is every story").
- **A search that finds nothing is told "Nothing in this category yet".** The
  empty state has one sentence for both reasons a list can be empty
  (`tool_news_default_pk_q-zzz_…` measures it under Top). Reproduced; a
  product decision whether a search deserves its own sentence, as Recipes has.
- **Choosing a category can leave a lead and nothing else.** With one Business
  story in Pakistan's edition, Business shows that story as the lead and the
  empty sentence under Latest (`…cat-Business…`). Reproduced.
- **The chosen category chip is unmarked**, as C69 records for Recipes — the
  same `is-on` class. Corrected the same way.
- **Publishers are not translated.** Headlines and categories read in the
  reader's language; "Dawn", "Reuters" and the rest are the names they
  publish under, and stay as they are.
- **Share** shares the top story and its publisher and age, not the unrelated
  quote the reference falls back to (C68); with no top story, Share is
  disabled.

### C71 — Calendar: a planner that plans one month and sorts by text

**Found in F6A on Calendar.**

- **Month, Week and Day change nothing — reproduced.** `calendar.tool.js`
  stores the chosen view and nothing reads it: `monthGrid()` always draws the
  current month (`tool_calendar_default_pk_view-week_…` measures the same 30
  days under "Week"). Reproduced — the control is drawn and chosen, the grid
  stays; a real week and day view is a product decision, not a conversion.
- **No navigation, no events of the reader's own — reproduced.** The grid is
  this month only; the agenda is three fixed items; "Add an event" toasts
  "New event". There is no create, edit or delete to convert (§ record layer
  stays Expenses and Documents).
- **The agenda is sorted as text — corrected, for ratification.** With a
  Muslim reader the next prayer joins the agenda and the list is sorted by
  `a.time > b.time`, comparing the *formatted* times: "2:00 pm" < "6:27 pm" <
  "6:30 pm" < "9:00 am", so the morning standup comes last
  (`tool_calendar_muslim_pk_…`). The agenda's intent is chronological; Flutter
  sorts by the time itself, in any clock and any digits.
- **Hijri days count past the end of the month — corrected, for
  ratification.** Each cell's Hijri day is `today's Hijri day − (today −
  date)`, never turning over: 30 September reads "46". Flutter computes each
  day's own Hijri date (`LumeHijriDate`, the reference's arithmetic, taken at
  the civil day rather than the UTC instant), so the month turns over.
- **The floating action has no name — corrected.** `UI.fab` writes
  `aria-label` from `o.label`, and the measured button carries none; Flutter's
  is announced "Add an event".
- **Holidays are the first four in data order, in English — partly
  reproduced.** The order is the reference's (Iqbal Day in November before
  Kashmir Day in February); the names, kinds and dates are written in the
  reader's language.

**Found on Calendar (reference tool 7), corrected or built the way C62's were:**

| widget | was | reference, measured |
|---|---|---|
| `LumeTimeline` | a 46-point gutter; a 9-point node (12 when now) on a `--border-2` rail; the done node accent-filled; subtitles on the 11-point role's line | `.tline`: 52-point gutter, end-aligned, 1 down; a 16-point rail with a 14-point node 3 down and a 1.5-point `--border` line from 18 to the next node; done muted with a card glyph, now accent inside a 4-point tint ring, upcoming a card in `--border-2`; title 13 / 700, sub 11 / 500 2 below; 16 between items (49 each) |
| `LumeFab` | a 24-point glyph | `.fab svg` 19 (51 × 50 with 16 either side) |
| `LumeMonthGrid` (new) | — | `.mgrid`: 16 of padding, title 13 / 700 with 12 below, heads 10 / 700 on 12 + 4, square cells 4 apart (41.72 at 390), radius 12, today accent-filled; every day announced with its full date and today as selected, where the reference's buttons carry only the number |
| tool host | no place for a floating action | `floating` — 22 from the end and 96 from the bottom, under the toast (`z-index` 20 under 70) |

**Ports with obligations.** `LumeHijriDate` is the reference's Kuwaiti
arithmetic, and `LumeSolar` its prayer-time calculation with its `CITIES`
table; `lume_hijri_test.dart` and `lume_solar_test.dart` hold them to values
the reference itself produced for the fixture day (Islamabad Maghrib 18:27,
London 19:35). Both are labels, not religious determinations — Dayroz
supplies the authority, method and madhab the reader follows.

### C72 — Currency & Gold: a converter that does not convert

**Found in F6A on Currency & Gold.**

- **One market, fixture figures — reproduced.** `metals()` authors gold at
  88 dollars a gram and silver at 1.05, converts them at the reference's own
  rate table, prices every currency's buying rate at 0.996 of its selling
  rate and gives each change by its place in the list. The ounce is 2,740
  *dollars* whatever the reader's currency, and 22 carat is 24 × 0.916. All
  reproduced; `goldrates_fixtures.dart` carries the Dayroz obligation (a
  licensed, timestamped source with its delay stated).
- **"What is my gold worth?" never answers — corrected, for ratification.**
  The converter writes the worth of ten grams once and reads neither field
  again: type 25 and it still says Rs 249,040. Flutter prices the weight
  typed (24-carat gold per gram × grams), keeps the weight in the tool
  session, and shows "—" for anything that is not a number of grams rather
  than a guessed price. The worth field is read-only.
- **The share card is an unrelated quote — corrected (C68).** Flutter shares
  the price the screen leads with — "Gold 24k: Rs 290,480 / tola", with the
  market and the day.
- **The chart's labels stretch with the chart — corrected.** The line chart
  is an SVG with `preserveAspectRatio="none"`, so at 700 and 1100 its "30d",
  "15d" and "Today" are drawn 1.5 and 2.2 times as wide as they are tall.
  Flutter places them where the reference does and draws the text unstretched.
- **English in every language — translated.** `rates.*`, `ccy.*` and
  `unit.*` have no Urdu or Arabic in the reference, and the axis labels are
  literals; all are keyed and translated here, as D12 decided for interests.

**Found on Currency & Gold (reference tool 8), corrected or built the way C62's were:**

| widget | was | reference, measured |
|---|---|---|
| `LumeDelta` | a 9-point glyph; the text on the role's 16-point line, untracked; a double space drawn double | `.delta`: glyph 11 on a line of 1, 3 apart; 11 / 700 / −.01em tabular on 13; spaces collapsed (`nowrap`); inside a summary caption it takes the caption's 1.45 (15.95) and its ink; Home's markets row keeps its 16-point line, because Home's `.delta` is `screens/shared.css`'s, not the tool one |
| `LumeRichRow` | a 36-point logo tile in 12 / 500 `text-2`; the value on 22; nothing between value and change | `.rrow__logo` 38 × 38, 11 / 800 / −.02em capitals in `text`; `.rrow__value` on 18; `.rrow__end` 2 apart (33 with a change) |
| `LumeSummaryCard` | the unit on its own 19-point line; a caption only as text | `.summary__unit` on the value's 1.05 line (15.75); `captionDelta` for `caption: UI.delta(…)` |
| `LumeTable` | text cells only | a `cell` builder for a drawn change, and `cellWidth`, so the column wants the drawn width as `table-layout: auto` does (85.02 at 390) |
| `LumeToolField` affix | the role's 16-point line | `.field__affix` 11 / 700 / −.01em on 13 |
| `LumeFormatting` | "$" for every dollar; "JPY " for the yen; no signed figures | "US$" to a world-English reader (Pakistan, the United Kingdom), "$" where English follows the United States and in the UAE; "¥"; `signed` and `signedPercent` with U+2212 and exactly the places asked for |
| `LumeSparkline`, `LumeLineChart` (new) | — | `sparkline()`: 56 × 22 view box stretched to 54, 2 of padding, a 1.6 line over a 14 % area; `lineChart()`: 320 × 132, 6 above and 20 below, grid at 0, ½ and 1, a 12 % area, a 2-point round-joined line, a 3.2 dot stretched with the box, labels 11 / 600 on the baseline 4 up, caption 10 below |

**Ports with obligations.** `lumeWalk` is `tool-data.js` `walk()` over the
reference's seeded generator; `lume_reference_walk_test.dart` rebuilds the
dollar row's sparkline and the 30-day chart from it and matches the `d`
attributes the reference drew, to the tenth.

### C73 — Flights: a live board of five fixed flights

**Found in F6A on Flights.**

- **"Live" over fixture data — reproduced, with the host's own freshness.**
  The tool is titled "Live tracking", its board "Live board", its map "Live
  position", its source "ADS-B network · Updated 30 sec ago", and every
  figure is `FLIGHTS` from `tool-data.js`. The host shows each tool's
  catalogue freshness as the reference does (Currency & Gold's "Delayed 15
  min" is the same rule), so this is reproduced, not relabelled.
  `flights_fixtures.dart` carries the Dayroz obligation: a licensed
  flight-status feed with its observation time, and positions from a real
  ADS-B source, before the word "Live" is true.
- **The board does not filter by the reader's airport — reproduced.**
  `flights.tool.js` computes `home` from the city and never reads it.
  Arrivals lists all five flights, wherever they land; Departures lists every
  flight still in the air or yet to leave, wherever it leaves from; Tracked
  is the flights en route, because no reader has favourited the tool and the
  reference falls back to `tone2 === 'live'`. The same class of finding as
  C30, kept the same way: `LumeFlightsTool.board` is tested to return what
  the reference returns.
- **"Track this flight" keeps nothing — reproduced.** It toasts "Tracking
  EK 624"; Tracked does not change. Tracking is a notification
  subscription, which is Dayroz's to build.
- **Distances are written without grouping — reproduced.** `L.distance`
  rounds and concatenates, so the table reads "38,000 ft" two rows above
  "2038 km" (the same decision as C31's two notations).
- **A scheduled flight is "Cruising" now — reproduced.** The timeline marks
  cruising as now whenever `progress < 1`, so TK 710, which has not left,
  cruises at 0 ft and 0 km/h.
- **The empty board's action does nothing — corrected, for ratification.**
  "No flights on this board" offers Arrivals, which only sets the view; a
  search that emptied Arrivals stays empty. Flutter's Arrivals also clears
  the search it is offering the alternative to.
- **The map's pins are buttons that do nothing — corrected.** Each is a
  `<button>` with a name and no action. Flutter announces them by name
  inside the map and does not present them as controls.
- **The share card is an unrelated quote — corrected (C68).** Flutter shares
  the chosen flight: "EK 624 · DXB → ISB · ETA 08:22", with the airline and
  the day.
- **English in every language — translated.** `flights.*`, `unit.km`,
  `unit.mi`, `common.field` and `common.value` are keyed and translated (D12);
  airline, airport and aircraft names are proper names and stay as written.

**Found on Flights (reference tool 9), corrected or built the way C62's were:**

| widget | was | reference, measured |
|---|---|---|
| `LumeJourney` | three to four labelled steps on a dotted rail — no `.journey` of that shape exists | rebuilt as `.journey`: two 66-point ends (code 17 / 800 / −.04em on 22, place 10 / 600 on 12, time 12 / 700 tabular on 15; 55 tall) 12 either side of a 46-point track 8 down — a dashed 2-point line 9 down, the accent progress over it, a 20-point craft in a 4-point tint ring on the progress point, what is left 26 down; ends trade sides in RTL and the craft turns round; moved to `lume_journey.dart` |
| `LumeMap` (new) | — | `.lmap`: 220 tall as `--tall`, radius 20 in a one-point border, card-2 under two 12 % washes and a 34-point grid at half strength, a 1.6 dashed route (4 on, 3 off) at .8, 26-point pins placed by percentage inside the border, the active one accent in a 5-point ring, the caption pill 12 in and 10 up on a 14-point line (22) |
| `LumeMetric` | an 84-point minimum; the value on the role's line; label on 16; the icon muted with 8 below | `.metric`: no minimum (61 without an icon, the specimen's 84 with one); value 15 / 800 / −.036em on 19, label 10 / 600 on 12, 2 apart; icon 16 in the accent with 7 below |
| `LumeMetrics` | 8 between columns | `.metrics { gap: 10px }` — 110 + 10 + 110 |
| `LumeRichRow` | no selected state; `valueSub` on 16; the meta line always the font's 12 | `.rrow.is-selected` on `tint-accent`, announced selected; `.rrow__valuesub` 10 / 600 on 12; `metaLineHeight` for a meta line a fallback glyph sets taller — Flights' "→" makes it 14 (75-point rows) |

### C63 — English dates written the wrong way outside the United States

**Found in F6A** on the UAE Tax capture ("Mon, 7 Sep") and confirmed by
grouping what ICU renders for `en-XX` in every country. `LumeFormatting`
sent every English locale outside the US to world English; ICU writes 119 of
them the American way ("Mon, Sep 7", "6:27 PM") — Saudi Arabia, Japan and Turkey
among them — and the UAE alone as "Mon, 7 Sep". Corrected: the 119 read the
American data, and the UAE's short date is spelled out. Denmark, Finland and
Indonesia ("6.27 pm") and Canada and Ireland ("p.m.") remain as `intl` writes
them; no converted tool shows them yet.

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

**Nothing is open.** Q6 and Q9 were closed at F5C with no
implementation change; Q8 was superseded at F3. They are kept struck through
rather than deleted, because a decision that was taken is evidence and a
deleted row invites the same question again.

| # | Question | Blocks | Recommendation |
|---|---|---|---|
| ~~Q6~~ | ~~**Should Urdu be set in Nastaliq rather than Naskh?**~~ · **Closed at F5C.** Naskh. Lume ships Noto Naskh Arabic and nothing else, so Naskh is what the design asks for and what the conversion reproduces. Nastaliq is a **Dayroz product decision**, not a conversion one: the production app may bundle `NotoNastaliqUrdu-Medium.ttf` and change how Urdu is set, and that is a change to the product rather than a correction to this reference. No implementation changes. | — | **Closed** |
| ~~Q8~~ | ~~**The stepper's buttons are 44 tall but 32 wide.** Making them 44 wide would widen the pill from 64 to 96 and change the control's proportions. Accept the residual, or change the design? | F6, where steppers are actually used | **Accept**, and record it. The height is the axis a thumb misses on in a vertical list, and it is recovered. Changing the pill would be the conversion redesigning a control it was asked to reproduce — better raised against the reference~~ · **Superseded.** Rejected, and corrected properly in F3 — see D6 |
| ~~Q9~~ | ~~**A country row is 41 points tall — three under §9's own 44 px floor.**~~ · **Closed at F5C: approved as a screen-specific target exception.** The row is 350 points *wide* and full-bleed, and its neighbours are adjacent, so there is nowhere to overhang and no thin control to jab past — the miss §9's floor guards against is not the miss on offer. Reproduced at 41, and recorded rather than corrected. It is not the D35 case: there the drawn box was 35 × 30 inside a card with room around it, and separating the target cost nothing. | — | **Closed**, option (a). No implementation changes |

## 4. Change log

| Date | Change | Reason |
|---|---|---|
| 2026-09-13 (F5C-C) | **C41 decided: reproduce.** An option row's title and its description run together on one line, exactly as the prototype draws them | The rendered Lume interface wins; the Dayroz obligation is recorded rather than the defect silently repaired |
| 2026-09-13 (F5C-C) | **C44 decided: carry the engine's `SOURCES` as a fixture**, and the Notifications route finished — five sections, not two | The table is what the category filter and the By tool section both need, and neither is an engine |
| 2026-09-13 (F5C-C) | **All twenty-one routes measured against the prototype** — a web capture, a Flutter capture, a side-by-side and a structural comparison each, in `ACCOUNT_PARITY.md` | A settings section fails quietly; a route that renders an empty body throws nothing |
| 2026-09-13 (F5C-C) | **C42, C46, C47, C48 raised and corrected** — the option row's ring and padding, the toolbar's back control and its target, the toolbar's title line, and the account form's own field shape | Found by adding the account routes to the measured-bounds comparison |
| 2026-09-13 (F5C-C) | **C41, C43, C44 raised and left open** — the option row's run-together description, the accumulation under a form, and the Notifications screen's second filter | The visual-authority rule reserves a visible departure from Lume for a decision, and these three are not ours to take |
| 2026-09-13 (F5C-B/C) | **Profile and the twenty-one account routes implemented** — one composition in four identity states, a per-route gate, and no placeholder among them | Profile was the last destination still rendering the F3 fixture, and a functional row must not point at a generic screen |
| 2026-09-13 (F5C-B/C) | **D40 and D41 recorded** — the version line names this build, and the Personalisation sheet is two editors | A version is a claim about which code is running; six of the sheet's seven controls are now routes |
| 2026-09-13 (F5C-D) | **C49–C51 raised and corrected; C46's parity claim withdrawn and re-earned** — five strings telling a phone user about their browser, the toolbar's missing transparent hairline and its subtitle's token line, and a report row wearing another finding's explanation | The generated table said Δ 1.00 on `toolbar` for all twenty-one routes while the prose beside it said `=`; exact values went from 249 of 372 to 316 |
| 2026-09-13 (F5C-D) | **Three Urdu plurals and two account strings corrected** — "1 ٹرینیں" for one train, and "3 signed in" on an Urdu Security route | The suite checked that the file was translated and never that a message counted; five new parity tests |
| 2026-09-13 (F5C-B/C) | **C34 raised and corrected** — the notification count and the notification list are the same faith-gated question, asked once | The reference counts eleven and shows ten to a non-Muslim reader |
| 2026-09-13 (F5C-B/C) | **C35–C40 raised and corrected** — the settings row's padding, icon and two gaps; a promised "Not set" that never rendered; the end's conditional gap; a tag that filled its width; a badge three points too tall; and the identity card's gap between blocks rather than lines | Found by adding Profile to the measured-bounds comparison in all three identity states, and then measuring each row's *parts* |
| 2026-09-13 (F5C) | **D38 and D39 recorded — the swap swaps and the day chips choose a day** | Two approved functional corrections; the reference ships a toast with no effect and three buttons with no handler |
| 2026-09-13 (F5C) | **C30 and C31 raised; decision taken: reproduce.** The departures heading names an origin the roster is not filtered by; two currency notations sit five rows apart | Both are captions written against unfiltered data; both carry a Dayroz obligation rather than a silent repair |
| 2026-09-13 (F5C) | **C32 and C33 raised; C33 corrected** — the search foot's items overflow rather than shrink, and the Search button had lost `.btn`'s tracking | A row of `Flexible` chips ellipsised "Tomorrow" at a width with 16 points to spare; the button had never been measured |
| 2026-09-13 (F5C) | **Q6 closed — Naskh.** Lume ships Noto Naskh Arabic and the conversion reproduces what Lume ships; Nastaliq is a Dayroz product decision | The conversion does not bundle a face the design has not asked for |
| 2026-09-13 (F5C) | **Q9 closed — the 41-point country row is an approved screen-specific target exception** | Full-bleed and 350 wide, with adjacent neighbours and nowhere to overhang; unlike D35 there is no spare room to separate the target into |
| 2026-09-13 (F5B · closure) | **D35 completed and reclassified** — a card action is drawn at 35 × 30 and touched at 44 × 44, with nothing visible moved | An exception was accepted where D6's remedy applies; `LumeGhostButton` removed and `LumeCardAction` put in its place |
| 2026-09-13 (F5B · closure) | **D36 approved and closed** — the ring label fits inside the arc at accessibility scales and is drawn at its measured size at the reference's | The four conditions are asserted, including an accessible value built from the data rather than the render |
| 2026-09-13 (F5B · closure) | **D37 withdrawn** — it was a corrected implementation defect, not a difference, and is written out in full under C27 | A number was assigned before the finding was understood; a corrected defect must not sit on a difference list |
| 2026-09-13 (F5B · closure) | **C24 given a real shape** — "updated 4 min ago" is computed from a pinned observation timestamp against the injected clock, not carried as the number 4 | Dayroz supplies a real observation time and the sentence follows it with no change to the widget |
| 2026-09-13 (F5B · closure) | **C22 given a section-level unavailable state** — Nearby is a source that can fail, and says so rather than naming a city the reader is not in | The reproduction stays; the shape Dayroz needs is now in place |
| 2026-09-13 (F5B) | **Today and Explore implemented** — eight sections each, in the order their sources emit them, against re-read source and re-measured bounds | The F5A inventory summary had Today's order wrong; the contract was rebuilt from `today.screen.js` |
| 2026-09-13 (F5B) | **C22 raised; decision taken: reproduce.** Nearby's three Karachi venues render in every market | Traced, classified as a data-accuracy failure, and put to a decision rather than settled |
| 2026-09-13 (F5B) | **C24 raised; decision taken: reproduce.** "updated 4 min ago" is a literal and stays one | The only dishonest value on a card whose other five are per-city |
| 2026-09-13 (F5B) | **C23 raised; decision taken: reproduce.** The ring sentence and the tasks statistic are the reference's literals, not the list's counts | An earlier F5B implementation derived them. That was a correction, not a reproduction, and it was never approved |
| 2026-09-13 (F5B) | **C25 raised and corrected** — the ayah's two citation forms are composed from surah, chapter and verse | The side-by-side showed the section subtitle had lost its separator |
| 2026-09-13 (F5B) | **C29 raised and corrected** — the ring card's sparkle is drawn | The artwork had been extracted and never placed |
| 2026-09-13 (F5B) | **C26, C27, C28 and D37 raised and corrected** — a card's border takes layout room, a page head's subtitle takes the font's line, a 20-point line is 25, and the recents strip keeps its two points | Found by adding Today and Explore to the measured-bounds comparison; two of them had been cancelling each other out inside the one-point tolerance |
| 2026-09-13 (F5B) | **D34, D35, D36 recorded** — Explore's conditional way back, the ghost action's 30-point box, and the ring label that shrinks rather than spilling | One reproduction, one recorded target exception, one overflow exception |
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

### D34 — Explore carries its own way back where it is not a tab

**New in F5B.** `explore.screen.js` keeps a hidden back button in the page head
and its router *"shows it only when no tab is selected"*, because Explore is
reachable in Pakistan without being one of that market's five tabs.

Flutter reproduces the rule rather than the mechanism: the host asks
`LumeDestinations.orderFor(country)` whether Explore is presented, and passes
an `onBack` only when it is not. `LumePageHead` gained a `leading` slot for
this one case; every other destination leaves it `null` and the head is the
two-part row it has always been.

### D35 — a card action's target is 44 × 44 and its drawing is not

**New in F5B; completed in the F5B closure pass. An invisible-target
adaptation, not an accessibility exception.**

`.ghostbtn` is 35 × 30 — under §9's 44-point floor on *both* axes, like
`.cnotice__act` and `.stepper__btn` before it (D6) — and it sits in a card foot
that is exactly its own height. The first F5B implementation left the target at
the drawn size and recorded an exception, because the obvious repair (asking
`LumePressable` for its 44-point floor) made every card carrying one fourteen
points taller and pushed every section below it down the page.

That was the wrong trade, and it has been replaced with D6's own remedy:
**separate the painted box from the target.**

| | drawn | target |
|---|---|---|
| `.ghostbtn` in Lume | 35 × 30 | 35 × 30 |
| Flutter, before | 35 × 30 | 35 × 30 |
| Flutter, now | **35 × 30, unchanged** | **44 × 44** |

The foot's row holds a 35 × 30 spacer per action, so the row is still 30 tall
and `.quote` is still 350 × 193.5. The glyph is drawn inside a 44 × 44
`LumePressable` in the card's own stack, laid exactly over that spacer and
extended **outward, away from its neighbour** — nine points into the card's
18-point padding on the trailing side, nine into the empty run before the
actions on the leading side:

```text
 ← leading                                        trailing →
       ┌─────────────────┐     ┌─────────────────┐
       │  ╭───────────╮  │     │  ╭───────────╮  │
       │  │ box 35×30 │ 9│  4  │ 9│ box 35×30 │  │
       │  ╰───────────╯  │     │  ╰───────────╯  │
       └─────────────────┘     └─────────────────┘
          target 1: 44            target 0: 44    ↑ 18 of card padding
```

**Why the targets are asymmetric.** The pitch between the two controls is 39 —
35 of box and 4 of gap — so two 44-point targets *centred* on their glyphs
would overlap by five points and a thumb aimed at Share would sometimes
bookmark. Pushing each one's spare nine points outward gives two targets that
touch at the four-point gap and never cross it. It is also why a third action
is refused by an assertion rather than silently given an overlapping target.

**What did not change.** The card's height, the glyph positions, the pitch, the
attribution's baseline, the divider, the quote mark. The Today goldens moved by
0.003 % of their pixels — anti-aliasing on the glyph edges — with no pixel
beyond the rasterisation tolerance, and the side-by-side against the prototype
scores identically before and after (35.121 %).

**What it costs.** `LumeGhostButton` is gone: it was a control whose drawn box
*was* its target, which is the shape this replaces. `LumeQuoteCard.actions`
takes `LumeCardAction` data rather than finished widgets, because the card has
to place the painted half and the interactive half in two different parts of
its tree.

Nineteen assertions in `test/core/widgets/card_action_target_test.dart`: the
drawn size, the target size, the card's height, the 39-point pitch, no overlap,
nothing outside the card, a tap at each of the four edges, taps just outside,
the run between them, the attribution beside them, one semantics node per
action, selected state, Tab, Enter, Space, a focus ring that moves nothing,
right-to-left, 200 % text, and a phone lying down.

### D36 — the day ring's label shrinks rather than spilling over the arc

**New in F5B. Approved and closed in the F5B closure pass.** The ring is a fixed 82-point circle and what is written inside
it cannot grow with the reader's text size: at 200 % the two lines are half
again as tall as the arc is wide, and the flex overflowed by 46 points.

The label now scales down to fit the arc's clear interior
(`LumeDayMetrics.ringInner`). **At every scale the reference is rendered at,
nothing is scaled at all** — a test asserts the label's own box still fits
inside that interior at 1.0 and 1.3, so the figure is drawn at its measured
size and the fallback only engages past the sizes the design covers. This is
the overflow exception the visual-authority rule allows, not a redesign.

**Approved, with the four conditions met.** At the reference's text scales the
label is drawn at its measured size and placement; at accessibility scales it
is fitted inside the ring rather than clipped; the ring itself is never resized
to accommodate text, so the arc is the reference's 82 points at every scale;
and the accessible value is built from the data rather than from the render, so
a screen reader reads "70% of day" in full whether or not the painted label
was scaled. Asserted in `today_explore_states_test.dart` at 1.0, 1.3 and 2.0.
**Closed.**

### D38 — the swap swaps

**New in F5C. An approved functional correction to a prototype defect (R2).**
`.railsearch__swap` in the reference toasts "Stations swapped" and swaps
nothing: the two fields hold their values, the query keeps its ends, and the
departures list does not move. The sentence is true of nothing that happened.

Flutter exchanges the two ends atomically — one `LumeJourneyQuery.swapped()`
builds the next query from the current one, so there is no moment where a
field has been written and its partner has not — asks the repository for the
new query, and writes the result. The announcement is built from the snapshot
that came back rather than from the query that was sent, so the sentence a
reader hears describes what is on screen.

The order matters more than it looks. Nothing visible is written until an
answer arrives, which makes **rollback the absence of a write**: a refused or
failed swap leaves the fields reading the snapshot that is still there, with
no second write to undo and no window in which the screen contradicts itself.
A swap that produces a route that is not a journey — one end missing, or the
same station twice — is refused before the repository is asked, and the
refusal is drawn on the departures section rather than over the page.

While a query is outstanding every control that would start another one is
inert, so a second tap is not a second request, and each request carries a
number: a late answer to a superseded question is dropped rather than painted.

Nothing about the geometry changed. The control is the reference's 34-point
circle in the reference's position, and `railswap` reads delta `=` on both
axes.

**Evidence.** `trains_query_test.dart` — exchange, double-swap restore,
same-station refusal, missing end, the busy state, failure and rollback,
keyboard activation, the screen-reader announcement's ordering, LTR and RTL,
state restoration, and a count proving no duplicate repository call.
Golden: `trains_swapped_390x844_light_en.png`.

### D39 — the day chips choose a day

**New in F5C. An approved functional correction to a prototype defect (R3).**
The reference's three `.railchip`s are `<button>`s with no handler. "Today" is
marked `.is-active` in the markup and stays marked; "Tomorrow" and the
calendar chip do nothing at all. Lume ships three controls that cannot be
operated.

Flutter makes them a single selection. Exactly one chip is selected at a time,
the chosen day is resolved to a real date against the **injected clock** — so a
screen left open past midnight answers for the new day, not the one it was
opened on — and the date travels to the repository as part of the query rather
than being displayed and discarded. The calendar chip opens the platform date
picker, which is P2 furniture: the reference's chip is labelled "Pick a date"
and has nothing behind it.

The results section carries its own loading, empty and failed states, so a day
with no service says so where the list is, and the rest of the screen — the
tracked service, the popular routes — is not disturbed by a question about
departures.

**The fixtures are honest about what they are.** One timetable answers every
selectable day, because the prototype ships one; what is real and explicit is
the *date identity* — each query carries the resolved `serviceDate`, the
repository receives it, and `LumeFakeTrainsRepository.emptyOn` can declare a
day with no service. No fixture claims to be live data, and C30 records that
the roster is not filtered.

**Evidence.** `trains_query_test.dart` — the initial day, each chip
selectable, only one selected, the date the repository receives, an empty day,
a failed day, rapid switching with stale-response protection, midnight
rollover across an injected clock, LTR and RTL, the `selected` semantics flag,
keyboard focus, and restoration. Golden:
`trains_tomorrow_390x844_light_en.png`; the refusal state is
`trains_invalid_390x844_light_en.png`.

### D40 — the version line names this build

**New in F5C.** Profile's foot and the About route both print a version. The
reference prints `4.1.0`, which is the web prototype's; Flutter prints the
package's own, read from `pubspec.yaml` and pinned by `build_version_test`.

A version number is a claim about which code the reader is running. Carrying
the prototype's across would be the one kind of statistic §125 forbids — a
figure that looks verified and is not — and would make a bug report name a
build that does not exist. The captures differ from the prototype by that
string, on purpose.

### D41 — the Personalisation sheet is two editors, not one

**New in F5C.** `sheet:personalise` is one tall sheet holding location,
language, units, currency, time, interests and the content switches. Six of
those seven now have a route of their own in the account section — the sheet
and the routes were always two ways to the same preference — and a second
language picker would be a second answer to the same question.

So the sheet is split at the two places that actually open it:

| entry point | opens |
|---|---|
| Profile's Interests row | the interests picker |
| the Region route's Change control | country, then the cities in it |

Both reuse onboarding's own views rather than copying them, both write through
the one profile store, and neither is a route: the reference opens a sheet
from both places, and a sheet has no address. The content switches stay where
the reference also keeps them, on the Privacy route.

### ~~D37~~ — withdrawn. Recorded as part of C27.

**Raised and withdrawn inside F5B.** D37 was given a number before it was
understood; it is not a difference at all, and a corrected defect must not be
left on a difference list. It is written out in full here because the F5B
report referenced the number without ever saying what it was.

**Not to be confused with C28**, which is the other measurement finding of the
same pass: `LumeType.naturalLine` carried `20 => 26` where two independent
measurements on Today — `.ring__value` and `.stat__value`, both 20/800 with
`line-height: normal` — render **25**. Flutter now uses the measured 25. That
too is restored parity, recorded in §2 as a correction, and it is not on any
difference list either.

| | |
|---|---|
| **What Lume renders** | `.hscroll { padding: 2px 20px 6px }` — the Tools hub's "Recently used" scroller carries two points of clearance above its cards and six below, so a pressed card's shadow has somewhere to go. Measured on `tools_named_pk`: `chips` ends at 203, `recent.wrap` starts at 227, and the first tile sits at **281**. |
| **What Flutter rendered** | The recents call site passed `EdgeInsets.only(bottom: 6)` instead of the metric, dropping the two points above. The first tile sat at **279**. |
| **The numeric difference** | Exactly **2.00 points**, on every element from the recents strip to the bottom of the page: `recent` 251 against 253, `cat` 327 against 329, `cat.title` 327 against 329, `cat.sub` 347 against 349, `cattool` 372 against 374. |
| **Source rule** | `.hscroll` in `assets/css/components.css`. |
| **Flutter widget** | `LumeHorizontalStrip.padding`, whose default is `LumeDestinationMetrics.stripPadding` = `EdgeInsets.fromLTRB(0, 2, 0, 6)` — the rule, already written down. The hub's recents section overrode it by hand. |
| **Why it differed** | A hand-written inset at one call site where a named metric existed. Nothing about Flutter, nothing about the design. |
| **Why it went unseen** | It was cancelling C27. `LumePageHead`'s subtitle was one point too tall, which pushed everything below the head one point *down*; the strip pulled everything below it two points *up*. Each element therefore landed within the one-point tolerance and the bounds comparison passed. Fixing the head alone exposed it — which is the argument for a tolerance tight enough that two errors cannot hide inside it. |
| **Classification** | **Exact parity, restored.** Not rounding, not an adaptation, not unresolved: an implementation defect, corrected. |
| **Affected** | The Tools hub only. It is the product's one recents strip; Home's Discover strip and the quick-action strip use the other two constructors and were always correct. |
| **Evidence** | `destination_bounds_test.dart`, "Tools · a user with a history": `recent`, `cat`, `cat.title`, `cat.sub` and `cattool` all read Δ `=` in `DESTINATION_PARITY.md`. The fifteen Tools goldens were regenerated and the side-by-side re-read. |

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
