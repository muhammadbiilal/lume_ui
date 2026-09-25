# Lume — Features, Screens and Capabilities Reference

## 1. Purpose of this document

A functional inventory of the Lume Flutter application: what each screen and
tool does, what context it uses, and — most importantly — what its data really
is. Nothing here claims an external service is connected: Lume has no backend
yet, and every screen says so where it matters.

How a tool's detailed behaviour came to be — including every reference feature
deliberately *not* reproduced because it would have meant inventing data — is
recorded in `docs/conversion_archive/ROLLOUT_WAVE_*.md` for that tool's wave.

## 2. Data classes

Every tool's source line is derived from its data class
(`lib/features/tools/domain/tool_capability.dart`), never written by hand, and
`test/release/release_readiness_test.dart` fails on any claim nothing supports.

| Class | Meaning | What the screen says |
| --- | --- | --- |
| **Computed** | Worked out on the device from the reader's city, time zone and clock — no fixture | the calculation it came from |
| **Your input** | Shows only what the reader typed, captured or picked this session | kept on the device |
| **Your records** | Shows only the reader's own entries; every derived figure (a streak, a rate, a due date) computed from them | kept until Lume is closed — **Reminders** alone is durable, stored on the device |
| **Sample** | Realistic demonstration data bundled with the app | **Sample data**, on the tool itself |

