# Screen matrix

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Every destination the Flutter reference has to contain, with its source module
and conversion status. Status values: `not started` · `in progress` ·
`built` · `compared` · `signed off`. A screen is not `signed off` until its
side-by-side comparison at the viewports in
[VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md) shows no unrecorded difference.

Counts: **10 top-level screens · 9 onboarding steps · 10 auth routes ·
21 account routes · 85 tool screens · 12 record families × 5 CRUD views.**

---

## 1. Top-level screens

Registered in `assets/js/screens/index.js`, in the order they occupy the outlet.

| # | Screen | Module | Lines | Sheet | Status |
|---|---|---|---|---|---|
| 1 | Home | `screens/home.screen.js` | 949 | `css/screens/home.css` | not started |
| 2 | Tools | `screens/tools.screen.js` | 266 | `css/screens/tools.css` | not started |
| 3 | Trains 🇵🇰 | `screens/trains.screen.js` | 178 | `css/screens/trains.css` | not started |
| 4 | Today | `screens/today.screen.js` | 390 | `css/screens/today.css` | not started |
| 5 | Explore | `screens/explore.screen.js` | 421 | `css/screens/explore.css` | not started |
| 6 | Profile | `screens/profile.screen.js` | 46 | `css/screens/profile.css` | not started |
| 7 | Account | `screens/account.screen.js` | 159 | `css/account.css` | not started |
| 8 | Auth | `screens/auth.screen.js` | 259 | `css/auth.css` | not started |
| 9 | Notifications | `screens/notifications.screen.js` | 210 | `css/screens/notifications.css` | **built (F5D)** — centre, banner, both sheets; quiet hours shared with the account route |
| 10 | Tool host | `screens/tool.screen.js` | 1097 | `css/tools/shared.css` | **frame complete (F3)** — the 85 tools it hosts are F6 |

Shared across all ten: `css/screens/shared.css`, `css/components.css`,
`css/crud.css`, `css/responsive.css`, `css/rtl.css`.

**F3 built what surrounds all ten, not the ten.** The shell, the three
navigation presentations, the route map, the tool-host frame and the
master-detail shell are complete and tested; every screen above has a route and
a fixture sitting in it until its own phase. The contracts they must satisfy are
in [NAVIGATION_CONTRACT.md](NAVIGATION_CONTRACT.md).

### Navigation destinations

| Country | Destinations |
|---|---|
| Pakistan | Home · Tools · **Trains** · Today · Profile |
| Everywhere else | Home · Tools · Today · **Explore** · Profile |

Explore stays reachable from contextual links where it is not a tab, with a
back affordance (`#exploreBack`). Never more than five destinations.

---

## 2. Onboarding — 9 steps

`screens/onboarding.screen.js` · `css/onboarding.css`. Nine progress segments,
a circular back button, Skip, and a staggered rise animation on entry
(`--dur-slow` / `--ease-out`, 40/110/160/210/260 ms delays).

| Step | Screen | Key elements | Status |
|---|---|---|---|
| 0 | Welcome | Brand mark + wordmark, floating SVG art, "Get started", "Already have an account? Sign in" | not started |
| 1 | Plan | Kicker "Plan", illustration, Continue | not started |
| 2 | Tools | Kicker "Tools", live tool count, illustration, Continue | not started |
| 3 | **Where are you based?** | Kicker "MAKE IT LOCAL", search, Recent / Popular / All-countries `locrow` list over 194 countries, sticky Continue | not started |
| 4 | **Which city are you in?** | Country kicker, search, "Use my current location", region groups or flat city list, sticky Continue | not started |
| 5 | **What are you here for?** | Kicker "MAKE IT YOURS", live count, Clear, six interest groups of individual chips, separate Islamic switch card, min 5 / max 10, Continue disabled below 5 | not started |
| 6 | Set up | Choice rows + calculation-method pills | not started |
| 7 | Name | Identity capture | not started |
| 8 | Success | Animated seal — ring draw 1 s, tick draw 0.5 s @ 0.8 s, three pops @ 1.0/1.1/1.2 s | not started |

Reference screens for F4, converted and compared first: **step 3 (Country)** and
**step 5 (Interests)**.

The country step is a **vertical list**, not a grid — see
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md#c1--the-onboarding-country-step-list-or-grid)
for the dead `.onb-country` rule that says otherwise.

---

