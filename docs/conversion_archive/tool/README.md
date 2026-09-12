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
| `probe_element.mjs` | Asks the running prototype *everything* about one selector — the whole computed style, the box, the inline style, the dataset, `hidden`, and four ancestors' display modes. `measure_destinations.mjs` reports a fixed set of properties for a fixed set of elements; this is what settling "is this element absent, hidden, or broken" actually takes. It waits 2.5 s, past the entry animation and the 1.1 s bar transition, so a zero cannot be "it had not started" |
| `android_home_probe.dart` | The **packaged application**, launched straight onto Home. `LumeApp` with one override, because the profile repository in this build is deliberately not durable (F4C) so every launch otherwise starts at onboarding. Built with `flutter build apk --debug -t …` and captured with `adb exec-out screencap`; it is how P2 was settled on a device rather than in a golden |
| `gen_catalogue.mjs` | Turns `catalogue.js` + `tool-specs.js` into `lib/features/catalogue/data/feature_catalogue.dart` — 85 features and 6 categories, with the names and status lines left to the ARBs |
| `gen_destination_art.mjs` | Lifts the fourteen destination drawings — six hero slides, two context strips, five Discover cards and the hub's empty state — into `assets/images/{home,tools}`, with theme variables replaced by sentinels |
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
