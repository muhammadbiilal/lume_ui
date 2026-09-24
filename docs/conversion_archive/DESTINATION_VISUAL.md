# Home, the Tools hub, Today and Explore — the visual comparison

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.
> The product-facing description of what Flutter does is
> `docs/LUME_DESTINATIONS.md`.

> **Scope note (2026-09-24).** This document's title and §1's value count
> (191) predate Profile and Trains being added to
> [DESTINATION_PARITY.md](DESTINATION_PARITY.md), which now covers all five
> destinations at 483 measured values. Trains stays out of scope for this
> note; Profile is covered in §6 below, added as part of a Wave 5
> visual-parity re-audit ([WAVE_5_DISCOVERY.md](WAVE_5_DISCOVERY.md) §3)
> rather than a full rewrite of this document.

The protocol is the one in [VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md):
the viewport is set through the DevTools Protocol, `window.innerWidth` is
asserted afterwards, both sides run with reduced motion forced and the same
pinned clock, and both render at a device pixel ratio of 1 so a logical pixel
is an image pixel.

---

## 1. What was captured

**Reference.** `docs/conversion_archive/tool/measure_destinations.mjs` writes a
whole profile to `lume-profile`, **freezes the page's clock** at the fixture
instant, drives the shell to a destination and writes the bounds, the
composition and the frame:

```bash
node docs/conversion_archive/tool/measure_destinations.mjs \
  --screen home --state muslim_pk --shot 1
node docs/conversion_archive/tool/measure_destinations.mjs \
  --screen tools --state default_pk --after tools_search --shot 1
node docs/conversion_archive/tool/measure_destinations.mjs \
  --screen today --state muslim_pk --shot 1
node docs/conversion_archive/tool/measure_destinations.mjs \
  --screen explore --state muslim_gb --shot 1
```

Freezing the clock is not a nicety. Home reads `new Date()` in a dozen places —
the greeting, the live row, the outage, the market session — so without it Home
is a different screen at breakfast and at midnight and there is nothing to
compare. The first run of this tool was taken after midnight and reported
"Tomorrow in Islamabad" and no market card at all.

**The composition is captured as data, not only as an image.** Which slides the
carousel kept and in what order, which eight tools filled the grid, which live
cards survived, which categories rendered and how many tools each holds. Those
are the part of Home and the hub that is easiest to get subtly wrong and
impossible to see in a screenshot.

**Flutter.** `test/goldens/destination_golden_test.dart` writes a
`.flutter.png` beside each `.web.png`, from the same user and the same
geometry, and pins each as a golden.

| artefact | where |
|---|---|
| reference frames | `shots/destinations/<screen>_<state>/*.web.png` |
| Flutter frames | `shots/destinations/<screen>_<state>/*.flutter.png` |
| side by side | `shots/destinations/<screen>_<state>/*.side.png` |
| per-pixel diff | `shots/destinations/<screen>_<state>/*.diff.png` |
| element bounds | [DESTINATION_PARITY.md](DESTINATION_PARITY.md) — **191 values** |
| the composition | `measurements/{home,tools}_*.json` |
| committed goldens | `test/goldens/images/{home,tools}_*.png` — **37** |

---

## 2. The cells

Primary: **390 × 844, English, light**, for Home in seven user states, the
hub in six, and Today and Explore in five each.

| cell | what it proves |
|---|---|
| 359 × 844 | the narrowest phone: two columns rather than three or four |
| 360 × 800 | the first width that does not trigger them |
| 390 × 844 | the primary composition |
| 700 × 900 | medium — capped at the measure and centred |
| 1100 × 900 | expanded — five columns, the same measure |
| 852 × 393 | a phone held sideways: compact presentation, capped content |
| 390 × 844 dark | authored, not inverted |
| 390 × 844 Urdu | RTL, real translations |
| 390 × 844 Arabic | RTL, real translations |
| 200 % text | the hero grows; nothing clips or overflows |

Home's state variants: not Muslim in Pakistan, Muslim in Pakistan, Muslim in
the United Kingdom, not Muslim in the United States, a user with a name and a
history, a user with the content switches off, still loading, one section
failed, offline, nothing loaded at all, a user with nothing recorded, and the
market open rather than shut.

The hub's: the shortlist, everything, the Islamic experience on, the United
Kingdom, a search with results, a search with none, and a shortlist with
nothing in it.

