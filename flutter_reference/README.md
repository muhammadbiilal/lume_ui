# Lume Flutter reference

A native Flutter translation of the Lume web prototype in the parent directory.
It is the authoritative mobile and tablet UI reference, and its presentation
layer is written so it can later move into the Dayroz production app without a
second restructuring.

**Status: Phase F0 complete — structure established, awaiting approval before
F1.** There is no Dart code, no `pubspec.yaml` and no Flutter project here yet;
creating them is the first act of F1.

## What this is not

- Not a WebView, and not embedded HTML
- Not a screenshot mockup
- Not a partial component gallery
- Not a redesign, a simplification or an interpretation in default Material
- Not connected to any backend

It is a re-authoring of the rendered Lume interface as Flutter widgets, held to
the measurements in
[`../docs/flutter_conversion/`](../docs/flutter_conversion/).

## The web prototype stays

`../index.html` and `../assets/` are not being replaced, ported or tidied. They
are the comparison source and stay authoritative. Nothing in this folder edits
them, and the capture tooling copies the prototype to a scratch directory rather
than driving it in place.

## Structure

```text
flutter_reference/
  lib/
    main.dart                 entry point
    app/
      app.dart                the application widget
      providers/              fixture providers — replaced by Dayroz providers later
    core/
      layout/                 width class, content measure, master-detail
      navigation/             destination set, eligibility
      routing/                GoRouter configuration
      theme/lume/             tokens, type, space, motion, gradients
      widgets/lume/           the shared component library
      localization/           locale, formatters, direction
      accessibility/          semantics helpers
      fixtures/               cross-feature fixture data
      testing/                harness shared by tests and the capture tool
    data/
      models/                 presentation models
      repositories/           fixture repositories — the integration seam
    features/<feature>/
      data/                   fixture repository for this feature
      presentation/           the screen widgets — no providers, no I/O
      view_models/            immutable data + typed callbacks
      fixtures/               one instance per visual state
      widgets/                pieces private to this feature
    l10n/                     app_en.arb, app_ur.arb, app_ar.arb
  assets/
    fonts/                    Plus Jakarta Sans 400-800, Noto Naskh Arabic, OFL
    icons/                    the 112-symbol Lume set
    images/
  test/
    core/  features/  goldens/  helpers/
  tool/
    capture/  compare/  measure/
  shots/                      capture artifacts, per screen and cell
```

`lib/features/` is empty until F4. Feature folders are created as their phase
reaches them, not up front.

The deviations from Dayroz's current layout, and the reason for each, are in
[DAYROZ_ARCHITECTURE_MAPPING.md](../docs/flutter_conversion/DAYROZ_ARCHITECTURE_MAPPING.md).

## The boundary that makes this reusable

```text
        Lume presentation widget          pure, no I/O, no providers
                    ↑
        screen view model + callbacks     immutable data, typed intents
                    ↑
  fixture adapter now │ Dayroz provider adapter later
```

One presentation widget per screen. Fixture data and Dayroz data drive the same
widget — there is no mock screen to be discarded and rebuilt.

## Planned dependencies

Five, all already in Dayroz at pinned stable versions: `flutter_riverpod`,
`go_router`, `flutter_localizations` + `intl`, `flutter_svg`, and
`flutter_lints` for development. No backend client, no `google_fonts`, no
charting package. Rationale and the deliberate exclusions are in
[DAYROZ_ARCHITECTURE_MAPPING.md §3](../docs/flutter_conversion/DAYROZ_ARCHITECTURE_MAPPING.md#3-dependency-plan).
