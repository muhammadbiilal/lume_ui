# Lume — Features, Screens and Capabilities Reference

## 1. Purpose of this document

This is a functional inventory of the current Lume prototype. It explains what each screen and feature does, what the user can do with it, what context it uses, and whether its information is local, calculated, static, cached, delayed or intended to be live.

The word **capable** here means the capability is represented in the current interface and its prototype behaviour. It does not mean a real external service is connected. Financial feeds, weather, transport, news, places, carrier information and similar datasets are realistic demonstrations unless a production integration is added.

## 2. Capability vocabulary

| Capability | Meaning in Lume |
| --- | --- |
| Search | Find records or content inside the current screen |
| Filters | Narrow content by category, status or type |
| Sorting | Change record order and, where supported, sort direction |
| History | Show previous calculations, activity or stored entries |
| Notifications | Generate or configure relevant reminders/alerts |
| Offline | Core screen remains usable without a network |
| Sharing | Produce shareable text or a visual share card |
| Export | Produce a named downloadable file or export action |
| Favourites | Save important items for faster return |
| Sensitive | Hide private detail from promotion and notification previews |
| Location required | Needs a city, position or device permission to be meaningful |

## 3. Global application capabilities

Lume currently provides these cross-product capabilities:

- Responsive mobile and desktop layouts.
- Light, dark and system appearance modes.
- English, Urdu and Arabic, including LTR/RTL switching.
- Locale-aware date, time, number, currency, distance and temperature formatting.
- Country, region and city personalization.
- Interest-based Home and Tools recommendations.
- Optional Islamic content with strict faith-content gating.
- Country-specific availability and global tools with localized content.
- Global search, tool search, recent tools and related tools.
- Guest use and a simulated device-local account lifecycle.
- Notification centre, categories, priorities, read/dismiss state, quiet hours and previews.
- Browser notification permission education and request flow.
- Browser geolocation, native sharing and telephone links where supported.
- Accessible roles, keyboard navigation, focus management and reduced motion.
- Loading, empty, no-results, offline, error, private and unavailable states.

## 4. Main screens

### 4.1 Home

**Purpose:** Give the user a personalized summary of what matters now.

**What it does:**

- Shows a time-based greeting, current date and selected city.
- Opens Profile from the avatar and Notifications from the bell.
- Shows immediate weather and, when enabled, prayer context.
- Displays a highlight carousel for timely content and important tools.
- Builds quick actions and quick tools from catalogue eligibility, interests and staple tools.
- Displays live-now and upcoming information only when relevant content exists.
- Shows at-a-glance progress, rates or regional information.
- Offers discovery cards without exposing sensitive or ineligible features.

**Context used:** name, country, city, language, interests, Islamic-content preference, current time, recent tools and regional data.

### 4.2 Tools

**Purpose:** Provide one searchable catalogue for every eligible utility.

**What it does:**

- Displays the number of currently available tools.
- Searches feature names and common keywords such as petrol, namaz or calculator.
- Filters tools by Everyday, Planning, Islamic, Money, Daily Life and Personal categories.
- Shows recently used tools.
- Opens each tool through the shared Tool Host.
- Displays a proper no-results state.
- Recalculates availability when country or faith settings change.

### 4.3 Trains destination

**Purpose:** Give Pakistan users fast access to train information from primary navigation where configured.

**What it does:**

- Shows routes, departure/arrival times, duration, status and fare information.
- Provides route/search controls and train-list interaction.
- Uses Pakistan-specific visibility and selected-city context.

**Current limitation:** train information is demonstration data, not connected to Pakistan Railways.

### 4.4 Today

**Purpose:** Present the user's day as an ordered plan.

**What it does:**

- Shows daily completion percentage and completed-task count.
- Displays compact daily statistics.
- Orders agenda events chronologically.
- Shows tasks with accessible checked/unchecked state.
- Uses the user's clock format, time zone and language.

### 4.5 Explore

