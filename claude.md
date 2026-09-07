# Lume — Global Mobile-First Daily Life Super-App

Design and build a premium, modern **mobile-first daily life super-app** with a sleek, polished **2026 UI/UX**.

The app combines:

* Everyday utilities
* Lifestyle tools
* Productivity
* Personal tools
* Money & rates
* Local/country-specific services
* News and entertainment
* Travel and transport
* Health and personal wellbeing
* Islamic features for Muslim users

The product must feel like a **real, production-ready global consumer application**, not a Figma concept, generic template, admin dashboard, banking dashboard, traditional Islamic app, or collection of unrelated mini-apps.

The overall visual identity must remain **neutral, modern and global**.

Islamic functionality is an important part of the product, but it should be an **optional personalized experience for Muslim users**, not the identity of the entire application.

---

# 1. CORE PRODUCT PRINCIPLE

The product should be thought of as:

**Global Core + Country Localization + Regional Localization + City Context + Language/Locale + User Interests + Optional Islamic Experience**

The application is intended to target **users globally**.

Pakistan is currently one of the most deeply localized markets, but the product must NOT be architected as a Pakistan-first application with a few international options.

The architecture must be capable of supporting:

* Pakistan
* United States
* United Kingdom
* UAE
* Saudi Arabia
* Canada
* India
* Australia
* Japan
* Germany
* France
* Indonesia
* Brazil
* Turkey
* Nigeria
* and every other country worldwide.

---

# 2. PERSONALIZATION MODEL

The application has several independent personalization dimensions.

Treat these as separate concepts:

**Religion**

*

**Country**

*

**Region / State / Province**

*

**City**

*

**Language**

*

**Locale**

*

**Currency**

*

**Units**

*

**Timezone**

*

**Interests**

*

**User preferences**

Do NOT incorrectly infer one dimension from another.

---

# 3. RELIGION

There are two primary user states:

* Muslim
* Non-Muslim

Religion controls the Islamic experience.

### Muslim

Islamic features are available.

### Non-Muslim

Islamic features should be hidden by default.

IMPORTANT:

**Never infer religion from country.**

Do not assume:

* Pakistan = Muslim
* Saudi Arabia = Muslim
* UAE = Muslim
* Arabic = Muslim
* Urdu = Muslim

Likewise, do not assume that a user in the UK, USA, Japan, Germany, etc. is non-Muslim.

A Muslim user can live anywhere.

A non-Muslim user can live anywhere.

Religion and country are completely independent.

---

# 4. COUNTRY

Country determines country-specific services and localization.

The application must support **all countries globally**.

Do NOT hard-code a small country list such as:

* Pakistan
* UK
* UAE
* Canada
* Saudi Arabia
* USA

Those should only be examples/popular countries.

The underlying location architecture must support a complete global country database.

---

# 5. REGION / STATE / PROVINCE

Where applicable, support:

**Country → Region/State/Province → City**

Examples:

Pakistan → Punjab → Lahore

United States → California → Los Angeles

Canada → Ontario → Toronto

Australia → New South Wales → Sydney

United Kingdom → England → London

Do not force unnecessary hierarchy on countries where it is not needed.

---

# 6. CITY

City is an important personalization layer.

Allow users to select any supported city globally.

Do NOT limit cities to manually entered examples.

City/location can power:

* Weather
* Prayer times
* Qibla
* Nearby mosques
* Nearby places
* Local news
* Fuel prices
* Loadshedding
* Transport
* Trains
* Flights
* Local events
* Emergency services
* Local recommendations
* Other location-aware services

---

# 7. GLOBAL LOCATION ONBOARDING

The existing onboarding already contains:

**“What are you here for?”**

Keep the existing onboarding step.

Do NOT duplicate it.

Improve/reorganize it only where necessary.

The onboarding should also capture the information needed for personalization.

---

## Where Are You Based?

Use:

**Where are you based?**

Supporting copy:

**This helps us personalize local information and services. It says nothing about who you are.**

The current implementation only provides a handful of countries.

That is NOT acceptable for a global app.

---

## Country Picker

Provide:

**Search countries**

The country selector should support:

* Search
* Popular countries
* Recently selected countries
* Full global country list

The user should be able to search for any country.