Today's and Explore's: Muslim in Pakistan, not Muslim in Pakistan, Muslim in
the United Kingdom, not Muslim in the United States, and the content switches
off — plus still loading and nothing loaded at all for both, one source failed
for Explore, and two scrolled cells each so the sections below 844 points are
pinned as pixels rather than only as `find.text`.

---

## 3. Why the per-pixel diff reads high

| state | beyond tolerance | rasterisation |
|---|---|---|
| home · Muslim, Pakistan | 53.2 % | 17.6 % |
| home · not Muslim, Pakistan | 50.8 % | 18.9 % |
| tools · a user with a history | 39.5 % | 10.6 % |
| today · Muslim, Pakistan | 35.1 % | 20.9 % |
| today · not Muslim, Pakistan | 39.2 % | 16.6 % |
| explore · Muslim, Pakistan | 43.5 % | 20.3 % |
| explore · Muslim, United Kingdom | 46.5 % | 20.1 % |

**These numbers are the two capture-level differences, not a layout mismatch.**
The prototype draws a 28-point simulated status bar above its screen (P1), so
every element is 28 points lower on the reference side and a per-pixel
comparison lights up every glyph in the column. The prototype's shell also
paints a blurred three-colour mesh behind the page; the Flutter shell paints it
too, but these captures are of the *screen*, which is what the comparison is
about.

A pixel diff cannot see past a uniform offset; a bounds comparison can. That is
why the parity evidence is [DESTINATION_PARITY.md](DESTINATION_PARITY.md) —
element positions measured from each side's own screen origin — and the diff
images are a second opinion rather than the verdict.

The side-by-side images are the ones to look at, and they were: Home at the
primary cell in both faith states, Home in Arabic, Home in dark, Home at 200
per cent, Home at 852 × 393, the hub at the primary cell, the hub at 1100, and
**all ten Today and Explore cells**. Four differences came out of that reading
and out of nothing else — see §4.

---

## 4. What the comparison caught

Found by looking at the renders, not by a passing test:

| found | fix |
|---|---|
| every line of text underlined in yellow | the page had no `Material` at its root, so `Text` fell back to the debug style — F4C's lesson, in a second place |
| the carousel's dots drawn as four tall bars | a 44-point tap target sized the dot instead of containing it |
| "Mon, 9/7" where the prototype says "Mon, 7 Sept" | `DateFormat.MEd` is the *numeric* skeleton; the design asks for a month name, which is `MMMEd` |
| "6:27PM" with no space | CLDR puts a narrow no-break space before the marker and Plus Jakarta Sans has no glyph for it |
| the Prayer Times tile naming a prayer that had passed while the strip above it named the next one | the status line is the catalogue's until the device can answer; one resolver now serves both |
| every heading one to five points too tall, compounding to 44 by the bottom of the page | most of the prototype's small text sets a size and leaves `line-height: normal`, which is the *font's* line — 12 on 15 and 11 on 13, which no single ratio produces |
| the hero 14 points too tall and 14 too high | `.hero`'s margin is the page's gap, not the carousel's own box |
| "Coming up" twelve points too tall | `.crow__label i` is a block, so the subtitle sits *under* the label — and on its own natural line |
| a catalogue tile's label at the top of a stretched tile | `margin-top: auto` pushes the label and its status to the bottom when a neighbour wraps to two lines |
| the row of tiles clipped by 18 points | `GridView` gives every cell one aspect ratio; a CSS grid gives every *row* its own height |
| the hero slide overflowing by 18 at one width and 2 in Urdu | the title takes two lines at most, and a script set on a 1.6 line needs a taller slide rather than a clipped one |
| a card pushed off the screen at 200 % text | the market pill and the figure at the end of a row could not shrink |
| the hub's empty state drawn as a record collection's — a 19-point title, a 28-point glyph, no illustration | `.empty` is its own component: a 15-point title, a 12-point body on an 18 line, and an 88 × 66 dashed magnifier |
| "Mon, Sep 7" and "6:27 PM" where the prototype writes "Mon, 7 Sept" and "6:27 pm" | `intl` has no `en_PK` and falls back to `en`, which *is* American English; CLDR inherits world English everywhere outside the United States (D31) |
| a Discover strip of 140-point cards around one 156 | `.hscroll` is a stretch flex, and a `Row` centres — one two-line card has to raise every card beside it |
| the strips at the window's edge rather than the content column's, at 700 and 1100 | a strip supplies its own gutters, so it sits outside `LumeMeasure` — and was never given the cap every other section has |
| the notification badge covering the bell at 200 % | past four points of overhang a pill stops being a badge; the count falls back to the reference's dot and stays in the accessible name |
| the badge reading 13 in London where the prototype reads 10 | the badge counts the notification sources that survive a profile, so it is 13 in Pakistan, 12 with the switches off and 10 abroad — fixture data, not one number |
| "34° and hazy sun" on the Discover card where the prototype says "34° and hazy" | the whole card is a literal — temperature included, in every market — so the fixture carries its three display values rather than reading the weather (C21) |
| a "local service" dot on seven tiles the prototype leaves bare | the prototype's pin branch reads a field the catalogue does not carry, and drawing one anyway was not a correctness repair (D28) |
| the ayah's section subtitle reading "Ar-Ra’d 13:28" where the prototype writes "Ar-Ra’d · 13:28" | the reference cites the same verse twice and differently; one finished string can only be right in one of the two places, so the surah, the chapter and the verse are carried separately (C25) |
| no sparkle on Today's ring card | `today.screen.js` hangs a 46-point sticker off its top corner; the artwork had been extracted and never placed (C29) |
| "2 of 4 tasks done" where the prototype says "2 of 5" | the ring sentence and the tasks statistic are the reference's literals and do not follow the list. Deriving them was a correction, not a reproduction (C23) |
| the quote card 13.5 points too tall, and every section below it pushed down | a ghost action was laid out at 44 because the shared pressable enforces §9's floor; `.ghostbtn` is 30, and the attribution's own 11-point margin was missing. The control is now drawn at 35 × 30 and touched at 44 × 44 (D35) |
| a list card two points short, and every section below it two points high | `LumeCard` painted its border without reserving room for it (C26) |
| every page head one point too tall, and every section below the hub's chips two points too high | `.page-head__sub` has no line height, so the line is the font's; the hub's recents strip had dropped `.hscroll`'s two points of top padding. Each was inside the one-point tolerance while the other was there (C27) |
| the day ring overflowing by 46 points at 200 % text | a fixed circle cannot hold a label that grows; it scales down inside the arc instead, and not at all at the sizes the reference is drawn at (D36) |
| no way back out of Explore in Pakistan, where it is not a tab | the reference keeps a back control in the head and shows it when no tab is selected (D34) |

