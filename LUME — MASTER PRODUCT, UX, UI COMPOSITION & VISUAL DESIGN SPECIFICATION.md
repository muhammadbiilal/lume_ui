# LUME
## Master Product, UX, UI Composition & Visual Design Specification
### Premium Information-Rich Super-App — 2027 Edition

**Document role:** Single source of truth for Lume product design, UX, UI composition, visual styling, tool behavior, regional adaptation, navigation, content hierarchy, and screen generation.

**Status:** Master specification

---

# 1. PURPOSE OF THIS DOCUMENT

This document is the authoritative specification for designing and generating Lume.

It defines not only **what tools exist**, but exactly how each tool should behave and how its interface should be composed.

Any designer, developer, AI UI generator, design system, or implementation process working on Lume should use this document as the primary product specification.

The objective is to prevent every tool from becoming the same generic screen.

Lume tools must have interfaces appropriate to the **type of information and task they perform**.

A financial market tool should feel like a financial data terminal.

A prayer tool should feel like a calm spiritual dashboard.

A flight tracker should feel like a live operational tracking interface.

A recipe tool should feel like a visual culinary workspace.

A document tool should feel like a secure personal records manager.

A calculator should feel fast and focused rather than unnecessarily complex.

---

# 2. PRODUCT VISION

Lume is a premium daily-life super-app that brings together:

- faith
- money
- markets
- travel
- transport
- weather
- utilities
- news
- productivity
- personal organization
- household management
- health-related personal records
- learning
- lifestyle
- everyday calculations

into one coherent application.

Lume should feel:

**Premium + Intelligent + Useful + Information-rich + Personal + Calm + Modern**

It must NOT feel:

- like a collection of unrelated mini-apps
- like a basic CRUD application
- like a generic dashboard template
- excessively minimalist
- visually noisy
- dependent on giant hero images
- composed entirely of cards
- composed entirely of lists
- like every tool was generated from the same template

---

# 3. CORE DESIGN PHILOSOPHY

## 3.1 Information-rich, not cluttered

Lume should expose useful information without overwhelming the user.

The design hierarchy is:

**Primary information → Supporting information → Context → Secondary actions → Advanced information**

Do not hide important information simply to make the interface look minimal.

Do not expose every available field simultaneously if it harms comprehension.

---

# 4. THE GOLDEN RULE FOR DATA-RICH SCREENS

When meaningful data exists, show meaningful data.

For example, a market security row should not merely be:

> Apple — $238 — +1.4%

If the available information supports it, a richer row should contain:

- company/logo
- ticker
- company name
- market/exchange
- current price
- currency
- absolute change
- percentage change
- direction indicator
- sparkline
- volume or market cap where relevant
- market/session status

The goal is not maximum data.

The goal is **maximum useful information density**.

---

# 5. INFORMATION HIERARCHY

Every screen must define:

### Level 1 — Primary
What the user came to see.

### Level 2 — Supporting
Information required to understand Level 1.

### Level 3 — Context
Freshness, source, location, comparison, historical context, status.

### Level 4 — Actions
What the user can do with the information.

### Level 5 — Advanced
Detailed information available through expansion, detail screens, sheets, tabs or secondary sections.

---

# 6. SCREEN DENSITY LEVELS

Every tool must declare a density level.

## Low Density

For:

- focused calculators
- simple converters
- QR scanner
- emergency actions
- simple timers

Composition:

- clear title
- one primary interaction
- minimal supporting content
- strong CTA

---

## Medium Density

For:

- notes
- shopping lists
- birthdays
- basic habits
- simple personal tools

Composition:

- summary/header
- primary content list
- compact actions
- occasional supporting cards

---

## High Density

For:

- weather
- prayer
- expenses
- news
- bills
- savings
- Quran
- calendar

Composition:

- summary
- multiple information blocks
- filters/tabs where useful
- lists
- charts or timelines where useful
- contextual actions

---

## Very High Density

For:

- markets
- flights
- trains
- health records
- financial trackers
- document management
- advanced analytics

Composition:

- summary strip
- dense data list/table
- filters
- search
- contextual controls
- visualizations
- detail views
- freshness/source indicators
- advanced information

---

# 7. LUME UI COMPOSITION PRINCIPLE

Every screen should be assembled from meaningful sections.

Recommended structure:

```text
Screen
 ├── Navigation Header
 ├── Context / Location / Account State
 ├── Summary / Hero Data
 ├── Primary Control
 ├── Primary Information Block
 ├── Supporting Information
 ├── Visualization
 ├── Detailed List / Table / Timeline
 ├── Secondary Actions
 └── Related Tools
```

Not every screen requires every section.

The tool specification determines which sections are appropriate.

---

# 8. GLOBAL SCREEN STRUCTURE

## Standard Tool Screen

```text
┌─────────────────────────────────┐
│ Back     Tool Title       Action │
├─────────────────────────────────┤
│ Context / location / freshness  │
├─────────────────────────────────┤
│ Primary summary                 │
├─────────────────────────────────┤
│ Controls / filters / tabs       │
├─────────────────────────────────┤
│ Main information                │
│                                 │
│ Supporting information          │
│                                 │
│ Visualization                   │
│                                 │
│ Detailed content                │
└─────────────────────────────────┘
```

---

# 9. NAVIGATION RULES

## Normal Screens

Use:

**Back navigation**

Do not place an X icon merely because the screen is full-screen.

---

## X / Close Icon

Use X only when the user is dismissing a temporary surface.

Appropriate:

- modal
- fullscreen viewer
- image viewer
- temporary overlay
- scanner result overlay
- temporary workflow
- transient presentation

---

## Bottom Sheets

Bottom sheets should normally NOT contain an X button.

Dismiss using:

- drag
- system back
- outside tap where appropriate

Use an X only when the sheet represents a persistent modal workflow where explicit close is valuable.

---

# 10. GLOBAL APP LIFECYCLE

## Launch

```text
Native Splash
      ↓
Branded Lume Launch
      ↓
Initialize App
      ↓
Restore Local State
      ↓
Determine User State
```

---

## First-Time User

```text
Launch
 ↓
Onboarding
 ↓
Personalization
 ↓
Permissions when necessary
 ↓
Home
```

---

## Returning User

```text
Launch
 ↓
Restore State
 ↓
Home
```

Do not force returning users through onboarding again.

---

## Deep Link / Notification

```text
Launch
 ↓
Initialize
 ↓
Restore State
 ↓
Open Requested Destination
```

The splash must never become an unnecessarily long loading screen.

---

# 11. LUME BRANDING

Lume branding must be consistent throughout the application.

Brand assets include:

- primary Lume logo
- compact logo
- app icon
- launch artwork
- onboarding artwork
- category illustrations
- tool icons
- empty-state illustrations
- sharing cards
- report branding
- generated document branding
- notification branding
- feature imagery

Branding must not overwhelm functional screens.

---

# 12. VISUAL DESIGN LANGUAGE

## Overall Style

Lume should use:

- refined surfaces
- strong typography hierarchy
- controlled spacing
- subtle depth
- restrained borders
- meaningful icons
- data visualization
- contextual imagery
- clear status indicators
- premium motion
- strong alignment

Avoid:

- excessive rounded cards
- random gradients
- excessive shadows
- decorative noise
- huge empty spaces
- tiny unreadable text
- inconsistent corner radii
- inconsistent spacing

---

# 13. TYPOGRAPHY

Use a clear typographic hierarchy:

### Display
Major values and hero metrics.

### Heading
Section and screen titles.

### Body
Primary descriptive information.

### Supporting
Metadata, timestamps, sources.