Examples:

* Pakistan
* Japan
* Germany
* Australia
* Nigeria
* Brazil
* Turkey
* Indonesia
* United Kingdom
* United States
* etc.

---

# 8. CITY ONBOARDING

After country selection:

**Which city are you in?**

Allow:

* Search city
* Popular cities
* Use current location

Example:

Pakistan:

* Islamabad
* Lahore
* Karachi
* Rawalpindi
* Peshawar
* Quetta

But these are examples only.

The system must support a global city database.

---

# 9. CURRENT LOCATION

Provide:

**Use my current location**

This should be optional.

If permission is granted, use location to determine:

* Country
* Region where available
* City where available
* Latitude
* Longitude
* Timezone

Use this information for relevant services.

The user must always be able to manually change their location.

Do not make location permission mandatory unless technically required by a specific feature.

---

# 10. LANGUAGE

Localization is a **first-class product requirement**.

Do not treat localization as an afterthought.

The application must be architected to support multiple languages.

Potential languages include:

* English
* Urdu
* Arabic
* Hindi
* French
* Spanish
* German
* Turkish
* Indonesian
* Malay
* Japanese
* Chinese
* Portuguese
* etc.

The exact initial language list can be decided separately.

The architecture must make adding languages easy.

---

# 11. LOCALIZATION

Localization means more than translating strings.

It should cover:

* Navigation
* Buttons
* Forms
* Empty states
* Error messages
* Notifications
* Onboarding
* Tool descriptions
* Settings
* Help content
* System messages
* Content where appropriate

Do NOT hard-code user-facing strings throughout the application.

Use a proper localization system.

---

# 12. LANGUAGE AND COUNTRY ARE INDEPENDENT

A user's language should NOT automatically be determined from country.

Examples:

Pakistan + English

UK + Urdu

Saudi Arabia + English

USA + Spanish

Japan + English

UAE + Arabic

All should work naturally.

---

# 13. LOCALE

Support locale-aware formatting.

Examples:

* en-PK
* en-GB
* en-US
* ar-SA
* ar-AE
* fr-CA

Locale should influence:

* Date format
* Number format
* Currency formatting
* Decimal separators
* Thousands separators
* Week start
* Regional terminology
* Units
* Language
* Time formatting

Do not hard-code English/US formatting globally.

---

# 14. CURRENCY

Currency must be localization-aware.

Examples:

Pakistan → PKR

United States → USD

United Kingdom → GBP

UAE → AED

Saudi Arabia → SAR

Japan → JPY

Eurozone → EUR

Do not hard-code PKR, USD, or GBP globally.

Money-related features should understand the user's current country/locale.

Users should still be able to manually select a preferred/base currency where appropriate.

---

# 15. UNITS

Support localized units.

Examples:

* km / miles
* °C / °F
* kg / lb
* liters / gallons
* km/h / mph

Allow:

**Automatic**

**Metric**

**Imperial**

Users should be able to override the automatic setting.

---

# 16. TIMEZONE

Time-sensitive functionality must respect the user's timezone.

Examples:

* Prayer times
* Weather
* Calendar
* Alarms
* Flights
* Trains
* Loadshedding
* Events
* Reminders

Do NOT hard-code timezone offsets.

---

# 17. RTL

Properly support RTL languages including:

* Arabic
* Urdu

RTL must correctly affect:

* Navigation
* Cards
* Lists
* Forms
* Bottom sheets
* Search
* Carousels
* Share cards
* Directional icons

Do not simply mirror everything mechanically.

Back/forward/next/previous icons must remain semantically correct.

---

# 18. THREE PRIMARY USER STATES

The application must be tested against at least these scenarios.

### Muslim + Pakistan

Country:

Pakistan

City:

Islamabad

Islamic:

Enabled

Result:

* Global features → visible
* Pakistan features → visible
* Islamic features → visible
* Localized currency → PKR
* Local services → Islamabad/Pakistan context

---

### Non-Muslim + Pakistan

Country:

Pakistan

City:

Islamabad

Islamic:

Disabled

Result:

* Global features → visible
* Pakistan features → visible
* Islamic features → hidden

---

### Muslim + United Kingdom

Country:

United Kingdom

