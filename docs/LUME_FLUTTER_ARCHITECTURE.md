# Lume — Flutter architecture

How the Flutter application is organised, and the rules that keep it that
way. Product requirements live in `claude.md`; this document is about the
code.

## 1. Layers

```text
lib/app/        the app widget and app-wide providers
lib/core/       feature-agnostic foundations
lib/features/   one folder per feature
lib/l10n/       localisation
```

Dependencies point inward: a feature may use `core/` and `app/`, and `core/`
imports no feature — with one necessary exception,
`core/routing/app_router.dart`, which has to know every destination and tool
to route to it.

Presentation shared by many features lives in a few hub features, and the
rest build on them: `tools/` (the tool frame, `tool_screen.dart`, used by every
tool), `records/` (the record engine), `catalogue/` (feature names),
`account/` (the personalisation sheet) and `share/` (the share sheet). Outside
those, a feature does not reach into another feature's internals; related
features share a small text or model file where they genuinely share a
vocabulary (the financial record families share `ledger_text.dart`).

### Inside a feature

```text
lib/features/<id>/
  domain/        pure Dart: models, rules, calculations. No Flutter imports
                 beyond `foundation`, no I/O. Unit-tested in isolation.
  data/          fixtures, repositories and platform adapters that produce
                 domain models.
  application/   Riverpod providers and controllers that join data to the
                 screen.
  presentation/  widgets.
```

Not every feature needs every layer: a pure calculator may be `domain/`
plus `presentation/`. The rule is the direction — presentation depends on
application and domain, domain depends on nothing.

## 2. State — Riverpod

- App-wide state lives in `lib/app/providers/`: locale, theme,
  personalisation (country, city, the Islamic experience, interests),
  time zone, the record repositories, the notification feed and platform
  services.
- A feature's own state lives in its `application/` folder.
- Every platform service is reached through a provider, so tests replace it
  with `overrides:` rather than by patching globals.
- Widgets read state with `ref.watch` in `build` and act with `ref.read` in
  callbacks.

## 3. Navigation — GoRouter

- `lib/core/routing/app_router.dart` owns the route table;
  `lib/core/routing/lume_routes.dart` owns the route names and builders.
- Five destinations per market: Home · Tools · Today · Explore · Profile
  globally, with Trains in place of Explore in Pakistan (Explore stays
  reachable from contextual links there). The set is decided by the
  catalogue and eligibility, not hard-coded per country.
- Every tool is reached as `/<destination>/tool/<id>`. The route asks the
  same eligibility question the hub asks before drawing a tile; a hidden
  tool and an unknown id are refused identically, so the refusal cannot
  reveal which one it was.
- The shell (`lib/core/navigation/`) draws one destination set three ways:
  a bottom bar when compact, a labelled rail when medium, a sidebar with
  master-detail when expanded (`lib/core/layout/lume_breakpoint.dart`:
  below 600, 600–839, 840 and up; a short shell is compact at any width).

## 4. The catalogue, eligibility and the tool registry

- `lib/features/catalogue/data/feature_catalogue.dart` declares every
  feature once: category, archetype, faith gating, countries, what it adapts
  to, sensitivity, sharing, freshness, its fallback source and what it
  requires. It is ordinary source, edited directly.
- `lib/features/catalogue/domain/eligibility.dart` is the only place that
  decides whether a feature exists for a user. Religion is never inferred
  from country, language or city; faith and market availability are
  separate rules.
- `lib/features/tools/application/tool_registry.dart` maps each catalogue id
  to the builder that opens it. `catalogue_test.dart` and the registry's own
  tests keep the two in step.
- A tool screen is built through `LumeToolScreen`
  (`lib/features/tools/presentation/tool_screen.dart`) inside
  `LumeToolFrame`, which draws the header, the source line and the related
  tools, and refuses to build a body the reader may not see — defence in
  depth behind the catalogue gate.

## 5. Honest data — capabilities and source claims

Every tool's source line is derived, never written by hand:
`LumeDataCapability` (`lib/features/tools/domain/tool_capability.dart`)
says what each tool's data really is — input only, computed on the device,
the reader's own records, durable storage, or sample data — and
`LumeSourceClaims` turns that and the catalogue's freshness into what the
screen may claim. Sample data is always marked as such.
`test/release/release_readiness_test.dart` fails on any claim that nothing
supports.