**Purpose:** Surface useful local and topical information beyond the personal plan.

**What it does:**

- Shows localized weather, temperature, rain, wind and sunset.
- Shows nearby/contextual content when available.
- Displays eligible sports/live cards.
- Lists localized or global news.
- Offers curated discovery tools.

### 4.6 Profile

**Purpose:** Provide the entry point for identity, preferences, privacy and support.

**What it does:**

- Renders honest guest, authenticated and expired-session states.
- Shows real profile data only when it exists.
- Offers sign-up/sign-in to guests.
- Provides personalization, notifications, region, language, appearance, units, currency and time settings.
- Provides account, security, sessions, data/sync and logout destinations to account holders.
- Provides help, about and tour destinations.
- Keeps account deletion visually separate from ordinary settings.

### 4.7 Account

**Purpose:** Host nested profile and settings screens.

**What it does:**

- Edits profile name, email and phone.
- Handles email-change verification behaviour.
- Changes the local prototype password after verifying the current password.
- Lists the current browser/device session and simulated other sessions.
- Supports sign-out of other sessions.
- Configures language, appearance, region, units, time zone, clock and currency.
- Hosts notification preferences and data/sync information.
- Confirms logout and account deletion.
- Warns before discarding unsaved form changes.

### 4.8 Authentication

**Purpose:** Handle identity flows outside the utility-tool system.

**What it does:**

- Supports sign-up, sign-in, password recovery, password reset, verification and session-expired flows.
- Validates email and password rules inline.
- Prevents double submission while processing.
- Provides password visibility controls.
- Keeps unknown-account and wrong-password errors indistinguishable.
- Preserves guest preferences when creating an account.
- Returns a signed-in user to an originally requested protected destination.

**Current limitation:** accounts, digests, tokens and sessions are simulated in browser storage. This is not production authentication.

### 4.9 Notifications

**Purpose:** Collect important Lume alerts in one privacy-aware centre.

**What it does:**

- Shows unread count on the global bell.
- Filters by All, Unread, Important and eligible categories.
- Prioritizes important items.
- Marks items read when opened and supports dismissal.
- Opens the related tool and returns to the centre afterward.
- Configures global, category and per-tool notification preferences.
- Configures quiet hours and notification-preview privacy.
- Educates the user before requesting browser permission.
- Prevents faith, country or sensitive-data leaks.

### 4.10 Tool Host

**Purpose:** Provide consistent navigation and layout around all 85 tool screens.

**What it does:**

- Builds a tool-specific header, subtitle, Back control and supported actions.
- Enforces catalogue eligibility before opening a tool.
- Applies the tool's approved archetype, density and composition.
- Adds source/freshness, privacy notes and eligible related tools.
- Displays an error state rather than a blank screen if construction fails.
- Manages tool detail navigation and cleanup when leaving.

### 4.11 Global Search

**Purpose:** Find tools and relevant destinations from anywhere in the shell.

**What it does:**

- Shows suggestions and recent searches.
- Searches eligible features using names and keywords.
- Opens matching tools or destinations.
- Excludes hidden faith, country and platform-specific entries.

### 4.12 Personalization and onboarding

**Purpose:** Establish a useful profile without forcing account creation.

**What it does:**

- Introduces the product and asks for optional name, interests and contextual preferences.
- Allows the name to be skipped without inventing an identity.
- Configures country, region and city.
- Keeps Islamic features opt-in rather than preselected.
- Uses neutral defaults when personalization is skipped.

## 5. Everyday tools — 8

