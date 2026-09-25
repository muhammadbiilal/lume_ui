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
| 1 | Home | `screens/home.screen.js` | 949 | `css/screens/home.css` | **built (F5A)** |
| 2 | Tools | `screens/tools.screen.js` | 266 | `css/screens/tools.css` | **built (F5A)** |
| 3 | Trains 🇵🇰 | `screens/trains.screen.js` | 178 | `css/screens/trains.css` | **built (F5B)** |
| 4 | Today | `screens/today.screen.js` | 390 | `css/screens/today.css` | **built (F5B)** |
| 5 | Explore | `screens/explore.screen.js` | 421 | `css/screens/explore.css` | **built (F5B)** |
| 6 | Profile | `screens/profile.screen.js` | 46 | `css/screens/profile.css` | **built (F5B)** |
| 7 | Account | `screens/account.screen.js` | 159 | `css/account.css` | **built (F5B)** — the 21 routes in §4 |
| 8 | Auth | `screens/auth.screen.js` | 259 | `css/auth.css` | **built (F4C)** — the 10 routes in §3 |
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
| 0 | Welcome | Brand mark + wordmark, floating SVG art, "Get started", "Already have an account? Sign in" | **built (F4B)** |
| 1 | Plan | Kicker "Plan", illustration, Continue | **built (F4B)** |
| 2 | Tools | Kicker "Tools", live tool count, illustration, Continue | **built (F4B)** |
| 3 | **Where are you based?** | Kicker "MAKE IT LOCAL", search, Recent / Popular / All-countries `locrow` list over 194 countries, sticky Continue | **built (F4A)** — the reference screen, converted and compared first |
| 4 | **Which city are you in?** | Country kicker, search, "Use my current location", region groups or flat city list, sticky Continue | **built (F4B)** |
| 5 | **What are you here for?** | Kicker "MAKE IT YOURS", live count, Clear, six interest groups of individual chips, separate Islamic switch card, min 5 / max 10, Continue disabled below 5 | **built (F4A)** — the reference screen, converted and compared first |
| 6 | Set up | Choice rows + calculation-method pills | **built (F4B)** |
| 7 | Name | Identity capture | **built (F4B)** |
| 8 | Success | Animated seal — ring draw 1 s, tick draw 0.5 s @ 0.8 s, three pops @ 1.0/1.1/1.2 s | **built (F4B)** |

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
| `signin` | Sign in | **built (F4C)** |
| `signup` | Create account — two steps | **built (F4C)** |
| `verify` | Verify email, with a resend countdown | **built (F4C)** |
| `forgot` | Forgot password | **built (F4C)** |
| `sent` | Reset link sent | **built (F4C)** |
| `reset` | Set a new password | **built (F4C)** |
| `updated` | Password updated | **built (F4C)** |
| `created` | Account created | **built (F4C)** |
| `expired` | Session expired | **built (F4C)** |
| `trouble` | Trouble signing in | **built (F4C)** |

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

All 21: **built (F5B)** — `test/features/account/` covers identity, preferences,
notifications, quiet hours, locale, reachability, destructive actions and
routing.

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
| `calculator` | Calculator | calculator | low | — | — | Y | — | **built** — exact scaled-integer decimal, bounded at 2^53−1 so a number means the same on every platform; division decided rather than approximated, and a non-terminating one refused and said; divide-by-zero refused where the reference returned 0; algebraic precedence; locale digits and separators in and out; history with an empty state; input-only (C98) |
| `converter` | Unit Converter | calculator | low | — | — | Y | — | **built (wave 4)** — the approved factor policy replaces the reference's own wrong/rounded factors (ROLLOUT_WAVE_4.md §3) |
| `currency` | Currency | explorer | high | — | — | Y | — | **built (wave 9)** — a real from/to picker, replacing the reference's fixed-side swap |
| `stopwatch` | Stopwatch | instrument | low | — | — | — | — | **built (wave 1)** |
| `timer` | Timer | instrument | low | — | — | Y | — | **built (F6A)** — reference tool for the clock-instrument archetype; clock face, preset chips, history rows (C66) |
| `age` | Age Calculator | calculator | low | — | — | — | — | **built (wave 1)** |
| `focus` | Focus Timer | instrument | low | — | — | Y | — | **built** — elapsed time from a boot clock and a start instant, so no drift from accumulated ticks; backgrounding stops the repaint, not the elapsing; a break phase the reference lacks, offered rather than auto-started; the reference's fabricated figures drawn only where the build reproduces it, under the sample mark, and never in development or release; no notification claim (C98) |
| `datecalc` | Date Calculator | calculator | low | — | — | — | — | **built (wave 1)** |