## 3. Authentication — 10 routes

`screens/auth.screen.js` + `ui/account-ui.js` (`AUTH.*`) · `css/auth.css`
(832 lines, its own token layer: `--auth-space-*`, `--auth-type-*`,
`--auth-radius-*`, `--auth-elevation-*`).

| Route | Screen | Status |
|---|---|---|
| `signin` | Sign in | not started |
| `signup` | Create account — two steps | not started |
| `verify` | Verify email, with a resend countdown | not started |
| `forgot` | Forgot password | not started |
| `sent` | Reset link sent | not started |
| `reset` | Set a new password | not started |
| `updated` | Password updated | not started |
| `created` | Account created | not started |
| `expired` | Session expired | not started |
| `trouble` | Trouble signing in | not started |

Auth has two layout breakpoints of its own on `.app--wide`: at **1180 px** the
panel becomes a 460 px elevated card; at **1380 px** it grows a 48 % illustrated
aside. Both reproduced — see
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md#c2--individual-screens-must-not-invent-their-own-breakpoints).

---

## 4. Account — 21 routes

`screens/account.screen.js` + `ui/account-ui.js` (`ROUTES.*`) · `css/account.css`.

| Group | Routes |
|---|---|
| Preferences | `prefs`, `language`, `region`, `currency`, `units`, `time`, `appearance`, `notifications` |
| Identity | `account`, `edit`, `email`, `phone` |
| Security | `security`, `password`, `sessions` |
| Data | `library`, `privacy`, `sync` |
| Support | `help`, `about` |
| Destructive | `delete` |

All 21: not started.

---

## 5. Tool screens — 85

Every catalogue feature opens its own tool screen; the registry refuses a
catalogue entry with no module and a module with no catalogue entry, checked at
load. Archetype and density come from `data/tool-specs.js`, and
`tests/verify.js` asserts every screen earns its declared density.

**Gate** — `faith` is the Islamic experience; a country code list is market
availability; `android` is platform. **Record** marks the twelve families that
run on the shared CRUD engine.

### Everyday — 8

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `calculator` | Calculator | calculator | low | — | — | Y | — | not started |
| `converter` | Unit Converter | calculator | low | — | — | Y | — | not started |
| `currency` | Currency | explorer | high | — | — | Y | — | not started |
| `stopwatch` | Stopwatch | instrument | low | — | — | — | — | not started |
| `timer` | Timer | instrument | low | — | — | Y | — | **built (F6A)** — reference tool for the clock-instrument archetype; clock face, preset chips, history rows (C66) |
| `age` | Age Calculator | calculator | low | — | — | — | — | not started |
| `focus` | Focus Timer | instrument | low | — | — | Y | — | not started |
| `datecalc` | Date Calculator | calculator | low | — | — | — | — | not started |

### Planning — 5

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `calendar` | Calendar | planner | high | — | — | Y | — | not started |
| `reminders` | Reminders | manager | medium | — | **yes** | Y | — | not started |
| `notes` | Notes | manager | medium | — | **yes** | Y | — | not started |
| `todos` | To-dos | manager | high | — | **yes** | Y | — | not started |
| `events` | Events | manager | medium | — | **yes** | — | — | not started |

### Islamic — 17

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `prayer` | Prayer Times | dashboard | high | faith | — | Y | — | not started |
| `qibla` | Qibla Compass | instrument | medium | faith | — | Y | — | not started |
| `mosques` | Nearby Mosques | tracking | high | faith | — | — | — | not started |
| `praytrack` | Prayer Tracker | tracker | high | faith | — | — | — | not started |
| `ramadan` | Ramadan | dashboard | high | faith | — | — | — | not started |
| `fasting` | Fasting Tracker | tracker | high | faith | — | — | — | not started |
| `taraweeh` | Taraweeh | tracking | medium | faith | — | — | — | not started |
| `ayah` | Ayah of the Day | reader | medium | faith | — | — | Y | not started |
| `quran` | Al-Qur’an | reader | high | faith | — | Y | Y | not started |
| `quransearch` | Search the Qur’an | explorer | high | faith | — | — | — | not started |
| `hadith` | Hadith | reader | high | faith | — | — | Y | not started |
| `duas` | Daily Duas | library | high | faith | — | — | Y | not started |
| `names99` | 99 Names | library | medium | faith | — | — | Y | not started |
| `hijri` | Islamic Calendar | planner | medium | faith | — | — | — | not started |
| `tasbih` | Tasbih | instrument | low | faith | — | Y | — | not started |
| `zakat` | Zakat Calculator | calculator | high | faith | — | — | — | not started |
| `faraid` | Faraid | calculator | high | faith | — | — | — | not started |

