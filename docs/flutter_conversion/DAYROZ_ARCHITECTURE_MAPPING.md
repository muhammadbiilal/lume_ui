# Dayroz architecture mapping

Read-only inspection of `D:\dayroz\` on 2026-09-11, carried out so the Lume
Flutter reference is organised the way the production app is and can later move
into it without a second restructuring.

**Dayroz was not modified.** No file was written, formatted, generated or
committed. `git status --porcelain` in `D:\dayroz\` reported only a
pre-existing untracked `.claude/` directory, unchanged by this inspection. No
`.env`, Supabase, Firebase, signing or credential file was opened.

The separation this document enforces:

> **Lume decides what the application looks like and how the interface behaves.
> Dayroz decides how the Dart is organised so later integration is straightforward.**

Dayroz's existing visual widgets, typography, colours, layouts and Material
patterns are **not** design references and are not copied where they differ
from Lume.

---

## 1. What Dayroz is

| | |
|---|---|
| Package name | `roznama` (app name Dayroz; `com.dayroz.app`) |
| Version | 0.4.0+4 |
| Dart SDK constraint | `^3.11.5` |
| Installed toolchain | Flutter 3.44.8 stable / Dart 3.12.2 — satisfies the constraint |
| Dart files | 555 |
| Test files | 161 |
| Feature modules | 86 under `lib/features/` |
| Registered tools | 72 in `lib/core/navigation/feature_registry.dart` |
| `GoRoute` declarations | 125 in `lib/core/routing/app_router.dart` |
| Localisation | 16 ARB locales, **3,147 keys each, fully populated** |
| Current branch | `feature/dayroz-lume-revamp` |

### A Lume migration is already in flight

This is the single most important finding of the inspection. `D:\dayroz\`
already contains:

- `lib/core/theme/lume/lume_tokens.dart` — 31 KB, tokens ported from
  `assets/css/tokens.css`, explicitly additive alongside the legacy
  `design_tokens.dart` / `semantic_colors.dart`.
- `lib/core/widgets/lume/` — 13 files, ~212 KB: `lume_primitives.dart`,
  `lume_charts.dart`, `lume_field.dart`, `lume_row.dart`, `lume_controls.dart`,
  `lume_badge.dart`, `lume_state.dart`, `lume_summary.dart`, `lume_surface.dart`,
  `lume_tile.dart`, `lume_metric.dart`, `lume_search.dart`, `lume_sheet.dart`.
- `lib/core/layout/lume_breakpoint.dart`, `lume_layout.dart`,
  `lume_master_detail.dart`.
- `docs/LUME_MIGRATION/` — ten documents, discovery through a Phase 4A audit
  and a parity audit.
- `tool/capture_lume.mjs` and `tool/measure_lume_primitives.mjs` — a CDP
  capture harness already pointed at `C:/Users/PC/Desktop/tes/tes`.

**Consequence for this phase.** The reference must not invent a parallel
vocabulary. It adopts Dayroz's existing Lume names — `LumeColors`, `LumeType`,
`LumeBreakpoints`, `LumeWidthClass`, `LumeFreshness`, `LumeSkeleton`,
`PageScaffold` — so a later migration is a file move plus an import rewrite,
not a rename pass. Where the reference improves on one of them, that is a
change proposed back to Dayroz, not a second name for the same thing.

---

## 2. Concern-by-concern

| Concern | Current Dayroz pattern | Flutter reference pattern | Integration impact |
|---|---|---|---|
| App bootstrap | `main.dart` → `runApp(ProviderScope(child: DayrozApp()))`; ~60 provider imports warmed at startup; Firebase, Supabase, timezone, intl initialised first | `main.dart` → `ProviderScope` → `LumeReferenceApp`; **no** Firebase, Supabase or network init | Direct transfer of the widget tree; the reference's bootstrap is discarded, Dayroz's is kept |
| Routing | `go_router ^14.6.2`, one `buildAppRouter(ref)` in `lib/core/routing/app_router.dart`, 125 `GoRoute`s, shell route for tabs | Same package, same single-file router, same shell-route shape; routes named after Lume destinations and tool ids | Routes merge into the existing table; tool paths need a name reconciliation (§6) |
| State management | `flutter_riverpod ^2.6.1`; ~95 provider files flat in `lib/app/`, one per concern, `*_provider.dart` | Same package; reference providers live in `lib/app/providers/` and supply **fixtures only** | Fixture providers are replaced by Dayroz providers behind the same view-model interface |
| Feature folders | Mostly flat (`lib/features/notes/*.dart`); 28 of 86 use `data/`, a few add `presentation/` or `widgets/` | Consistently layered: `data/ presentation/ view_models/ fixtures/ widgets/` | A superset of Dayroz's newest convention (prayer, weather, currency, petrol, loadshedding already use `data/` + `presentation/`). Flat features absorb it without conflict |
| Shared widgets | `lib/core/widgets/` (33 legacy) + `lib/core/widgets/lume/` (13 Lume) | `lib/core/widgets/lume/` only | Drops into the existing `lume/` folder. Legacy widgets are **not** copied |
| Theme / tokens | `app_theme.dart` (28 KB) + `design_tokens.dart` + `semantic_colors.dart` (legacy Emerald & Gold) **and** `theme/lume/lume_tokens.dart` (Lume) | `core/theme/lume/` only — tokens, type, space, motion, gradients | Additive, exactly as Dayroz already treats it. The legacy theme is untouched and eventually retired by Dayroz, not by this reference |
| Models | `lib/data/models/` — ~60 plain Dart classes | `lib/data/models/` — presentation models only, matching Lume record schemas | Reference models are view-shaped; Dayroz models map onto them in the fixture adapter's place |
| Repositories | `lib/data/repositories/` + `lib/data/sources/`, HTTP/Supabase-backed | `lib/data/repositories/` — fixture repositories with the same method shapes | The seam. Swapping the implementation is the whole integration story |
| Localisation | `l10n.yaml` → `arb-dir: lib/l10n`, template `app_en.arb`, class `AppLocalizations`, `nullable-getter: false`, `untranslated-messages-file` | Identical `l10n.yaml`; en/ur/ar only, mirroring the web prototype's real coverage | Keys must not collide. Reference keys are prefixed and reconciled in the F9 pass |
| Assets | `assets/fonts/` (Plus Jakarta Sans 400–800, Noto Naskh Arabic, Noto Nastaliq Urdu, plus legacy Sora/Inter), `assets/icons/nav/`, `assets/icons/tools/`, `assets/data/`, `assets/cities/` | `assets/fonts/` (Plus Jakarta Sans 400–800 + Noto Naskh Arabic + OFL), `assets/icons/`, `assets/images/` | Fonts are already the same five weights in Dayroz. Icons need one reconciliation (§6) |
| Testing | `flutter_test` + `flutter_lints ^6.0.0`; 161 files flat in `test/`; no `test/helpers/`; **no goldens** | `test/core/`, `test/features/`, `test/goldens/`, `test/helpers/` with a shared harness | Additive. The reference brings the golden suite Dayroz does not have |
| Lints | `package:flutter_lints/flutter.yaml`, `build/**` excluded, no custom rules | Identical, plus the same exclusion | Same file, no drift |
| Responsive layout | `core/layout/lume_breakpoint.dart` — three width classes **plus a 480 px compact-height override**, measured with `LayoutBuilder`, read through a `BuildContext` extension | The same file, same boundaries, same rationale | Already aligned. This is the reference implementation of §9 of the brief |
| Fixtures / view models | No formal convention; screens read providers directly | `fixtures/` + `view_models/` per feature, presentation widget takes data + callbacks | New discipline the reference introduces; Dayroz adopts it per screen as it migrates |

---

## 3. Dependency plan

The reference takes **five** packages, every one of them already in Dayroz at a
pinned, stable version. Nothing new is proposed for F1.

| Package | Dayroz version | Why the reference needs it |
|---|---|---|
| `flutter_riverpod` | `^2.6.1` | Provider shape the presentation layer is written against |
| `go_router` | `^14.6.2` | Routing, shell route, redirect-based gating |
| `flutter_localizations` + `intl` | SDK / `any` | ARB localisation, locale-aware dates, numbers, currency |
| `flutter_svg` | `^2.3.0` | The 112-symbol icon set and the decorative illustrations |
| `flutter_lints` (dev) | `^6.0.0` | Same lint contract |

Deliberately **not** taken:

| Not taken | Why |
|---|---|
| `supabase_flutter`, `firebase_*`, `http` | The reference has no backend by instruction |
| `shared_preferences` | Reference state is fixtures, not persistence |
| `google_fonts` | Fonts are bundled; Dayroz removed this dependency for the same reason |
| `fl_chart` | Lume's charts are bespoke SVG (`sparkline`, `lineChart`, `barChart`, `donut`, `progressRing`, `heatmap`). `CustomPainter` reproduces them exactly; `fl_chart` would impose its own visual language |
| A golden-test package (`golden_toolkit` et al.) | `flutter_test`'s `matchesGoldenFile` is enough and adds nothing to Dayroz's surface |

Any package beyond this list is proposed in its own phase report with platform
support, licence and integration impact stated, and stays out until approved.

---

## 4. The presentation / view-model boundary

The rule that makes the reference reusable:

```
        Lume presentation widget          ← pure, const-constructible, no I/O
                    ↑
        screen view model + callbacks     ← immutable data + typed intents
                    ↑
  fixture adapter now │ Dayroz provider adapter later
```

Each feature folder is:

```
features/<feature>/
  presentation/   the widgets. Take a view model and callbacks. No providers,
                  no repositories, no async, no DateTime.now().
  view_models/    immutable data classes + the callback interface
  fixtures/       deterministic view-model instances, one per visual state
  data/           fixture repository implementing the contract Dayroz later fills
  widgets/        pieces private to this feature
```

Four rules that keep the boundary real:

1. **A presentation widget never imports a provider.** It cannot know whether
   its data came from a fixture or from Supabase.
2. **A view model is immutable and has no behaviour** beyond derived getters.
   Formatting that depends on locale takes the locale as an argument.
3. **Callbacks are typed intents**, not strings. The web's
   `data-act="tool:calculator"` becomes `onOpenTool(FeatureId.calculator)`.
4. **Fixtures are deterministic.** No `DateTime.now()`, no `Random`. Time is
   injected, so a golden taken today matches one taken next week.

There is **one** presentation widget per screen. Fixture data and Dayroz data
drive the same widget; there is no mock screen to be discarded later.

---

## 5. Directly transferable / needs an adapter / must not be copied

**Directly transferable** — moves as files, imports rewritten:

- `core/theme/lume/` — tokens, type, space, motion, gradients
- `core/widgets/lume/` — the whole component library
- `core/layout/` — breakpoint, measure, master-detail
- `features/*/presentation/` and `features/*/widgets/` — every screen widget
- `features/*/view_models/` — the data shapes
- `test/goldens/` and `test/helpers/`
- `tool/capture`, `tool/compare`, `tool/measure`

**Needs an adapter** — same interface, different implementation:

- `features/*/data/` — fixture repositories → Dayroz repositories
- `app/providers/` — fixture providers → Dayroz providers
- Record models → Dayroz's `lib/data/models/` equivalents
- ARB keys → merged into Dayroz's 16-locale set, collisions resolved
- Routes → merged into `app_router.dart`'s 125 routes

**Must not be copied from Dayroz into the reference:**

- `core/theme/app_theme.dart`, `design_tokens.dart`, `semantic_colors.dart` —
  the legacy Emerald & Gold system
- `core/widgets/` outside `lume/` — 33 pre-Lume widgets
- `Sora` and `Inter` font families — pre-Lume faces
- Any Material default that differs from a Lume specification

---

## 6. Conflicts and risks

| # | Risk | Detail | Mitigation |
|---|---|---|---|
| 1 | **Duplicated effort** | Dayroz's Lume migration has already reached a Phase 4A audit with 13 Lume widget files and a parity audit. Building the reference independently could reimplement work that exists, or diverge from it | Adopt Dayroz's Lume class names and file layout verbatim. Every F2 component is checked against its `lib/core/widgets/lume/` counterpart before being written; where one exists and matches the web, the reference re-derives it from the web and the two are diffed |
| 2 | **Catalogue mismatch** | Lume has **85** tools; Dayroz's `feature_registry.dart` has **72**. Ids and route paths differ | The reference follows the Lume catalogue's 85 ids exactly. An id-reconciliation table is produced in F6 |
| 3 | **Localisation key collision** | Dayroz has 3,147 keys × 16 locales; the reference will add its own. Dayroz's own convention forbids minting keys in a parallel wave because all 16 ARBs collide | Reference keys mirror the web's dotted names in a reserved prefix; reconciliation is a single serial pass in F9 |
| 4 | **Translation coverage gap** | Dayroz has all 16 locales fully populated; the web prototype ships en (2,587), ur (730), ar (726) | The reference matches the **web**, which is the source of truth for this conversion. It does not invent translations |
| 5 | **Legacy theme still live** | Dayroz renders on Emerald & Gold while screens migrate one at a time | The reference carries only Lume. Nothing legacy is imported, so nothing legacy comes back with it |
| 6 | **Icon set divergence** | Lume ships 112 inline SVG symbols; Dayroz has `assets/icons/nav/` and `assets/icons/tools/` plus `cupertino_icons` | The reference bundles the Lume 112 as SVG assets under the same `#i-*` names. Reconciliation is an F9 item |
| 7 | **Package-name confusion** | Dayroz's pubspec `name:` is `roznama`, so its imports are `package:roznama/…` | The reference uses `package:lume_reference/…`; the move is one find-and-replace |
| 8 | **Dayroz's flat feature folders** | 58 of 86 features are flat | The reference uses the layered shape. Documented here as a deliberate, additive deviation |
| 9 | **Dayroz has no goldens** | 161 tests, zero golden files | The reference brings the golden suite. It is new surface for Dayroz, not a conflict |
| 10 | **`fl_chart` vs bespoke charts** | Dayroz uses `fl_chart`; Lume's charts are hand-drawn SVG with their own visual language | The reference paints Lume's charts with `CustomPainter`. Dayroz's chart screens are recomposed, not re-skinned |

---

## 7. Expected migration path

1. `flutter_reference/lib/core/theme/lume/` and `core/layout/` are diffed
   against Dayroz's existing files; differences are resolved in the reference's
   favour where the web proves it, and reported.
2. `core/widgets/lume/` moves across, superseding the 13 files already there.
3. Per feature, `presentation/`, `view_models/` and `widgets/` move into
   `lib/features/<feature>/`.
4. `data/` fixture repositories are replaced by Dayroz repositories that satisfy
   the same contract. The presentation layer does not change.
5. Routes merge into `app_router.dart`; ids reconciled per risk 2.
6. ARB keys merge per risk 3; the 13 locales the reference does not ship keep
   Dayroz's existing translations.
7. Goldens come across as the regression net for everything above.

---

## 8. Files inspected in `D:\dayroz\` (read-only)

`pubspec.yaml` · `analysis_options.yaml` · `l10n.yaml` · `lib/main.dart` ·
`lib/app/app.dart` · `lib/app/` (95 provider filenames) ·
`lib/core/` (19 subdirectory names) · `lib/core/theme/` ·
`lib/core/theme/lume/lume_tokens.dart` · `lib/core/layout/lume_breakpoint.dart` ·
`lib/core/routing/app_router.dart` · `lib/core/navigation/feature_registry.dart` ·
`lib/core/widgets/` · `lib/core/widgets/lume/` · `lib/data/models/` ·
`lib/data/repositories/` · `lib/data/sources/` · `lib/features/` (86 names,
subfolder shapes) · `lib/l10n/` · `test/` · `tool/capture_lume.mjs` ·
`tool/measure_lume_primitives.mjs` · `docs/LUME_MIGRATION/README.md` ·
`docs/LUME_MIGRATION/05_CONVENTIONS.md` · `docs/` index.

No secret, credential, signing or machine-configuration file was opened.