### Planning — 5

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `calendar` | Calendar | planner | high | — | — | Y | — | **built (F6A)** — reference tool for the planner archetype; zone strip, view control, month grid with Hijri days, timeline agenda with the next prayer, holidays, add action, export record (C71) |
| `reminders` | Reminders | manager | medium | — | **yes** | Y | — | **built (wave 7)** — the one durable record family (ROLLOUT_WAVE_7.md) |
| `notes` | Notes | manager | medium | — | **yes** | Y | — | **built (wave 2)** |
| `todos` | To-dos | manager | high | — | **yes** | Y | — | **built (wave 2)** |
| `events` | Events | manager | medium | — | **yes** | — | — | **built (wave 2)** |

### Islamic — 17

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `prayer` | Prayer Times | dashboard | high | faith | — | Y | — | **built (wave 10)** — real solar computation, method/madhab disclosed rather than presented as chosen |
| `qibla` | Qibla Compass | instrument | medium | faith | — | Y | — | **built (wave 8)** — a real great-circle bearing and distance to the Kaaba |
| `mosques` | Nearby Mosques | tracking | high | faith | — | — | — | **built (wave 10)** — no real places directory exists; an honest empty state plus a real "Open in Maps" hand-off |
| `praytrack` | Prayer Tracker | tracker | high | faith | — | — | — | **built (wave 10)** — a real per-day/per-prayer check-in, replacing the reference's clock-time-passed proxy |
| `ramadan` | Ramadan | dashboard | high | faith | — | — | — | **built (wave 10)** — fixed two real reference bugs in the days-until and named-year math |
| `fasting` | Fasting Tracker | tracker | high | faith | — | — | — | **built (wave 10)** — a real fast-entry log, replacing 100% bare-literal figures |
| `taraweeh` | Taraweeh | tracking | medium | faith | — | — | — | **built (wave 10)** — the reference's own tool draws on mosques' fabricated data; rebuilt from scratch as a real rakaat/Juz tracker |
| `ayah` | Ayah of the Day | reader | medium | faith | — | — | Y | **built (wave 9)** |
| `quran` | Al-Qur’an | reader | high | faith | — | Y | Y | **built (wave 9)** — 12 of 114 surahs, disclosed, not presented as complete |
| `quransearch` | Search the Qur’an | explorer | high | faith | — | — | — | **built (wave 9)** |
| `hadith` | Hadith | reader | high | faith | — | — | Y | **built (F6A)** — reference tool for scripture readers; the day's hadith with share and save, search, collections with counts, browse rows with grades; hadith kept as written, the interface translated (C77) |
| `duas` | Daily Duas | library | high | faith | — | — | Y | **built (wave 9)** |
| `names99` | 99 Names | library | medium | faith | — | — | Y | **built (wave 9)** — 12 of 99, disclosed |
| `hijri` | Islamic Calendar | planner | medium | faith | — | — | — | **built (wave 10)** — real tabular-calendar day-walk to find the next six transitions, not the reference's one-year-only fixture |
| `tasbih` | Tasbih | instrument | low | faith | — | Y | — | **built** — counts and resets, nothing prescriptive; the five phrases exactly as the reference holds them, with the conventional count stated as a fact about the round; the fixture history dropped and replaced by a line saying nothing is written down; switching phrase asks first; a live region that announces once per burst, not once per tap; input-only (C98) |
| `zakat` | Zakat Calculator | calculator | high | faith | — | — | — | **built (wave 8)** — reuses Gold Rates' own fixture nisab |
| `faraid` | Faraid | calculator | high | faith | — | — | — | **built (wave 10)** — three heir categories per the Qur'an's own fixed shares; discloses the wife-alone remainder the reference silently drops |

