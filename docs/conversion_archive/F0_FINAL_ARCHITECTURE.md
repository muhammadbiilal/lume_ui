# Phase F0 (corrected) — final Flutter architecture and conversion plan

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document plans the conversion. When the conversion is
> finished it is removed, or relabelled historical, at Phase F9.

Supersedes the earlier F0 proposal of a permanent `flutter_reference/`
subproject beside a permanent web prototype. That structure is withdrawn; the
skeleton has been deleted.

**The final state of `C:\Users\PC\Desktop\tes\tes\` is a clean, native Flutter
mobile and tablet project.** Not a migration repository, not a dual web/Flutter
repository, not a permanent comparison workspace. The web implementation is a
temporary conversion input and is removed once Flutter parity is proven and
independently protected.

---

## 1. Proposed root Flutter folder tree

Modelled on `D:\dayroz\`, whose tracked root is exactly this shape.

```text
tes/
  android/                       flutter create, then Lume application id
  ios/
  lib/
    main.dart                    bootstrap — ProviderScope, no backend init
    app/
      app.dart                   LumeApp: MaterialApp.router, theme, locale
      providers/                 fixture providers; Dayroz providers replace them
    core/
      layout/                    width class, content measure, master-detail
      navigation/                destination set, feature registry, eligibility
      routing/                   app_router.dart — GoRouter, shell route, redirects
      theme/
        lume/                    tokens, type, space, motion, gradients
      widgets/
        lume/                    the shared widget system
      localization/              locale resolution, formatters, direction
      accessibility/             semantics helpers, announcements
      fixtures/                  cross-feature fixture data and the clock seam
      testing/                   harness shared by tests and the gallery
    data/
      models/                    presentation models
      repositories/              fixture repositories — the integration seam
    features/<feature>/
      data/                      fixture repository for this feature
      presentation/              screen widgets — no providers, no I/O
      view_models/               immutable data + typed callbacks
      fixtures/                  one instance per visual state
      widgets/                   pieces private to this feature
    l10n/
      app_en.arb  app_ur.arb  app_ar.arb
  assets/
    fonts/                       Plus Jakarta Sans 400-800, Noto Naskh Arabic, OFL
    icons/                       the 112-symbol Lume set, as SVG
    images/
    data/                        geography, seed content, demonstration data
  test/
    core/  features/  goldens/  helpers/
  integration_test/
  tool/                          Dart/Flutter developer scripts only
  docs/
  pubspec.yaml
  analysis_options.yaml
  l10n.yaml
  .metadata
  .gitignore
  README.md
  claude.md
  LUME_COMPLETE_DESIGN_SPECIFICATION.md
  LUME_FEATURES_AND_SCREEN_CAPABILITIES.md
  LUME_FLUTTER_ARCHITECTURE.md
  Lume_Phone_and_Tablet_Design_System.docx
  Lume_CRUD_Visual_and_Interaction_Guide.docx