### Micro
Very small metadata only when necessary.

Critical values must never depend on micro typography.

---

# 14. SPACING SYSTEM

Use a consistent spacing scale.

Recommended base unit:

**4 px**

Typical spacing:

- 4
- 8
- 12
- 16
- 20
- 24
- 32
- 40
- 48

Use larger spacing to establish hierarchy rather than arbitrary gaps.

---

# 15. CORNER RADIUS

Use a limited radius system.

Suggested:

- small controls: 8 px
- standard cards: 12–16 px
- prominent surfaces: 16–20 px
- pills: fully rounded

Do not use a different radius for every component.

---

# 16. ICONOGRAPHY

Icons must communicate function.

Use:

- consistent stroke/weight
- consistent optical sizing
- platform-appropriate touch targets
- filled states for selected navigation where useful
- outlined states for inactive actions

Do not use decorative icons that add no meaning.

---

# 17. IMAGERY

Images are used when they add:

- context
- recognition
- emotional value
- geographic context
- product recognition
- food recognition
- travel context
- article context
- spiritual atmosphere
- onboarding storytelling

Do not force images into:

- calculators
- dense financial tables
- utility tools
- operational data interfaces

---

# 18. DATA VISUALIZATION

Use visualization when it improves understanding.

Possible visualizations:

- line charts
- area charts
- bar charts
- donut charts
- sparklines
- progress rings
- progress bars
- heatmaps
- timelines
- maps
- route maps
- candlestick charts
- comparison charts

Every visualization must answer a question.

Do not add charts simply to make a screen look sophisticated.

---

# 19. DATA FRESHNESS

Live or changing data must communicate freshness.

Examples:

- Updated 30 sec ago
- Live
- Delayed 15 min
- Updated today
- Last synced
- Source: provider

Freshness indicators must be visually subordinate but discoverable.

---

# 20. COUNTRY / REGION ARCHITECTURE

Lume is globally oriented.

Pakistan is a regional configuration, not the definition of the application.

The user's country/region can influence:

- currency
- exchanges
- markets
- fuel prices
- taxes
- emergency numbers
- units
- public holidays
- news
- transport
- weather defaults
- prayer calculation conventions
- languages
- address formats
- phone formats
- mobile packages
- financial products

Users must be able to change region when appropriate.

---

# 21. GLOBAL MARKETS MODEL

Markets must not be hardcoded to PSX.

## Pakistan

Possible defaults:

- PSX
- KSE-100
- KSE-30
- KMI-30
- local equities
- PKR

## United States

Possible defaults:

- NYSE
- NASDAQ
- S&P 500
- Dow Jones
- Russell indexes
- USD

## United Kingdom

Possible defaults:

- LSE
- FTSE 100
- FTSE 250
- GBP

## Other Countries

Use their relevant:

- exchanges
- indices
- currencies
- market sessions

Global markets remain available regardless of local region.

---

# 22. TOOL SCREEN ARCHETYPES

Lume uses specialized screen archetypes.

## A. Dashboard

Best for:

- prayer
- weather
- expenses
- savings
- bills
- habits

Composition:

```text
Header
Summary
Key metrics
Primary action
Supporting cards
Chart
Recent activity
Related tools
```

---

## B. Data Explorer

Best for:

- markets
- fuel
- currency
- national savings

Composition:

```text
Header
Region / source
Summary metrics
Search
Filters
Tabs
Rich data rows
Charts
Detail view
```

---

## C. Live Tracking

Best for:

- flights
- trains
- weather radar

Composition:

```text
Header
Live status
Map
Filters
Live list
Selected item
Timeline
Refresh/freshness
```

---

## D. Reader

Best for:

- Quran
- Hadith
- News
- documents

Composition:

```text
Header
Context
Content
Reader controls
Progress
Bookmarks
Secondary actions
```

---

## E. Calculator

Best for:

- tax
- EMI
- fuel cost
- tip
- BMI
- age
- unit conversion

Composition:

```text
Header
Inputs
Primary calculation
Result
Breakdown
History
Save/share
```

---

## F. Manager

Best for:

- documents
- health records
- subscriptions
- lending
- installments

Composition:

```text
Summary
Search
Filters
Grouped records
Status
Detail
Actions
History
```

---

# 23. CORE TOOL BLUEPRINT MATRIX

The following matrix defines what each tool should show and how it should be composed.

---

# 24. PRAYER & ISLAM

## 24.1 Prayer Times

**Density:** High  
**Archetype:** Spiritual Dashboard

### Primary information

- current location
- current prayer
- next prayer
- countdown
- today's five prayer times
- sunrise/sunset

### Secondary information

- prayer method
- calculation convention
- madhab/asr method
- date
- location

### UI composition

```text
Header
Location + date
Next Prayer Hero
Countdown
Five-Prayer Timeline
Sunrise / Sunset
Prayer Method
Upcoming Days
Related Tools
```

### Visual treatment

Calm, focused, spacious.

Use a subtle time/progress visualization rather than a generic chart.

---

## 24.2 Qibla Compass

**Density:** Medium  
**Archetype:** Instrument

Show:

- direction
- degrees
- distance to Kaaba
- calibration state
- location

Composition:

```text
Header
Compass
Qibla Direction
Distance
Calibration
Location
```

---

## 24.3 Nearby Mosques

**Density:** High  
**Archetype:** Map + List

Show:

- mosque name
- distance
- walking/driving time
- prayer availability
- address
- rating where available
- facilities where available

Composition:

```text
Header
Map
Search
Distance Filters
Mosque List
Selected Mosque
Directions
```

---

## 24.4 Prayer Tracker

**Density:** High  
**Archetype:** Habit Dashboard

Show:

- today's completion
- streak
- monthly completion
- prayer breakdown
- missed prayers
- qada planning

Composition:

```text
Summary
Today's Five Prayers
Completion Ring
Calendar Heatmap
Statistics
Qada Planner
Insights
```

---

## 24.5 Ramadan

**Density:** High  
**Archetype:** Seasonal Dashboard

Show:

- Ramadan day
- days remaining
- suhoor
- iftar
- fasting status
- prayer information
- Quran progress
- charitable goals

Composition:

```text
Ramadan Header
Day / Countdown
Suhoor + Iftar
Prayer Timeline
Fasting Progress
Quran Progress
Goals
Duas
```

---

## 24.6 Fasting Tracker

**Archetype:** Tracker

Show:

- fasting days
- streak
- monthly calendar
- voluntary/obligatory classification
- missed fasts
- progress

---

## 24.7 Taraweeh

**Archetype:** Schedule + Location

Show:

- nearby mosques
- Taraweeh times
- rakaat information where available
- distance
- directions
- schedule

---

## 24.8 Ayah of the Day

**Archetype:** Reader Card

Show:

- Arabic
- translation
- transliteration where enabled
- surah/ayah
- recitation
- tafsir
- bookmark
- share

---

## 24.9 Al-Quran

**Density:** High  
**Archetype:** Reader + Library

Show:

- continue reading
- surah list
- juz
- reading progress
- bookmarks
- notes
- recitation
- translations
- tafsir

Composition:

```text
Continue Reading
Progress
Search
Surah/Juz Navigation
Reading Area
Reader Controls
Bookmarks
Notes
```

---

## 24.10 Search the Quran

**Archetype:** Search Explorer

Show:

- search field
- Arabic results
- translations
- surah
- ayah number
- matched terms
- filters
- saved results

---

## 24.11 Hadith

**Archetype:** Library + Reader

Show:

- collection
- book
- hadith
- narrator/metadata where available
- grading/source where available
- Arabic
- translation
- bookmark/share

---

