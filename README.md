# Lume

A global daily-life super-app: everyday utilities, planning, money, local
services, travel, personal records and an optional, deeply integrated
Islamic experience — personalised by country, city, language, locale,
units, currency, time zone and interests, and by nothing the user did not
choose.

Lume is a native Flutter application for Android and iOS phones and
tablets. There is no backend yet: data is realistic fixture data, and every
screen says so where it matters (see *Build profiles* below).

## Prerequisites

- Flutter 3.44 (stable) with Dart `^3.11.5`, matching the Dayroz production
  app so the presentation layer moves across without an SDK negotiation.
- An Android SDK and/or Xcode for the platform you run on.

## Getting started

```bash
flutter pub get
flutter gen-l10n          # regenerate lib/l10n/app_localizations*.dart from the ARBs
flutter run               # a development build
```

## Checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze lib test
flutter test                          # the full suite, goldens included
python scripts/check_goldens.py       # every committed golden is still compared
```

Golden images live in `test/goldens/images/`. After an intended visual
change, regenerate the affected ones with
`flutter test --update-goldens <test file>` and review the diff before
committing it.

## Build profiles

Chosen with `--dart-define=LUME_BUILD=…`
(`lib/core/config/lume_build_profile.dart`):

| profile | define | what a tool's source line says | may ship |
|---|---|---|---|
| parity | `parity` | the original design reference's own copy, for golden comparison | never — a release binary compiled as parity refuses to start |
| development | none | what the data adapters' capabilities actually support | no |
| release | `release` | what the data adapters' capabilities actually support | yes |

```bash
flutter build apk --release --dart-define=LUME_BUILD=release
flutter build ios --release --dart-define=LUME_BUILD=release
```

`test/release/release_readiness_test.dart` fails on any claim — storage,
liveness, an update time — that no adapter's capability supports.

## Project structure

```text
lib/
  main.dart              entry point
  app/                   the app widget and app-wide Riverpod providers
                         (locale, theme, personalisation, time zone,
                         records, notifications, platform services)
  core/                  everything feature-agnostic:
    routing/             GoRouter configuration and route names
    navigation/          the shell, bottom bar / rail / sidebar, the tool
                         frame, master-detail
    theme/ widgets/      the design system: tokens, type, and the shared
                         Lume widget library
    layout/              width classes (compact / medium / expanded)
    localization/        locale-aware formatting and numerals
    values/ time/        money, currency, dates, IANA time zones, the Hijri
                         calendar, solar calculations
    platform/            adapters for the dialer, share sheet, camera,
                         image saving and links — each behind an interface
    fixtures/ config/    fixture data and the build profile
  features/<id>/         one folder per feature, layered as
                         domain/ data/ application/ presentation/
  l10n/                  ARB sources (en, ur, ar) and generated localizations
test/                    mirrors lib/; goldens/, helpers/, release/
assets/                  fonts, icons, images and bundled data
scripts/                 maintenance tools (golden inventory, time-zone
                         data generation)
docs/                    maintenance documentation
```

## How it is put together

**The catalogue is the single source of truth.** Every feature is declared
once in `lib/features/catalogue/data/feature_catalogue.dart` — its
category, faith gating, countries, locale awareness, sensitivity, sharing
and what it requires. `lib/features/tools/application/tool_registry.dart`
maps each of the 85 catalogue ids to its screen.

**Visibility is decided in one place.** Whether a feature exists for this
user is answered by `lib/features/catalogue/domain/eligibility.dart` and
nowhere else, so Home, Tools, Today, Explore, search, navigation,
notifications, recents, related tools and deep links cannot disagree. Faith
and country are separate rules: religion is never inferred from country,
and a route refuses a hidden feature exactly as it refuses one that does not
exist.

**Width is decided in one place.** Compact (below 600) uses a bottom bar,
medium (600–839) a labelled navigation rail, expanded (840 and up) a
persistent sidebar with master-detail.

**A record flow is written once.** The record families share one record
layer (`lib/features/records/`): typed models over a versioned envelope,
optimistic-lock conflicts, Undo where deletion is recoverable and none where
it is not (documents, health records).

**Localisation is first-class.** English, Urdu and Arabic, with real RTL;
no user-facing string is hard-coded. Numbers, dates, currency and units
follow the reader's locale and preferences, independently of their country.

## Documentation

- `docs/LUME_FLUTTER_ARCHITECTURE.md` — the architecture in depth.
- `docs/LUME_ONBOARDING.md`, `docs/LUME_AUTH.md`, `docs/LUME_ACCOUNT.md`,
  `docs/LUME_DESTINATIONS.md`, `docs/LUME_LOCALIZATION.md` — maintenance
  documents for those areas.
- `claude.md` — the product requirements.
- `docs/conversion_archive/` — **historical, non-authoritative.** The
  record of converting Lume from its original browser prototype, kept for
  the reasoning behind decisions (the `ROLLOUT_WAVE_*.md` files in
  particular). Nothing in the build or the docs above depends on it, except
  the frozen reference measurements some parity tests read from
  `docs/conversion_archive/measurements/`.

## Not yet production

No backend, no real authentication, no live data providers, no cloud sync,
no push service. The account engine simulates identity locally and is
explicitly not production security.