| Feature | What it does | User capabilities | Context/data |
| --- | --- | --- | --- |
| Calculator | Performs standard arithmetic calculations. | Enter expressions, calculate results and review history; works offline. | On-device, local |
| Unit Converter | Converts values across supported measurement units. | Select units, convert, review history and favourite common conversions; offline. | Units and locale; on-device |
| Currency | Explores and converts foreign-exchange rates. | Search currencies, convert amounts, view history, save favourites and share. | Country/currency/locale; delayed demo interbank feed |
| Stopwatch | Measures elapsed time and records laps. | Start, pause, reset and review lap/history information; offline. | On-device live timer |
| Timer | Counts down from a selected duration or preset. | Start, pause, reset, choose presets, keep history and configure completion notification. | On-device live timer |
| Age Calculator | Calculates exact age and date-based breakdown. | Enter birth date, calculate exact duration, keep history and share result. | Locale-aware on-device calculation |
| Focus Timer | Runs a focused work/Pomodoro-style session. | Start/pause/reset focus sessions, use presets, review history and enable completion alerts. | On-device live timer |
| Date Calculator | Adds/subtracts dates and calculates date differences. | Enter dates/durations, calculate, review history and work offline. | Locale/time-zone-aware calculation |

## 6. Planning tools — 5

| Feature | What it does | User capabilities | Context/data |
| --- | --- | --- | --- |
| Calendar | Organizes events across calendar and agenda views. | Navigate dates, search events, create/view entries, export and configure alerts; offline prototype. | Country, locale and time zone; on-device |
| Reminders | Manages reminders and their schedules. | Search, view status/repeat details and configure notifications; offline. | Locale/time zone; on-device |
| Notes | Stores and organizes personal notes. | Search, sort, favourite and export notes; offline. | On-device |
| To-dos | Manages tasks and completion state. | Add/view/check tasks, search, filter, sort and configure reminders; offline. | Locale/time zone; on-device |
| Events | Manages scheduled activities. | Search/filter events, view timing and configure alerts. | City, locale and time zone; on-device prototype |

## 7. Islamic tools — 17

All tools in this section are visible only when Islamic content is enabled.

| Feature | What it does | User capabilities | Context/data |
| --- | --- | --- | --- |
| Prayer Times | Shows daily prayers, current/next prayer and timing progress. | View schedule and countdown, share/export timings and configure prayer alerts; offline calculation. | City, country, time zone and locale; astronomical calculation |
| Qibla Compass | Shows the bearing toward the Kaaba. | View direction/instrument guidance and use location context offline. | City/position; computed great-circle bearing |
| Nearby Mosques | Displays nearby mosque results and map-style pins. | Search, filter and sort mosques; select a pin/result. | City/location/units; cached demo places directory |
| Prayer Tracker | Records completed prayers and streak/progress. | Mark prayers, inspect history/heatmap, export and configure reminders; offline. | Time zone; on-device |
| Ramadan | Summarizes Ramadan dates, fasting-day and prayer context. | View key timing/status, share and configure alerts; offline calculations. | City/country/time zone; Hijri and solar calculations |
| Fasting Tracker | Records fasts and progress. | Mark fasts, view history/stats and export; offline. | Time zone; on-device |
| Taraweeh | Helps find and compare Taraweeh locations/times. | Search/filter places and configure alerts. | City/units; cached demo directory |
| Ayah of the Day | Presents a daily Qur'anic verse. | Read, favourite and share; available offline. | Language; static Qur'an text with daily selection |
| Al-Qur’an | Provides Qur'an reading and navigation. | Browse by Surah/Juz/bookmarks, search, track reading history/progress, favourite and share; offline. | Language; static Qur'an text |
| Search the Qur’an | Searches Qur'anic text by word or reference. | Search, filter, review history, favourite results and work offline. | Language; static Qur'an text |
| Hadith | Provides a searchable Hadith reader. | Search/filter collections, favourite and share narrations; offline. | Language; static Hadith collection |
| Daily Duas | Provides a categorized dua library. | Search/filter categories, open duas, favourite and share; offline. | Language; static dua collection |
| 99 Names | Presents Asma ul Husna as a visual library. | Search, open details, favourite, review history and share; offline. | Language; static content |
| Islamic Calendar | Displays Hijri dates and Islamic events. | Navigate dates, export and configure event alerts; offline. | Country/locale/time zone; Umm al-Qura-style calculation |
| Tasbih | Provides a focused dhikr counter. | Increment/reset counter and review sessions/history; offline. | On-device |
| Zakat Calculator | Estimates zakat using assets, liabilities and nisab. | Enter values, calculate eligibility/amount, inspect breakdown, save history, share and export; offline logic with rate input. | Country/currency/locale; delayed demo metal rates |
| Faraid | Calculates Islamic inheritance distribution. | Enter estate/heirs, change heir counts, inspect shares, keep history, share and export. | Currency/locale; static classical-rule prototype |

