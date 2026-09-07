# Premium Mobile-First Daily Life Super-App

Design a premium, modern **mobile-first daily life super-app** with a sleek, polished 2026 UI/UX.

The app combines everyday utilities, lifestyle tools, productivity features, personal tools, Pakistan-specific services, and Islamic features into one unified experience.

The overall product should feel like a **modern global consumer application**, NOT a traditional Islamic app, banking dashboard, government portal, or collection of unrelated utilities.

Islamic functionality should be an important part of the product for Muslim users, but it should be **personalized based on the user's selected profile/preferences**.

The product must support three primary personalization states:

1. **Muslim user**
2. **Non-Muslim user**
3. **Country-specific personalization**, especially Pakistan

Religion and country must be treated as **separate dimensions**.

For example:

* Muslim + Pakistan → Islamic features + Pakistan-specific features
* Muslim + non-Pakistan → Islamic features + globally relevant tools
* Non-Muslim + Pakistan → Pakistan-specific features, but **Islamic features hidden by default**
* Non-Muslim + non-Pakistan → General/global features

The user should always be able to modify their preferences later from Profile/Settings.

---

# Overall Design Direction

Create a **sleek, minimal, premium, highly polished mobile interface** with:

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
* Abstract decorative background elements
* Small floating stickers/illustrations around cards
* Premium iconography
* Smooth carousel interactions
* Excellent light and dark mode support
* Strong accessibility and readability
* Avoid clutter and excessive decoration

The interface should feel inspired by the quality of modern apps such as Apple, Notion, Linear, Revolut, Arc, Airbnb, Headspace and modern productivity/lifestyle apps — but **do NOT copy their interfaces**.

The result should feel like one carefully designed product with its own visual identity.

---

# Core Product Principle

The application contains many features, but it must **never feel like a giant toolbox or app marketplace**.

The design system must make all functionality feel like it belongs to the same ecosystem.

For example:

* Quran
* Prayer Times
* Calculator
* Weather
* Calendar
* Notes
* Fuel Prices
* Cricket
* Parcel Tracking
* Expenses
* Recipes
* Trains
* Flights

should all use the same underlying:

* Typography
* Spacing
* Card language
* Icon system
* Navigation patterns
* Interaction patterns
* Color system
* Illustration language
* Motion system

The application should feel like **one super-app**, not 70 mini-apps.

---

# Mobile Layout

Design primarily for a **390 × 844 mobile viewport**.

Use a consistent mobile grid with approximately:

* 16–20px horizontal page padding
* 12–16px spacing between cards
* 20–28px section spacing
* 12–20px card radius
* Comfortable touch targets
* Sticky/floating bottom navigation

The UI should feel spacious rather than compressed.

Support larger and smaller mobile screens gracefully.

Avoid designing desktop-first layouts that are simply squeezed into mobile.

---

# Personalization & Onboarding

There is already an onboarding step called:

**“What are you here for?”**

Use the existing onboarding flow rather than creating unnecessary duplicate questions.

Before adding new onboarding screens, inspect the existing onboarding options and determine which required personalization choices are already represented.

If a required preference is missing, **extend the existing onboarding flow naturally** instead of creating a separate disconnected onboarding experience.

---

## Religion Personalization

The application should determine whether Islamic functionality is relevant based on the user's onboarding/profile selection.

If the existing **“What are you here for?”** onboarding already allows the user to indicate interests or Islamic preferences, reuse that information.

If it does not adequately determine whether Islamic features should be shown, add a lightweight personalization step such as:

**What would you like your app to include?**

Possible choices:

* Everyday life
* Productivity
* Money & finance
* Health & wellness
* Travel
* News & entertainment
* Islamic features
* Pakistan-specific services

If the product already explicitly asks the user's religion, use that existing value instead of asking again.

Do NOT repeatedly ask users whether they are Muslim throughout the application.

---

# Muslim vs Non-Muslim Experience

## Muslim Users

For Muslim users, Islamic functionality should be fully integrated into:

* Home
* Today
* Tools
* Search/Explore where relevant
* Personalized recommendations
* Notifications/reminders

Islamic features should feel like a **natural part of the user's daily life**, not like a separate application.

Examples:

* Next Prayer
* Prayer Countdown
* Quran Continue Reading
* Ayah of the Day
* Hadith
* Daily Duas
* Tasbih
* Qibla
* Ramadan
* Fasting Tracker

These can appear contextually on Home and Today.

---

## Non-Muslim Users

For non-Muslim users:

**Do NOT show Prayer & Islam as a prominent section by default.**

Do not:

* Put Islamic tools in the main Quick Tools grid
* Show Prayer cards on Home
* Show Quran/Hadith cards in Today
* Add Islamic navigation tabs
* Push Islamic notifications
* Make the user feel that the app is primarily an Islamic application

Instead, the experience should focus on:

* Daily Life
* Money
* Productivity
* Personal
* Travel
* News
* Entertainment
* Health
* Utilities
* Country-specific services

However, Islamic functionality should not be permanently inaccessible.

Users should be able to change their preferences from:

**Profile → Personalization → Interests / Content Preferences**

If they later choose Islamic features, the relevant experience can become available.

---

# Country Personalization

Country-specific functionality must be independent of religion.

If the user's country is Pakistan, expose Pakistan-specific utilities where appropriate.

For example:

A Pakistani Muslim:

* Islamic features → visible
* Pakistan features → visible

A Pakistani non-Muslim:

* Islamic features → hidden by default
* Pakistan features → visible

Do not assume that being Pakistani means the user is Muslim.

Likewise, do not assume that being Muslim means the user is Pakistani.

Country-specific features should be clearly identified internally as localized features, but avoid cluttering the UI with excessive country flags.

---

# Feature Architecture

Organize the application around four major feature groups:

1. **Prayer & Islam**
2. **Money & Rates**
3. **Daily Life**
4. **Personal**

These categories should not necessarily appear as four huge blocks everywhere.

Use contextual surfacing:

* Home → personalized highlights
* Today → daily information
* Tools → categorized utilities
* Explore → discovery
* Profile → personalization/settings

---

# Prayer & Islam

**17 features**

These features are intended for **Muslim users**.

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

---

## Islamic UX Principles

Islamic features should feel:

* Calm
* Respectful
* Modern
* Elegant
* Accessible
* Content-focused

Do NOT make the UI:

* Ornamental
* Excessively gold/green
* Mosque-themed everywhere
* Filled with Arabic decorative patterns
* Visually old-fashioned
* Overly religious in the global application shell

Use subtle Islamic visual references only where appropriate.

For example:

* Minimal geometric patterns
* Subtle crescent-inspired shapes
* Elegant Arabic typography where actual Arabic content is displayed
* Calm gradients
* Minimal decorative motifs

The main application should still look like a **global premium consumer product**.

---

# Money & Rates

**14 features**

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

Pakistan-specific financial features should be automatically available when the user's country is Pakistan.

Do not show the 🇵🇰 emoji everywhere in the actual production UI.

Use localization metadata internally and subtle UI labels such as:

**Pakistan**

when necessary.

---

# Daily Life

**18 features**

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

Pakistan-specific services should appear automatically for Pakistani users.

Global features should remain available regardless of country.

---

# Personal

**23 features**

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

Personal features should feel highly private, organized and user-controlled.

Sensitive personal features should not be unnecessarily surfaced on the Home screen.

For example:

* Medication
* Pregnancy
* Cycle Tracking
* Vaccinations
* Health Records

should be accessible through Personal/Health rather than aggressively promoted.

---

# Home Screen

Create a beautiful personalized dashboard/home screen.

The Home screen must **change based on the user's profile, country, preferences, and usage**.

Do not create one identical Home screen for every user.

---

## Header

Top section:

* User greeting
* Current date
* Optional location
* Profile/avatar button
* Notification button

Example:

**Good morning 👋**

**Monday, 7 September**

Keep this area minimal and elegant.

For Muslim users, contextual information such as the next prayer can appear below the header.

For non-Muslim users, replace that space with relevant daily information.

---

# Hero Carousel

Create a large horizontal **hero carousel** directly below the header.

Use 2–4 horizontally swipeable cards.

Each card should have:

* Large headline
* Short supporting text
* CTA
* Beautiful SVG illustration
* Abstract decorative background shapes
* Floating illustration/sticker elements
* Subtle gradient or textured background
* Small pagination dots
* Smooth swipe animation

Possible slides should be **personalized**.

### General slides

1. **Plan your day**

   * Tasks, reminders and calendar

2. **Useful tools, all in one place**

   * Calculator, converter, currency, weather, etc.

3. **Stay on top of your money**

   * Expenses, rates, savings and financial tools

4. **Your day at a glance**

   * Weather, calendar, news and personalized information

### Muslim-specific slides

For Muslim users:

**Your next prayer**

* Prayer name
* Prayer time
* Countdown
* Location

