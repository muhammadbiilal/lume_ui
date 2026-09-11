# Visual verification

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

How a Flutter screen is proved to match the Lume web screen. A screen is not
complete because its tests pass; it is complete when the two captures agree at
every viewport in the matrix and every remaining difference is recorded.

---

## 1. Why this needs a protocol

The first naive approach does not work, and has already been proven not to
work: `chrome --headless --screenshot --window-size=390,844` produces a
390-pixel-wide image **of a 500 CSS-pixel render**. The page reports
`innerWidth === 500` at every size asked for, and the resulting images are
500 px layouts cropped to 390 — which makes the reference look like it clips its
own header and cuts its chips in half, which it does not.

So:

- The viewport is set through the **DevTools Protocol**
  (`Emulation.setDeviceMetricsOverride`), the only thing that actually moves it.
- Every capture **asserts `window.innerWidth`** afterwards rather than trusting
  a flag, and fails the capture when the number is wrong.
- Every capture records the measured **shell width** and `scrollWidth`, so a
  horizontal overflow is caught as data rather than noticed by eye.

## 2. Measure the shell, not the window

The web prototype renders itself as a device on a desk once the window passes
600 px: 24 px of stage padding, a gradient ground, and the app given a 26 px
radius, a border and `--shadow-lg`. That frame is browser presentation and is
not reproduced in Flutter — see
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

**Therefore the two sides are compared on the shell, not the window.**

| | Web | Flutter |
|---|---|---|
| Capture viewport | CDP device metrics at W × H | `tester.view.physicalSize` at W × H, DPR 1 |
| Compared region | bounding box of `.app` | the whole surface |
| Asserted | `innerWidth === W`, `.app` width, `scrollWidth <= clientWidth` | shell width, no overflow |

At compact width the shell **is** the window minus nothing (the 560 px cap only
bites above 560), so the two regions coincide and a whole-page diff is valid.
At medium and expanded the web capture is cropped to `.app` first.

## 3. The viewport matrix

Nine geometries. Every reference screen is captured at all of them; every other
screen at the four marked **core**.

| # | Size | Class | Why | Core |
|---|---|---|---|---|
| V1 | 360 × 800 | compact | The narrow-phone sub-breakpoint (`max-width: 359px` is just below; 360 is the first width that does *not* trigger it) | |
| V2 | 359 × 800 | compact | Triggers the narrow rules: 2-column category grid, 20 px greeting, 28 px auth title | |
| V3 | **390 × 844** | compact | The Design System's phone reference | **core** |
| V4 | 400 × 860 | compact | Mid-compact | |
| V5 | 430 × 932 | compact | Large phone | |
| V6 | **700 × 1000** | medium | Rail, centred content | **core** |
| V7 | **1100 × 900** | expanded | Sidebar, master-detail; below the 1180 wide sub-breakpoint | **core** |
| V8 | 1280 × 800 | expanded | Above 1180 — 4-column metrics, 5-column tiles | |
| V9 | **852 × 393** | compact (height override) | Landscape phone. **Flutter only** — the web has no height rule, so this capture proves the native adaptation, it does not compare against a web capture | **core** |

Each geometry is captured in the full state matrix:

| Axis | Values |
|---|---|
| Theme | light, dark |
| Language / direction | en (ltr), ur (rtl), ar (rtl) |
| Personalisation | the five states in [SCREEN_MATRIX.md §7](SCREEN_MATRIX.md#7-personalisation-states-every-screen-is-checked-in) |
| Text scale | 1.0, and 2.0 for overflow checks |

Not every screen needs every cell. The required set per screen is: core
viewports × {light, dark} × {en, ur} × its own personalisation state, plus
ar at V3, plus 2.0 text scale at V3 and V7.

## 4. Equal inputs

A comparison is only evidence if both sides were given the same thing. Before
any capture:

| Input | Rule |
|---|---|
| Data | The same fixture. Flutter fixtures are derived from the web's demonstration data and seeded records, not re-invented |
| Time | **Pinned.** The web driver freezes the clock; Flutter fixtures inject time. No `DateTime.now()`, no `Random` anywhere in a fixture |
| Profile | Same country, region, city, language, units, currency, clock, faith flag and interests |
| Theme | Same explicit theme — never "system" |
| Scroll | Both at scroll offset 0 unless the comparison is specifically of a scrolled state |
| Selection | Same record selected, or none |
| Motion | Reduced motion **on** for both, so shimmer and pulse are still |
| Transient chrome | The in-app notification banner is removed before capture on both sides |

## 5. Tooling

Three tools under `tool/`, and the reference repository is
never written to by any of them — the web is copied to a scratch directory and
driven there.

### `tool/capture/capture_web.mjs`

Serves a scratch copy of the prototype, launches Chrome with
`--remote-debugging-port`, drives it over CDP, and writes a PNG plus a JSON
sidecar.

```bash
node tool/capture/capture_web.mjs \
  --screen home --width 390 --height 844 --dpr 2 \
  --theme dark --lang ur --state C --out shots/web
```

Sidecar contents, all asserted before the PNG is written:

```json
{
  "requestedWidth": 390, "innerWidth": 390,
  "shellWidth": 390, "scrollWidth": 390, "clientWidth": 390,
  "dataBp": "compact", "dir": "rtl", "lang": "ur", "theme": "dark",
  "bounds": { "...": "per-component rects" }
}
```

The capture **fails** rather than writing a misleading image when
`innerWidth !== requestedWidth`, or when `scrollWidth > clientWidth` on a screen
that is not supposed to scroll horizontally.

A driver script is injected into the scratch copy to reach states the URL alone
cannot — advancing onboarding to a given step, selecting a record, forcing a
collection into its offline or error state.

### `tool/capture/capture_flutter.dart`

A widget test that pumps one screen at one geometry with one fixture and writes
the same PNG-plus-sidecar pair.

```bash
flutter test tool/capture/capture_flutter.dart \
  --dart-define=screen=home --dart-define=width=390 --dart-define=height=844
```

`tester.view.devicePixelRatio = 1.0` so logical pixels are image pixels and the
two sides are directly comparable.

### `tool/compare/compare.mjs`

Takes a web PNG, a Flutter PNG and both sidecars, and emits:

- a side-by-side board,
- a difference image (per-pixel delta, with a tolerance band for
  anti-aliasing — permitted difference P7),
- a measurement table: component bounds from both sidecars, with a per-edge
  delta in logical pixels,
- a text report: visible line counts, text wrapping points, baseline offsets,
  item density, and whether either side scrolls where the other does not.

### `tool/measure/measure.mjs`

Reads bounding boxes, computed styles and text metrics for a named selector in
the web, and the corresponding `RenderBox` and `TextPainter` metrics in Flutter,
for the component-level measurement the
[COMPONENT_MATRIX](COMPONENT_MATRIX.md) requires.

## 6. What is compared

For every screen, at every required cell:

1. **Raw web capture** saved.
2. **Raw Flutter capture** saved.
3. **Side-by-side** board produced.
4. **Difference image** produced where a pixel diff is meaningful.
5. **Component bounds** compared — position and size, per edge, in logical pixels.
6. **Text wrapping and baselines** compared — where a line breaks and where it sits.
7. **Visible line counts** compared.
8. **Item density** compared — how many rows, chips or cards fit above the fold.
9. **Scrolling** compared — same content height, same overflow behaviour.
10. **Every remaining difference recorded**, and either corrected or added to
    [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) with approval.

Artifacts live under `docs/conversion_archive/shots/<screen>/<cell>/` as
`web.png`, `flutter.png`, `side.png`, `diff.png`, `report.md`.

## 7. Tolerances

| Measure | Tolerance | Reason |
|---|---|---|
| Component position and size | **0 px** | Logical pixels are the same unit on both sides |
| Text baseline | ≤ 1 px | Font metric rounding |
| Anti-aliased edge pixels | ≤ 2 % of pixels, ≤ 8/255 per channel | Permitted difference P7 |
| Line break position | **0** | A different break is a real difference, not a rendering artifact — see D2 |
| Visible line count | **0** | |
| Item density above the fold | **0** | |

Anything outside these is a defect until it is recorded and approved.

## 8. Goldens

`matchesGoldenFile` covers the Flutter side as a regression net once a cell has
been signed off. Goldens **do not replace** the web comparison: a golden proves
Flutter has not changed, not that Flutter matches Lume. Every golden is created
only after its cell has been compared against the web and signed off, so the
golden freezes an agreed image rather than an accidental one.

Golden coverage required per component: every state in its `States` column,
light and dark, LTR and RTL. Per screen: the core viewports at both themes in
en and ur.

## 9. Regressions in the web prototype

The web is the comparison source and must not drift. Before every capture run
the harness confirms:

```bash
npm test    # must be 10/10 suites, 697 assertions, 0 failures
git status  # the prototype must be unmodified
```

A capture run against a modified prototype is void. The prototype is **never**
edited to make Flutter agree with it; where the web is genuinely wrong, the
finding is recorded in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) and the fix
is approved on its own terms.