## 8. Money tools — 15

| Feature | What it does | User capabilities | Context/data |
| --- | --- | --- | --- |
| Currency & Gold | Shows localized FX, gold and bullion information. | Search rates, inspect movements/history, favourite and share. | Country/currency/units/locale; delayed demo market data |
| Markets | Provides a detailed regional/global market explorer. | Switch asset classes, search, filter, sort, view charts/details/timeframes, favourite, share, export and configure alerts. | Country/currency/locale; delayed demo exchange feed |
| Fuel Prices | Shows localized pump-price information. | Compare fuel types, review history, share and configure price alerts. | Country/region/currency/units; daily demo regulator data |
| Fuel Cost | Estimates trip fuel consumption and cost. | Enter distance, efficiency and price; compare scenarios, save history and share; offline. | Country/currency/units; current demo pump price |
| Tax Calculator | Estimates income tax using selected country's slabs. | Enter income, calculate breakdown, keep history, share and export; offline calculation. | Supported country/currency/locale; annual statutory demo slabs |
| National Savings | Explores Pakistan National Savings products and returns. | Search/sort schemes, compare returns and review history. | Pakistan/currency/locale; weekly demo schedule |
| Prize Bonds | Shows bond denominations, draws and prize structures. | Search results/denominations, view history and configure draw alerts. | Pakistan/currency/locale; official-shaped demo draw data |
| Bills | Summarizes bills, due dates and payment status. | Search/filter/sort bills, inspect history, export and configure due alerts. | Country/currency/locale/time zone; device + demo provider data |
| Mobile Packages | Compares mobile operator packages. | Search, filter and sort by operator/type/value. | Pakistan/currency/locale; weekly demo tariffs |
| Loan / EMI | Calculates loan instalments and amortization. | Enter principal/rate/tenure, calculate EMI, inspect yearly schedule, save history, share and export; offline. | Currency/locale; on-device |
| Tip & Split | Splits a bill and calculates gratuity. | Enter bill, tip and people; calculate per-person amount, save history and share; offline. | Currency/locale; on-device |
| Lending Ledger | Tracks who owes or is owed money. | Search/filter/sort people and entries, review history, export and configure reminders. | Currency/locale; on-device |
| Installments | Tracks active purchase instalments. | Filter/sort plans, view schedules/history and configure due alerts. | Currency/locale; on-device |
| Committee | Tracks a rotating savings committee/ROSCA. | View pool, member order and history; export and configure reminders. | Currency/locale; on-device |
| Compound Interest | Projects investment growth over time. | Enter principal/contribution/rate/years, view chart/table, save history and share; offline. | Currency/locale; on-device |

## 9. Daily Life tools — 18

