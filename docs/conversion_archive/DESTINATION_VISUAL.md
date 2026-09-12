# Home and the Tools hub — the visual comparison

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.
> The product-facing description of what Flutter does is
> `docs/LUME_DESTINATIONS.md`.

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
| element bounds | [DESTINATION_PARITY.md](DESTINATION_PARITY.md) — **179 values** |
| the composition | `measurements/{home,tools}_*.json` |
| committed goldens | `test/goldens/images/{home,tools}_*.png` — **37** |

---

## 2. The cells

Primary: **390 × 844, English, light**, for Home in seven user states and the
hub in six.

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

---

## 3. Why the per-pixel diff reads high

| state | beyond tolerance | rasterisation |
|---|---|---|
| home · Muslim, Pakistan | 53.3 % | 17.6 % |
| home · not Muslim, Pakistan | 50.9 % | 18.9 % |
| tools · a user with a history | 39.8 % | 10.7 % |

**These numbers are the two capture-level differences, not a layout mismatch.**
The prototype draws a 28-point simulated status bar above its screen (P1), so
every element is 28 points lower on the reference side and a per-pixel
comparison lights up every glyph in the column. The prototype's shell also
paints a blurred three-colour mesh behind the page; the Flutter shell paints it
too, but these captures are of the *screen*, which is what the comparison is
about.

A pixel diff cannot see past a uniform offset; a bounds comparison can. That is
why the parity evidence is [DESTINATION_PARITY.md](DESTINATION_PARITY.md) —
**179 element positions measured from each side's own screen origin** — and the
diff images are a second opinion rather than the verdict.

The side-by-side images are the ones to look at, and they were: Home at the
primary cell in both faith states, Home in Arabic, Home in dark, Home at 200
per cent, Home at 852 × 393, the hub at the primary cell, and the hub at 1100.

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
| the notification badge clipped at 200 % | a count is information; the badge grows with it |

---

## 5. The remaining discrepancy list

Everything below is deliberate and recorded in
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

| # | difference | size |
|---|---|---|
| P1 | the simulated status bar is not drawn | 28 points of vertical offset on every screen |
| P2 | the test environment has no emoji face, so the greeting's `👋` renders as a box in a *capture* | none on a device |
| D20 | a line box's fractional height is rounded to whole logical pixels | under a fifth of a point per heading, about three by the bottom of Home |
| D22 | the tile status line is translated | the prototype renders it in English in all three languages |
| D23 | the Discover strip is 16 points taller | its outage card names a real time in the user's own clock, and "Next outage 7:00 PM" takes two lines where a hard-coded "14:00" took one (C17) |
| D24 | the quick-action strip starts at the gutter | the prototype's negative margin cancels its own padding and puts the first pill against the screen edge (C19) |
| D25 | a live card is 350 wide | the prototype's is 372.31 and overflows its column by 22.31 (C20) |
| D26 | the progress bar is drawn | the prototype's never renders (C15) |
| D27 | the notification badge is a pill with a number in it | the prototype's is a 7-point dot given `'99+'` (C16) |
| D28 | the "local service" dot is drawn | the prototype tests a field the catalogue renamed (C13) |
| D29 | the market's session is correct | four defects, listed in `docs/LUME_DESTINATIONS.md` §5 (C11) |
| D30 | the Discover strip honours the content switches | the prototype gates it by attribute only (C12) |

Nothing else differs by more than a logical pixel outside the drift D20
describes. There is no state in which Flutter shows a control the reference
does not, or omits one it does, except where the table above says so.
