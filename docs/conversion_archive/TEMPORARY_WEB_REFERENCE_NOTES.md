# Temporary web reference notes

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** Everything in this file describes the browser prototype that
> Lume is being converted *from*. It is deleted at Phase F9, together with the
> files it describes. Nothing here may migrate into `claude.md`, `README.md` or
> the `LUME_*` product specifications.

While the conversion runs, the HTML/CSS/JavaScript source at the repository root
is available for one purpose only: **determining what the Flutter interface must
be**. It is a conversion input, not part of the product.

## What it may be used for

- Inspecting exact behaviour
- Extracting design tokens
- Understanding component composition
- Capturing reference screens
- Measuring dimensions and styles
- Verifying visual parity
- Understanding responsive and RTL behaviour

## What it may not be used for

- Building new product behaviour. The web source is frozen. A defect found in it
  is recorded in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) and fixed in
  Flutter, not patched in JavaScript.
- Any runtime dependency of the Flutter application.
- Anything after Phase F9.

## The files, and what each is for

| Path | What it holds | Needed until |
|---|---|---|
| `index.html` | The shell, and the **112-symbol icon sprite** | F1 — icons extracted to `assets/icons/`, then only for capture |
| `assets/css/tokens.css` | Colour, type, space, radius, motion, gradients | F1 — ported to `lib/core/theme/lume/` |
| `assets/css/base.css` | Reset, shell, the browser-only stage and device frame | F1 |
| `assets/css/components.css` | The shared component library, 119 classes | F2 |
| `assets/css/crud.css` | Record lists, details, forms and states, 94 classes | F7 |
| `assets/css/responsive.css` | The three width classes | F1, F3 |
| `assets/css/rtl.css` | Direction; the seven selectors that genuinely flip | F1, F8 |
| `assets/css/onboarding.css`, `auth.css`, `account.css` | Onboarding and identity | F4 |
| `assets/css/screens/*.css` | One sheet per screen | F5 |
| `assets/css/tools/shared.css` | The tool component library, 456 classes | F6 |
| `assets/js/core/` | Router, lifecycle, profile store, eligibility, records, width class | F1, F3 |
| `assets/js/data/catalogue.js` | **85 features** — the feature registry | F1 |
| `assets/js/data/tool-specs.js` | Archetype, density, capabilities, related tools | F6 |
| `assets/js/data/record-schemas.js` | **12 record families** | F7 |
| `assets/js/data/geo.js`, `tool-data.js`, `solar.js` | **194 countries**, demonstration data | F1 — ported to `assets/data/` and Dart fixtures |
| `assets/js/i18n/` | 2,587 en / 730 ur / 726 ar strings | F1 — ported to ARB |
| `assets/js/screens/`, `assets/js/tools/`, `assets/js/ui/` | Screen, tool and component composition | F2–F7 |
| `tests/` | 10 suites, **697 assertions** — the parity oracle | F9 |
| `scripts/serve.js` | Serves the prototype for capture | F9 |
| `package.json`, `node_modules/` | `jsdom`, for the web suite only | F9 |

## Running it while it is still here

```bash
npm install
npm run serve          # http://localhost:8080 — needed for capture
npm test               # must stay 10 suites / 697 assertions / 0 failures
```

The app is ES modules, so a browser refuses to load it from `file://`. Serve it.

**The suite is the parity oracle.** If it is not green, any capture taken from
the prototype is void and any parity claim based on it is worthless. Check it
before every capture run, and check `git status` — a capture against a modified
prototype proves nothing.

## Capture and measurement

Conversion-only tooling, kept under `docs/conversion_archive/tool/` so it is
never mistaken for Flutter development tooling, and deleted at F9.

The viewport must be set through the DevTools Protocol
(`Emulation.setDeviceMetricsOverride`). `chrome --headless --screenshot
--window-size=W,H` does **not** move the CSS viewport here — the page reports
`innerWidth === 500` whatever is asked for, and the images come out as 500 px
layouts cropped to the requested width, which makes the prototype look as though
it clips its own header. Every capture therefore asserts `innerWidth`, records
the shell width and `scrollWidth`, and fails rather than writing a misleading
image.

Comparison measures the **shell**, not the window: above 600 px the prototype
draws itself as a device on a desk, and that frame is not reproduced in Flutter.

Full protocol: [VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md).

## How this ends

At Phase F9, once Flutter parity is approved and Flutter's own tests protect
tokens, typography, component contracts, navigation, responsive behaviour, RTL,
localisation, accessibility, CRUD states, fixtures, goldens, measurements,
overflow, wrapping and state preservation — every file in the table above is
deleted in one commit, against the manifest in
[F0_FINAL_ARCHITECTURE.md §4](F0_FINAL_ARCHITECTURE.md#4-final-web-removal-plan),
and this document goes with them.

Two things must be rescued **before** that commit is possible, and the removal
gate checks both:

1. The **112 icons**, which exist only inside `index.html`.
2. The **geography, seed and demonstration data**, which exist only in
   `assets/js/data/`.