## 6. Records

Record families share one layer (`lib/features/records/`):

- `LumeRecordRepository` is the interface; `LumeMemoryRecordRepository` is
  the in-memory store most families use, and `LumeSqliteRecordRepository`
  is the durable store (currently Reminders only).
- Each family is a typed model with a codec over a versioned envelope
  (`LumeRecord`); nothing outside the codec sees raw maps.
- Writes carry the envelope's version as an optimistic lock, so a conflict
  is shown to the reader, never resolved by last-write-wins.
- Deletion is recoverable with Undo, except for documents and health
  records, which say they cannot be undone and arm no Undo.
- Money is `LumeMoney` (integer minor units plus an ISO 4217 currency);
  arithmetic refuses mixed currencies.

## 7. Platform boundaries

Every platform capability sits behind an interface in `lib/core/platform/`
with one platform implementation and one recording fake for tests — for
example `LumeDialer` / `LumePlatformDialer` / `LumeRecordingDialer`. The
same shape covers sharing, exporting, saving images, opening links, the
camera and the scanner. Tests override the provider with the recording
fake. Do not rely on a provider's platform default to give you the fake:
Flutter's test binding reports `defaultTargetPlatform` as Android on every
host, so a provider that switches on the platform resolves to the *real*
adapter in a test unless it is overridden explicitly.

## 8. Design system

`lib/core/theme/lume/` holds the tokens — colours (light and an
independently authored dark theme), type (Plus Jakarta Sans, Noto Naskh
Arabic for Arabic script), spacing, radii, motion and gradients.
`lib/core/widgets/lume/` holds the shared widget library every screen is
built from. Fonts are bundled, never fetched. Icons are one SVG set in
`assets/icons/`, drawn through `LumeIcon`, which mirrors directional glyphs
in RTL and leaves pictures of things (clocks, compasses) alone.

## 9. Localisation

- ARB sources in `lib/l10n/` (`app_en.arb`, `app_ur.arb`, `app_ar.arb`);
  `flutter gen-l10n` generates `app_localizations*.dart`. No user-facing
  string is hard-coded.
- `test/core/localization/arb_parity_test.dart` keeps the three files in
  step and enforces the copy rules (for example, nothing tells a reader
  about a browser).
- Numbers, dates, currency and units go through `LumeFormatting`
  (`lib/core/localization/lume_format.dart`) for the reader's locale;
  numerals inside RTL text are isolated with `LumeNumerals`.
- Language, locale, country, currency and units are independent settings.

## 10. Time

Clocks are injected (`LumeClockScope`), never read from `DateTime.now()`
inside a widget, so every screen is testable at a fixed instant. Time zones
come from the pinned IANA database behind `LumeTimeZoneService`
(`lib/core/time/lume_iana_zones.dart`). Prayer times, the Hijri calendar and
sun/moon are computed on the device (`lib/core/time/`).

## 11. Testing

- `test/` mirrors `lib/`. Widget tests pump through `pumpLume`
  (`test/helpers/lume_harness.dart`) with provider overrides, a fixed
  clock, and a chosen locale, surface size and text scale.
- Every screen is checked in Urdu and Arabic (RTL) and at 200 % text scale
  for overflow.
- Golden images (`test/goldens/`) cover the destinations and reference
  tools across widths, themes and languages;
  `scripts/check_goldens.py` finds goldens no test compares any more.
- Parity tests compare layout against measurements frozen from the
  original design reference (`docs/conversion_archive/measurements/`) and
  design tokens frozen in `test/helpers/reference_tokens.dart`.
- Before committing: `dart format --set-exit-if-changed lib test`,
  `flutter analyze lib test`, `flutter test`.

## 12. Future Dayroz integration

The fixture adapters are the seam. A production integration replaces a
fixture or in-memory repository with a real one behind the same interface
and provider, and updates that tool's `LumeDataCapability`; the screens do
not change. The SDK constraint and the core dependencies already match
Dayroz, so the presentation layer moves across without negotiation.