### Money — 15

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `compound` | Compound Interest | calculator | medium | — | — | — | — | **built (wave 1)** |
| `goldrates` | Currency & Gold | explorer | high | — | — | — | — | **built (F6A)** — reference tool for the data-explorer archetype; market strip, gold summary with its change, metals table, currency search, rows with sparkline and delta, 30-day line chart, gold converter, price share card (C72) |
| `markets` | Markets | explorer | veryhigh | — | — | — | — | **built (wave 9)** — the three world-board sections the catalogue promises; the reference's fuller stocks/forex/commodities scope flagged, not built |
| `fuel` | Fuel Prices | explorer | high | — | — | — | — | **built (wave 9)** |
| `fuelcost` | Fuel Cost | calculator | medium | — | — | — | — | **built (wave 9)** — reads Fuel Prices' own fixture directly, not a duplicated table |
| `tax` | Tax Calculator | calculator | high | PK GB US IN AE SA | — | — | — | **built (F6A)** — reference tool for the form-calculator archetype; taxable, untaxed and unsupported compositions |
| `natsavings` | National Savings | explorer | high | PK | — | — | — | **built (wave 9)** |
| `prizebonds` | Prize Bonds | explorer | high | PK | — | — | — | **built (wave 9)** |
| `bills` | Bills | dashboard | high | — | — | Y | — | **built (wave 9)** |
| `packages` | Mobile Packages | explorer | high | PK | — | — | — | **built (wave 9)** |
| `loan` | Loan / EMI | calculator | high | — | — | — | — | **built (wave 1)** |
| `tipsplit` | Tip & Split | calculator | low | — | — | Y | — | **built (wave 1)** |
| `ledger` | Lending Ledger | manager | high | — | **yes** | Y | — | **built** — its own host over record-layer transactions; people, entries and allocations; FIFO-by-obligation, manual allocation, credit, void and restore, delete with Undo, archive; filters by balance, search, sort; reminder preview; `lume.ledger/1` export and import, CSV export; sensitive; nothing seeded (C90) |
| `installments` | Installments | manager | high | — | **yes** | Y | — | **built** — its own host over record-layer transactions; plans, stored anchored monthly schedules and payments; deposit; payments in order with void and restore; locked terms once paid; cancel and reinstate; delete with Undo; filters, search and five sorts; per-currency summaries; due by month; sensitive; no notifications; nothing seeded (C94) |
| `committee` | Committee | manager | high | — | **yes** | Y | — | **built** — its own host over record-layer transactions; a committee, its members, its shares, its stored monthly cycles, contributions and payouts; as many cycles as shares, so every cycle has one recipient; a payout only when its own cycle is fully collected, in any order; one member may hold several shares; locked terms once anything financial exists; cancel on a day with Reinstate; delete with Undo; filters, search and four sorts; `lume.committee/1` export and import, CSV export; sensitive; no notifications; nothing seeded (C96) |

### Daily Life — 18

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `aqi` | Air Quality | dashboard | high | — | — | — | — | **built (wave 9)** |
| `sunmoon` | Sun & Moon | dashboard | medium | — | — | — | — | **built (wave 2)** — computed for the reader's city with `LumeSolar`, no fixture figures |
| `worldclock` | World Clock | explorer | medium | — | — | — | — | **built (wave 3)** — the reader's own zone leads the list, with offsets exact to the minute and the direction in words; days read Yesterday/Today/Tomorrow, falling back to the date two days out; any of the 341 canonical zones or 577 cities can be added, searched by CLDR label; a converter that converts; ticks on the minute with no drift; aliases read, never rewritten; every failure typed and said; computed, so its source bar names the IANA database rather than claiming an update (C98) |
| `holidays` | Public Holidays | planner | medium | — | — | — | — | **built (wave 9)** — 6 countries plus a 3-entry global fallback, no year printed anywhere |
| `weather` | Weather | dashboard | high | — | — | Y | — | **built (F6A)** — reference tool for context dashboards; context bar, conditions summary, heat advisory, next 12 hours, five days with temperature bars, air quality, sun and moon, conditions; generated figures under "Delayed", never "Live" (C76) |
| `loadshed` | Loadshedding | dashboard | high | PK | — | — | — | **built (wave 9)** |
| `trains` | Trains | tracking | veryhigh | PK | — | — | — | **built (wave 9)** — extends the §33 destination's own model additively |
| `flights` | Flights | tracking | veryhigh | — | — | — | — | **built (F6A)** — reference tool for the tracking archetype; search, board view, metrics, route map, live board with a selected flight, journey, aircraft table, timeline, track and share actions (C73) |
| `news` | News | reader | high | — | — | — | — | **built (F6A)** — reference tool for the editorial-reader archetype; edition strip, search, categories, lead story, art rows, reading rows, share card (C68, C70) |
| `cricket` | Cricket | dashboard | high | — | — | — | — | **built (wave 9)** |
| `emergency` | Emergency | action | low | — | — | Y | — | **built (F6A)** — reference tool for the action archetype; SOS card, call grid through the D6 dialer contract, info rows, note (C67) |
| `qr` | QR Scanner | instrument | low | — | — | Y | — | **built (F6A)** — reference tool for camera instruments; viewfinder, Scan and From gallery through the scanner contract (unavailable in this build, said plainly), what it recognises, history (C78) |
| `docscan` | Document Scanner | instrument | medium | — | — | Y | — | **built (wave 10)** — a new capture contract mirroring the scanner's shape; no PDF export or perspective crop (no such package exists) |
| `passport` | Passport Photos | instrument | medium | — | — | — | — | **built (wave 10)** — real pixel work via `dart:ui` (decode/crop/resize/re-encode), replacing the reference's static mockup |
| `vehicle` | Vehicle & Fines | manager | high | PK | — | — | — | **built (wave 10)** |
| `mediasaver` | Media Saver | manager | medium | — | — | — | — | **built (wave 10)** — an honest "no network access" notice, replacing the reference's fixed-toast "Fetch" |
| `wastatus` | WhatsApp Status | library | medium | android | — | — | — | **built (wave 10)** — the reference is itself a non-functional mockup; real instructional content instead |
| `speedtest` | Speed Test | instrument | medium | — | — | — | — | **built (wave 10)** — the reference's numbers are pure `Math.random()`; an honest "can't measure this here" state plus a real hand-off to fast.com |

