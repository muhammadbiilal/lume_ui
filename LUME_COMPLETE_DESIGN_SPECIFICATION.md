# Lume — Complete Product and Interface Design Specification

## 1. Document purpose

This document is the implementation-facing design reference for the current Lume prototype. It explains what the product is, who it serves, how the interface behaves, how personalization affects content, and which visual and interaction rules must remain consistent when the code is changed.

It is based on the current `tes.zip` implementation and its existing design specifications. When this document and the running implementation disagree, the mismatch should be reviewed deliberately rather than silently changing either side.

## 2. Product definition

Lume is a responsive, multilingual daily-life super-app that brings frequently used personal, planning, financial, regional, health, travel, and Islamic utilities into one interface.

The product promise is:

> One calm, personalized place for the small tasks and information people need throughout the day.

The current version is a high-fidelity browser prototype. It contains working interactions and realistic demonstration data, but it does not yet connect to production APIs, a remote database, secure server-side authentication, payment services, or cloud synchronization.

## 3. Product principles

1. **Useful before impressive.** Every visible section must help the user complete a task, understand a status, or reach something relevant.
2. **Personalization without assumptions.** Country, city, language, interests, faith content, units, currency, time zone, and theme are explicit user choices.
3. **Faith and country are separate dimensions.** Islamic content depends on the faith-content preference. Country-specific content depends on availability in the selected country.
4. **No invented data.** Missing information should have a designed empty, unavailable, loading, error, or private state.
5. **Progressive depth.** Home gives a glance; category and tool screens provide detail; focused tools provide action.
6. **Mobile first, desktop composed.** Mobile uses the full screen. Desktop constrains content without turning every screen into an oversized mobile card.
7. **Accessible by default.** Keyboard access, focus visibility, semantic roles, readable contrast, touch targets, reduced motion, and RTL support are requirements.
8. **Honest privacy.** Sensitive data and notification previews must be identified clearly. The interface must not imply production-grade security that is not implemented.

## 4. Target users and contexts

Lume is designed for people who regularly switch between small daily tasks: checking weather, prayer times, rates, tasks, bills, schedules, health information, travel information, calculators, and saved personal records.

Primary contexts:

- Quick one-handed mobile checks.
- Short task completion, such as a calculation or checklist update.
- Morning and evening daily overview.
- Country-aware information while living or travelling abroad.
- English, Urdu, or Arabic use, including RTL layouts.
- Guest use on one device, with an optional local prototype account.

## 5. Information architecture

### 5.1 Primary destinations

| Destination | Purpose | Typical content |
| --- | --- | --- |
| Home | Personalized daily overview | Greeting, context cards, highlights, quick actions, quick tools, live items, upcoming items and discovery |
| Tools | Searchable utility catalogue | Search, category filters, recently used tools and all available utilities |
| Today | Personal daily plan | Progress ring, statistics, agenda, tasks and daily completion state |
| Explore | Contextual discovery | Weather, nearby/contextual information, sports, news and recommendations |
| Profile | Identity and preferences | Guest/account state, settings, personalization, privacy and support destinations |

The Pakistan configuration may expose Trains as a specialized destination. Account, Authentication, Notifications and individual Tool screens sit above the primary navigation and return users to their previous context.

### 5.2 Tool catalogue

The catalogue contains 85 tools in six categories:

| Category | Count | Examples |
| --- | ---: | --- |
| Everyday | 8 | Calculator, unit converter, currency, timer, age and date calculator |
| Planning | 5 | Calendar, reminders, notes, to-dos and events |
| Islamic | 17 | Prayer times, Qibla, Qur'an, duas, tasbih, zakat and faraid |
| Money | 15 | Markets, gold and FX, tax, bills, loans, expenses and savings |
| Daily life | 18 | Weather, AQI, trains, flights, news, emergency, QR and vehicle tools |
| Personal | 22 | Health, documents, medicines, habits, water, goals, recipes and pregnancy |

Every tool has a unique ID, name, icon, category, product group, search keywords, relevance interests, availability rules, metadata, supported capabilities, composition archetype, density and data-awareness contract.

## 6. Personalization model

### 6.1 Profile dimensions

The interface may adapt using:

- Display name and avatar initials.
- Country, region and city.
- Language and text direction.
- Selected interests.
- Islamic-content preference.
- Measurement system.
- Currency.
- Time zone and clock format.
- Light, dark or system theme.
- Notification preferences and privacy settings.

### 6.2 Visibility rules

Feature visibility must be calculated from catalogue metadata, not scattered conditional logic.