| Feature | What it does | User capabilities | Context/data |
| --- | --- | --- | --- |
| Weather | Shows current conditions and forecast-style information. | View temperature/feels-like/rain/wind, favourite location, share and configure weather alerts; cached offline display. | City/country/units/locale/time zone; delayed demo forecast |
| Air Quality | Shows AQI, pollutant status and health guidance. | View current level/history, share and configure warnings. | City/country/locale; delayed demo stations |
| Sun & Moon | Shows sunrise, sunset, daylight and lunar information. | View astronomical events/timeline and share; offline calculation. | City/country/time zone/locale; computed |
| Loadshedding | Shows electricity outage windows. | View daily schedule/history and configure outage notifications; cached offline display. | Pakistan city/region/time zone; daily demo distributor data |
| Trains | Tracks train routes, status, stations and fares. | Search/filter/sort, open train detail/timeline, review history, share and configure alerts. | Pakistan/city/currency/locale/time zone; intended live operator feed |
| Flights | Tracks arrivals/departures and flight progress. | Search/filter/sort, open status/timeline, review history, share and configure alerts. | Country/city/locale/time zone/units; intended live ADS-B feed |
| News | Provides localized and global news reading. | Search/filter, open stories, favourite, share and review reading history; offline cache capability. | Country/city/language/locale; intended live publisher feeds |
| Cricket | Shows match summary, scorecard and standings/details. | Filter competitions/views, inspect batting/bowling/table data, share, review history and configure alerts. | Country/language/locale; intended live match feed |
| Emergency | Provides local emergency services and direct call actions. | View services and activate real `tel:` links; works offline. | Country/region/city/language; static directory |
| QR Scanner | Provides a camera-oriented QR scan interface. | Request camera permission, simulate/perform scan flow and review scan history; offline capability. | Camera permission; live device input |
| Document Scanner | Provides document capture and export flow. | Request camera, capture/preview document, review history and export. | Camera permission; on-device |
| Passport Photos | Helps compose passport/ID photos to country specifications. | Capture/select, frame to requirements, review prior items and export. | Country/locale + camera permission; static specifications |
| Vehicle & Fines | Manages vehicle details, token/insurance dates and fine checks. | Search/filter vehicles, view history and configure reminders. | Pakistan/region/currency/locale; daily-shaped demo excise data |
| Media Saver | Organizes media-saving actions from a supplied link. | Enter a link, view saved/history items and use offline device records. | On-device prototype |
| WhatsApp Status | Presents an Android status-media library. | Request storage/media permission, browse items and review history offline. | Android/device permission; local prototype |
| Speed Test | Presents an internet-speed testing instrument. | Start a test and view ping/download/upload-style result/history. | Country/locale; intended nearest test server |
| World Clock | Compares time across cities and zones. | Search zones, select/favourite cities and compare current times offline. | Time zone/locale/language; IANA zones |
| Public Holidays | Shows country and regional holidays. | Search/filter holidays, navigate schedule and export; offline. | Country/region/locale/language; annual calendar data |

## 10. Personal tools — 22