### Money — 15

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `compound` | Compound Interest | calculator | medium | — | — | — | — | not started |
| `goldrates` | Currency & Gold | explorer | high | — | — | — | — | not started |
| `markets` | Markets | explorer | veryhigh | — | — | — | — | not started |
| `fuel` | Fuel Prices | explorer | high | — | — | — | — | not started |
| `fuelcost` | Fuel Cost | calculator | medium | — | — | — | — | not started |
| `tax` | Tax Calculator | calculator | high | PK GB US IN AE SA | — | — | — | **built (F6A)** — reference tool for the form-calculator archetype; taxable, untaxed and unsupported compositions |
| `natsavings` | National Savings | explorer | high | PK | — | — | — | not started |
| `prizebonds` | Prize Bonds | explorer | high | PK | — | — | — | not started |
| `bills` | Bills | dashboard | high | — | — | Y | — | not started |
| `packages` | Mobile Packages | explorer | high | PK | — | — | — | not started |
| `loan` | Loan / EMI | calculator | high | — | — | — | — | not started |
| `tipsplit` | Tip & Split | calculator | low | — | — | Y | — | not started |
| `ledger` | Lending Ledger | manager | high | — | — | — | — | not started |
| `installments` | Installments | manager | high | — | — | — | — | not started |
| `committee` | Committee | manager | high | — | — | — | — | not started |

### Daily Life — 18

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `aqi` | Air Quality | dashboard | high | — | — | — | — | not started |
| `sunmoon` | Sun & Moon | dashboard | medium | — | — | — | — | not started |
| `worldclock` | World Clock | explorer | medium | — | — | — | — | not started |
| `holidays` | Public Holidays | planner | medium | — | — | — | — | not started |
| `weather` | Weather | dashboard | high | — | — | Y | — | not started |
| `loadshed` | Loadshedding | dashboard | high | PK | — | — | — | not started |
| `trains` | Trains | tracking | veryhigh | PK | — | — | — | not started |
| `flights` | Flights | tracking | veryhigh | — | — | — | — | not started |
| `news` | News | reader | high | — | — | — | — | not started |
| `cricket` | Cricket | dashboard | high | — | — | — | — | not started |
| `emergency` | Emergency | action | low | — | — | Y | — | **built (F6A)** — reference tool for the action archetype; SOS card, call grid through the D6 dialer contract, info rows, note (C67) |
| `qr` | QR Scanner | instrument | low | — | — | Y | — | not started |
| `docscan` | Document Scanner | instrument | medium | — | — | Y | — | not started |
| `passport` | Passport Photos | instrument | medium | — | — | — | — | not started |
| `vehicle` | Vehicle & Fines | manager | high | PK | — | — | — | not started |
| `mediasaver` | Media Saver | manager | medium | — | — | — | — | not started |
| `wastatus` | WhatsApp Status | library | medium | android | — | — | — | not started |
| `speedtest` | Speed Test | instrument | medium | — | — | — | — | not started |

### Personal — 22

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `parcel` | Parcel Tracker | tracking | high | — | — | Y | — | not started |
| `shopping` | Shopping List | manager | medium | — | **yes** | Y | — | not started |
| `birthdays` | Birthdays | planner | medium | — | **yes** | — | — | not started |
| `streak` | Daily Streak | tracker | medium | — | — | — | — | not started |
| `recipes` | Recipes | library | high | — | — | — | — | **built (F6A)** — reference tool for the visual-library archetype; search, cuisine chips, image-card strip, art rows, `.state` empty, share card (C68, C69) |
| `mealplan` | Meal Planner | planner | high | — | — | — | — | not started |
| `alarms` | Alarms | manager | medium | — | — | — | — | not started |
| `learning` | Learning & Growth | tracker | high | — | — | — | — | **built (F6A)** — reference tool for the tracker archetype; bar chart and heatmap |
| `documents` | Documents | manager | veryhigh | — | **yes** | — | — | not started |
| `vaccines` | Vaccinations | manager | high | — | — | — | — | not started |
| `health` | Health Records | manager | veryhigh | — | **yes** | — | — | not started |
| `play` | Play | library | medium | — | — | — | — | not started |
| `babybudget` | Baby Budget | dashboard | high | — | — | — | — | not started |
| `habits` | Habits | tracker | high | — | **yes** | Y | — | not started |
| `water` | Water | tracker | medium | — | **yes** | Y | — | not started |
| `bmi` | BMI Calculator | calculator | medium | — | — | — | — | not started |
| `cycle` | Cycle Tracker | planner | high | — | — | — | — | not started |
| `pregnancy` | Pregnancy | dashboard | high | — | — | — | — | not started |
| `expenses` | Expenses | dashboard | veryhigh | — | **yes** | Y | — | not started |
| `goals` | Savings Goals | dashboard | high | — | — | — | — | not started |
| `subs` | Subscriptions | manager | high | — | — | — | — | not started |
| `meds` | Medication | manager | high | — | **yes** | — | — | not started |