- `faith: true`: show only when Islamic content is enabled.
- `countries: [...]`: show only in a supported country.
- `adapts: true`: show globally but use regional data and formatting.
- `reqCity: true`: require a meaningful city context.
- `sens: true`: treat as sensitive and avoid promotional exposure on Home.
- `android: true`: expose only where the platform capability makes sense.
- Hidden tools must not reappear through search, recents, notifications, deep links, related tools or cached navigation state.

### 6.3 Default experience

A user who skips interest selection should still receive a useful default experience centred on weather, calendar, tasks, notes, calculations, expenses and news. Islamic interests must never be silently selected.

## 7. Navigation and screen behaviour

### 7.1 Navigation model

- The bottom tab bar controls primary destinations.
- Tool links open the shared tool host with a tool-specific composition.
- Back returns to the exact previous context.
- An in-tool detail view returns to its tool board before leaving the tool.
- Sheets are used for temporary choices or supporting workflows.
- Authentication opened as an interruption must offer a clear dismissal route.
- Switching primary tabs clears stale nested screen stacks.
- Reopening a tool starts from its intended root unless the product explicitly restores state.

### 7.2 Screen states

Every data-bearing screen must design and implement:

1. Loading or skeleton state.
2. Populated state.
3. Empty state.
4. No-search-results state where relevant.
5. Offline or stale-data state for network-dependent tools.
6. Permission-denied or unavailable state where relevant.
7. Recoverable error state.
8. Sensitive/private state where relevant.

A failed render must never leave a blank screen.

## 8. Screen specifications

### 8.1 Home

**Goal:** answer “What matters to me now?” within a few seconds.

Required composition:

1. Status/header region with greeting, date, location, notification entry and profile avatar.
2. Immediate context cards, such as prayer and weather when eligible.
3. Highlight carousel with timely, useful or promotional content.
4. Quick actions based on high-frequency needs.
5. Quick tools selected from interests and staples.
6. Live-now region when meaningful live content exists.
7. At-a-glance cards for near-term personal or regional information.
8. Upcoming items.
9. Discovery cards.

Rules:

- Sensitive tools must not be promoted.
- Hidden faith or country content must not leak into carousels or discovery.
- The greeting uses a real user-provided name or remains neutral.
- Location-sensitive values must follow the selected city and country.

### 8.2 Tools catalogue

**Goal:** make any available utility easy to find.

Required composition:

1. Page heading and visible tool count.
2. Search field.
3. Category chips.
4. Recently used tools, when history exists.
5. Category sections containing available tools.
6. Designed empty state for unmatched search.

Search should match names and common keywords. Filters and counts must use the same eligibility rules as the rendered catalogue.

### 8.3 Today

**Goal:** show the user's day as an understandable plan rather than a data dump.

Required composition:

1. Date and summary heading.
2. Completion/progress card.
3. Useful daily statistics.
4. Chronological agenda.
5. Task list with semantic checkbox state.

Times must remain valid across 12-hour and 24-hour formats, locales and time zones. Completion percentages must be announced accessibly.

### 8.4 Explore

**Goal:** surface useful context beyond the user's saved plan.

Required composition:

1. Heading and location context.
2. Weather summary.
3. Around-you content when available.
4. Sports/live content when eligible.
5. News list.
6. Curated discovery cards.

The screen should never display a local market, emergency number, weather unit or venue from the wrong country.

### 8.5 Profile

**Goal:** make identity, account state, settings, privacy and support understandable.

The screen composition remains stable across guest, authenticated and expired states, while the available rows and values adapt honestly.

Guest requirements:

- Offer account creation and sign-in.
- Do not invent an email, name, statistics or cloud state.
- Allow device-level personalization and data controls.

Authenticated requirements:

- Show the actual name/email available.
- Offer edit profile, security, sessions, notifications, data/sync and logout.
- Isolate account deletion in a clearly destructive section.

Expired-session requirements:

- Explain that the session ended.
- Do not render the user as authenticated or silently downgrade them.
- Offer sign-in and continue-as-guest paths.

### 8.6 Account settings

Account settings are hierarchical screens hosted inside the account surface. They include profile editing, email/phone changes, security, password changes, sessions, language, appearance, region, units, time, currency, notifications, data/sync and account deletion.

Rules:

- Dirty forms require discard confirmation.
- Save remains inactive until a value changes.
- Errors are inline, connected to fields and focusable.
- Nested Back returns to the parent account screen.
- Destructive actions require clear explanation and confirmation.

### 8.7 Authentication

Authentication is a flow, not a utility tool.

Supported prototype flows:

- Sign up.
- Sign in.
- Forgot-password request.
- Reset-password result.
- Verification.
- Session-expired recovery.
- Success/arrival state.

Design rules:

- Mobile uses the entire canvas; desktop constrains forms to approximately 460 px.
- Sign-in and sign-up are sibling flows.
- Validation starts after interaction, not on initial render.
- Error space is reserved to avoid layout jumping.
- Password rules appear before submission.
- Unknown-account and incorrect-password responses remain indistinguishable.
- Verification masks the email address.
- Loading prevents double submission.
- Success screens do not expose a route back into a completed flow.

The current local account engine is for prototype behaviour only. Production authentication requires a backend, secure password hashing, server-issued sessions, email delivery, rate limits, CSRF/XSS protection, audit events and secure recovery tokens.

### 8.8 Notifications

Notifications are a platform capability with a global bell entry.

Required composition:

1. Header with Back and settings.
2. All, Unread and Important tabs.
3. Eligible category filters.
4. Notification rows with icon, title, body, time, priority and read state.
5. Empty states for filtered views.

Rules:

- Priority outranks simple recency where required.
- Opening marks an item read.
- Dismissal removes it.
- Sensitive details respect preview settings.
- Faith and country eligibility apply to notification generation and display.
- Browser permission must never be requested at boot.
- The user sees an education step before the system prompt.
- A denial is explained and not repeatedly prompted.

### 8.9 Tool host and tool screens

The shared host supplies the header, Back behaviour, supported actions and body container. Each tool supplies its own content composition.

Tool archetypes include:

- Manager/list tool.
- Calculator/form tool.
- Dashboard/status tool.
- Data explorer.
- Focused interaction.
- Action interface.
- Reader/library.

Capabilities may include search, filtering, sorting, history, notifications, offline support, sharing, export and favourites. A capability must appear only if it is actually supported.

Tool detail rules:

- Search sits above what it filters.
- Active filters and sort direction are semantically exposed.
- Calculators recompute from validated values.
- Tables can scroll and remain keyboard accessible.
- Charts communicate data rather than decorate empty space.
- Data sources and freshness appear where needed.
- Related tools respect eligibility.
- Sensitive tools show a privacy note.

## 9. Visual system

### 9.1 Overall style

Lume uses a calm, rounded, modern visual language with soft surfaces, restrained depth, strong content hierarchy and teal-led accent colour. The interface should feel trustworthy and useful rather than noisy or gamified.

### 9.2 Design tokens

All colours, typography, spacing, radii, shadows, control sizes and animation durations should come from semantic tokens.

Required token principles:

- Semantic surface and text tokens instead of component-specific raw colours.
- Light and dark themes re-author surfaces, text, borders and ambient decoration.
- Input radius: approximately 14 px.
- Button radius: approximately 14–16 px.
- Card radius: approximately 24–32 px.
- Pills use a full pill radius.
- Default icons: approximately 20–22 px.
- Small icons: approximately 16 px.
- Main input and primary action height: approximately 52–56 px.
- Secondary action height: approximately 48–52 px.
- Interactive touch target: at least 44 px.
- Press feedback completes within approximately 150 ms.

### 9.3 Typography

- Plus Jakarta Sans is the main Latin UI family.
- Noto Naskh Arabic supports Urdu and Arabic script.
- Headings use strong but controlled weight.
- Inputs use at least 16 px text to prevent mobile browser zoom.
- Numeric content uses consistent numeral styling.
- Long translations must wrap without clipping or forcing physical left/right layout assumptions.

### 9.4 Components

Core reusable components include:

- App bar and tool header.
- Bottom tab bar.
- Cards, summary cards and stat rows.
- Lists, timelines and related-tool rows.
- Search bars, fields and form grids.
- Buttons, icon buttons, chips and segmented controls.
- Tables, charts, progress rings and sparklines.
- Tags, badges and freshness/source labels.
- Sheets, dialogs, toasts and banners.
- Empty, error, offline, private and loading states.

Components must not contain product-specific availability logic. They receive already-resolved data and state.

## 10. Responsive behaviour

### Mobile

- Full-width screens and bottom navigation.
- Safe-area padding at top and bottom.
- Forms fill the available width.
- Sheets rise from the bottom where appropriate.
- Horizontal content uses deliberate scroll containers with accessible labels.

### Tablet and desktop

- Content receives a readable maximum width.
- Authentication forms remain constrained.
- Spacing increases without making controls unnecessarily large.
- The layout may use columns where hierarchy benefits, but content order remains logical for keyboard and screen-reader users.

## 11. Localization and RTL

- English uses LTR.
- Urdu and Arabic use RTL.
- Direction is applied at document and layout levels.
- Physical `left` and `right` assumptions should be replaced with logical CSS properties.
- Directional navigation icons mirror; semantic icons such as Close do not.
- Every visible string must resolve through localization or an intentional content source.
- A fallback string must exist so translation keys never reach the interface.
- Currency, temperature, distance, numbers, dates and times follow the selected locale/profile.