## 24.12 Daily Duas

**Archetype:** Category Library

Show:

- categories
- recommended dua
- Arabic
- translation
- transliteration
- source
- audio
- favorites

---

## 24.13 99 Names of Allah

**Archetype:** Learning Grid + Detail

Show:

- Arabic name
- transliteration
- meaning
- explanation
- audio
- favorites
- progress

---

## 24.14 Islamic Calendar

**Archetype:** Calendar

Show:

- Gregorian date
- Hijri date
- Islamic events
- Ramadan
- important dates
- conversion

---

## 24.15 Tasbih

**Archetype:** Focus Interaction

Show:

- counter
- selected dhikr
- target
- progress
- session history
- haptic feedback

Keep this screen focused.

---

## 24.16 Zakat Calculator

**Density:** High  
**Archetype:** Calculator + Financial Breakdown

Show:

- cash
- gold
- silver
- investments
- business assets
- liabilities
- nisab
- zakat rate
- final amount
- calculation breakdown

---

## 24.17 Faraid

**Archetype:** Guided Calculator

Show:

- estate
- debts
- heirs
- inheritance rules
- distribution
- explanation

Use progressive steps instead of presenting every field simultaneously.

---

# 25. MONEY & RATES

## 25.1 Currency & Gold

**Density:** High  
**Archetype:** Data Explorer

Show:

- selected currencies
- buy/sell where applicable
- open/interbank rates where available
- gold price
- silver price
- per-tola/per-gram units
- source
- timestamp
- historical chart

Composition:

```text
Region / Market
Current Rates
Gold/Silver
Converter
Historical Chart
Source/Freshness
```

---

# 26. MARKETS

**Density:** Very High
**Archetype:** Financial Data Explorer
**Composition:** Approved reference composition — see §26.13

This is one of Lume's most information-rich screens, and one of the few with an
**approved reference composition**. The composition below is not a suggestion
derived from the archetype: it is the specification. See §123 — Reference
Composition Fidelity.

**Primary purpose**

Let the user understand the current state of the markets at a glance, move
between asset classes, discover securities, inspect performance and follow
what they care about.

---

## 26.1 Global markets context

Markets is global and country-aware. The user's country selects the default
local market; global markets stay reachable from anywhere.

| Country | Exchange | Indices | Currency |
|---|---|---|---|
| Pakistan | Pakistan Stock Exchange | KSE-100, KSE-30, KMI-30, All Share | PKR |
| United States | NYSE · NASDAQ | S&P 500, Nasdaq Composite, Dow Jones, Russell 2000 | USD |
| United Kingdom | London Stock Exchange | FTSE 100, FTSE 250, FTSE All-Share | GBP |
| UAE | DFM · ADX | DFM General, ADX General | AED |
| Saudi Arabia | Saudi Exchange | TASI, Nomu | SAR |
| India | NSE · BSE | NIFTY 50, SENSEX, Bank NIFTY | INR |
| Elsewhere | the local exchange | its own index family | its own currency |

The interface must therefore expose a way to change **country/region,
exchange and local/global market**. Pakistan is a configuration, never the
definition of the product.

---

## 26.2 Market-type navigation — the primary control

The primary Markets interface uses a prominent segmented control near the top
of the content:

```text
[ Stocks ] [ Indices ] [ Forex ] [ Commodities ]
```

Additional classes where the market supports them: **ETFs, Crypto, Bonds,
Futures**.

This is a major navigation element, not a filter chip row. It appears
**before** the primary market content. The selected class must be
unmistakable.

Do **not** place an indices list directly below the header without this
control. Doing so makes Indices the whole product rather than one asset class
within it.

---

## 26.3 Hero — the primary market summary

Immediately after the market-type selector, show the most important
market, index or security for the selected class:

```text
┌───────────────────────────────────────┐
│ ◉  KSE 100                          › │
│    Karachi Stock Exchange             │
│                                       │
│    72,348.21                          │
│    ▲ +1,245.32  (+1.75%)             │
│                          ╱╲╱╲╱╲╱╲    │
│                                       │
│  1D   1W   1M   3M   1Y   5Y         │
└───────────────────────────────────────┘
```

Carries: logo, name, exchange, current value, absolute change, percentage
change, direction, a real trend chart and a timeframe selector.

The timeframe selector must change the chart. The hero should read as a
financial market summary, not as a generic card with a number in it.

---

## 26.4 Top assets — discovery

A prominent discovery section, titled for the selected asset class, with a
**See all** affordance:

```text
Top Stocks                          See all
```

Each row carries every field the dataset has (§84, §114):

```text
[Logo]  HBL                       Rs. 142.50
        Habib Bank Limited           +2.31%
        PSX · Banking · Vol 8.9M    ╱╲╱╲╱╲
```

Never reduce a row to name + price + percentage.

Where available add volume, market cap, exchange and session status.

---

## 26.5 Market overview

Below the primary content, a Market Overview section:

```text
┌───────────────────────────────────────┐
│ Market Overview                       │
│                                       │
│ Total Market Cap   Volume   Adv/Dec   │
│ Rs. 9.8T           512.4M   198 / 102 │
│ ▲ +1.32%           ▲ +18.7%           │
└───────────────────────────────────────┘
```

Metrics adapt to the selected exchange and asset class: market cap, volume,
turnover, trades, advancing, declining, unchanged, gainers, losers, breadth.

Show only what the market actually provides. Never pad the section with
metrics that are unavailable.

---

## 26.6 Indices

Indices is a **dedicated class within the market-type control**, not the
default body of the screen. Each row carries name, description, exchange,
value, absolute change, percentage change, direction and a sparkline.

---

## 26.7 Search

Markets provides search across company, ticker, index, currency pair,
commodity and exchange.

Search must be discoverable without displacing the hero. It belongs in the
header or immediately above the asset list — not as the screen's opening
element.

---

## 26.8 Filters

Filters adapt to the selected market type.

| Class | Filters |
|---|---|
| Stocks | exchange, sector, market cap, gainers, losers, volume |
| Indices | country, exchange, index family |
| Forex | currency, major/minor/exotic, region |
| Commodities | category, contract/type, unit |

Never expose a filter that does not apply to the current class.

---

## 26.9 Asset detail

Selecting an asset opens a detailed financial screen.

**Stock:** logo, name, ticker, exchange, price, absolute and percentage
change, chart, timeframe selector, open, high, low, previous close, volume,
market cap, 52-week high/low, related indices, session status, source and
freshness.

**Currency pair:** pair, bid/ask where available, rate, change, historical
chart, inline conversion.

**Commodity:** price, unit, contract/type, change, historical chart.

---

## 26.10 Market states

Markets must have designed states for:

live · delayed · stale · loading · empty · connection failure ·
market closed · market opening soon · market holiday

These are compositions, not error strings. "Market closed" says when it
reopens; "empty" offers a retry; "loading" uses skeletons shaped like the
content that is coming.

---

## 26.11 Market switching

A **Change Market** interaction opens a bottom sheet containing country,
region, exchange and a global option. The choice persists.

```text
┌───────────────────────────────────────┐
│ Change Market                       ✕ │
│                                       │
│ 🇵🇰  Pakistan (Default)            ✓ │
│ 🇺🇸  United States                    │
│ 🇬🇧  United Kingdom                   │
│ 🇦🇪  UAE                              │
│ 🇸🇦  Saudi Arabia                     │
│ 🌐  Global markets                    │
└───────────────────────────────────────┘
```

---

## 26.12 Light and dark

Markets has both. Dark mode is designed, not inverted: charts, status
indicators, surfaces, rows and text hierarchy are re-authored for a dark
ground (§58).