---

## 5. The remaining discrepancy list

Everything below is deliberate and recorded in
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

Sorted by what kind of difference each one is, because they are not the same
kind of thing and reading them as one list was how an unapproved redesign got
past a review.

**Exact parity, with a capture artefact**

| # | difference | size |
|---|---|---|
| P1 | the simulated status bar is not drawn | 28 points of vertical offset on every screen |
| P2 | the test environment has no emoji face, so the greeting's `👋` renders as a box in a *capture* | **none at runtime** — verified on a Pixel 6 Pro, Android 16, running the packaged application |
| D20 | a line box's fractional height is rounded to whole logical pixels | under a fifth of a point per heading, about three by the bottom of Home |

**Approved native adaptation**

| # | difference | size |
|---|---|---|
| D34 | Explore carries its own way back where it is not a tab | the reference keeps the same control and shows it on the same condition; Flutter asks the destination registry rather than the router |
| D22 | the tile status line is translated | the prototype renders it in English in all three languages |
| D23 | the Discover strip is 15.75 points taller | the outage card names a real time in the user's own clock; "Next outage 7:00 pm" is 127.93 wide in a 124-point region, so it takes two lines, and `.hscroll` stretches every card with it (C17) |
| D31 | dates and clocks are world English | `intl` has no `en_PK`; this restores what the prototype renders |
| D32 | a 12-hour clock is 12-hour in every locale | `DateFormat.jm` carried `en_GB`'s own hour cycle |

**Correctness, privacy or accessibility repair**

An *invisible-target* repair changes what can be touched and nothing that can
be seen: the drawn control keeps the reference's coordinates to the point, and
the goldens move only where anti-aliasing does.

| # | difference | size |
|---|---|---|
| D35 | a card action is touched across 44 × 44 | the prototype's `.ghostbtn` is 35 × 30 on both axes, under §9's floor. **Nothing drawn moved**: the card is still 350 × 193.5 and the goldens moved by 0.003 % of their pixels, none beyond the rasterisation tolerance |
| D36 | the day ring's label fits inside the arc at accessibility text scales | the prototype's flex overflows by 46 points at 200 %. At the scales the reference is drawn at, nothing is scaled at all |
| D25 | a live card is 350 wide | the prototype's is 372.31 and overflows its column by 22.31, and the screen by 2.31 (C20) |
| D27 | the notification badge is a pill with a number in it | the prototype's is a 7-point dot whose digits render outside it, across the bell (C16) |
| D28 | the "local service" marker is drawn | the prototype's branch tests a field the catalogue does not carry, and the pin renders nowhere (C13) |
| D29 | the market's session is correct | four defects, listed in `docs/LUME_DESTINATIONS.md` §5 (C11) |
| D30 | every entry surface asks the same eligibility question | the prototype gates Discover by attribute, and its tool route asks nothing at all (C12) |