### Personal — 22

| id | Name | Archetype | Density | Gate | Record | Quick | Share | Status |
|---|---|---|---|---|---|---|---|---|
| `parcel` | Parcel Tracker | tracking | high | — | — | Y | — | **built (wave 9)** — session-only selection, no record family (matches the reference) |
| `shopping` | Shopping List | manager | medium | — | **yes** | Y | — | **built (wave 2)** |
| `birthdays` | Birthdays | planner | medium | — | **yes** | — | — | **built (wave 4)** |
| `streak` | Daily Streak | tracker | medium | — | — | — | — | **built (wave 8)** — real streak/best/rate math, replacing a seeded PRNG heatmap |
| `recipes` | Recipes | library | high | — | — | — | — | **built (F6A)** — reference tool for the visual-library archetype; search, cuisine chips, image-card strip, art rows, `.state` empty, share card (C68, C69) |
| `mealplan` | Meal Planner | planner | high | — | — | — | — | **built (wave 6)** — reader-entered scheduling only |
| `alarms` | Alarms | manager | medium | — | — | — | — | **built (wave 10)** — the reference's own alarms are hardcoded and cosmetic-only; ported faithfully rather than inventing real scheduling |
| `learning` | Learning & Growth | tracker | high | — | — | — | — | **built (F6A)** — reference tool for the tracker archetype; bar chart and heatmap |
| `documents` | Documents | manager | veryhigh | — | **yes** | — | — | **built (F6A)** — the record layer's second family; records with their standing, detail, add, edit and a delete that is for good (no Undo), two panes at expanded; the vault summary, renew note, category filter, sort, grouped vault, export (C75) |
| `vaccines` | Vaccinations | manager | high | — | — | — | — | **built (wave 8)** |
| `health` | Health Records | manager | veryhigh | — | **yes** | — | — | **built (wave 8)** — richer list/detail/form |
| `play` | Play | library | medium | — | — | — | — | **built** — the four games it lists and a statement that none can be played yet; the reference ships no game, only tiles that toast their own names. Personal bests and play counts removed as records nobody set, and the "Recently played" section with them; the tiles are not controls (C98) |
| `babybudget` | Baby Budget | dashboard | high | — | **yes** | Y | — | **built** — its own host over record-layer transactions; a budget, its categories and its spends; the reader's own monthly plan or none at all, so a ratio is never invented; donut shares by largest remainder, totalling 100; one record type for a planned purchase and the spend it becomes, moved in a single write; Coming up ordered overdue-first; the six months ending with the reader's own, in their language and the budget's currency; a start date nothing may predate; archive with Bring back; delete with Undo; filters, search and three sorts; `lume.babybudget/1` export and import, CSV export; sensitive; no notifications; nothing seeded (C97) |
| `habits` | Habits | tracker | high | — | **yes** | Y | — | **built (wave 8)** — real streak/rate math |
| `water` | Water | tracker | medium | — | **yes** | Y | — | **built (wave 4)** |
| `bmi` | BMI Calculator | calculator | medium | — | — | — | — | **built (wave 8)** — pure calculator (`inputOnly`) |
| `cycle` | Cycle Tracker | planner | high | — | — | — | — | **built (wave 8)** — real average-interval prediction |
| `pregnancy` | Pregnancy | dashboard | high | — | — | — | — | **built (wave 8)** — one stored date, real week/trimester/due-date math |
| `expenses` | Expenses | dashboard | veryhigh | — | **yes** | Y | — | **built (F6A)** — reference tool for the finance dashboard and the first record family; records with search, chips, detail, add, edit, delete with Undo and a discard guard, two panes at expanded; range, spend against budget, week, categories, filtered and sorted transactions, budgets, recurring, insights, export (C74) |
| `goals` | Savings Goals | dashboard | high | — | — | — | — | **built (wave 5)** |
| `subs` | Subscriptions | manager | high | — | — | — | — | **built (wave 5)** |
| `meds` | Medication | manager | high | — | **yes** | — | — | **built (wave 8)** |

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