```

Deviations from Dayroz, each deliberate:

| Deviation | Reason |
|---|---|
| `features/<f>/{data,presentation,view_models,fixtures,widgets}` consistently | Dayroz is mostly flat (58 of 86); its newest features already use `data/` + `presentation/`. The reference uses the fuller shape everywhere so the presentation/view-model boundary is structural, not a convention |
| `integration_test/` present | Dayroz has none. Required by the corrected phase plan |
| `test/goldens/` and `test/helpers/` | Dayroz has 161 flat test files and zero goldens. The golden suite is new surface the conversion brings |
| `core/theme/lume/` only | No `app_theme.dart`, `design_tokens.dart` or `semantic_colors.dart`. Dayroz's legacy Emerald & Gold layer is not copied |
| `core/accessibility/`, `core/fixtures/`, `core/testing/` | Dayroz has no equivalents; they carry conversion-specific discipline that survives into production |

## 2. Dayroz-compatible architecture summary

| Concern | Pattern adopted |
|---|---|
| SDK | Dart `^3.11.5`, satisfied by the installed Flutter 3.44.8 / Dart 3.12.2 |
| State | `flutter_riverpod ^2.6.1`; one provider per concern, `*_provider.dart` |
| Routing | `go_router ^14.6.2`; one `buildAppRouter(ref)`; `StatefulShellRoute` for the five destinations; `redirect` enforces eligibility |
| Localisation | `l10n.yaml` → `arb-dir: lib/l10n`, template `app_en.arb`, class `AppLocalizations`, `nullable-getter: false`, `untranslated-messages-file` |
| Lints | `package:flutter_lints/flutter.yaml`, `build/**` excluded |
| Fonts | Bundled in `pubspec.yaml`, never fetched. All five Plus Jakarta weights have real files so Flutter never synthesises a faux bold |
| Package name | `lume` (Dayroz's is `roznama`; the move is one import rewrite) |
| Naming | `snake_case.dart` files, `PascalCase` widgets, `Lume`-prefixed shared types |

**Names adopted verbatim from Dayroz's in-flight Lume layer** so integration is a
file move rather than a rename pass: `LumeColors`, `LumeType`,
`LumeBreakpoints`, `LumeWidthClass`, `LumeBreakpointScope`, `LumeSkeleton`,
`LumeFreshness`, `PageScaffold`, and the `context.widthClass` /
`context.hasDetailPane` extension getters.

Dependencies — five, all already pinned in Dayroz: `flutter_riverpod`,
`go_router`, `flutter_localizations` + `intl`, `flutter_svg`, `flutter_lints`.
Deliberately excluded: `supabase_flutter`, `firebase_*`, `http`,
`shared_preferences`, `google_fonts`, `fl_chart`, and any golden-test package.

**Lume still defines every interface detail.** Dayroz supplies the Dart
organisation and nothing visual.

## 3. Temporary web-retention plan

The Flutter project is created **at the root, alongside the web files**. They
coexist by name rather than by relocation, so no relative path is rewritten and
`npm test` keeps passing unchanged throughout — which matters, because the web
suite is the parity oracle until Flutter's own tests replace it.

| Path | Owner | During conversion | At F9 |
|---|---|---|---|
| `index.html`, `assets/css/`, `assets/js/`, `scripts/`, `tests/`, `package.json`, `package-lock.json`, `node_modules/` | web | kept, marked temporary | **deleted** |
| `assets/fonts/`, `assets/icons/`, `assets/images/`, `assets/data/` | Flutter | created | kept |
| `lib/`, `test/`, `integration_test/`, `tool/`, `android/`, `ios/` | Flutter | created | kept |
| `docs/conversion_archive/` | conversion | working record | removed or relabelled historical |
| `build/` | both | gitignored; shared directory, transient only | Flutter only |

`assets/` is the only genuine overlap, and it is not a conflict: Flutter bundles
only the subfolders `pubspec.yaml` declares, so `assets/css/` and `assets/js/`
are simply never packaged. `tests/` (web) and `test/` (Flutter) are distinct
names on a case-insensitive filesystem.

Rules while both exist:

1. The web source is a **read-only conversion input**. No new product behaviour
   is built in it. Bug-for-bug reproduction is the goal.
2. Every web file carries its temporary status in
   [TEMPORARY_WEB_REFERENCE_NOTES.md](TEMPORARY_WEB_REFERENCE_NOTES.md), and
   `README.md` says so from F1 onward.
3. `npm test` must stay 10 suites / 697 assertions / 0 failures. A capture run
   against a modified prototype is void.
4. Chrome/CDP capture is conversion tooling under `docs/conversion_archive/`,
   never a Flutter development dependency.

## 4. Final web-removal plan

Removal happens **once**, in a dedicated commit at F9, after parity is approved
and after Flutter's own tests can maintain the design without the website.

Gate — all seven must hold before a single file is deleted:

1. Every screen, state and component has a Flutter implementation.
2. Visual parity has been approved for every screen in the matrix.
3. Flutter tests independently protect tokens, typography, component contracts,
   navigation, responsive behaviour, RTL, localisation, accessibility, CRUD
   states, fixtures, goldens, layout measurements, overflow, text wrapping and
   state preservation.
4. No Flutter tooling, test, asset or document references a web file — proven by
   repository-wide search, not assumed.
5. Git history can recover every deleted file.
6. A removal manifest exists and is approved.
7. `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`,
   goldens, integration tests, an Android build and available iOS validation all
   pass **before** the deletion, so a regression afterwards is unambiguously the
   deletion's fault.

Removal manifest — the files that go:

| Item | Note |
|---|---|
| `index.html` | 25 KB shell + 112-symbol icon sprite. **Icons must be extracted to `assets/icons/` in F1 before this can be deleted** |
| `assets/css/` | 19 stylesheets, 7,449 lines |
| `assets/js/` | 152 modules, ~26,400 lines |
| `tests/` | 11 JavaScript suites, 4,688 lines, 697 assertions |
| `scripts/` | `serve.js`, `build.js`, `bundler.js` |
| `package.json`, `package-lock.json` | npm manifest; `jsdom` dev dependency |
| `node_modules/` | already gitignored |
| `build/` | web bundle output; already gitignored |
| `.gitignore` web entries | `node_modules/`, `tests/_peek.js` |
| Chrome/CDP capture tooling | moved to `docs/conversion_archive/` at F1, deleted here |
| `docs/conversion_archive/` | removed, or relabelled historical and non-authoritative |

After removal the repository must contain **no** dependency on HTML, CSS,
JavaScript, browser `localStorage`, browser routing, DOM events, jsdom, Node
build scripts, Chrome/CDP, or `npm`.

Not deleted incrementally. Nothing is removed while any Flutter screen is still
unfinished, because that would destroy the ability to compare it.

## 5. Flutter-native documentation plan

Final documentation speaks as though Lume is a native Flutter application —
widget, screen, route, provider, controller, view model, theme token, logical
pixel, constraint, build context, state, fixture, golden test, Android, iOS,
phone, tablet. It does not depend on DOM, CSS selector, JavaScript module,
browser route, `localStorage`, jsdom, Chrome viewport, npm or HTML shell.

| Document | Action | Phase |
|---|---|---|
| `claude.md` | **Rewritten completely** as maintenance instructions for the native Flutter application — product definition, architecture, platforms, folder structure, Riverpod rules, GoRouter rules, feature conventions, presentation/view-model boundary, design system, Plus Jakarta Sans typography, colour and semantic tokens, spacing/radius/shadow/motion, phone and tablet responsive behaviour, compact-height behaviour, bottom bar / rail / sidebar / master-detail, screen contracts, component contracts, CRUD architecture, loading / empty / error / offline / conflict / privacy states, localisation and ARB rules, en / ur / ar and LTR / RTL, accessibility, fixture and test rules, golden and responsive verification, clean-code rules, backend integration boundaries for future Dayroz use, definition of completion, and the Flutter commands | F8 |
| `README.md` | **Rewritten** — product overview, supported platforms, Flutter/Dart prerequisites, install, dependencies, `flutter gen-l10n`, running on Android and iOS, tests, `dart format`, `flutter analyze`, golden workflow, build commands, project structure, architecture summary, design-system summary, fixture mode, production-integration boundary. Every `npm`, jsdom, ES-module and "open the HTML file" reference removed | F8 |
| `LUME_COMPLETE_DESIGN_SPECIFICATION.md` | **Rewritten** in Flutter/mobile terms — application shell, native routing, widget composition, themes and tokens, mobile/tablet layouts, safe areas, keyboard handling, native focus and semantics, responsive constraints, platform behaviour | F8 |
| `LUME_FEATURES_AND_SCREEN_CAPABILITIES.md` | **Rewritten** — routes, screen responsibilities, view models, fixture states, interactions, responsive variants, localisation, accessibility, future production-data boundaries | F8 |
| `LUME_SCREEN_BASED_REFACTORING_PLAN.md` | **Renamed** `LUME_FLUTTER_ARCHITECTURE.md` and replaced with the real Flutter architecture — feature-first folders, core layers, Riverpod providers and controllers, GoRouter, presentation widgets, view models, data adapters, fixtures, localisation, testing, platform boundaries, Dayroz integration. **Every internal link to the old name updated** | F8 |
| `Lume_Phone_and_Tablet_Design_System.docx` | **Rewritten** as a native Flutter design-system specification — `ThemeData`, `ColorScheme`, `TextTheme`, widget states, logical pixels, constraints, `SafeArea`, `MediaQuery`, `Directionality`, `Semantics`, bottom navigation, navigation rail, sidebar, master-detail. No CSS custom properties or web selectors as the primary specification. Rendered and visually inspected after every material revision | F8 |
| `Lume_CRUD_Visual_and_Interaction_Guide.docx` | **Rewritten** as a Flutter CRUD guide — screens and widgets, Riverpod state, view models, form controllers, validation lifecycle, async loading, optimistic updates, offline, save failure, version conflict, Undo, irreversible deletion, compact navigation, tablet master-detail, accessibility announcements, focus and keyboard, testing contracts. Rendered and inspected after every material revision | F8 |
| `docs/conversion_archive/*` | Temporary. Decided at F9: retained and labelled historical and non-authoritative, or removed. `README.md`, `claude.md` and the product documents must not require them | F9 |

The eleven CRUD mockups and two design mockups embedded in the two `.docx`
files are Lume design artifacts, not web artifacts, and are preserved through
the rewrite.

## 6. Files rewritten, renamed, archived, deleted

### Rewritten in place
`claude.md` · `README.md` · `LUME_COMPLETE_DESIGN_SPECIFICATION.md` ·
`LUME_FEATURES_AND_SCREEN_CAPABILITIES.md` ·
`Lume_Phone_and_Tablet_Design_System.docx` ·
`Lume_CRUD_Visual_and_Interaction_Guide.docx`

### Renamed
`LUME_SCREEN_BASED_REFACTORING_PLAN.md` → `LUME_FLUTTER_ARCHITECTURE.md`,
content replaced, inbound links updated.

### Archived (already done, this commit)
`docs/flutter_conversion/` → `docs/conversion_archive/`, every file stamped
*Temporary conversion evidence*: `README.md`, `BASELINE_F0.md`,
`WEB_TO_FLUTTER_MAPPING.md`, `DAYROZ_ARCHITECTURE_MAPPING.md`,
`COMPONENT_MATRIX.md`, `SCREEN_MATRIX.md`, `VISUAL_VERIFICATION.md`,
`KNOWN_DIFFERENCES.md`, plus this document and
`TEMPORARY_WEB_REFERENCE_NOTES.md`.

`COMPONENT_MATRIX.md` and `SCREEN_MATRIX.md` are candidates for promotion to
Flutter-native product documents at F8; that is decided then, not assumed now.

### Deleted already (this commit)
`flutter_reference/` — the withdrawn subproject skeleton. Empty; no content lost.

### Deleted at F9
Everything in the removal manifest in §4.

### Created
`pubspec.yaml` · `analysis_options.yaml` · `l10n.yaml` · `.metadata` ·
`android/` · `ios/` · `lib/**` · `assets/{fonts,icons,images,data}` ·
`test/**` · `integration_test/` · `tool/**` · `LUME_FLUTTER_ARCHITECTURE.md`.

## 7. Risks of changing the repository root

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | **`flutter create` overwrites `README.md` or `.gitignore`** | High | Run `flutter create` into a scratch directory and copy in only `android/`, `ios/`, `.metadata` and the platform scaffolding. `README.md`, `.gitignore`, `claude.md` and the `LUME_*` documents are merged by hand |
| R2 | **`assets/` shared between two systems** | Medium | Flutter bundles only declared subfolders; `assets/css` and `assets/js` are never packaged. Verified by inspecting the built asset manifest in F1 |
| R3 | **`build/` shared** | Low | Both gitignored. `npm run build` is not run during conversion; if it is, `flutter clean` follows |
| R4 | **The web suite is the only parity oracle until Flutter's tests exist** | High | The web suite must stay green at 697 assertions for the whole conversion; a run against a modified prototype is void. Flutter tests are written per phase, not deferred to F9 |
| R5 | **Icon loss** — 112 symbols live only inside `index.html` | High | Extracted to `assets/icons/` in F1, before `index.html` is deletable. The removal gate checks this explicitly |
| R6 | **Demonstration data loss** — geography, seeds and tool data live in `assets/js/data/` | High | Ported to `assets/data/` and Dart fixtures during F1–F7; the removal gate checks it |
| R7 | **Deleting too early strands unfinished screens** | High | Single removal commit at F9, gated on seven conditions, never incremental |
| R8 | **`.docx` rewrite loses the 13 embedded mockups** | Medium | Media extracted and re-embedded; both files rendered and visually inspected after every material revision |
| R9 | **Two `claude.md` audiences in flight** | Medium | Root `claude.md` is rewritten last (F8). Until then conversion instructions live only in `docs/conversion_archive/` |
| R10 | **ARB key collision with Dayroz's 3,147 × 16** | Medium | Reference keys mirror the web's dotted names under a reserved prefix; reconciliation is one serial pass at integration |
| R11 | **Android/iOS identifiers** | Low | Application id and display name chosen at F1 and stated in that report; not silently copied from Dayroz |

## 8. Dayroz remains read-only

`D:\dayroz\` is inspected only. Nothing has been or will be written, formatted,
generated or committed there, and its backend is never connected.

Verified at F0: `git status --porcelain` in `D:\dayroz\` reports only a
pre-existing untracked `.claude/` directory, unchanged by the inspection. No
`.env`, Supabase, Firebase, signing or credential file was opened.

One read-only copy **out** of Dayroz is proposed for F1 and flagged here for
approval: the OFL-licensed font binaries in `D:\dayroz\assets\fonts\` —
`PlusJakartaSans-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`,
`PlusJakartaSans-OFL.txt` and `NotoNaskhArabic-Regular.ttf`. These are exactly
the faces Lume specifies and copying them avoids a network fetch. Copying is a
read of Dayroz and a write into this repository; Dayroz is unchanged. If you
prefer, they are downloaded from Google Fonts instead — say which.

## 9. The final project builds without Node, npm, Chrome or web runtime files

Confirmed as the acceptance condition for F9 and F10. After removal the
repository is a standard Flutter project and the complete verification suite is:

```bash
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test --update-goldens   # only when a golden change is intended
flutter test integration_test
flutter build apk --debug
flutter build ios --no-codesign  # where iOS tooling is available
```

Plus a repository-wide search for web fingerprints — `npm`, `jsdom`,
`localStorage`, `querySelector`, `data-bp`, `.css`, `.js` module imports,
`index.html`, `chrome`, `CDP` — which must return nothing outside git history.

No Node, no npm, no Chrome, no CDP, no browser prototype. `package.json` is
gone, so there is no npm command left to run.

---

## Status

**Approved, and F1 is complete.** The Flutter project exists at the root, the
fonts are bundled and verified, the 112 icons are extracted, and the tokens,
themes, responsive system, localisation, fixtures and test harness are in place.
Every web file is still here and its suite is still green.

What F1 changed about this plan: nothing structural. `assets/` did coexist
without conflict, `tests/` and `test/` did stay distinct, and `npm test` did keep
passing unmodified — the three assumptions §3 rested on. One item from §4's
removal gate is now discharged early: the 112 icons no longer exist only inside
`index.html`.