## 12. Accessibility requirements

- All actions are reachable by keyboard.
- Focus is visibly styled with a clear 2 px treatment.
- Dialogs move focus inside and hide the background from assistive technology.
- Closing a dialog returns focus meaningfully.
- Checkboxes, switches, tabs, segmented controls, progress indicators and map pins expose correct roles and state.
- Roving keyboard behaviour is used for radio-like groups.
- Charts and visual status indicators include textual meaning.
- Reduced-motion preferences stop looping and entrance motion without hiding outcomes.
- Colour is never the only state signal.
- Error messages connect to their fields and are announced.

## 13. Data, privacy and security model

### Current prototype

- Most data is embedded demonstration data.
- Device preferences and prototype account records use browser storage.
- Passwords are converted to a lightweight local digest; this is explicitly not production security.
- Browser geolocation is requested only through user action.
- Browser notification permission is requested only after education and consent.
- Native sharing and telephone links use browser/platform support.

### Production requirements

Before launch, introduce:

- Secure backend APIs and database.
- Server-side authorization for every protected resource.
- Modern password KDF or managed identity provider.
- Secure cookies or carefully protected tokens.
- Email/phone verification and recovery delivery.
- Consent, retention and account-deletion policies.
- Encryption in transit and at rest.
- Audit logs and abuse/rate limiting.
- Live-data provider contracts, caching and freshness rules.
- Monitoring, analytics and error reporting with privacy controls.
- Offline synchronization and conflict handling where promised.

## 14. Quality and testing contract

The existing automated suite covers:

- All tool compositions under multiple personalization states.
- Faith and country gating.
- Pakistan, UK, US, Saudi and other regional behaviour.
- English, Urdu and Arabic/RTL.
- Navigation and deep links.
- Search, filtering and sorting.
- Calculator and date/time edge cases.
- Notifications and permission flow.
- Guest, sign-up, sign-in, recovery, session and account-deletion flows.
- Accessibility roles, focus and reduced motion.
- Visual token and authentication layout contracts.

Any refactor must keep these tests passing. New screen modules should add lifecycle, routing and isolation tests rather than relying only on screenshot comparison.

## 15. Definition of design completion

A screen is complete only when:

- Its purpose and primary action are obvious.
- It follows the approved content order.
- Every interaction has feedback.
- Loading, empty, offline, denied and error states are handled where applicable.
- Eligibility and personalization are correct.
- English, Urdu and Arabic render without leaks or clipping.
- Mobile, desktop, light, dark, LTR, RTL and reduced-motion modes work.
- Keyboard and assistive-technology semantics are correct.
- No fake security, fake live status or invented user data is shown.
- Relevant automated tests pass.

## 16. Ready-to-use design prompt

Use the following prompt when asking another coding or design system to reproduce or extend Lume:

```text
Act as a senior product designer and frontend architect. Design and implement Lume, a calm, responsive, multilingual daily-life super-app. Preserve these product rules:

1. Primary destinations are Home, Tools, Today, Explore and Profile. Account, Authentication, Notifications and Tool screens are nested destinations.
2. Personalize using country, city, language, interests, Islamic-content preference, units, currency, time zone and theme.
3. Faith eligibility and country availability are separate. Hidden content must not leak through search, recents, notifications, related tools or deep links.
4. Support English LTR, Urdu RTL and Arabic RTL with locale-aware currency, numbers, dates, time, temperature and distance.
5. Use a calm rounded interface with semantic tokens, teal-led accents, 24–32 px cards, 14–16 px controls, 44 px minimum touch targets, visible focus and full dark-mode tokens.
6. Build honest loading, empty, no-results, offline, denied, error, stale and private states. Never render a blank screen or invent user data.
7. Keep mobile screens full-width and constrain desktop forms/content appropriately. Respect safe areas, reduced motion and keyboard navigation.
8. Treat authentication and notifications as platform flows, not utility tools. Do not claim production security unless a real backend exists.
9. Each tool declares its metadata, capabilities, eligibility, data awareness, density and composition archetype. Search appears above filtered content; source and freshness appear on data tools.
10. Preserve the existing Lume screen composition and behaviour tests. Add tests for every new state and interaction.

Before coding, produce: screen inventory, user flows, information architecture, component inventory, semantic design tokens, responsive rules, localization/RTL rules, accessibility checklist, state matrix, data contracts and acceptance criteria. Then implement without changing the approved visual hierarchy or product behaviour unless the change is explicitly documented.
```