---

## 26.13 Reference composition

This is the approved order. It is binding (§123).

```text
Header  (back · title · subtitle · share · overflow)
   ↓
Market context / selected region
   ↓
Stocks │ Indices │ Forex │ Commodities        ← primary control
   ↓
Primary market / index hero
   ↓
Trend chart + timeframe selector
   ↓
Top Stocks / Top Assets          (See all)
   ↓
Market Overview
   ↓
Additional market data
   ↓
Search / discovery
   ↓
Bottom navigation
```

The following composition must **not** be used:

```text
Market status → Turnover / Volume / Trades → Indices → Search
```

---

## 26.14 Visual direction

Markets should read as a premium financial-data product: information-dense,
structured, analytical, clean and readable. Use rich data rows, sparklines,
financial charts, compact metrics, segmented controls, status badges, company
and exchange marks, and restrained direction indicators.

Markets must not look like a generic dashboard assembled from three large
cards.

---

## 26.15 Responsive

Small screens keep the market-type selector, the hero and the rich rows, and
collapse secondary metrics. Large screens expand the chart, expose more
metrics, widen the tables and add columns — they do not stretch mobile cards
(§116).

---

# 27. Fuel Prices

**Density:** Medium/High  
**Archetype:** Regional Data Explorer

Show:

- fuel type
- current price
- unit
- region
- effective date
- previous price
- change
- historical trend
- nearby stations where available

---

# 28. Fuel Cost

**Archetype:** Calculator

Inputs:

- distance
- fuel economy
- fuel type
- price

Output:

- total fuel
- total cost
- cost per distance
- comparison scenarios

---

# 29. Tax Calculator

**Density:** High  
**Archetype:** Guided Calculator

Show:

- income
- deductions
- taxable income
- brackets
- estimated tax
- effective rate
- breakdown

Country-specific rules must be configurable.

---

# 30. National Savings

**Archetype:** Financial Data Explorer

Show:

- product types
- current rates
- maturity
- payout frequency
- eligibility
- historical rates
- expected return

---

# 31. Prize Bonds

**Archetype:** Search + Results

Show:

- bond denomination
- draw number
- draw date
- prize tiers
- winning numbers
- search/check function
- history

---

# 32. Bills

**Density:** High  
**Archetype:** Financial Dashboard

Show:

- upcoming bills
- overdue bills
- total due
- due dates
- provider
- payment status
- history

Composition:

```text
Due Summary
Upcoming
Overdue
Providers
Bills List
Payment Actions
History
```

---

# 33. Mobile Packages

**Archetype:** Comparison Explorer

Show:

- provider
- package name
- data
- minutes
- SMS
- validity
- price
- activation
- expiry

Use comparison rows rather than oversized cards.

---

# 34. Loan / EMI

**Archetype:** Calculator + Breakdown

Show:

- principal
- rate
- tenure
- monthly payment
- total interest
- total repayment
- amortization
- comparison

---

# 35. Tip & Split

**Archetype:** Focused Calculator

Show:

- bill
- tip
- people
- per-person amount
- custom split

Keep it fast.

---

# 36. Lending Ledger

**Archetype:** Personal Financial Manager

Show:

- total lent
- total borrowed
- outstanding
- due dates
- people
- transactions
- reminders

---

# 37. Installments

**Archetype:** Financial Manager

Show:

- active plans
- monthly payment
- remaining amount
- next payment
- progress
- merchant
- schedule

---

# 38. Committee

**Archetype:** Group Finance Manager

Show:

- committee amount
- members
- monthly contribution
- schedule
- payout order
- current cycle
- payment status
- history

---

# 39. DAILY LIFE

# 39.1 Calendar

**Density:** High  
**Archetype:** Calendar + Agenda

Show:

- month/week/day
- events
- tasks
- reminders
- birthdays
- holidays
- Islamic dates

Composition:

```text
Calendar Header
Date Navigation
Calendar
Agenda
Tasks
Events
Quick Add
```

---

# 40. Weather

**Density:** High  
**Archetype:** Environmental Dashboard

Show:

- current temperature
- feels-like
- condition
- high/low
- humidity
- wind
- visibility
- pressure where available
- sunrise/sunset
- hourly 24h
- 5-day forecast
- AQI
- alerts

Composition:

```text
Location
Current Conditions
Temperature
Hourly Timeline
5-Day Forecast
AQI
Sun/Moon
Alerts
```

---

# 41. Loadshedding

**Archetype:** Schedule Dashboard

Show:

- area
- current status
- next outage
- duration
- daily schedule
- historical reliability
- notification

---

# 42. Trains

**Density:** Very High  
**Archetype:** Live Tracking

Show:

- train roster
- departure
- arrival
- status
- delay
- platform where available
- route
- station timeline
- speed
- next stop
- map
- freshness

Composition:

```text
Search
Departure Selector
Train Status Summary
Train List
Selected Train
Route Map
Station Timeline
Live Data
Reminder
```

---

# 43. Flights

**Density:** Very High  
**Archetype:** Live Tracking + Map

Show:

- flight number
- airline
- aircraft
- departure
- arrival
- status
- scheduled time
- actual time
- delay
- position
- altitude
- speed
- distance
- ETA
- aircraft type

Composition:

```text
Airport / Flight Search
Live Board
Filters
Map
Flight List
Selected Flight
Aircraft Data
Route
Timeline
```

---

# 44. News

**Density:** High  
**Archetype:** Editorial Feed

Show:

- category
- headline
- image
- source
- publication time
- reading time
- saved state
- read/unread
- related stories

Composition:

```text
Top Stories
Categories
Search
Story Feed
Source Controls
Saved
Article Reader
Related Stories
```

Use images heavily here because they provide real information/context.

---

# 45. Cricket

**Density:** High  
**Archetype:** Live Sports Dashboard

Show:

- live match
- teams
- score
- wickets
- overs
- run rate
- required rate
- batsmen
- bowlers
- match status
- fixtures
- results
- standings

Use live score hierarchy and compact statistical rows.

---

# 46. Emergency

**Density:** Low  
**Archetype:** Action Dashboard

Show:

- emergency services
- local emergency numbers
- location
- nearest services
- quick call actions
- medical information shortcut if configured

Actions must be extremely obvious.

---

# 47. Unit Converter

**Density:** Low  
**Archetype:** Calculator

Show:

- category
- input
- output
- swap
- favorites
- recent conversions

---

# 48. BMI Calculator

**Archetype:** Calculator

Show:

- height
- weight
- BMI
- category
- reference range
- history

---

# 49. Age Calculator

**Archetype:** Calculator

Show:

- date of birth
- age
- months
- days
- next birthday
- elapsed time

---

# 50. QR Scanner

**Archetype:** Scanner

Composition:

```text
Camera
Scan Frame
Detected Content
Action
History
```

---

# 51. Document Scanner

**Archetype:** Camera Workflow

Show:

- camera
- edge detection
- capture
- crop
- enhancement
- reorder
- PDF export

---

# 52. Passport Photos

**Archetype:** Guided Image Tool

Show:

- country
- photo dimensions
- capture/import
- alignment
- background guidance
- preview
- export

---

# 53. Vehicle & Fines

**Archetype:** Vehicle Manager

Show:

- vehicle
- registration
- fines
- expiry
- taxes
- insurance
- documents
- reminders

---

# 54. Media Saver

**Archetype:** Utility Manager

Show:

- detected media
- source
- preview
- download/save
- history
- storage

---

# 55. WhatsApp Status

**Archetype:** Media Utility

Show:

- detected statuses
- image/video preview
- save
- history
- storage

---