City:

London

Islamic:

Enabled

Result:

* Global features → visible
* UK/local features → visible where supported
* Islamic features → visible
* Pakistan-only features → hidden

---

### Non-Muslim + United States

Country:

United States

City:

New York

Islamic:

Disabled

Result:

* Global features → visible
* US-localized features → visible where supported
* Islamic features → hidden

---

# 19. FEATURE REGISTRY

Continue using the existing:

**catalogue.js**

as the **single source of truth**.

Every feature should contain metadata describing:

* id
* category
* faith
* countries
* regions
* cities
* languages
* locale
* currency
* units
* timezone
* adapts
* sensitive
* staple
* shareable
* requiresLocation
* requiresCity
* requiresCountry

The feature registry determines:

* Whether the feature is visible
* Whether it is faith-gated
* Whether it is country-specific
* Whether it requires location
* Whether it is localized
* Whether it is sensitive
* Whether it supports sharing
* How it adapts to the user's context

---

# 20. VISIBILITY VS LOCALIZATION

These are different concepts.

A feature can be:

### Global

Visible worldwide.

Example:

Calculator.

### Global + Localized

Visible worldwide but adapts to location.

Example:

Weather.

### Country-specific

Visible only in supported countries.

Example:

Pakistan Fuel Prices.

### Faith-gated

Visible only when Islamic functionality is enabled.

Example:

Quran.

### Faith-gated + Localized

Visible to Muslim users and adapts to location.

Example:

Prayer Times.

Do not mix these concepts.

---

# 21. ORIGINAL FEATURE CATALOGUE

## Prayer & Islam — 17

* Prayer Times
* Qibla Compass
* Nearby Mosques
* Prayer Tracker
* Ramadan
* Fasting Tracker
* Taraweeh
* Ayah of the Day
* Al-Quran
* Search the Quran
* Hadith
* Daily Duas
* 99 Names of Allah
* Islamic Calendar
* Tasbih
* Zakat Calculator
* Faraid

These features are **for Muslim users**.

They should not appear in the default experience of non-Muslim users.

---

# 22. ISLAMIC ONBOARDING FLOW

Do not force Islamic onboarding on every user.

The existing:

**“What are you here for?”**

step should remain.

Within it, Islamic interests should be available as an optional area.

For example:

**What are you here for?**

### Everyday

* Utilities
* Productivity
* Planning

### Money

* Finance
* Expenses
* Savings

### Lifestyle

* Weather
* News
* Recipes
* etc.

### Islamic

Only show Islamic interests when appropriate based on the user's selected preference.

Allow the user to choose Islamic interests such as:

* Prayer
* Quran
* Hadith
* Duas
* Ramadan
* Qibla
* Tasbih
* etc.

Do not force users to select every Islamic feature.

---

# 23. NON-MUSLIM EXPERIENCE

For non-Muslim users:

Do NOT show Islamic features in:

* Home
* Quick Tools
* Tools categories
* Today
* Explore
* Search
* Notifications
* Recommendations
* Hero carousel
* Recent features

unless the user explicitly enables the Islamic experience.

The application should feel completely natural without Islamic functionality.

Do not leave empty placeholders saying:

“Islamic features are disabled.”

Simply provide a clean experience.

---

# 24. MUSLIM EXPERIENCE

For Muslim users, Islamic functionality becomes available.

However, do NOT turn the Home screen into an Islamic dashboard.

Islamic content should be integrated carefully.

Use:

* Prayer
* Quran
* Ayah of the Day
* Other selected personalized content

when relevant.

Do not display everything at once.

---

# 25. HOME SCREEN

Create a beautiful dashboard/home screen.

---

## Header

Show:

* User greeting
* Current date
* Optional city/location
* Profile/avatar
* Notification button

Example:

**Good morning 👋**

**Monday, 7 September**

**Islamabad**

Keep the header minimal.

---

# 26. HERO CAROUSEL

Create a large horizontal hero carousel below the header.

Use:

**2–4 horizontally swipeable cards.**

Each card should have:

* Large headline
* Supporting text
* CTA
* Beautiful SVG illustration
* Abstract decorative shapes
* Floating illustration/sticker
* Subtle gradient/textured background
* Pagination dots
* Smooth swipe animation

