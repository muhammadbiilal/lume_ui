# Authentication — the visual comparison

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.
> The product-facing description of what Flutter does is `docs/LUME_AUTH.md`.

The protocol is the one in [VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md):
the viewport is set through the DevTools Protocol, `window.innerWidth` is
asserted afterwards, both sides run with reduced motion forced and the same
pinned clock, and both render at a device pixel ratio of 1 so a logical pixel
is an image pixel.

---

## 1. What was captured

**Reference.** `docs/conversion_archive/tool/measure_auth.mjs` drives the
running prototype to a named state and writes both the bounds and the frame:

```bash
node docs/conversion_archive/tool/measure_auth.mjs --route signin --shot 1
```

`--route` names a *state*, not only a screen — `signin_error` is the sign-in
screen after a refused submission, `signin_busy` is the same screen during the
420 ms the button spends working. Sixteen states were measured.

**Flutter.** `test/goldens/auth_golden_test.dart` writes `.flutter.png` beside
each `.web.png`, from the same state and the same geometry.

**Paired.** `compare.mjs` writes `.side.png`, `.diff.png` and `.report.md` for
each pair.

| Artefact | Where |
|---|---|
| reference frames | `shots/auth/auth_<state>/*.web.png` |
| Flutter frames | `shots/auth/auth_<state>/*.flutter.png` |
| side by side | `shots/auth/auth_<state>/*.side.png` |
| per-pixel diff | `shots/auth/auth_<state>/*.diff.png` |
| element bounds | [AUTH_PARITY.md](AUTH_PARITY.md) — **467 values** |
| committed goldens | `test/goldens/images/auth_*.png` — **115** |

---

## 2. The cells

Primary, for every one of the eleven screens: **390 × 844, English, light.**

Across the suite:

| Cell | What it proves |
|---|---|
| 359 × 844 | the narrowest supported phone: tighter gutters, 28 px heading, 108 seal |
| 390 × 844 | the primary composition |
| 700 × 900 | medium — one column, capped at 420, centred |
| 1100 × 900 | the card composition: 460 wide, padded, bordered, display heading |
| 1400 × 900 | two regions — the decorative aside and the task |
| 852 × 393 | a phone held sideways |
| 390 × 844 dark | authored, not inverted |
| 390 × 844 Urdu | RTL, real translations |
| 390 × 844 Arabic | RTL, real translations |
| 200 % text | four screens, each scrolling rather than clipping |
| keyboard open | the panel's bottom rises above it |

States with their own goldens: a refused submission, a field that failed on
blur, the button working, a flow that interrupted something, offline, a
password part-way to acceptable, a password that meets every rule, the
verification screen once the resend window has opened, the arrival screen with
no name, an expired link, and the splash.

---

## 3. Why the per-pixel diff reads high

| state | beyond tolerance | rasterisation |
|---|---|---|
| signin | 38.5 % | 20.5 % |
| signup2 | 47.1 % | 18.2 % |
| forgot | 37.0 % | 21.1 % |
| sent | 30.9 % | 14.1 % |
| reset | 34.9 % | 16.0 % |
| created | 27.0 % | 15.9 % |
| expired | 22.0 % | 17.3 % |
| trouble | 23.3 % | 17.0 % |
| verify | 43.2 % | 18.1 % |

**These numbers are the two documented differences, not a layout mismatch.**
The prototype draws a 28-point simulated status bar above its screen (P1) and a
floating navigation bar over the bottom of it (D18). Flutter's flow covers the
shell and has neither. So every element is 28 points higher on the Flutter
side, and a per-pixel comparison lights up every glyph in the column.

A pixel diff cannot see past a uniform offset; a bounds comparison can. That is
why the parity evidence is [AUTH_PARITY.md](AUTH_PARITY.md) — **467 element
positions measured from each side's own panel origin, every one within a
logical pixel** — and the diff images are kept as a second opinion rather than
as the verdict.

The side-by-side images are the ones to look at, and they were: all eleven
screens at the primary cell, plus Arabic, dark, 200 per cent, the keyboard, the
card composition and the two-region composition.

---

## 4. What the comparison caught

Found by looking at the renders, not by a passing test:

| Found | Fix |
|---|---|
| every line of text underlined in yellow | the screen had no `Material` at its root, so `Text` fell back to the debug style |
| the recovery link centred in its row instead of at the end of it | a `Container` told to align its child fills the width it is offered — the same trap as F4B's D15 pills |
| every screen four points too low | `.auth__top`'s `min-height` is a border-box measurement: it includes the 16 above it |
| the supporting paragraph wrapping a line early on four screens | `max-width: 34ch` was estimated rather than measured; a real `ch` is wider than the guess |
| centred copy sitting off the centre | a capped block must *fill* the width it is capped to, not shrink-wrap inside it |
| the status screens' action in the middle of the screen | `.auth__grow` belongs between the form and the action, not after everything |
| `PASSWORD MUST CONTAIN` in sentence case | `text-transform: uppercase` was not applied |
| the aside's artwork confined to the padded box and stretched | `inset: 0` is the aside, not the padded box, and `slice` is one scale for both axes |
| the desktop heading at phone size | the card composition steps up to the display ramp |
| the panel overflowing by 23 points at 1100 | an intrinsic height that lied, because `ConstrainedBox` forwards an unclamped width when asked for height — F4B's lesson, in a second place |

---

## 5. The remaining discrepancy list

Everything below is deliberate and recorded in
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

| # | Difference | Size |
|---|---|---|
| P1 | the simulated status bar is not drawn | 28 points of vertical offset on every screen |
| D18 | the navigation bar is not drawn over the flow | the footer is no longer covered; a bottom-anchored action sits 28 lower in absolute terms |
| D19 | a tall screen scrolls rather than compressing its header | 12 points on the reset screen, 6 of them on the back control |
| D20 | the legal line's inline link has no padded box | 2 points of paragraph height on one screen |
| D21 | the seal fades and scales rather than drawing its stroke | no static difference; the arrival animation differs |

Nothing else differs by more than a logical pixel. There is no state in which
Flutter shows a control the reference does not, or omits one it does, except
where the table above says so.