# 56. Speed Test

**Archetype:** Live Instrument

Show:

- ping
- download
- upload
- server
- connection type
- historical tests

Use animated measurement visualization.

---

# 57. PERSONAL TOOLS

# 57.1 To-dos

**Archetype:** Task Manager

Show:

- today
- overdue
- upcoming
- priorities
- categories
- due dates
- completion
- recurring tasks

---

# 58. Notes

**Archetype:** Workspace

Show:

- pinned notes
- recent notes
- folders
- search
- tags
- attachments
- editing

---

# 59. Parcel Tracker

**Archetype:** Tracking Timeline

Show:

- tracking number
- carrier
- current status
- location
- ETA
- timeline
- delivery events

---

# 60. Shopping List

**Archetype:** Checklist

Show:

- lists
- categories
- items
- quantities
- checked state
- estimated total
- shared list

---

# 61. Birthdays & Anniversaries

**Archetype:** Timeline + Calendar

Show:

- upcoming dates
- countdown
- person
- event type
- reminders
- history

---

# 62. Daily Streak

**Archetype:** Habit Dashboard

Show:

- current streak
- longest streak
- calendar
- milestones
- completion rate

---

# 63. Recipes

**Density:** High  
**Archetype:** Visual Library + Reader

Show:

- recipe image
- title
- cuisine
- preparation time
- cooking time
- servings
- ingredients
- nutrition where available
- steps
- favorites

---

# 64. Meal Planner

**Archetype:** Planner

Show:

- weekly meals
- breakfast/lunch/dinner
- calories where configured
- recipes
- shopping integration
- substitutions

---

# 65. Alarms

**Archetype:** Time Manager

Show:

- alarms
- recurring schedules
- labels
- active/inactive
- next alarm
- quick actions

---

# 66. Learning & Growth

**Archetype:** Learning Dashboard

Show:

- current goals
- courses/topics
- progress
- streak
- recent learning
- milestones
- recommended content

---

# 67. Documents

**Density:** Very High  
**Archetype:** Secure Records Manager

Show:

- document categories
- expiry status
- upcoming expiry
- expired
- masked sensitive numbers
- attachments
- reminders
- search

Composition:

```text
Expiry Summary
Categories
Search
Documents
Status
Document Detail
Secure Viewer
Reminder
```

Sensitive information should be protected by device authentication where appropriate.

---

# 68. Vaccinations

**Archetype:** Health Timeline

Show:

- person
- vaccination
- date
- dose
- next due
- history
- reminders
- attachments

---

# 69. Health Records

**Density:** Very High  
**Archetype:** Personal Health Record Manager

Show:

- people
- conditions/events
- appointments
- reports
- medications where relevant
- documents
- expenses
- timelines

Composition:

```text
Person Selector
Health Summary
Timeline
Records
Documents
Appointments
Expenses
Reports
Export
```

---

# 70. Play

**Archetype:** Entertainment Library

Show:

- games/content
- recently played
- favorites
- categories
- progress

Keep this visually lighter.

---

# 71. Baby Budget

**Archetype:** Financial Planner

Show:

- monthly budget
- categories
- spending
- upcoming expenses
- trends
- goals

---

# 72. Habits

**Archetype:** Habit Dashboard

Show:

- habits
- streak
- completion
- weekly/monthly charts
- reminders
- insights

---

# 73. Water

**Archetype:** Health Tracker

Show:

- daily target
- consumed
- remaining
- intake timeline
- streak
- reminders

---

# 74. Cycle Tracker

**Archetype:** Calendar + Timeline

Show:

- current cycle
- calendar
- historical cycles
- predictions where appropriate
- notes
- reminders

Privacy must be prioritized.

---

# 75. Pregnancy

**Archetype:** Timeline Dashboard

Show:

- current week
- estimated milestone timeline
- appointments
- notes
- reminders
- educational information

Keep sensitive information private.

---

# 76. Expenses

**Density:** Very High  
**Archetype:** Financial Dashboard

Show:

- total spending
- income
- balance
- categories
- transactions
- daily/monthly trends
- budgets
- recurring expenses

Composition:

```text
Financial Summary
Spending Chart
Category Breakdown
Transactions
Budget Progress
Recurring
Insights
```

---

# 77. Savings Goals

**Density:** High  
**Archetype:** Goal Dashboard

Show:

- goals
- target amount
- current amount
- percentage
- remaining amount
- target date
- contribution history
- projected completion

Use progress visualization prominently.

---

# 78. Subscriptions

**Archetype:** Recurring Expense Manager

Show:

- active subscriptions
- monthly total
- annual total
- renewal date
- provider
- price
- category
- cancellation reminders

---

# 79. Medication Reminders

**Archetype:** Schedule + Timeline

Show:

- medication
- dosage
- schedule
- next dose
- adherence
- reminders
- history

Sensitive data should be protected.

---

# 80. RECOMMENDED PREMIUM TOOLS

Lume may expand beyond the original 72 tools where data availability and user value justify it.

Potential additions:

### Time & Travel

- World Clock
- Time Zone Converter
- Public Holidays
- Travel Planner
- Packing List
- Route & Distance Planner
- Toll Calculator
- Parking Timer
- Local Events

### Weather & Environment

- Weather Radar
- Sun & Moon
- UV Index
- Air Quality Explorer
- Internet Outage

### Finance

- Net Worth
- Portfolio Tracker
- Investment Return Calculator
- Compound Interest
- Currency Alerts
- Price Tracker
- Budget Planner
- Group Expenses
- Financial Calendar

### Personal

- Journal
- Reflection
- Goals
- Focus Timer
- Digital Wellbeing
- Warranty Tracker
- Maintenance Tracker
- Vehicle Maintenance
- Home Inventory
- Gift Planner

These must only be added when they can be implemented with meaningful functionality.

Do not inflate the product merely to increase the tool count.

---

# 81. TOOL METADATA CONTRACT

Every Lume tool must have a structured specification containing:

```text
tool_id
name
category
description

primary_archetype
density

country_aware
region_aware
currency_aware
language_aware

requires_account
requires_location
requires_permission

supports_offline
supports_search
supports_filters
supports_sorting
supports_history
supports_notifications
supports_sharing
supports_export
supports_favorites

data_source
data_freshness

primary_information
secondary_information

primary_actions
secondary_actions

visualizations
screen_sections

home_eligible
quick_action_eligible

search_keywords
related_tools

regional_configurations
```

---

# 82. EVERY TOOL UI SPECIFICATION

Each tool specification must answer:

### 1. What is the user trying to accomplish?

### 2. What information is most important?

### 3. What information is secondary?

### 4. What is the primary action?

### 5. What is the correct screen archetype?

### 6. What density should the interface use?

### 7. What components should appear?

### 8. What data should each component display?

### 9. What controls are required?

### 10. Does it need search?

### 11. Does it need filters?

### 12. Does it need sorting?

### 13. Does it need charts?

### 14. Does it need a map?

### 15. Does it need a timeline?

### 16. Does it need history?

### 17. Does it need reminders?

### 18. Does it support offline mode?

### 19. How does country/region change the interface?

### 20. What happens when data is unavailable?

---

# 83. STANDARD COMPONENT LIBRARY

Lume should maintain reusable components for:

- AppHeader
- ToolHeader
- SectionHeader
- SummaryCard
- MetricCard
- RichListRow
- CompactListRow
- DataTable
- SearchBar
- FilterBar
- SegmentedControl
- Tabs
- Chip
- StatusBadge
- ProgressRing
- ProgressBar
- Sparkline
- LineChart
- BarChart
- DonutChart
- Timeline
- Calendar
- Map
- MapMarker
- EmptyState
- ErrorState
- OfflineState
- Skeleton
- BottomSheet
- Modal
- ConfirmationDialog
- DatePicker
- TimePicker
- NumericInput
- FormSection
- SourceLabel
- FreshnessLabel
- Avatar
- Logo
- ImageCard
- ShareCard
- FloatingActionButton
- QuickAction
- RelatedToolCard

---

# 84. RICH LIST ROW STANDARD

For information-rich datasets, use a structured row.

Example:

```text
┌──────────────────────────────────────────┐
│ [LOGO]  AAPL                       $238.42│
│         Apple Inc.                  USD   │
│         NASDAQ                    +2.41%  │
│                              ╱╲╱╲╱╱╲     │
└──────────────────────────────────────────┘
```

Depending on the dataset, add:

- volume
- market cap
- status
- distance
- ETA
- rating
- secondary metric

Do not overload every row.

---

# 85. CARD DESIGN

Cards should represent meaningful groups of information.

Good:

**Weather**

```text
28°
Feels like 31°
Partly cloudy

Humidity 64%   Wind 14 km/h
AQI 72
```

Bad:

A card containing only:

> Weather

Cards should have informational purpose.

---

# 86. TABLES

Tables are appropriate for:

- financial datasets
- rates
- historical records
- dense comparisons
- transaction data

On mobile, use:

- horizontally scrollable tables
- stacked rows
- expandable rows
- priority columns

Never force every field into a tiny unreadable row.

---

# 87. SEARCH

Search should be available when the dataset is large enough to justify it.

Examples:

- markets
- news
- Quran
- hadith
- documents
- parcels
- recipes
- bills
- transactions

Search should support relevant domain-specific matching.

---

# 88. FILTERS

Filters should be contextual.

Examples:

Markets:

- region
- exchange
- asset type
- gainers/losers
- market cap

News:

- category
- source
- date

Documents:

- category
- expiry
- status

Expenses:

- category
- date
- account

Do not expose irrelevant filters.

---

# 89. SORTING

Sorting should expose meaningful dimensions.

Examples:

Markets:

- price
- percentage change
- market cap
- volume

Parcels:

- latest update
- ETA

Documents:

- expiry
- category
- recently updated

Expenses:

- amount
- date
- category

---

# 90. LOADING STATES

Use skeletons for information-rich screens.

Examples:

- metric skeleton
- list skeleton
- chart skeleton
- map loading state

Avoid blank screens.

---

# 91. EMPTY STATES

Every tool must have a meaningful empty state.

Example:

Savings:

> No goals yet.

Then:

**Create your first savings goal**

Avoid generic:

> No data.

---

# 92. ERROR STATES

Errors must explain:

- what failed
- whether the user can retry
- whether cached information is available

Example:

> Market data couldn't be refreshed.

**Retry**

If cached data exists:

> Showing data from 4 minutes ago.

---

# 93. OFFLINE STATES

Offline-capable tools should clearly distinguish:

- live data
- cached data
- locally stored data

Do not pretend stale data is live.

---

# 94. PERSONALIZATION

Lume should adapt Home and tools based on:

- location
- language
- currency
- frequently used tools
- time of day
- season
- recent activity
- saved items
- preferred markets
- favorite cities
- notification preferences

Personalization must remain understandable and controllable.

---

# 95. HOME SCREEN COMPOSITION

Home must NOT be a giant grid containing all 72 tools.

Recommended:

```text
Greeting / Context
Today's Important Information
Quick Actions
Personalized Tools
Live Information
Upcoming Items
Recent Activity
Recommended Tools
```

Examples of contextual Home information:

Morning:

- prayer
- weather
- calendar
- tasks

During market hours:

- market snapshot

Evening:

- tomorrow's weather
- upcoming reminders
- pending tasks

Ramadan:

- suhoor
- iftar
- prayer
- fasting
- Quran progress

---

# 96. TOOL DISCOVERY

Use:

- categories
- search
- favorites
- recent tools
- suggested tools
- personalized shortcuts

Avoid presenting 72 equally weighted icons.

---

# 97. RELATED TOOLS

Tools should connect intelligently.

Examples:

Weather → Calendar → Travel

Markets → Currency → Gold

Prayer → Qibla → Nearby Mosques

Flights → Weather → Travel Planner

Expenses → Savings → Subscriptions

Vehicle → Fuel → Fines → Maintenance

Documents → Vehicle → Reminders

Quran → Prayer → Ramadan

This makes Lume feel like one ecosystem instead of separate mini-apps.

---

# 98. SHARING

Where useful, tools should generate branded shareable cards.

Examples:

- weather summary
- prayer times
- market snapshot
- expense report
- savings progress
- Quran ayah
- recipe
- travel itinerary

Share cards must contain:

- Lume branding
- relevant data
- date/time
- source where appropriate

---

# 99. EXPORT

Where meaningful, support:

- PDF
- CSV
- image
- share card

Especially for:

- expenses
- health records
- documents
- financial calculations
- reports
- schedules

---

# 100. NOTIFICATIONS — GLOBAL SYSTEM

Notifications are a **platform capability of Lume**, not a feature of any one
tool. Lume owns the notification infrastructure; tools raise notification
events into it.

```text
                    ┌─────────────────────┐
                    │ Notification Engine │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┴─────────────────┐
             │                                   │
      In-App Notifications                Push Notifications
             │                                   │
      ┌──────┴──────┐                     OS Notification
      │             │
   Badge     Notification Centre
      │             │
      │      Detail / Deep Link
      │
  Banner / Snackbar
```

Both paths share one model: categories, priorities, preferences, deep links,
read state, grouping and privacy rules.

A bell icon on its own is not a notification system.

---

## 100.1 Global entry point

One global Notifications entry point, in the app header:

```text
┌───────────────────────────────────────┐
│ Good morning 👋                 🔔 ③ │
└───────────────────────────────────────┘
```

The badge shows the unread count, disappears at zero, formats compactly above
99, and updates as state changes. It is not oversized.

A tool screen does not repeat the bell when the global header already carries
it.

---

## 100.2 Notification centre

```text
Header
   ↓
Unread summary / "All caught up"
   ↓
All │ Unread │ Important          ← filter tabs
   ↓
Category filters (optional)
   ↓
Notification list
```

Category filters: Prayer · Markets · Money · Travel · Weather · News ·
Personal · System.

---

## 100.3 Notification row

Carries category icon, title, short message, timestamp, unread indicator, and
optionally an image, an action and a status.

```text
[📈]  KSE-100 moved +2.1%                    ● 
      Crossed your alert threshold.
      2 min ago                        [View Market]
```

Concise, but informative enough to act on without opening it.

---

## 100.4 Detail and deep linking

Every actionable notification knows its destination:

| Notification | Destination |
|---|---|
| Market alert | Markets → the security |
| Flight change | Flights → the flight |
| Parcel update | Parcel Tracker → the shipment |
| Bill due | Bills → the bill |
| Document expiry | Documents → the document |
| Prayer reminder | Prayer Times |

The user must never have to go and find the thing they were just told about.

---

## 100.5 Push notifications

Lume supports OS-level push for market alerts, prayer reminders, bill due
dates, parcel updates, flight changes, train delays, weather alerts, document
expiry, subscription renewals, savings reminders, tasks, habits, medication
and important system events.

A notification is only generated when the user has enabled its category.

**Structure:** title · body · category · priority · timestamp · deep link ·
optional action · optional icon/image · unique id.

---

## 100.6 Priority