Example slides:

### Slide 1

**Plan your day**

Tasks, reminders and calendar.

### Slide 2

**Your next prayer**

Prayer time + countdown.

Only relevant to Muslim users.

### Slide 3

**Read something meaningful**

Quran / relevant daily content.

Only relevant to Muslim users.

### Slide 4

**Useful tools, all in one place**

Calculator, converter, currency, Qibla, etc.

Hero slides should be selected based on relevance.

Do not show Islamic hero slides to non-Muslim users.

Do not exceed 4 slides.

---

# 27. QUICK TOOLS

Create a:

**Quick Tools**

section.

Use a responsive grid of compact cards.

Examples:

* Calculator
* Currency
* Weather
* Calendar
* Qibla
* Tasbeeh
* Notes
* Timer

Quick Tools should personalize based on:

* User interests
* Religion
* Country
* Frequently used features
* Recent activity

Do not let one category dominate the entire grid.

For example, if a Muslim user selects many Islamic interests, do not make all 8 quick tools Islamic.

Use intelligent balancing/round-robin/relevance.

---

# 28. TODAY

Create a personalized:

**Today**

experience.

It can include:

### Prayer

For Muslim users:

* Next prayer
* Countdown
* Prayer name
* Prayer time
* Progress indicator

### Quran

For Muslim users:

* Continue Reading
* Surah
* Ayah progress
* Progress bar
* Continue button

### Daily Quote

Where appropriate:

* Quote
* Author/source
* Bookmark
* Share

### Weather

Localized by:

* City
* Country
* Units
* Locale

### Calendar

Localized by:

* Country
* Locale
* Timezone

Do not overload Today.

---

# 29. IMPORTANT HOME CORRECTION — HADITH

Do NOT claim that Hadith is currently part of Home simply because Hadith exists as a feature.

Hadith is an Islamic feature.

It does NOT automatically belong on Home.

Unless specifically included in the approved Home content strategy:

**Do NOT add Hadith to Home.**

The same principle applies to:

* Dua
* Tasbih
* Zakat
* Faraid
* Ramadan
* etc.

Feature availability does not mean the feature must be promoted on Home.

---

# 30. TOOLS SCREEN

Create a dedicated:

**Tools**

screen.

Organize features into categories.

Do not display all tools as one giant undifferentiated list.

---

## Everyday

* Calculator
* Unit Converter
* Currency Converter
* Stopwatch
* Timer
* Age Calculator
* Date Calculator

---

## Planning

* Calendar
* Reminders
* Notes
* To-do
* Events

---

## Islamic

Visible only to Muslim users:

* Prayer Times
* Quran
* Search Quran
* Hadith
* Duas
* Tasbih
* Qibla
* Islamic Calendar
* 99 Names of Allah
* Zakat Calculator
* Faraid
* Ramadan

---

## Lifestyle

* Weather
* News
* Daily Quotes
* Nearby Places
* Other useful utilities

---

# 31. MONEY & RATES

Features:

* Currency & Gold 🇵🇰
* Markets
* Fuel Prices 🇵🇰
* Fuel Cost 🇵🇰
* Tax Calculator 🇵🇰
* National Savings 🇵🇰
* Prize Bonds 🇵🇰
* Bills 🇵🇰
* Mobile Packages 🇵🇰
* Loan / EMI
* Tip & Split
* Lending Ledger
* Installments
* Committee

The 🇵🇰 marker means the feature is currently localized for Pakistan.

It does NOT mean the entire Money category is Pakistan-only.

Future country-specific implementations should be supported through the localization/capability system.

---

# 32. DAILY LIFE

Features:

* Calendar
* Weather
* Loadshedding 🇵🇰
* Trains 🇵🇰
* Flights
* News 🇵🇰
* Cricket
* Emergency 🇵🇰
* Unit Converter
* BMI Calculator
* Age Calculator
* QR Scanner
* Document Scanner
* Passport Photos
* Vehicle & Fines 🇵🇰
* Media Saver
* WhatsApp Status 🤖
* Speed Test

Country-specific features should only appear where supported.

Global features should remain available globally.

News, Weather, Cricket and similar content can be **global features with localized content**, where appropriate.