A few record tools (Birthdays, Water, Focus Timer's history) draw sample rows
only in the *parity* build used for design comparison; in a development or
release build they start empty.

## 3. Global application capabilities

- Phone and tablet layouts: a bottom bar when compact (below 600), a labelled
  navigation rail when medium (600–839), a sidebar with master-detail when
  expanded (840 and up); a short screen is compact at any width.
- Light, dark and system appearance; dark is authored, not inverted.
- English, Urdu and Arabic, with right-to-left layout for Urdu and Arabic and
  directional icons that mirror while pictures of things do not.
- Locale-aware dates, times, numbers, currency, distance and temperature;
  metric or imperial by preference, independent of country.
- Country, region and city personalisation; interest-based Home and Tools.
- The Islamic experience is opt-in, never inferred from country or language.
- Country-specific tools appear only where they have launched; global tools
  stay global.
- Global search, tool search, recent tools, related tools and favourite tools.
- Guest use and a simulated, device-local account lifecycle.
- A notification centre — categories, priorities, read and dismiss, quiet
  hours, preview privacy — over sample notifications. **Reminders** is the one
  feature that schedules real notifications on the device.
- Visual share cards through the platform share sheet; named export files;
  handing a number to the dialer (never placing a call); handing a link or a
  maps search to another app; the camera and photo picker for QR Scanner,
  Document Scanner and Passport Photos; saving an image to Photos.
- Screen-reader semantics, focus order, reduced motion, 200 % text scale.
- Loading, empty, no-results, offline, error, private and unavailable states.

## 4. Main screens

### 4.1 Home

**Purpose:** a personalised summary of what matters now.

- A time-based greeting, the date and the selected city; Profile from the
  avatar and Notifications from the bell.
- Weather, and prayer context when the Islamic experience is on.
- A highlight carousel of at most four slides chosen for relevance.
- Quick tools built from eligibility, interests and staple tools, balanced so
  no single category dominates.
- At-a-glance and discovery cards that never expose sensitive or ineligible
  features.

**Context used:** name, country, city, language, interests, the Islamic
preference, the current time, recent tools and regional data.

### 4.2 Tools

One searchable catalogue of every eligible tool: the available count, search
by name and common keywords (petrol, namaz, calculator), the six categories,
recently used tools, and a real no-results state. Availability recalculates
when country or the Islamic preference changes.

### 4.3 Trains (Pakistan)

A primary destination in Pakistan: routes, departures and arrivals, duration,
status and fares, with search and a train detail. Sample data — not connected
to Pakistan Railways.

### 4.4 Today

The reader's day as an ordered plan: completion, compact statistics, the
agenda in time order, and tasks with accessible checked state, in the reader's
clock format, time zone and language.

### 4.5 Explore

Localised weather, contextual and topical content, eligible sports cards,
news and curated discovery tools. Reachable from contextual links in Pakistan,
where Trains takes its place in the navigation.

### 4.6 Profile

Honest guest, signed-in and expired-session states; real profile data only
when it exists; sign-up and sign-in for guests; personalisation, notifications,
region, language, appearance, units, currency and time; account, security,
sessions, data and sign-out for account holders; help and about; account
deletion kept apart from ordinary settings.

### 4.7 Account

Twenty-one routes: preferences (language, region, currency, units, time,
appearance, notifications), identity (profile, name, email, phone), security
(password, sessions — this device and simulated others), data (library,
privacy, sync), support (help, about) and deletion. Unsaved form changes are
guarded before leaving.

### 4.8 Authentication

Sign-up, sign-in, password recovery and reset, email verification and
session-expired flows, with inline validation, protection against double
submission, password visibility, indistinguishable unknown-account and
wrong-password errors, guest preferences preserved on sign-up, and a return to
the destination originally asked for.

**Limitation:** accounts, tokens and sessions are simulated on the device. This
is not production authentication.

### 4.9 Notifications

An unread count on the bell; All, Unread, Important and category filters;
priority ordering; read on open and dismiss; the related tool opened and the
centre returned to afterwards; global, category and per-tool preferences;
quiet hours and preview privacy; an explanation before the system permission
is asked for; and no faith, country or sensitive-data leaks.

### 4.10 Tool host

The frame around all 85 tools: the header with Back and the tool's actions,
the eligibility check before any body is built, the tool's archetype and
density, its source line, privacy note and related tools, and an error state
rather than a blank screen.

### 4.11 Global search

Suggestions and recent searches over eligible features, by name and keyword;
matching tools and destinations open directly; hidden faith, country and
platform entries never appear.

### 4.12 Onboarding

The product introduced; country (from all 194), region and city; interests
(29 offered, at least five); the Islamic experience as an opt-in switch, never
preselected; an optional name that is never invented; neutral defaults when
skipped. **"Use my current location" is shown but not yet wired** — choosing a
place is by hand for now.

## 5. Everyday — 8

| Tool | What it does in this app | Data |
| --- | --- | --- |
| Calculator | Exact decimal arithmetic with operator precedence, history and locale digits; refuses divide-by-zero rather than answering 0 | Your input |
| Unit Converter | Converts across measurement units using internationally defined factors | Your input |
| Currency | Converts between any two currencies with a from/to picker | Sample |
| Stopwatch | Elapsed time and laps, from a clock that keeps counting through sleep | Your input |
| Timer | Counts down from a duration or preset | Sample (its history section) |
| Age Calculator | Exact age from a date of birth, and the next birthday | Your input |
| Focus Timer | Focus and break phases, timed from a start instant so it never drifts | Your input |
| Date Calculator | Differences between dates, and a date plus or minus days, with weekday and holiday counts | Sample (the holiday count) |

## 6. Planning — 5

| Tool | What it does in this app | Data |
| --- | --- | --- |
| Calendar | Month grid (with Hijri days for Muslim readers), the day's agenda with the next prayer, holidays, export | Sample |
| Reminders | Create, repeat and complete reminders, with real scheduled notifications | Your records — **stored on the device** |
| Notes | A record family: search, sort, detail, add, edit, delete with Undo | Sample |
| To-dos | Tasks with done state, filters and progress | Sample |
| Events | Scheduled events | Sample |

## 7. Islamic — 17

Visible only when the Islamic experience is on.

| Tool | What it does in this app | Data |
| --- | --- | --- |
| Prayer Times | Next prayer and countdown, the five prayers, sunrise and sunset; the calculation method (Muslim World League, standard Asr) stated plainly | Computed |
| Qibla Compass | Bearing and distance to the Kaaba from the reader's city (no live compass sensor) | Computed |
| Nearby Mosques | Names the reader's place and opens a real mosque search in their maps app — no invented list | Your input |
| Prayer Tracker | Check off each prayer; streak, monthly rate and missed (qada) prayers computed from the check-ins | Your records |
| Ramadan | Before Ramadan, a countdown in real days; during it, the day, Suhoor and Iftar from the real Fajr and Maghrib, and a countdown to Iftar | Computed |
| Fasting Tracker | Log fasts (sunnah or qada); streak, completion and a 30-day view computed from them | Your records |
| Taraweeh | Log each night's rakaat and the juz reached; streaks and Qur'an progress computed | Your records |
| Ayah of the Day | A daily ayah, shared as a visual card | Sample (a bundled selection) |
| Al-Qur’an | Reads 12 of the 114 surahs — said on screen, not presented as complete | Sample |
| Search the Qur’an | Searches the bundled surahs | Sample |
| Hadith | The day's hadith, search and collections; narrations kept as written | Sample |
| Daily Duas | A categorised dua library, shared as cards | Sample |
| 99 Names | 12 of the 99 names, with their meanings — the rest await a verified source | Sample |
| Islamic Calendar | Today's Hijri date, the month grid, the next six calendar transitions and a converter; the tabular calendar named as such | Computed |
| Tasbih | A dhikr counter over five phrases, with rounds; nothing written down | Your input |
| Zakat Calculator | Zakat due from assets and liabilities against the nisab | Sample (the metal price behind the nisab) |
| Faraid | Shares for a wife, sons and daughters by the Qur'an's fixed shares; any remainder it does not cover is shown, not silently dropped | Your input |

## 8. Money — 15

| Tool | What it does in this app | Data |
| --- | --- | --- |
| Compound Interest | Projects growth from principal, contributions, rate and years, as a chart and table | Your input |
| Currency & Gold | Gold, metals and currency rows with movement, a 30-day chart and a gold converter | Sample |
| Markets | Indices, crypto and ETFs | Sample |
| Fuel Prices | Pump prices by fuel type | Sample |
| Fuel Cost | Trip cost from distance, efficiency and Fuel Prices' own price | Sample (the price) |
| Tax Calculator | Income tax by the slabs of a supported country (PK, GB, US, IN, AE, SA) | Sample (the slabs) |
| National Savings | Pakistan's savings instruments and their returns | Sample |
| Prize Bonds | Denominations and draw results; saving your own numbers is not offered | Sample |
| Bills | Bills with due status | Sample |
| Mobile Packages | Pakistan's operator bundles | Sample |
| Loan / EMI | Instalment, total interest and the schedule | Your input |
| Tip & Split | Per-person share of a bill with tip | Your input |
| Lending Ledger | Who owes whom: people, entries, allocations, void and restore | Your records |
| Installments | Purchase plans, their schedules and payments | Your records |
| Committee | A rotating savings committee: members, shares, cycles, payouts | Your records |

## 9. Daily Life — 18

| Tool | What it does in this app | Data |
| --- | --- | --- |
| Weather | Conditions, the next 12 hours, five days, air quality, sun and moon | Sample |
| Air Quality | An estimated index and pollutants, labelled estimated | Sample |
| Sun & Moon | Sunrise, sunset, twilight, daylight and the moon's phase | Computed |
| World Clock | The reader's zone first, then any of 341 zones or 577 cities, with a converter | Computed |
| Public Holidays | Six countries' holidays plus a global fallback, as illustrative dates | Sample |
| Loadshedding | Pakistan outage windows | Sample |
| Trains | Routes, departures, a train's journey, stops and fares | Sample |
| Flights | A board, a selected flight's journey, aircraft and timeline | Sample |
| News | A lead story, categories and reading rows | Sample |
| Cricket | A match summary and scorecard | Sample |
| Emergency | National emergency numbers; a press opens the dialer, never calls | Sample (the directory) |
| QR Scanner | Scans with the camera or from a photo, decoded on the device | Sample (its history list); scans are your input |
| Document Scanner | Captures pages with the camera or from photos, and shares each page as an image | Your input |
| Passport Photos | Crops a captured or picked photo to the country's size (2×2 in for the US, 35×45 mm elsewhere) and saves it | Your input |
| Vehicle & Fines | Pakistan vehicle records with a fleet search | Sample |
| Media Saver | Says plainly that Lume has no network access to fetch media | Your input |
| WhatsApp Status | Explains how to save a status with WhatsApp's own save button — Lume cannot read the folder | — (no data) |
| Speed Test | Says it cannot measure speed here, and opens a real test in another app | Your input |

## 10. Personal — 22

| Tool | What it does in this app | Data |
| --- | --- | --- |
| Parcel Tracker | Two shipments and their milestones | Sample |
| Shopping List | Items with bought state and progress | Sample |
| Birthdays | Upcoming birthdays and anniversaries | Your records |
| Daily Streak | A streak, best streak and rate from real check-ins | Your records |
| Recipes | A searchable recipe library | Sample |
| Meal Planner | Meals the reader plans, by day and slot | Your records |
| Alarms | Three example alarms; the switches are not connected to any alarm | Sample |
| Learning & Growth | Learning progress as a bar chart and heatmap | Sample |
| Documents | Private document records; deletion is permanent | Sample |
| Vaccinations | Vaccination records and what is due | Your records |
| Health Records | Health entries with a detailed form; deletion is permanent | Your records |
| Play | Lists four games and says none can be played yet | Sample |
| Baby Budget | A budget, categories and spends | Your records |
| Habits | Daily habits with real streaks and rates | Your records |
| Water | Daily intake against a goal | Your records |
| BMI Calculator | BMI from height and weight | Your input |
| Cycle Tracker | Cycle dates and a prediction from the reader's own average interval | Your records |
| Pregnancy | Week, trimester and due date from one stored date | Your records |
| Expenses | Transactions, budgets, categories and insights | Sample |
| Savings Goals | Goals and their progress | Your records |
| Subscriptions | Subscriptions and renewals | Your records |
| Medication | Medicines and doses | Your records |

## 11. Availability summary

- **Islamic experience only:** Prayer Times, Qibla Compass, Nearby Mosques,
  Prayer Tracker, Ramadan, Fasting Tracker, Taraweeh, Ayah of the Day,
  Al-Qur’an, Search the Qur’an, Hadith, Daily Duas, 99 Names, Islamic Calendar,
  Tasbih, Zakat Calculator and Faraid.
- **Pakistan only:** National Savings, Prize Bonds, Mobile Packages,
  Loadshedding, Trains and Vehicle & Fines. Tax supports PK, GB, US, IN, AE
  and SA.
- **Android only:** WhatsApp Status.
- **Camera or photo access, asked for only when used:** QR Scanner, Document
  Scanner and Passport Photos.
- **Sensitive** (kept off Home, Today and share cards; private in
  notifications): Lending Ledger, Installments, Committee, Documents,
  Vaccinations, Health Records, Baby Budget, Cycle Tracker, Pregnancy,
  Expenses, Savings Goals, Subscriptions and Medication.

Availability is enforced not only in Tools but in Home, search, recent tools,
notifications, related tools and deep links.

## 12. Production-readiness boundaries

### Working today

- All 85 tool screens, the six destinations, onboarding, authentication and
  the account routes.
- Personalisation and eligibility rules.
- Calculations, including prayer times, the Hijri calendar, Qibla and zakat.
- The record layer, with Reminders on a durable store.
- Navigation, back stacks, sheets and dialogs on phone and tablet.
- Localisation, RTL, dark mode and accessibility semantics.
- Honest source lines, enforced by test.
- Around 6,600 automated tests, including golden images.

### Still required for production

- A backend and database; secure real authentication and authorisation.
- Real email and phone verification and password recovery.
- Live weather, finance, transport, sports, news, places and carrier data.
- Durable storage for every record family, with secure storage for
  documents, health and financial records.
- Cloud sync and multi-device conflict resolution.
- A push-notification service, and delivered notifications beyond Reminders.
- Device location for "Use my current location".
- Analytics, monitoring, audit logs, abuse controls and rate limiting.

## 13. Capability acceptance rule

A feature should not claim a capability merely because a button can be drawn.
Search must narrow results; filters and sorting must change content;
calculators must recompute; history must persist at its promised scope; sharing
and export must produce meaningful output; notifications must respect
eligibility and privacy; and no live or provider label is shown until a real
integration exists.