**Reverted — the prototype is reproduced, and these are no longer differences**

| # | what was wrong | what it is now |
|---|---|---|
| D24 | the strip was started at the gutter and the negative margin called a defect | full bleed, first pill at x 0, asserted in the bounds comparison (C19) |
| D26 | the progress bar was drawn | not drawn. The prototype's `.bar` is dead, incomplete markup: emitted with valid data, invisible because it is left out of the rule block that blockifies its own fill, in a card that reserves no room for one. Flutter's card is 350 × 86, the prototype's exactly (C15) |
| D28 | a "local service" dot was drawn on country-restricted tiles | not drawn. The pin branch reads `f.loc`, no catalogue entry declares it, and the rendered hub shows no pin anywhere. The country gate, the marker capability and the precedence contract are all kept (C13, C14) |

**Reproduced by decision, against the conversion's own judgement**

Traced, classified and put to a decision rather than settled. All three came
back the same way, and all three carry a Dayroz obligation.

| # | what Lume does | what Flutter does |
|---|---|---|
| C22 | names three Karachi venues, with distances, to every reader on earth | the same three, in every market |
| C23 | writes "2 of 5 tasks done" and `2/5` whatever the list holds | the same two literals, in every state |
| C24 | claims the weather was updated 4 minutes ago, always | the same claim |

**Nothing is awaiting a decision.** Every difference above is either exact
parity, an approved adaptation, a correctness repair with its conditions met,
or a reproduction taken by decision.

Nothing else differs by more than a logical pixel outside the drift D20
describes. There is no state in which Flutter shows a control the reference
does not, or omits one it does, except where the tables above say so.

---

## 6. Profile

**Captured at one cell only: 390 × 844, light, English.** Unlike Home,
Tools, Today and Explore, Profile has never been measured across dark
mode, Urdu, Arabic, or any width other than the primary phone geometry —
[DESTINATION_PARITY.md](DESTINATION_PARITY.md) covers exactly three
states (`Profile · a guest`, `Profile · signed in`, `Profile · a session
that has run out`), each at the single default cell. This is a genuine
coverage gap, not a reviewed-and-clean result — treat dark mode and RTL
for Profile as unaudited, the same way §2's cell table treats them as
audited for the other four destinations.

**One finding, resolved as a measurement-scope artifact, not a defect.**
`DESTINATION_PARITY.md`'s guest-state `phead.acts` row (the profile
header's action buttons) reads prototype height 101 against Flutter
height 46, a −55 delta with no prior explanation. Investigated directly:

- The prototype's `.phead__acts` (`assets/css/account.css`) is a flex
  column wrapping *both* stacked buttons plus a 9px gap: 46 + 9 + 46 = 101,
  confirmed against the raw measurement JSON, whose `text` field is the
  concatenation of both buttons' labels.
- `test/features/destinations/destination_bounds_test.dart`'s `phead.acts`
  check measures `find.byType(LumeButton).first` — the *first* button
  only — with `checkHeight: false`, so the mismatch was already known and
  deliberately not asserted; it was simply never annotated as a scope
  limitation.
- The signed-in and session-expired states, which render exactly one
  button, measure 46 against 46 — an exact match — confirming the
  Flutter widget tree is correct and the discrepancy is specific to the
  two-button guest case being measured by a single-button finder.
- `LumeIdentityCard` (`lib/core/widgets/lume/lume_settings.dart`) renders
  both guest buttons with a 9-point gap and 14-point top margin
  (`LumeSettingsMetrics.actsGap`/`actsTop`), matching `.phead__acts`'s
  `gap: 9px; margin-top: 14px` exactly.

**No code change is needed.** The test's `note:` field for this row has
been updated to say so explicitly, so the next reader doesn't have to
re-derive it.

**Not yet done, and needed before Profile is reused by a Wave 5 tool:**
dark mode and Urdu/Arabic capture and review, at minimum at the primary
cell, matching the bar the other four destinations already clear.