Do not hide an otherwise global feature merely because its first implementation is Pakistan-focused.

---

# 33. TRAINS

Pakistan currently has:

**Trains**

as a first-class bottom navigation destination.

For Pakistan, the navigation can be:

**Home · Tools · Trains · Today · Profile**

Trains should have a full screen containing:

* Route search
* Departures
* Live running status
* Fares
* Relevant train information

The underlying architecture should allow other countries to eventually have their own transport systems.

Do not make the architecture Pakistan-specific.

---

# 34. PERSONAL

Features:

* To-dos
* Notes
* Parcel Tracker 🇵🇰
* Shopping List
* Birthdays & Anniversaries
* Daily Streak
* Recipes
* Meal Planner
* Alarms
* Learning & Growth
* Documents
* Vaccinations
* Health Records
* Play
* Baby Budget
* Habits
* Water
* Cycle Tracker ♀
* Pregnancy ♀
* Expenses
* Savings Goals
* Subscriptions
* Medication Reminders

Sensitive personal features must be handled carefully.

Do not unnecessarily surface sensitive features on Home.

---

# 35. COUNTRY LOCALIZATION

Use:

**Global Core + Country Capabilities**

Example:

### Pakistan

Currently localized:

* Fuel Prices
* Fuel Cost
* Tax Calculator
* National Savings
* Prize Bonds
* Bills
* Mobile Packages
* Loadshedding
* Trains
* Vehicle & Fines
* Local News
* Parcel Tracking
* Emergency
* etc.

But the architecture must support:

### UK

Potential:

* UK Trains
* UK Tax
* UK Fuel
* UK Public Holidays
* UK Local News

### UAE

Potential:

* UAE Bills
* UAE Fuel
* UAE Public Services
* UAE Local Information

### Saudi Arabia

Potential:

* Saudi Services
* Saudi Fuel
* Saudi Local Information

### India

Potential:

* Indian Trains
* Indian Fuel
* Indian Tax
* Indian Bills

etc.

Do not implement country logic throughout individual screens.

Use centralized capability metadata.

---

# 36. PERSONALIZATION SETTINGS

Users must be able to change:

## Location

* Country
* Region/state
* City
* Current location

## Language

* App language

## Islamic Content

* Enable/disable
* Islamic interests

## Content Preferences

* News
* Sports
* Finance
* Lifestyle
* Productivity
* Islamic
* etc.

## Units

* Automatic
* Metric
* Imperial

## Currency

* Automatic
* Preferred currency

## Time

* 12-hour
* 24-hour

Changing these settings should dynamically update the application.

---

# 37. LOCATION CHANGE

Changing country must NOT delete personal data.

Do not delete:

* Notes
* Tasks
* Expenses
* Favorites
* Documents
* Personal records

Changing country only changes relevant localized services.

Likewise:

Changing language must not reset data.

Changing Islamic preference must not delete Islamic data.

It should only change visibility.

---

# 38. EXTERNAL SHARING — IMPORTANT

Whenever content is shared outside the application, use a **visual share card** instead of plain text whenever the feature supports sharing.

This applies to:

* Quran Ayah
* Hadith
* Dua
* Ayah of the Day
* Daily Quote
* Islamic reminders
* Other shareable content

The primary shared artifact should be the generated visual card.

---

# 39. SHARE CARD SYSTEM

Create a reusable share-card generator.

---

## Quran Share Card

Include:

* Surah
* Ayah
* Arabic
* Translation
* Reference
* Lume branding

---

## Hadith Share Card

Include:

* Hadith
* Source
* Reference
* Lume branding

---

## Dua Share Card

Include:

* Arabic
* Translation
* Reference
* Lume branding

---

## Quote Share Card

Include:

* Quote
* Author/source
* Lume branding

---

## Daily Reminder

Include:

* Short message
* Optional reference
* Lume branding

---

# 40. SHARE CARD PREVIEW

Flow:

**Share**

↓

**Generate Share Card**

↓

**Preview**

Actions:

* Share
* Save Image
* Close

The system share sheet should receive the generated image/card rather than plain text as the primary artifact.

---

# 41. SHARE CARD LOCALIZATION

Share cards must respect:

* Language
* Locale
* RTL/LTR
* Arabic typography
* Urdu typography
* Translation
* Date formatting
* Content direction

For example:

English:

LTR

Urdu:

RTL

Arabic:

RTL

Do not create an English-only share system.

---

# 42. SHARE CARD VISUAL DESIGN

Share cards must belong to the same Lume design system.

Use:

* Same typography
* Same spacing
* Same brand language
* Same accent system
* Same illustration language
* Same rounded geometry
* Same premium aesthetic

Islamic cards can contain subtle Islamic visual cues.

Avoid:

* Excessive mosque imagery
* Generic stock graphics
* Gold ornamental borders
* Overly decorative Islamic patterns
* Old-fashioned Islamic-app aesthetics

The result should feel like **Lume**, not a separate Islamic application.

---

# 43. BRANDING

Use the **Lume** brand.

The global application shell should remain visually neutral.

The user should NOT immediately assume:

**“This is an Islamic app.”**

However, when a Muslim user enters Islamic functionality, that experience should feel:

* Thoughtful
* Authentic
* Premium
* Respectful
* Deeply integrated

Do not create a separate visual product for Islamic functionality.

---

# 44. HOME — NON-MUSLIM EXAMPLE

Example:

**Good morning 👋**

Monday, 7 September

Islamabad

Hero:

**Plan your day**

Quick Tools:

* Calculator
* Weather
* Calendar
* Notes
* Currency
* Timer

Today:

* Weather
* Tasks
* Calendar
* News
* Money
* Personal goals

No Islamic cards should appear.

---

# 45. HOME — MUSLIM EXAMPLE

Example:

**Good morning 👋**

Monday, 7 September

Islamabad

Hero:

**Your next prayer**

Asr

4:52 PM

in 01:24:32

Quick Tools:

* Prayer
* Quran
* Calculator
* Weather
* Notes
* Currency

Today:

* Prayer progress
* Continue Quran
* Ayah of the Day
* Calendar
* Weather

Again:

**Do not automatically add Hadith to Home.**

---

# 46. BOTTOM NAVIGATION

Global:

**Home · Tools · Today · Explore · Profile**

Pakistan:

**Home · Tools · Trains · Today · Profile**

Explore can still be reachable through contextual links when it is not a primary tab.

Do not create an Islamic-specific bottom navigation tab.

Islamic features should live inside:

* Home
* Today
* Tools
* Explore
* Search

based on personalization.

---

# 47. SEARCH

Global search should understand:

* Feature names
* Localized names
* User language
* Common terminology
* Country-specific terminology

Examples:

**petrol**

→ Fuel Prices

**salary tax**

→ Tax Calculator

**surah rahman**

→ Quran Search

**qibla**

→ Qibla Compass

Search must respect visibility rules.

If Islamic functionality is disabled, Islamic features must not leak into search results.

---

# 48. NOTIFICATIONS

Notifications must respect:

* Religion
* Country
* Region
* City
* Language
* Locale
* Timezone
* Preferences

Example:

Muslim user:

**Asr is in 20 minutes**

Non-Muslim user:

No prayer notification.

Pakistan user:

**Fuel prices updated**

UK user:

Do not show Pakistan fuel notifications.

Urdu user:

Notification should be localized into Urdu.

---

# 49. HOME PERSONALIZATION

Personalization should improve relevance without making the app unpredictable.

Do NOT constantly move entire sections around.

Keep the primary navigation stable.

Personalize:

* Hero
* Quick Tools
* Recommendations
* Today cards
* Local information
* Recently used features

The user should always know where things are.

---

# 50. VISUAL DESIGN DIRECTION

Create a:

**sleek + minimal + premium + highly polished mobile interface**

with:

* Mobile-first responsive layout
* Clean visual hierarchy
* Generous spacing
* Modern typography
* Soft rounded cards
* Subtle borders
* Light shadows
* Smooth micro-interactions
* Elegant gradients used sparingly
* Beautiful SVG illustrations
* Abstract decorative elements
* Small floating stickers
* Premium iconography
* Smooth carousels
* Excellent light/dark mode
* Accessibility
* Readability

Avoid clutter.

---

# 51. DESIGN INSPIRATION

The quality bar should feel inspired by modern products such as:

* Apple
* Notion
* Linear
* Revolut
* Arc
* Airbnb
* Headspace

But do NOT copy their interfaces.

Create an original visual identity for Lume.

---

# 52. MOBILE LAYOUT

Design primarily for:

**390 × 844**

Use approximately:

* 16–20px horizontal padding
* 12–16px card spacing
* 20–28px section spacing
* 12–20px card radius
* Comfortable touch targets
* Sticky/floating bottom navigation

The interface should feel spacious.

---

# 53. ILLUSTRATIONS

Use custom SVG illustrations.

Visual language:

* Abstract blobs
* Soft geometry
* Floating stars
* Sparkles
* Stickers
* Doodles
* Gradient mesh
* Floating circles
* Minimal line illustrations
* Subtle patterns

Place decorative elements:

**behind or around cards**

not over important content.

Do not use generic stock illustrations.

---

# 54. CARD SYSTEM

Create consistent card types:

1. Hero card
2. Feature card
3. Compact tool card
4. Content card
5. List card
6. Statistic card
7. Progress card
8. Horizontal scroll card

Use hierarchy through:

* Size
* Typography
* Spacing
* Background treatment
* Iconography

rather than excessive colors.

---

# 55. TYPOGRAPHY

Use a modern professional font such as:

* Inter
* Geist
* Manrope
* Plus Jakarta Sans
* SF Pro style alternative

Use:

* Strong large headings
* Medium section titles
* Highly readable body text
* Small metadata

Avoid excessive font weights.

For Arabic/Urdu, use appropriate fonts where required.

---

# 56. ICONS

Use one consistent SVG icon library.

Preferred:

* Lucide
* Phosphor
* Hugeicons
* Heroicons

Do NOT mix unrelated icon styles.

Keep stroke width and visual weight consistent.

---

# 57. COLOR SYSTEM

Use a sophisticated neutral foundation.

Primary UI:

* Soft/off-white background
* White cards
* Near-black primary text
* Muted gray secondary text
* Subtle borders

Use one distinctive accent color.

Possible direction:

Modern teal/green or another sophisticated accent.

Gradients should be reserved for:

* Hero cards
* Featured content
* Important states
* Decorative illustrations

Do not make every card colorful.

---

# 58. DARK MODE

Support:

* Near-black background
* Slightly lighter cards
* Subtle borders
* Muted text
* Carefully adjusted accent
* Reduced gradient intensity

Do not simply invert colors.

Dark mode should feel intentionally designed.

---

# 59. MOTION

Use subtle:

* Hero swipe animation
* Card press feedback
* Navigation transition
* Progress animation
* Expand/collapse
* Bottom sheets
* Skeleton loading
* Button micro-interactions
* Page transitions
* Share-card generation

Animations should be fast and intentional.

Avoid excessive bouncing.

---

# 60. ACCESSIBILITY

Support:

* Strong contrast
* Readable typography
* Large touch targets
* Screen reader labels
* Focus states
* Reduced motion
* Dynamic font scaling
* RTL
* Color-independent status indicators

Localization must not break accessibility.

Allow for longer translated strings.

Do not assume English text lengths.

---

# 61. SENSITIVE FEATURES

Sensitive personal features include areas such as:

* Health records
* Vaccinations
* Medication reminders
* Pregnancy
* Cycle tracking
* Personal documents
* Financial records

Do not unnecessarily surface these features prominently on Home.

They should be discoverable without being intrusive.

---

# 62. SECURITY / PRIVACY UX

Location, religion, health, financial and other personal preferences should be handled respectfully.

Do not expose sensitive information in:

* Public cards
* Notifications without appropriate controls
* Shared content
* Unnecessary recommendations

Users should have clear control over personalization.

---

# 63. ARCHITECTURE RULE

Do NOT scatter country/religion logic across screens.

Avoid patterns such as:

```text
if country == Pakistan
```

everywhere.

Instead:

Use centralized feature/capability metadata.

Likewise, do not create scattered:

```text
if Muslim
```

checks throughout the UI.

The visibility system should be centralized.

---

# 64. DEFENCE-IN-DEPTH VISIBILITY

Feature gating must happen at multiple levels.

Do not only hide the entry point.