| Feature | What it does | User capabilities | Context/data |
| --- | --- | --- | --- |
| Parcel Tracker | Shows shipment status and delivery timeline. | Search tracking items, inspect milestones/history, share and configure alerts. | Country/locale/time zone; delayed demo carrier data |
| Shopping List | Organizes grocery and shopping items. | Add/check items, search/filter and share list; offline. | Currency/locale; on-device |
| Birthdays | Tracks birthdays and upcoming dates. | Search people/dates and configure reminders; offline. | Locale/time zone; on-device |
| Daily Streak | Summarizes consistency across tracked activity. | View streak/history and configure reminders; offline. | On-device |
| Recipes | Provides a searchable visual recipe library. | Search/filter, open recipes, favourite and share; offline. | Units/locale/language; static recipe data |
| Meal Planner | Organizes meals across a week. | Navigate schedule, search, plan/export meals and work offline. | Units/locale; on-device |
| Alarms | Manages scheduled alarms. | View/toggle alarms and configure notification behaviour; offline. | Time zone/locale; on-device |
| Learning & Growth | Tracks courses or learning progress. | Search, favourite, record progress/history and work offline. | On-device |
| Documents | Organizes private document records. | Search/filter/sort, inspect records, export and configure expiry reminders; offline. | Country/locale; sensitive on-device demo store |
| Vaccinations | Tracks vaccination records and due dates. | Filter records, export and configure due reminders; offline. | Country/locale; sensitive on-device demo store |
| Health Records | Organizes private reports and health entries. | Search/filter/sort records, export and configure reminders; offline. | Country/currency/locale; sensitive on-device demo store |
| Play | Provides a small offline game/puzzle library. | Browse/open activities, favourite and review history. | On-device |
| Baby Budget | Summarizes baby-related spending. | View category breakdown/history and export; offline. | Currency/locale; on-device |
| Habits | Tracks daily habits and streaks. | Mark today, inspect history/heatmap/insights, export and configure reminders; offline. | Time zone/locale; on-device |
| Water | Tracks daily hydration. | Add intake, view goal/progress/history and configure reminders; offline. | Units/locale; on-device |
| BMI Calculator | Calculates body mass index from height and weight. | Enter measurements, view classification and retain history; offline. | Units/locale; on-device |
| Cycle Tracker | Tracks menstrual-cycle dates and predictions. | Record dates, inspect calendar/history and configure reminders; offline. | Locale/time zone; sensitive on-device demo store |
| Pregnancy | Shows pregnancy week, milestones and appointment-style items. | View progress/history and configure reminders; offline. | Locale/time zone/units; sensitive on-device demo store |
| Expenses | Summarizes transactions and spending categories. | Search/filter/sort, view charts/history, share and export; offline. | Country/currency/locale/time zone; sensitive on-device |
| Savings Goals | Tracks savings targets and progress. | View goals/history, share/export and configure contribution reminders; offline. | Currency/locale; sensitive on-device |
| Subscriptions | Tracks recurring subscriptions and renewal dates. | Search/filter/sort, inspect history, export and configure renewal alerts. | Currency/locale/time zone; sensitive on-device |
| Medication | Tracks medicines, doses and schedules. | View dose timeline/history, export and configure reminders; offline. | Time zone/locale; sensitive on-device demo store |

## 11. Availability summary

- **Islamic-only:** Prayer Times, Qibla, Nearby Mosques, Prayer Tracker, Ramadan, Fasting Tracker, Taraweeh, Ayah, Qur'an, Qur'an Search, Hadith, Duas, 99 Names, Hijri Calendar, Tasbih, Zakat and Faraid.
- **Pakistan-only in the current catalogue:** National Savings, Prize Bonds, Mobile Packages, Loadshedding, Trains and Vehicle & Fines. Tax supports multiple configured countries.
- **Android-oriented:** WhatsApp Status.
- **Permission-oriented:** Qibla/nearby location, QR Scanner, Document Scanner, Passport Photos and WhatsApp Status.
- **Sensitive:** Documents, Vaccinations, Health Records, Cycle Tracker, Pregnancy, Expenses, Savings Goals, Subscriptions and Medication.

Availability is enforced not only in the Tools catalogue but also in Home recommendations, global search, recent tools, notifications, related tools and deep links.

## 12. Current production-readiness boundaries

### Working as a prototype

- Complete interface compositions for all 85 tools.
- Personalization and eligibility rules.
- Calculations and formatted demonstration data.
- Local preferences, history and account simulation.
- Navigation, Back stacks, sheets and dialogs.
- Localization, RTL, dark mode and accessibility semantics.
- Notification-centre logic and browser-permission flow.
- Automated verification and regression coverage.

### Still required for production

- Backend APIs and database.
- Secure real authentication and authorization.
- Real email/phone verification and password recovery.
- Live weather, finance, transport, sports, news, places and carrier providers.
- Secure document/health storage and compliance controls.
- Real cloud sync and multi-device conflict resolution.
- Production push-notification service.
- Payment/bill-payment integrations if money movement is intended.
- Analytics, monitoring, audit logs, abuse controls and rate limiting.
- Provider-specific caching, offline and freshness policies.

## 13. Capability acceptance rule

A feature should not claim a capability merely because a button can be drawn. Search must actually narrow results; filters and sorting must change content; calculators must recompute; history must persist at its promised scope; sharing/export must produce meaningful output; notifications must respect eligibility and privacy; and live/provider labels must not be used until real integrations exist.
