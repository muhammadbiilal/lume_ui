# Conversion tooling

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** Everything here drives the browser prototype Lume is being
> converted *from*, and is deleted with it at Phase F9. It is deliberately kept
> out of the repository's `tool/` directory so it is never mistaken for Flutter
> development tooling — after F9 there is no Node, no npm and no Chrome in this
> project.

| Script | What it does |
|---|---|
| `capture_web.mjs` | Serves a scratch copy of the prototype, drives Chrome over CDP, and writes a PNG plus a JSON sidecar of measured facts |
| `compare.mjs` | Puts a web capture and a Flutter capture side by side, diffs them, and reports the measurable differences |
| `measure_components.mjs` | Reads a component's own box out of a fixture page |
| `measure_onboarding.mjs` | Drives the onboarding flow to a step and reports every element's bounds |
| `measure_destinations.mjs` | Writes a whole profile to `lume-profile`, **freezes the page's clock**, drives the shell to Home or the Tools hub, and reports bounds *and the composition* — which slides the carousel kept, which eight tools filled the grid, which live cards survived, which categories rendered. `--state` names a user, `--after` a chip or a query, `--scroll` a position, `--shot 1` writes the PNG |
| `gen_catalogue.mjs` | Turns `catalogue.js` + `tool-specs.js` into `lib/features/catalogue/data/feature_catalogue.dart` — 85 features and 6 categories, with the names and status lines left to the ARBs |
| `gen_home_art.mjs` | Lifts Home's thirteen drawings — six hero slides, two context strips, five Discover cards — into `assets/images/home`, with theme variables replaced by sentinels |
| `measure_auth.mjs` | Drives the authentication flow to a named *state* — `signin`, `signin_error`, `signin_busy`, `signup2`, `sent`, `reset`, `updated`, `created`, `expired`, `trouble`, `verify` — and reports bounds, and a PNG with `--shot 1` |

The Flutter side of the capture is a widget test — `test/helpers/capture.dart`
— so both sides run through the same code paths their real callers use.

## Why CDP

`chrome --headless --screenshot --window-size=390,844` does **not** move the CSS
viewport here. The page reports `innerWidth === 500` at every size asked for, and
the images come out as 500 px layouts cropped to the requested width — which
makes the prototype look as though it clips its own header and cuts its chips in
half. It does not.

`Emulation.setDeviceMetricsOverride` is the only thing that actually moves the
viewport, so every capture sets it through the DevTools Protocol and then
**asserts `window.innerWidth`** rather than trusting the flag. A capture whose
viewport is wrong fails instead of writing a misleading image.

## Measure the shell, not the window

Above 600 px the prototype draws itself as a device on a desk: 24 px of stage
padding, a 26 px radius, a border and a large shadow. That frame is browser
presentation and is not reproduced in Flutter, so the comparison crops the web
capture to the `.app` element's bounds first. Below 600 px the two coincide.

## Before every run

```bash
npm test        # must be 10 suites / 697 assertions / 0 failures
git status      # the prototype must be unmodified
```

A capture taken from a modified or failing prototype is void, and any parity
claim resting on it is worthless.