**Read something meaningful**

* Quran
* Hadith
* Ayah of the day

Do not show Muslim-specific carousel slides to non-Muslim users unless they explicitly enable Islamic content.

---

# Quick Tools

Create a **Quick Tools** section.

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

For non-Muslim users, replace Islamic quick tools such as Qibla/Tasbeeh with frequently used general tools.

For Muslim users, Islamic tools may appear naturally among Quick Tools.

Each tool should have:

* Clean SVG icon
* Short label
* Optional small status/value
* Subtle background treatment

Avoid huge colorful icons.

Keep the iconography sophisticated and consistent.

---

# Today Section

Create a personalized **Today** experience.

The content should change based on the user.

---

## Muslim Today Experience

Possible cards:

### Prayer

Show:

* Next prayer
* Countdown
* Prayer name
* Prayer time
* Progress indicator

### Ayah of the Day

Show:

* Ayah
* Surah
* Reference
* Bookmark
* Share

### Hadith

Show:

* Hadith text
* Source
* Bookmark
* Share

### Quran

**Continue Reading**

Show:

* Surah name
* Ayah progress
* Progress bar
* Continue button

### Daily Dua

Show:

* Dua
* Arabic
* Translation
* Bookmark

---

## General Today Experience

For non-Muslim users, replace Islamic content with:

* Daily weather
* Calendar events
* Tasks
* Reminders
* Daily quote
* News
* Cricket
* Money/rates
* Personal goals
* Streaks
* Relevant Pakistan services

The Today page should feel personalized rather than like a static feed.

---

# Tools Screen

Create a dedicated **Tools** screen.

Organize tools into categories instead of showing everything at once.

Use:

* Category headers
* Compact tool cards
* Search
* Recently Used
* Favorites
* Smart recommendations

Possible categories:

## Everyday

* Calculator
* Unit Converter
* Currency Converter
* Stopwatch
* Timer
* Age Calculator
* Date Calculator

## Planning

* Calendar
* Reminders
* Notes
* To-do
* Events

## Islamic

Visible only for users who have Islamic functionality enabled.

* Prayer Times
* Quran
* Hadith
* Duas
* Tasbeeh
* Qibla
* Hijri Calendar
* Zakat Calculator
* Ramadan
* Faraid

## Money

* Currency & Gold
* Markets
* Fuel Prices
* Fuel Cost
* Tax Calculator
* National Savings
* Prize Bonds
* Bills
* Mobile Packages
* Loan / EMI
* Tip & Split
* Lending Ledger
* Installments
* Committee

## Daily Life

* Weather
* Loadshedding
* Trains
* Flights
* News
* Cricket
* Emergency
* QR Scanner
* Document Scanner
* Passport Photos
* Vehicle & Fines
* Media Saver
* WhatsApp Status
* Speed Test

## Personal

* To-dos
* Notes
* Shopping List
* Birthdays
* Recipes
* Meal Planner
* Alarms
* Learning & Growth
* Documents
* Health
* Habits
* Water
* Expenses
* Savings Goals
* Subscriptions
* Medication Reminders
* etc.

---

# Search & Discovery

Because the application contains many utilities, provide powerful global search.

Users should be able to search:

* Tools
* Features
* Content
* Quran
* Hadith
* News
* Places
* Settings
* Personal records where appropriate

Examples:

Search:

**“currency”**

→ Currency Converter

Search:

**“petrol”**

→ Fuel Prices / Fuel Cost

Search:

**“qibla”**

→ Qibla Compass

Search:

**“salary tax”**

→ Pakistan Tax Calculator

Search:

**“surah rahman”**

→ Quran Search

Search should provide intelligent results without making the interface feel technical.

---

# Bottom Navigation

Create a modern floating/sticky bottom navigation.

Suggested tabs:

* Home
* Tools
* Today
* Explore
* Profile

However, **Trains 🇵🇰 is an important feature and should be treated as a first-class navigation experience for Pakistani users**.

If the product requirements specify Trains as a bottom tab, adapt the navigation for Pakistan users accordingly.

For example:

### General users

Home · Tools · Today · Explore · Profile

### Pakistan users

Home · Tools · Trains · Today · Profile

Or use a context-aware navigation strategy where Trains can become a prominent primary destination without breaking the overall navigation system.

Do not overload the bottom navigation with too many tabs.

Use:

* Simple SVG icons
* Active/inactive states
* Clear labels
* Smooth animated active indicator
* Comfortable touch targets

Do not use oversized icons.

---