---

## 6. CRUD views — 12 families × 5

Twelve record families share one engine (`tools/crud-engine.js`) built from
`data/record-schemas.js`. None of them writes its own list, form or delete
confirmation, and the Flutter reference keeps that: one engine, twelve schemas.

| Family | Tool | List emphasis (CRUD guide §11) | Deletion |
|---|---|---|---|
| Tasks | `todos` | Due state and completion | recoverable — Undo |
| Reminders | `reminders` | Due state and completion | recoverable — Undo |
| Notes | `notes` | Title, excerpt, modified date | recoverable — Undo |
| Expenses | `expenses` | Amount, category, date | recoverable — Undo |
| Medication | `meds` | Next dose and adherence | recoverable — Undo |
| Documents | `documents` | Type, expiry, lock state | **irreversible** — no Undo |
| Health records | `health` | Date, value, source | **irreversible** — no Undo |
| Habits | `habits` | Progress and streak | recoverable — Undo |
| Water | `water` | Progress and streak | recoverable — Undo |
| Shopping | `shopping` | Checked state and quantity | recoverable — Undo |
| Events | `events` | Date and recurrence | recoverable — Undo |
| Birthdays | `birthdays` | Date and recurrence | recoverable — Undo |

Five views per family: **list · detail · new · edit · delete** (delete is a
confirmation sheet, not a screen). Plus the collection states in
[WEB_TO_FLUTTER_MAPPING.md §7](WEB_TO_FLUTTER_MAPPING.md#7-states): loading,
empty, populated, no-results, offline, load error, save failure, conflict.

`documents` and `health` are the two families whose consideration in the guide
is secure deletion and consent. Their confirmation says the action cannot be
undone, and then no Undo is armed — `tests/crud.js` asserts that one is not
secretly armed.

---

## 7. Personalisation states every screen is checked in

The five states `tests/verify.js` drives, and the Flutter fixtures mirror them.

| State | Country | City | Islamic | Lang | Dir | Visible / 85 |
|---|---|---|---|---|---|---:|
| A | Pakistan | Islamabad | on | en | ltr | 85 |
| B | Pakistan | Islamabad | off | en | ltr | 68 |
| C | United Kingdom | London | on | ur | **rtl** | 79 |
| D | United States | New York | off | en | ltr | 62 |
| E | Saudi Arabia | Riyadh | on | ar | **rtl** | 79 |

State E also runs imperial units, so unit formatting is exercised against a
country whose own default is metric — proving units are a user override rather
than a country lookup.

---

## 8. Conversion order

| Phase | Contents |
|---|---|
| F3 | Shell, five destinations, three navigation presentations, tool host, back behaviour |
| F4 | Onboarding 0–8, auth ×10. Country and Interests compared first |
| F5 | Home, Today, Tools, Explore, Trains, Profile, Account ×21, Notifications, Search |
| F6a | Calculators — 12 |
| F6b | Instruments — 9 |
| F6c | Informational and dashboards — 12 |
| F6d | Explorers and markets — 9 |
| F6e | Readers — 4 and libraries — 5 |
| F6f | Planners — 6 and trackers — 6 |
| F6g | Live tracking — 5 |
| F6h | Action — 1 |
| F7 | Managers — 16, of which 12 are record families with all five views and every state |

12 + 9 + 12 + 9 + 9 + 12 + 5 + 1 + 16 = **85**. Every catalogue feature is in
exactly one batch.