Also protect:

* Feature screen
* Search
* Deep links
* Sheets
* Modals
* Notifications
* Recommendations
* Quick Tools
* Hero
* Recent features
* Inactive screens
* Navigation

If a feature is hidden, it should not be accessible indirectly.

---

# 65. VERIFICATION

The application should be tested across multiple personalization states.

At minimum test:

1. Muslim + Pakistan + Islamabad
2. Non-Muslim + Pakistan + Islamabad
3. Muslim + UK + London
4. Non-Muslim + USA + New York

Also test:

* English
* Urdu
* Arabic
* RTL
* Different currencies
* Different units
* Different timezones
* Different cities
* Country switching
* Language switching
* Islamic preference switching

Verify that the UI re-renders correctly.

---

# 66. IMPORTANT INVARIANTS

The following must always remain true:

### Religion

Religion does not depend on country.

### Country

Country does not depend on religion.

### Language

Language does not depend on religion.

### Currency

Currency is locale/country-aware but user-overridable where appropriate.

### Units

Units are locale-aware but user-overridable.

### City

City affects location-aware services.

### Islamic

Islamic features are hidden for non-Muslims by default.

### Pakistan

Pakistan-specific features only appear where Pakistan localization applies.

### Global

Global features remain globally discoverable.

### Sharing

Supported external content uses visual share cards.

---

# 67. FINAL PRODUCT MODEL

Think of Lume as:

**GLOBAL**

The app works worldwide.

↓

**LOCAL**

Country/region/city personalize relevant services.

↓

**PERSONAL**

Interests and usage personalize the experience.

↓

**LOCALIZED**

Language, currency, units, date/time and formatting adapt.

↓

**OPTIONAL ISLAMIC**

Muslim users receive a deeply integrated Islamic experience.

↓

**PRIVATE**

Personal and sensitive information remains controlled by the user.

---

# 68. FINAL PRODUCT GOAL

Do NOT build:

* An old Islamic app
* A Pakistan-only app
* A generic admin dashboard
* A banking dashboard
* A generic template
* A collection of unrelated UI kits
* An overly colorful children's app
* A cluttered utility directory

Build:

**A global, premium daily-life super-app.**

The experience should feel:

**Global**

**Personal**

**Localized**

**Contextual**

**Useful**

**Premium**

**Modern**

**Friendly**

**Minimal**

**Highly polished**

The user should feel that Lume understands:

**where they are,**

**what language they speak,**

**what tools they care about,**

**what is relevant around them,**

and, if they are Muslim,

**what Islamic functionality is useful to them.**

But the app must never make incorrect assumptions about the user.

---

# 69. FINAL PRIORITIES

Prioritize, in this order:

### 1. Cohesive Product

Everything should feel like one application.

### 2. Global Architecture

Support all countries, cities, languages and locales.

### 3. Correct Personalization

Religion, country, city, language and preferences remain independent.

### 4. Excellent UX

Frequently used tools should be reachable within 1–2 taps.

### 5. Premium UI

Sleek, spacious, minimal and polished.

### 6. Localization

Language, currency, units, date, time, timezone and content must adapt correctly.

### 7. Islamic Experience

Deep and thoughtful for Muslim users without defining the entire app.

### 8. Pakistan Localization

Pakistan currently receives deep local services, but the architecture must scale globally.

### 9. Share Cards

Shareable content should leave the platform as beautiful visual cards rather than plain text.

### 10. Production Readiness

The final result must feel like a real consumer application ready for production.

---

# FINAL STATEMENT

The goal is **NOT**:

> “A Pakistan app with international options.”

The goal is:

> **“A global daily-life super-app with deep localization and an optional, deeply integrated Islamic experience.”**

Pakistan is currently one of the deepest localized markets.

Islamic functionality is an important personalized experience for Muslim users.

Localization is a core part of the product.

And the entire system must be architected so that new countries, cities, languages, currencies, services and localized experiences can be added without rebuilding the application.

The final product should feel like a **real, production-ready 2026 global consumer super-app**, not a concept.

**Sleek + Premium + Minimal + Global + Localized + Personal + Useful + Modern + Friendly + Highly Polished.**

Every screen should feel intentional, consistent and production-ready.