# Illustrations & Decorative Elements

Use **SVG illustrations and abstract decorative shapes** throughout the interface.

Visual language should include:

* Abstract blobs
* Soft geometric shapes
* Floating stars
* Sparkles
* Small stickers
* Doodles
* Gradient mesh shapes
* Floating circles
* Minimal line illustrations
* Subtle patterns

These should sit **behind or around cards**, not interfere with content.

Think of them as:

**background decorative illustrations**

or

**floating UI stickers**.

Keep them subtle and premium.

Do NOT use generic stock illustrations.

Prefer custom SVG illustrations that match the app's visual language.

---

# Cards

Create several card styles:

1. Hero card
2. Feature card
3. Compact tool card
4. Content card
5. List card
6. Statistic card
7. Progress card
8. Horizontal scroll card
9. Personalized recommendation card
10. Empty state card
11. Status/information card

Cards should feel consistent but not repetitive.

Use hierarchy through:

* Size
* Typography
* Spacing
* Background treatment
* Iconography

rather than excessive colors.

---

# Typography

Use a modern professional font such as:

* Inter
* Geist
* Manrope
* Plus Jakarta Sans
* SF Pro style alternative

Use:

* Strong large headings
* Medium-weight section titles
* Highly readable body text
* Small secondary metadata

Avoid excessive font weights.

Arabic content should use a suitable Arabic typeface with excellent readability and proper RTL support.

---

# Icons

Use a consistent SVG icon library.

Preferred style:

* Lucide
* Phosphor
* Hugeicons
* Heroicons

Keep stroke width and visual weight consistent throughout the application.

Do NOT mix unrelated icon styles.

---

# Color System

Use a sophisticated neutral foundation.

Primary UI:

* Soft/off-white background
* White cards
* Near-black primary text
* Muted gray secondary text
* Subtle borders

Use one distinctive accent color throughout the product.

Accent can be:

* Modern teal
* Sophisticated green
* Modern blue
* Another premium accent

Use gradients only for:

* Hero cards
* Featured content
* Important states
* Decorative illustrations

Avoid making every card colorful.

Islamic sections should NOT automatically become green/gold.

The Islamic experience should inherit the same global design system.

---

# Dark Mode

Design the interface so it works beautifully in dark mode.

Dark mode should use:

* Near-black background
* Slightly lighter cards
* Subtle borders
* Muted text
* Carefully adjusted accent colors
* Reduced gradient intensity

Do not simply invert colors.

---

# Interactions & Motion

Add subtle animations:

* Hero carousel swipe
* Card press feedback
* Bottom navigation transition
* Progress animations
* Expand/collapse
* Modal bottom sheets
* Skeleton loading
* Button micro-interactions
* Page transitions
* Pull-to-refresh
* Search transitions
* Favorite/bookmark animations
* Tool opening transitions

Animations should feel:

* Fast
* Smooth
* Intentional
* Premium

Avoid excessive bouncing or gimmicky animations.

---

# Personalization Engine

The Home screen and feature discovery should adapt based on:

* User interests
* Religion preference
* Country
* Frequently used tools
* Recently used tools
* Favorite tools
* Time of day
* Calendar events
* Relevant contextual information

For example:

A Pakistani Muslim who frequently checks prayer times and fuel prices might see:

1. Next Prayer
2. Fuel Price
3. Weather
4. Continue Quran
5. Calendar
6. Quick Tools

A Pakistani non-Muslim might see:

1. Weather
2. Fuel Price
3. Calendar
4. News
5. Trains
6. Quick Tools

A user outside Pakistan might see:

1. Weather
2. Calendar
3. Currency
4. Tasks
5. News
6. Quick Tools

Do not hard-code these exact layouts.

The design should establish a system that can dynamically personalize the content.

---

# Feature Visibility Rules

Implement a clear feature visibility model.

### Islamic features

Visible when:

* User is Muslim
* OR user has explicitly enabled Islamic features/content

Hidden by default when:

* User is non-Muslim

### Pakistan-specific features

Visible when:

* Country = Pakistan

Regardless of:

* Muslim
* Non-Muslim

### Global features

Visible for everyone.

### Personal/sensitive features

Visible only when relevant and/or enabled by the user.

This logic should be consistent across:

* Home
* Tools
* Today
* Search
* Explore
* Notifications
* Recommendations
* Widgets
* Shortcuts

A hidden feature should not randomly appear somewhere else in the application.

---

# Changing Preferences

Users must be able to change their personalization later.

Provide a clean settings experience such as:

**Profile → Personalization**

Possible controls:

### Interests

* Productivity
* Money
* Lifestyle
* Health
* Travel
* News
* Entertainment
* Islamic

### Location / Country

* Country
* City
* Location permissions

### Content Preferences

* Islamic content
* News
* Sports
* Financial information
* Recommendations

Do not make personalization feel permanent or restrictive.

Users should be able to change these settings at any time.

---

# Empty States

Create premium empty states for features without data.

Examples:

* No tasks
* No expenses
* No saved Quran content
* No subscriptions
* No upcoming events
* No parcel
* No savings goals
* No favorite tools

Use:

* Simple SVG illustration
* Short explanation
* One primary CTA

Avoid generic illustrations and excessive text.

---

# Loading States

Use polished skeleton loaders.

Skeletons should match the final component structure.

Avoid showing generic spinners everywhere.

Use:

* Skeleton cards
* Skeleton lists
* Shimmer where appropriate
* Progressive loading

---

# Error States

Errors should be human-readable.

Avoid technical messages such as:

“API Error 500”.

Instead:

**Something went wrong**

“We couldn't load the latest fuel prices.”

CTA:

**Try again**

Where appropriate, show cached information with a timestamp.

---

# Accessibility

Prioritize:

* Strong contrast
* Readable typography
* Large touch targets
* Screen-reader friendly labels
* Clear focus states
* Reduced motion support
* RTL support for Arabic
* Dynamic font scaling
* Avoid color-only status indicators

---

# Localization

The architecture should support localization from the beginning.

Support:

* English
* Urdu
* Arabic where relevant
* RTL layouts

Do not hard-code UI text into illustrations.

Dates, numbers, currencies and units should be localized.

Pakistan-specific features should use appropriate:

* PKR
* Pakistani date/context where required
* Local fuel terminology
* Pakistani tax terminology
* Pakistani financial products
* Pakistani transport information

---

# Privacy & Sensitive Features

Some features contain personal or sensitive information.

Examples:

* Health Records
* Vaccinations
* Medication Reminders
* Pregnancy
* Cycle Tracker
* Expenses
* Savings
* Documents
* Personal Records

These should have:

* Clear privacy messaging where appropriate
* Secure-looking UI
* Minimal exposure on Home
* User-controlled visibility
* Appropriate authentication/locking where required

Do not surface sensitive information in large promotional cards.

---

# UX Principles

Follow these principles:

* Content first
* Minimal cognitive load
* Progressive disclosure
* Clear hierarchy
* One primary action per section
* Easy thumb navigation
* Consistent interaction patterns
* Large enough touch targets
* Avoid unnecessary screens
* Avoid information overload
* Make frequently used tools accessible within 1–2 taps
* Personalize without making the UI unpredictable
* Never overwhelm users with all available features
* Keep the most useful information immediately accessible

---

# Important Design Constraints

Do NOT make the app look like:

* An old Islamic app
* A generic admin dashboard
* A banking dashboard
* A generic template
* A collection of unrelated UI kits
* An overly colorful children's app
* A government portal
* A utility directory
* A feature marketplace
* A Figma concept with unrealistic interactions

Instead, create a **single cohesive design system** where:

* Quran
* Prayer Times
* Calculators
* Weather
* Calendar
* Notes
* News
* Cricket
* Money
* Travel
* Trains
* Health
* Personal tools

all feel like they belong to the same premium product.

---

# Production Quality

The final result should look like a **real, production-ready 2026 consumer mobile application**, not a Figma concept.

Every screen should feel:

* Intentional
* Consistent
* Functional
* Polished
* Responsive
* Accessible
* Production-ready

Avoid placeholder-looking UI.

Use realistic content, realistic states, realistic loading behavior and realistic empty/error states.

---

# Final Product Priorities

Prioritize:

**Sleek + Premium + Minimal + Useful + Modern + Friendly + Highly Polished**

The application should feel like:

**“One beautiful app that quietly takes care of everyday life.”**

The user should never feel that they are navigating dozens of unrelated utilities.

The complexity should exist **behind the scenes**.

The experience presented to the user should remain:

**Simple → Personal → Contextual → Fast → Beautiful**

Most importantly:

**Do not force Islamic functionality onto non-Muslim users.**

**Do not hide Pakistan-specific functionality from Pakistani non-Muslim users.**

**Do not assume religion from country.**

**Do not assume country from religion.**

Use onboarding and personalization to determine the appropriate experience, while always allowing users to change their preferences later.