**CRITICAL** emergency and critical system events
**HIGH** flight cancellation, severe weather, imminent document expiry
**NORMAL** parcel update, bill reminder, market alert
**LOW** recommendations and informational updates

Do not abuse high priority.

---

## 100.7 Categories

Faith · Finance · Markets · Travel · Weather · News · Personal · Reminders ·
Documents · Health · System.

---

## 100.8 Per-tool settings

Every notification-enabled tool exposes its own controls, independently
switchable:

```text
Markets            Weather           Bills            Prayer
□ Price alerts     □ Severe          □ Upcoming       □ Prayer reminder
□ % movement       □ Rain            □ Due today      □ Adhan
□ Market open      □ Temperature     □ Overdue        □ Upcoming prayer
□ Market close     □ AQI
□ Major news
```

---

## 100.9 Global settings

**Settings → Notifications**

*General* — push, in-app, sounds, haptics, badge count
*Categories* — the eleven above
*Quiet hours* — start and end
*Privacy* — show preview, hide sensitive content, lock-screen detail

---

## 100.10 Quiet hours

During quiet hours low-priority notifications are suppressed and high-priority
behaviour follows the user's configuration; critical notifications may still
pass.

Nothing is silently lost — everything suppressed remains in the notification
centre.

---

## 100.11 Permission

Never request push permission cold. Use an education flow first:

```text
Stay informed

Useful alerts for prayer, markets, travel,
bills, weather and reminders.

              [Enable notifications]
                  Not now
```

If permission is denied: explain how to enable it later, keep in-app
notifications working, and never prompt aggressively again.

---

## 100.12 In-app versus push

Inside Lume: banner, snackbar, badge, inline alert or a centre entry.
Outside Lume: push, where permission exists.

Both refer to the same event. Never both for the same event at the same time.

**Choosing the surface**

*Snackbar* lightweight confirmation · *Banner* important context ·
*Centre* persistence · *Modal* only for critical decisions ·
*Push* only when the user is away.

---

## 100.13 Grouping, deduplication, expiry

Group repetitive events:

```text
KSE-100 up 0.5% · up 0.8% · up 1.1% · up 1.4%
                    ↓
KSE-100 market activity — 4 updates
```

Suppress or merge duplicates raised within a short interval. Time-sensitive
notifications expire: they stay in history but stop presenting as active.

---

## 100.14 Actions

Where meaningful: Parcel [Track] · Bill [Pay] · Task [Complete] ·
Flight [View Flight] · Market [View Market] · Prayer [View Prayer].

No action is better than a meaningless one.

---

## 100.15 Data model

```text
notification_id · user_id · category · type · title · body · timestamp
priority · read_state · deep_link · action · icon · image
source_tool · related_entity_id · created_at · expires_at · group_id
```

**States:** unread · read · actioned · expired · dismissed · grouped.

---

## 100.16 Privacy

Sensitive content respects the privacy setting.

> "Your medical report for [condition] is ready."

becomes

> "Your health record has been updated."

Financial amounts are withheld from previews when privacy mode is on.

---

## 100.17 Badges

Global badge: unread count. Tool badges only where they mean something —
Bills → overdue, Documents → expiring. Not on everything.

---

## 100.18 States of the centre

*Empty* — "You're all caught up. New alerts and updates will appear here."
Never "No data."
*Loading* — skeleton rows, never a blank screen.
*Error* — "Couldn't load notifications. [Retry]", with cached entries still
visible.

---

## 100.19 Persistence

History persists per the retention policy. Unread state stays consistent
across launches, across the push and in-app paths, and across devices where
synchronisation exists.

---

## 100.20 The rule

Notifications must be useful, contextual and actionable. They are not an
engagement mechanism.

The user should think *"Lume told me something useful"*, never *"Lume keeps
interrupting me."*

---

# 101. ACCESSIBILITY

All tools must support:

- readable contrast
- scalable text
- screen readers
- accessible touch targets
- non-color-only status indicators
- meaningful labels
- reduced motion
- keyboard navigation where applicable

---

# 102. MOTION

Motion should communicate:

- transition
- state
- progress
- confirmation
- live updates

Avoid decorative animation.

Examples:

- market value updates
- countdown
- progress
- scanner detection
- map movement
- loading

---

# 103. HAPTICS

Use sparingly for:

- successful scan
- prayer tracker completion
- Tasbih
- toggle confirmation
- important action completion

---

# 104. SECURITY & PRIVACY

Sensitive tools must use appropriate protection.

Potentially sensitive:

- documents
- health records
- cycle/pregnancy information
- medications
- financial records
- personal identifiers

Use:

- device authentication
- masked values
- secure storage
- privacy-aware screenshots where appropriate
- controlled sharing

---

# 105. REGIONAL CONFIGURATION MODEL

Country-aware tools must not fork into separate products.

Instead:

```text
Tool
 ↓
Regional Configuration
 ↓
Country
 ↓
Local Data Sources
 ↓
Local Formatting
```

Example:

```text
Markets
 ├── Pakistan
 │    └── PSX
 ├── United States
 │    ├── NYSE
 │    └── NASDAQ
 ├── United Kingdom
 │    └── LSE
 └── Global
```

---

# 106. LOCALIZATION

Localization must affect:

- language
- number formatting
- currency
- date format
- units
- address formatting
- phone formatting
- local terminology

Never hardcode Pakistan-specific assumptions into globally applicable tools.

---

# 107. SOURCE TRANSPARENCY

Data-driven tools should expose source information where appropriate.

Examples:

> Source: Exchange

> Updated 2 min ago

> Forecast updated 8 min ago

Source information should not dominate the interface.

---

# 108. DATA QUALITY

The UI must distinguish:

**Live**

**Recently updated**

**Delayed**

**Cached**

**Estimated**

**Unavailable**

Do not present estimated or stale data as exact live information.

---

# 109. MASTER TOOL GENERATION INSTRUCTION

When generating any Lume tool:

> Design the tool according to its domain rather than applying a generic screen template.

Determine:

1. user goal
2. primary information
3. secondary information
4. information density
5. appropriate screen archetype
6. required components
7. component order
8. required controls
9. visualizations
10. interactions
11. regional behavior
12. loading/empty/error/offline behavior
13. personalization
14. related tools
15. sharing/export
16. notification opportunities

The result must be a complete production-ready interface specification.

---

# 110. MASTER VISUAL GENERATION PROMPT

When generating a visual representation of a Lume screen:

> Create a premium 2027 Lume super-app interface using the Lume Master Product, UX, UI Composition & Visual Design Specification.
>
> The screen must be information-rich but not cluttered.
>
> Use the specified tool archetype and density level.
>
> Use a clear information hierarchy.
>
> Show realistic domain-specific information.
>
> Use meaningful data visualization where specified.
>
> Use rich list rows where datasets require them.
>
> Use appropriate imagery only where it adds informational value.
>
> Maintain consistent Lume typography, spacing, iconography, surfaces, corner radii, controls and navigation.
>
> Do not turn every section into a generic rounded card.
>
> Do not simplify data-rich tools into title/value/percentage rows.
>
> Do not invent irrelevant UI elements.
>
> The resulting screen should look like a production-ready premium application rather than a generic UI concept.

---

# 111. TOOL-BY-TOOL GENERATION RULE

Before designing a tool, answer:

```text
TOOL:
CATEGORY:

USER JOB:

PRIMARY DATA:

SECONDARY DATA:

DENSITY:
LOW / MEDIUM / HIGH / VERY HIGH

ARCHETYPE:

PRIMARY SCREEN SECTIONS:

SECONDARY SCREEN SECTIONS:

PRIMARY ACTION:

SECONDARY ACTIONS:

SEARCH:
YES / NO

FILTER:
YES / NO

SORT:
YES / NO

CHART:
YES / NO

MAP:
YES / NO

TIMELINE:
YES / NO

HISTORY:
YES / NO

NOTIFICATIONS:
YES / NO

SHARING:
YES / NO

EXPORT:
YES / NO

OFFLINE:
YES / NO

REGIONAL ADAPTATION:

DATA SOURCE:

FRESHNESS:

EMPTY STATE:

ERROR STATE:

OFFLINE STATE:

RELATED TOOLS:
```

Only after defining these should the UI be generated.

---

# 112. INFORMATION-RICHNESS QUALITY TEST

Before approving a screen ask:

### Information

- Does it show the information the user actually needs?
- Are important available fields unnecessarily hidden?
- Is the primary information immediately visible?

### Composition

- Is the correct archetype being used?
- Does the screen have a logical hierarchy?
- Are sections ordered by importance?

### Visual

- Does it look premium?
- Is spacing consistent?
- Is typography hierarchical?
- Are icons meaningful?
- Is imagery purposeful?

### Interaction

- Are search/filter/sort controls present when useful?
- Are actions obvious?
- Are advanced options discoverable?

### Data

- Is freshness clear?
- Is source information available?
- Are stale/offline states distinguishable?

### Regional

- Does the tool adapt to country/region?
- Is local currency/unit/date formatting correct?

---

# 113. ANTI-GENERIC UI RULE

The following is prohibited as a default strategy:

```text
Header
Large Card
Large Card
Large Card
List
Bottom Navigation
```

for every tool.

Instead, each tool must have its own information architecture.

Examples:

Markets → financial data explorer

Weather → environmental dashboard

Flights → map + live board

Quran → reader

Recipes → visual library + step reader

Expenses → financial dashboard

Emergency → action interface

Documents → secure records manager

Tasbih → focused interaction

---

# 114. ANTI-MINIMALISM RULE

Do not remove meaningful information merely because a screen looks cleaner without it.

Bad:

```text
AAPL
$238
+2%
```

Better:

```text
Apple Inc.
AAPL · NASDAQ

$238.42 USD
+$4.72  +2.02%

7D Sparkline
Volume · Market Cap · Session
```

Use the richer structure when the information is available and useful.

---

# 115. ANTI-CLUTTER RULE

Information richness does NOT mean displaying everything.

Use:

- progressive disclosure
- expandable rows
- tabs
- detail screens
- bottom sheets
- filters
- contextual controls

The goal is:

**high information value per visual area.**

---

# 116. RESPONSIVE DESIGN

Although Lume is mobile-first, compositions must adapt to:

- small phones
- large phones
- tablets
- desktop/web where applicable

On larger screens:

- use multi-column layouts
- expand data tables
- increase visualization area
- show secondary information beside primary content
- preserve hierarchy

Do not simply stretch mobile cards across the screen.

---

# 117. HOME ELIGIBILITY

Not every tool belongs on Home.

Home candidates should generally be:

- frequently used
- time-sensitive
- personalized
- actionable
- contextually relevant

Examples:

- Prayer
- Weather
- Calendar
- Tasks
- Markets
- Expenses
- Bills
- Parcels
- Savings
- News

---

# 118. QUICK ACTION ELIGIBILITY

Quick actions should prioritize tasks users want to perform immediately.

Examples:

- Add expense
- Add task
- Scan QR
- Scan document
- Start Tasbih
- Add note
- Add water
- Start timer
- Check parcel
- Add shopping item

---

# 119. DESIGN SYSTEM CONSISTENCY

The same component may appear across tools, but its composition must adapt to context.

For example:

A `RichListRow` in Markets may contain:

- logo
- ticker
- price
- change
- sparkline

The same structural component in Parcels may contain:

- carrier icon
- tracking number
- status
- location
- ETA

The component system provides consistency without making every tool identical.

---

# 120. FINAL PRODUCT PRINCIPLE

Lume should feel like a collection of **best-in-class specialized tools unified by one design language**.

Not:

> one template repeated 72 times.

Instead:

> 72+ specialized experiences sharing one intelligent product system.

---

# 121. FINAL MASTER COMMAND

Use this command whenever designing, reviewing, or generating Lume:

> **Build Lume according to the Master Product, UX, UI Composition & Visual Design Specification.**
>
> Determine the correct information architecture for the specific tool.
>
> Determine what information the user needs.
>
> Determine the correct density.
>
> Determine the correct screen archetype.
>
> Determine the required sections and their order.
>
> Determine the correct components for each section.
>
> Display meaningful available information instead of reducing rich datasets to simplistic rows.
>
> Use charts, maps, timelines, tables, imagery, progress indicators and other visualizations only where they improve comprehension.
>
> Apply Lume's global visual language without forcing every tool into the same layout.
>
> Adapt the experience to the user's country, region, currency, language and local context where relevant.
>
> Support appropriate states for loading, empty, error, offline and stale data.
>
> Preserve privacy and accessibility.
>
> Connect related tools where contextual value exists.
>
> The final result must feel premium, information-rich, intelligent, coherent and production-ready.

---

# 122. SINGLE SOURCE OF TRUTH

This document is the authoritative Lume specification.

Do not require a separate external `tools.md` to understand Lume.

External tool documents may be used as research/reference material, but Lume's actual product behavior, tool information architecture, UI composition, visual system and generation rules must be defined here.

If an older Lume prompt conflicts with this document, this document takes precedence.

Future tools should be added to this document using the same specification model.

**End of Lume Master Specification.**


---

# 123. REFERENCE COMPOSITION FIDELITY

Some Lume tools have an **approved reference composition**: a specific
information architecture, section order, primary control and interaction model
that has been designed and signed off.

**The rule**

> When a Lume tool has an approved reference composition, the generated UI must
> preserve that reference's information architecture, hierarchy, section
> ordering, primary controls and interaction model. The visual design system is
> applied *to* the reference. The screen must not be reinterpreted into a
> different layout merely because another generic Lume composition is available.

**Why this exists**

Without it, the generation path degrades into:

```text
Master specification → generic UI interpretation → invented layout
```

An archetype label such as "Markets = Financial Data Explorer" is an
*abstraction*, and an abstraction invites reinterpretation. Reading only the
archetype, a generator will produce a screen that satisfies "data explorer" in
the abstract while contradicting the approved product — the right components in
the wrong order, with the wrong element leading.

The correct path is:

```text
Master specification → Tool blueprint → Approved composition → Visual styling
```

**What is binding**

For a tool with an approved composition, these are fixed:

1. **Section order** — the sequence in the reference, top to bottom
2. **The primary control** — what the user reaches for first, and where it sits
3. **The lead element** — what occupies the top of the content area
4. **Hierarchy** — which information is primary, supporting and contextual
5. **The interaction model** — what selecting, filtering and switching do

These remain free:

- typography, colour, spacing and radius, within the design system
- illustration, iconography and motion
- how a section is composed internally, provided its role is preserved
- additional supporting sections **below** the reference's last binding section
- responsive adaptation (§116), provided small screens keep 1–4 above

**Tools with an approved composition**

| Tool | Composition |
|---|---|
| Markets | §26.13 |

Others are added here as they are designed. A tool with no entry in this table
is composed from its archetype (§22) and its density (§6) as before.

**Enforcement**

An approved composition is machine-checkable: the order of a screen's sections
can be asserted against the reference. A tool listed above must carry its
composition in the tool metadata contract (§81), and the verification suite
(§65) must fail when a screen's rendered section order diverges from it.

A composition that is only written down is a suggestion. A composition that is
tested is a specification.
