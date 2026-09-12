# Phase F0 — measured baseline

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Everything below was measured on the repository as it stands, before any
Flutter work. It is the number the conversion is checked against later.

Date: 2026-09-11 · Branch: `feat/master-spec-tool-system` · Working tree clean
at the point of measurement.

## Toolchain

| | |
|---|---|
| Flutter | 3.44.8 stable, engine `13ffd72b2f`, 2026-07-23 |
| Dart | 3.12.2 stable |
| Node | v24.8.0 |
| Chrome | present at `C:/Program Files/Google/Chrome/Application/chrome.exe` (needed for CDP capture) |
| Web runtime deps | none — the prototype is dependency-free at runtime |
| Web dev deps | `jsdom ^25.0.0` only |

## Web test suite — baseline

```
npm test
```

All ten suites pass. **697 assertions, 0 failures, 10/10 suites green.**

> The 697 is this baseline's number and stays as the record of it. Two later
> commits pinned clock-dependent tests and added assertions, so the count from
> F4 onward is **715** — see the canonical count in
> [TEMPORARY_WEB_REFERENCE_NOTES.md](TEMPORARY_WEB_REFERENCE_NOTES.md).

| Suite | Assertions | Result |
|---|---:|---|
| `tests/architecture.js` | 45 | ALL ARCHITECTURE CHECKS PASSED |
| `tests/verify.js` | 12 | ALL CHECKS PASSED |
| `tests/interact.js` | 59 | ALL INTERACTION CHECKS PASSED |
| `tests/controls.js` | 25 | ALL CONTROL CHECKS PASSED |
| `tests/regress.js` | 54 | ALL REGRESSION CHECKS PASSED |
| `tests/notify.js` | 35 | ALL NOTIFICATION CHECKS PASSED |
| `tests/account.js` | 190 | ALL ACCOUNT CHECKS PASSED |
| `tests/auth.js` | 95 | ALL AUTHENTICATION LAYOUT CHECKS PASSED |
| `tests/design.js` | 92 | ALL DESIGN SYSTEM CHECKS PASSED |
| `tests/crud.js` | 90 | ALL CRUD CHECKS PASSED |

`tests/design.js` is the contract the Flutter design system has to satisfy too:
it asserts the shipped hex of twelve colour tokens, that dark mode is authored
rather than inverted, the eight semantic type styles, 20 px page padding,
12/16/26 px radii, the 44 px touch target, the 1.75 px icon stroke, 160/260/420 ms
motion, the 600/840 boundaries, the 84 px rail, the 244 px sidebar, the
680–760 px reading cap and the 360–440 px list pane — plus a golden pass at
compact, medium and expanded.

## Codebase size

| | Files | Lines |
|---|---:|---:|
| JavaScript (`assets/js`) | 152 | ~26,400 |
| CSS (`assets/css`) | 19 | 7,449 |
| Tests (`tests/`) | 11 | 4,688 |
| Build/serve scripts | 3 | 466 |
| **Total inspected** | **185** | **~39,000** |

Unique CSS class selectors across all stylesheets: **1,088**.
Icon sprite in `index.html`: **112 symbols**, one 24 px stroke set.

## Feature and screen counts

| | Count |
|---|---:|
| Catalogue features (`data/catalogue.js`) | **85** |
| Tool modules (`tools/registry.js`) | **85** (registry refuses any mismatch at load) |
| Tool specs (`data/tool-specs.js`) | **85** |
| Tool archetypes | **11** |
| Record families (`data/record-schemas.js`) | **12** |
| Top-level screens (`screens/index.js`) | **10** |
| Onboarding steps | **9** |
| Account routes | **21** |
| Auth routes | **10** |
| Shared component builders (`ui/components.js`) | **60** |
| CRUD component builders (`ui/crud.js`) | **22** |
| Countries (`data/geo.js`) | **194** |

### Features by category

| Category | Count |
|---|---:|
| Everyday | 8 |
| Planning | 5 |
| Islamic | 17 |
| Money | 15 |
| Daily Life | 18 |
| Personal | 22 |

### Features by archetype

| Archetype | Count |
|---|---:|
| manager | 16 |
| calculator | 12 |
| dashboard | 12 |
| explorer | 9 |
| instrument | 9 |
| planner | 6 |
| tracker | 6 |
| tracking | 5 |
| library | 5 |
| reader | 4 |
| action | 1 |

### Gating

| Gate | Features |
|---|---|
| Faith (Islamic experience) | 17 |
| Country-restricted | `tax` (PK/GB/US/IN/AE/SA), `natsavings`, `prizebonds`, `packages`, `loadshed`, `trains`, `vehicle` (PK) |
| Preference-gated | `cricket`, `news`, `markets`, `goldrates` |
| Android-only | `wastatus` |

## Visible-feature counts per personalisation state

Measured by `tests/verify.js`, which builds every visible tool in each state.

| State | Visible / 85 | Direction |
|---|---:|---|
| Muslim + Pakistan + Islamabad (en) | 85 | ltr |
| Non-Muslim + Pakistan + Islamabad (en) | 68 | ltr |
| Muslim + United Kingdom + London (ur) | 79 | **rtl** |
| Non-Muslim + United States + New York (en) | 62 | ltr |
| Muslim + Saudi Arabia + Riyadh (ar, imperial) | 79 | **rtl** |

Every tool builds in every state it is visible in, with no untranslated keys and
no leaked faith or country content.

## Localisation

| | |
|---|---:|
| Declared languages | 8 — en, ur, ar, fr, es, tr, id, hi |
| Shipped dictionaries | **3** — en (ltr), ur (rtl), ar (rtl) |
| English keys | **2,587** |
| Urdu keys | 730 → **25.2 %** of English |
| Arabic keys | 726 → **25.0 %** of English |

Untranslated keys fall back to English rather than showing the key, so a partial
translation degrades instead of breaking. The five declared-but-unshipped
languages (fr, es, tr, id, hi) have no dictionary in the web prototype.

## Navigation

One destination set, three presentations, never more than five destinations.

| Country | Tab order |
|---|---|
| Pakistan | Home · Tools · Trains · Today · Profile |
| Everywhere else | Home · Tools · Today · Explore · Profile |

| Width class | Range | Navigation |
|---|---|---|
| compact | below 600 | bottom bar with sliding pill |
| medium | 600–839 | 84 px labelled rail, stacked label |
| expanded | 840–1366 | 244 px persistent sidebar with wordmark |

The class is measured from the **shell**, not the window, and stamped on `<html>`
as `data-bp`. Nothing else in the app counts pixels.

## Design guide images

The two `.docx` guides carry the visual references the conversion compares
against: **11 PNG mockups** in `Lume_CRUD_Visual_and_Interaction_Guide.docx`
(list, create, detail, edit, delete, empty, loading, error, success, tablet
master-detail, tablet form) and **2** in
`Lume_Phone_and_Tablet_Design_System.docx` (the same tablet pair).

## Reproducing this baseline

```bash
npm install
npm test                 # 10 suites, 697 assertions
npm run serve            # http://localhost:8080
npm run build            # bundles to build/index.html and self-checks
```
