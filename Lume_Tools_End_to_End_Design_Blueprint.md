# Lume — Tools Experience, End-to-End Design & Product Blueprint

## Purpose

This document is the **design and product source of truth for how Lume's tools should behave from entry to completion**, not merely a catalogue of screens.

The supplied Dayroz tool specification documents what the existing tools do, their routes, account requirements, data behavior, failure handling, and important implementation decisions. This blueprint turns that information into a **design-system and UX-flow contract** that Lume should use when designing or redesigning every tool end-to-end.

**Important:** Do not treat this document as permission to invent a different product. Preserve the documented behavior unless an item is explicitly marked as a proposed improvement. Where the source does not specify a behavior, design the missing state deliberately rather than silently assuming one.

Source basis: the supplied `Pasted markdown(1).md`, whose registry is described as the single source of truth for the Tools hub, Home quick-tools row, and search. The source documents 72 tools across four categories. fileciteturn2file0L33-L43

---

# 1. Core Design Principle

Every Lume tool must be designed as a **complete user journey**, not as an isolated screen.

For every tool, design:

1. **Discovery**
2. **Entry**
3. **Context / prerequisites**
4. **Primary task**
5. **Input**
6. **Validation**
7. **Loading**
8. **Success**
9. **Empty state**
10. **Error state**
11. **Offline / degraded state**
12. **Permission state**
13. **Authentication state**
14. **Save / persistence behavior**
15. **Edit / update behavior**
16. **Delete / destructive behavior**
17. **Undo / recovery**
18. **Reminder / notification behavior**
19. **Share / export behavior**
20. **Deep-link behavior**
21. **Back navigation**
22. **Return-to-context behavior**
23. **Settings**
24. **Localization**
25. **Accessibility**
26. **Security / privacy**
27. **Analytics / product events**
28. **First-use education**
29. **Repeat-use optimization**

The designer should always be able to answer:

> "What happens if a user enters this feature for the first time, uses it successfully, makes a mistake, loses internet, denies a permission, signs out, comes back tomorrow, and shares or exports the result?"

---

# 2. Existing Tool Architecture — Preserve This Model

## 2.1 Single feature registry

Lume should continue using one feature registry as the source of truth for:

- Tools hub
- Home quick tools
- Search
- Visibility
- Navigation
- Recommendations
- Recents
- Pins / hidden tools
- Feature metadata
- Country / region eligibility
- Authentication requirements
- Gender-specific availability where applicable
- Platform-specific availability

The supplied implementation already uses ranked search and two-layer authentication gating. Search ranks exact name above prefix, word-start, substring, and keyword/id matches; long-press supports open/pin/hide; and route-level auth is a backstop for deep links. fileciteturn2file0L33-L43

### Required rule

**Never implement tool availability independently inside individual screens.**

Use centralized metadata such as:

```text
id
category
route
name
description
keywords
faith
countries
regions
cities
languages
accountRequired
genderRestriction
platformRestriction
requiresLocation
requiresCity
requiresCountry
sensitive
shareable
offlineCapable
dataSource
dataFreshness
```

---


# 2A. First-Class Apple + Android Product Requirement

Lume must be designed and implemented as a **first-class cross-platform product for both Apple/iOS and Android**.

This is a product requirement, not a later compatibility task.

## Platform strategy

Do **not**:

- Design Android first and adapt it to iOS later
- Design iOS first and adapt it to Android later
- Treat one platform as the reference implementation
- Force identical interaction patterns when the operating systems have different conventions
- Hide platform-specific behavior until the end of development

Instead:

> **Keep the product model, information architecture, feature behavior, data model and visual language consistent across platforms, while allowing each platform to use interaction patterns that feel native to its users.**

### Product parity

Both platforms must provide the same:

- Feature set
- Account capabilities
- Data
- Personalization
- Country/region/city behavior
- Localization
- Search
- Tool visibility
- Notifications
- Sharing
- Sync
- Privacy controls
- Export capabilities
- Core workflows
- Error handling
- Offline behavior
- Deep-link destinations

A user moving from iPhone to Android, or Android to iPhone, should not feel that they are using a different product.

### Native adaptation

The **outcome should be consistent; the interaction can be platform-native**.

Examples:

| Area | iOS | Android |
|---|---|---|
| Back navigation | Swipe-back / navigation stack | System back / gesture |
| Share | iOS Share Sheet | Android Sharesheet |
| Permissions | iOS permission flow | Android permission flow |
| Date/time | iOS-native conventions where appropriate | Android-native conventions where appropriate |
| Photos/files | iOS Photos/Files behavior | Android photo picker/file picker |
| Notifications | APNs / iOS notification behavior | FCM / Android notification behavior |
| Camera | iOS camera permission/lifecycle | Android camera permission/lifecycle |
| Location | iOS location permission levels | Android location permission levels |
| Biometrics | Face ID / Touch ID where available | BiometricPrompt / supported device biometrics |
| Safe areas | Notches, Dynamic Island, home indicator | Cutouts, navigation bars, edge-to-edge |
| App lifecycle | iOS foreground/background lifecycle | Android activity/process lifecycle |
| Deep links | Universal Links | Android App Links |
| Widgets | iOS WidgetKit where supported | Android App Widgets where supported |

Do not force the same UI control when a native platform control would provide a substantially better experience.

## Platform-specific design rules

### iOS

Design for:

- Safe-area insets
- Dynamic Island / camera cutouts
- Home indicator
- Large navigation titles where appropriate
- Swipe-back behavior
- iOS keyboard and accessory behavior
- iOS permission prompts
- Share Sheet
- Photos / Files integration
- Face ID / Touch ID
- APNs notification behavior
- Universal Links
- Background execution limitations
- Dark Mode
- Dynamic Type
- VoiceOver
- Haptic conventions

### Android

Design for:

- Edge-to-edge layouts
- Display cutouts
- Navigation gesture / system navigation
- System Back
- Material interaction conventions
- Android keyboard behavior
- Android permission prompts
- Android photo picker / file picker
- BiometricPrompt
- FCM notifications
- Android App Links
- Background execution limitations
- Dark Mode
- Font scaling
- TalkBack
- Android haptics

## Permissions must be platform-aware

Never assume that requesting a permission works identically on both platforms.

For each permission-dependent feature define:

```text
Feature
  ↓
Why permission is required
  ↓
Platform-specific education
  ↓
iOS / Android OS permission
  ↓
Granted
  ├── Continue
  └── Permanently denied → Settings recovery
```

The feature's product behavior must remain consistent even when the underlying OS implementation differs.

This applies to:

- Camera
- Microphone
- Photos
- Files
- Location
- Notifications
- Sensors
- Bluetooth where required
- Biometrics

## Camera and scanner parity

Tools such as:

- QR Scanner
- Document Scanner
- Passport Photos
- Media Saver where applicable

must have equivalent capabilities on iOS and Android.

Test:

- Permission denied
- Permission revoked after previously granting it
- Camera unavailable
- App backgrounded during capture
- App killed during capture
- Low-light camera behavior
- Image picker fallback
- Rotation/orientation
- Multiple-page capture
- Save/export
- Native sharing

## Notification parity

Every notification feature must be tested independently on:

### iOS

- Notification permission not requested
- Permission denied
- Permission allowed
- Notification settings changed externally
- Focus / notification modes
- Scheduled notifications
- Deep-link opening
- App terminated
- App backgrounded

### Android

- Notification permission behavior by Android version
- Permission denied
- Notification channels
- Channel disabled
- Battery/background restrictions
- Scheduled notifications
- Deep-link opening
- App terminated
- App backgrounded

The user-facing feature should not expose unnecessary platform complexity, but the design system must account for it.

## Deep-link parity

Every deep link must have an equivalent destination on both platforms.

Example:

```text
Notification
      ↓
Deep Link
      ↓
Resolve feature
      ↓
Restore context
      ↓
Open exact content/action
```

Examples:

```text
Prayer reminder
→ Prayer detail

Bill reminder
→ Specific bill

Medication reminder
→ Specific medication entry

Calendar event
→ Specific event

Parcel update
→ Specific parcel

Shared health record
→ Shared record
```

If the app is not installed, define the fallback behavior.

If the user is signed out, preserve the destination through authentication.

## Responsive design

Lume is mobile-first, but "mobile-first" must not mean "one fixed phone layout."

Design systems must account for:

- Small phones
- Large phones
- Foldables where practical
- Different aspect ratios
- Dynamic text sizes
- One-handed use
- Landscape where the feature supports it
- System font scaling
- Accessibility settings
- Notches/cutouts
- Safe areas

Do not design using a single device screenshot as the specification.

## Design system requirement

Create a platform-aware design system:

```text
Lume Design System
├── Shared tokens
│   ├── Typography
│   ├── Spacing
│   ├── Radius
│   ├── Elevation
│   ├── Icons
│   ├── Motion
│   └── Semantic colors
│
├── Shared components
│   ├── Cards
│   ├── Lists
│   ├── Forms
│   ├── Sheets
│   ├── Dialogs
│   ├── Empty states
│   ├── Error states
│   └── Tool shells
│
└── Platform adapters
    ├── iOS
    │   ├── Navigation
    │   ├── Permissions
    │   ├── Share
    │   ├── Pickers
    │   └── System integrations
    │
    └── Android
        ├── Navigation
        ├── Permissions
        ├── Share
        ├── Pickers
        └── System integrations
```

The visual identity remains Lume. Platform adaptation happens at the interaction/system-integration layer.

## Cross-platform acceptance rule

A feature is **not complete** until it has been reviewed on both iOS and Android.

For every tool, QA must include:

```text
iOS
├── Small screen
├── Large screen
├── Dark mode
├── Accessibility text scaling
├── Permission states
├── Offline state
├── Notification behavior
├── Share/export
├── Deep link
└── App lifecycle

Android
├── Small screen
├── Large screen
├── Dark mode
├── Accessibility text scaling
├── Permission states
├── Offline state
├── Notification behavior
├── Share/export
├── Deep link
└── App lifecycle
```

## Cross-platform design principle

**Do not chase pixel-identical UI across iOS and Android at the expense of usability.**

Instead target:

> **Behavioral parity + information parity + brand consistency + native interaction quality.**

A button may look or behave slightly differently because the platform expects it to, while the user's goal, result and data remain identical.

---

# 3. Global Lume Personalization Must Drive Tools

Tool behavior must respect the same independent personalization dimensions defined by the main Lume product prompt:

- Religion
- Country
- Region / state / province
- City
- Language
- Locale
- Currency
- Units
- Timezone
- Interests
- Account state
- Device/platform capabilities

**Never infer religion from country.**

A Muslim user in Pakistan and a non-Muslim user in Pakistan can receive the same Pakistan-localized tools while seeing different Islamic experiences.

Likewise:

- Muslim + UK → Islamic tools available + UK localization
- Non-Muslim + UK → Islamic tools hidden by default + UK localization
- Muslim + Pakistan → Islamic tools + Pakistan localization
- Non-Muslim + Pakistan → Pakistan tools without automatically exposing Islamic tools

---

# 4. Tool Lifecycle Design

Every tool should use the following state machine.

```text
DISCOVER
   ↓
OPEN
   ↓
CHECK CONTEXT
   ├── Auth required → Sign-in gate → Return to original destination
   ├── Permission required → Permission education → OS permission
   ├── Location required → Location explanation → Location selection / permission
   ├── Country unavailable → Explain availability
   └── Ready
        ↓
FIRST LOAD
   ├── Cached data
   ├── Live data
   ├── Local computation
   └── Empty / unavailable
        ↓
PRIMARY EXPERIENCE
   ↓
VALIDATION
   ├── Valid → Calculate / save / fetch
   └── Invalid → Inline correction
        ↓
RESULT
   ├── Save
   ├── Edit
   ├── Share
   ├── Export
   ├── Reminder
   └── Continue / related tool
        ↓
RETURN / REVISIT
```

---

# 5. Every Screen Needs More Than the Happy Path

## 5.1 Loading

Do not automatically use a full-screen spinner.

Prefer:

- Skeleton where layout is known
- Cached data immediately
- Inline loading for secondary content
- Progress for long operations
- Explicit "Building PDF…" / processing states
- Cancel where an operation may take a long time

The source repeatedly uses cached-first `StreamProvider` patterns for weather, currency, fuel and loadshedding so existing data is not hidden behind a spinner. fileciteturn2file9L684-L714

## 5.2 Empty

An empty state must explain:

- What is empty
- Why it is empty
- What the user can do next

Never show a blank page.

## 5.3 Error

Errors should answer:

- What failed?
- Is user action needed?
- Can they retry?
- Will retrying immediately help?

For shared infrastructure such as rate-limited services, distinguish "service busy" from "no internet" where possible. The mosque flow already follows this principle. fileciteturn2file4L620-L634

## 5.4 Offline

Each tool must declare:

```text
offlineMode:
  full
  cached
  partial
  unavailable
```

The UI must be honest about freshness.

Never label cached data "Live."

---

# 6. Authentication Design

Authentication should be **capability-based**, not screen-based.

A tool may be:

- Fully guest-capable
- Guest-capable with local state
- Guest-capable with signed-in sync
- Guest-capable for calculation but sign-in required for history
- Fully account-required

The supplied tool hub already deliberately keeps some experiences usable while signed out and gates only persistence/reminders. Bills and Zakat are explicit examples. fileciteturn2file0L40-L43

### Required UX

When authentication is required:

1. User taps feature/action.
2. Explain the benefit of signing in.
3. Preserve intent.
4. Sign in / create account.
5. Return to the exact action or destination.
6. Never dump the user at Home.

---

# 7. Location & Country Design

Location must be layered:

```text
Country
  ↓
Region / State / Province
  ↓
City
  ↓
Optional precise device location
```

Do not require GPS merely because a city is needed.

The existing mosque and weather experiences demonstrate city-based behavior without requiring GPS; the mosque tool uses the selected city's coordinates and explicitly does not request GPS permission. fileciteturn2file4L320-L327

### Every location-dependent tool must support

- Current selected city
- Change city
- Search city
- Country change
- Missing location
- Stale location
- Location unavailable
- Optional precise-location upgrade

---

# 8. Shared Design Patterns

Lume should standardize these patterns across tools.

## 8.1 Search

- Exact match first
- Prefix next
- Word-start
- Substring
- Keyword/id
- Localized names and aliases
- Arabic / Urdu / Roman Urdu aliases where relevant
- Empty state
- Recent searches where useful
- Clear search

The existing registry search ranking should remain the behavioral baseline. fileciteturn2file0L35-L37

## 8.2 Forms

Every form needs:

- Clear labels
- Correct keyboard
- Input formatting
- Inline validation
- Range validation
- Required/optional distinction
- Preserve valid values after an error
- Submit disabled only when there is a clear reason
- Draft recovery for long forms
- Unsaved-changes handling

The existing Zakat implementation is a strong example: invalid amounts must never silently become zero, drafts are restored, and destructive clearing is separated from saved history.

## 8.3 Destructive actions

Use:

```text
Intent → Confirmation → Action → Success → Undo where possible
```

Explain the consequence.

If deletion cascades to related data, say so before confirmation.

The Committee flow is an example where deleting a member removes collection records and therefore explicitly asks first.

## 8.4 Share

Anything intended to be shared outside Lume should use the **visual share-card system** where appropriate.

Do not simply dump raw text into WhatsApp/social sharing.

Share cards should support:

- Brand
- Title
- Main content
- Source/reference
- Date when relevant
- Localized typography
- RTL
- Correct aspect ratio
- High contrast
- Safe margins
- Preview
- Save image
- Native share sheet

The source already uses rendered PNG cards for Ayah of the Day and Daily Streak; the verse card includes Arabic, translation, reference and wordmark. fileciteturn2file1L117-L131

### Share-card rule

For Quran, Hadith, duas, reminders, quotes, rates, achievements and other shareable content:

```text
Create → Preview → Render → Share
```

Never make sharing depend on copying text unless the user explicitly chooses "Copy text."

---

# 9. Cross-Tool Data Relationships

Lume should feel like **one system**, not 72 mini-apps.

Shared data should propagate automatically where appropriate.

Examples from the existing implementation:

- Selected city → Prayer, Weather, Qibla, Islamic Calendar and other city-scoped tools
- Petrol snapshot → Fuel Cost
- Prayer data → Ramadan
- Prayer log → Calendar activity
- Bills / installments / committee / medication → Calendar
- Quran bookmarks → Reader
- Shared Hijri offset → all Hijri surfaces

Prayer times explicitly write to shared city state so related city-scoped features follow immediately. fileciteturn2file5L377-L387

Calendar already aggregates dated information from multiple sources and hides sources that the user is not allowed to see. fileciteturn2file9L649-L675

### New requirement

Create a **cross-tool dependency map**.

Every feature should declare:

```text
readsFrom:
writesTo:
deepLinksTo:
appearsInCalendar:
appearsInNotifications:
appearsInHome:
canShare:
canExport:
canBePinned:
```

This will prevent duplicate logic and inconsistent states.

---

# 10. Notifications & Reminders

Notifications should be a thin layer over the underlying feature state.

Every notification must have:

- Source feature
- Exact deep-link destination
- Localized title/body
- Permission status
- User-configurable timing
- Quiet-hours behavior
- Duplicate prevention
- Expiration behavior
- Disabled-state handling

If the OS blocks notifications, the UI should say so rather than pretending the reminder is active. The Daily Streak flow explicitly warns when the OS is blocking notifications. fileciteturn2file1L128-L131

### Notification architecture

```text
Feature state
   ↓
Reminder configuration
   ↓
Scheduler
   ↓
Notification
   ↓
Deep link
   ↓
Exact source context
```

---

# 11. Calendar as a Cross-App Surface

The Calendar should remain an aggregation layer, not become a second database.

It can surface:

- Public holidays
- Islamic dates
- User events
- Tasks
- Bills
- Installments
- Committee rounds
- Document expiry
- Medication doses
- Relevant activity summaries

The existing calendar expands recurring sources into concrete dates for the visible range and deliberately avoids leaking dots for hidden/inaccessible tools. fileciteturn2file2L177-L207

### Design rule

Every calendar item must either:

- Open its source tool, or
- Be a user-created event editable in Calendar.

---

# 12. Data Freshness & Source Honesty

Any data-driven tool must visibly communicate freshness when freshness affects trust.

Use states such as:

```text
LIVE
UPDATED 2 MIN AGO
CACHED — UPDATED YESTERDAY
STALE
OFFLINE
SOURCE UNAVAILABLE
ESTIMATE
```

Never disguise fallback data as live data.

The Currency tool already distinguishes Karachi Sarafa, International Spot and stale fallback states; National Savings distinguishes bundled, cached/stale and live data. This should become a global Lume pattern.

---

# 13. Calculators Must Be Trustworthy

For calculators:

- Validate every input
- Define realistic ranges
- Show units
- Explain formulas where useful
- Never turn malformed input into zero
- Never calculate from unavailable live data
- Show source/date for external rates
- Explain assumptions
- Distinguish estimate from official result
- Allow reset
- Preserve drafts for complex calculations
- Save snapshots if history is supported

Examples already documented include BMI range guards and Zakat rate freshness/input guards. fileciteturn2file6L414-L457

---

# 14. Sensitive & Private Features

Sensitive features require stronger UX and privacy treatment.

Potentially sensitive examples include:

- Health records
- Vaccinations
- Medication
- Pregnancy
- Cycle tracking
- Financial records
- Expenses
- Lending
- Documents
- Personal notes
- Saved religious activity

For each sensitive feature, define:

- Account requirement
- Local vs cloud storage
- Encryption expectations
- Sharing permissions
- Export
- Delete
- Session/device protection
- Data retention
- What appears in notifications
- What appears on Calendar/Home
- What is excluded from search previews

Health records already demonstrate private storage, RLS, signed URLs, export and controlled sharing; this should become the reference architecture for sensitive data. fileciteturn2file7L521-L568

---

# 15. Feature-Specific End-to-End Design Expectations

The following groups must be designed as complete journeys.

## Prayer & Islam

The existing 17 tools are:


### Prayer & Islam

#### Prayer times

The app's daily prayer schedule for the selected city — the five times plus sunrise, with a live countdown to whichever prayer is next.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

#### Qibla compass

Points the user at the Kaaba, either as a live magnetometer compass or — when the device can't do that — as a plain bearing in degrees.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

### Money & Rates

#### Currency & Gold

One tool, three tabs: live rates and bullion, a converter, and the USD/PKR chart.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

#### Markets

One tool, three tabs: **PSX**, **Global stocks** and **Crypto**.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

### Daily Life

#### Calendar

**One unified calendar.** Holidays, Islamic dates, occasions, tasks, bills, installments, committee rounds, document expiries and medication doses on the same grid, with the Hijri date on every day.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

#### Weather

Current conditions, the next 24 hours, a 5-day forecast and air quality for the selected city.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

### Personal

#### To-dos

A full task manager: lists, priorities, due dates and times, recurrence, sub-tasks, tags, reminders, multi-select and a calendar view.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

#### Notes

Sticky notes with colours, pins, tags, checklists and archive.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.

#### Parcel tracker

Track Pakistani courier parcels — **TCS, Leopards, PostEx, Trax, CallCourier, BlueEx and Daewoo FastEx** — with a checkpoint timeline and push alerts.

**End-to-end design must define:** entry → context → main action → states → persistence → reminders → sharing/export → deep links → return path → settings → localization → accessibility.


---

# 16. Proposed Improvements / Additions to the Existing Tool System

These are **product improvements**, not claims about the current implementation.

## 16.1 Create a universal Tool Detail Contract

Every tool should have a machine-readable product definition:

```text
ToolDefinition
├── identity
├── visibility
├── localization
├── permissions
├── authentication
├── data
├── actions
├── states
├── persistence
├── notifications
├── sharing
├── export
├── dependencies
├── privacy
└── analytics
```

This lets Lume generate consistent navigation, search, gating and design behavior without duplicating rules.

## 16.2 Add a universal "tool state matrix"

For every tool, document:

| State | UI | User action | Data behavior |
|---|---|---|---|
| First use | onboarding / empty | Start | initialize |
| Loading | skeleton / progress | wait/cancel | fetch/process |
| Success | result | continue/save/share | persist if needed |
| Empty | explanation | create/search/retry | no data |
| Error | actionable error | retry/edit | preserve valid state |
| Offline | cached/degraded | retry later | no false freshness |
| Permission denied | explanation | Settings/retry | feature disabled |
| Signed out | sign-in CTA | Sign in | preserve intent |
| Expired | refresh/retry | refresh | revalidate |
| Destructive | confirmation | confirm/cancel | mutate + undo |

## 16.3 Add "first successful action" optimization

Do not make users configure everything before they can experience value.

Design the shortest successful path first.

Examples:

- Calculator → enter values → result
- QR → scan → result
- Prayer → see today's times
- Weather → see today's weather
- Notes → write first note
- To-do → create first task

Then offer deeper configuration after value is established.

## 16.4 Add "return context"

When a user leaves a tool for:

- Sign in
- Settings
- Permission
- Share
- External map
- Camera
- File picker

return them to the exact state they left.

## 16.5 Add universal draft recovery

For long or valuable forms:

```text
Typing → autosave draft → app closes → reopen → restore
```

Show:

- Draft restored
- Discard draft
- Continue

## 16.6 Add universal export/durability strategy

Any user-created information that matters should have a path to leave the app:

- Export PDF
- Export image
- Share
- Download
- Copy structured data
- Backup/sync

The health-record source explicitly treats export as a durability invariant: the record must remain reachable outside the app. fileciteturn2file7L523-L533

## 16.7 Add a universal permission education layer

Before invoking OS permission:

```text
Why we need it
↓
What happens if allowed
↓
Allow
↓
OS permission
```

If denied:

```text
Feature unavailable
Why
Open Settings
Try again
```

This is especially important for:

- Camera
- Photos/files
- Notifications
- Location
- Sensors
- Microphone/audio

## 16.8 Add feature relationship recommendations

At the end of a tool, recommend only genuinely related next actions.

Examples:

```text
Prayer times
→ Prayer tracker
→ Qibla
→ Nearby mosques

Fuel prices
→ Fuel cost

Currency
→ Markets

Quran
→ Bookmarks
→ Search Quran
→ Share ayah
```

Do not use generic "Recommended" noise.

## 16.9 Add cross-tool search intent

Search should understand:

- Tool name
- Alias
- Local language
- Romanized spelling
- User intent
- Country context

For example:

```text
"petrol"
→ Fuel prices
→ Fuel cost

"namaz"
→ Prayer times
→ Prayer tracker

"birthday"
→ Birthdays & anniversaries
→ Age calculator
```

Still preserve deterministic exact-name priority.

## 16.10 Add a universal share-card renderer

One renderer should power:

- Ayah
- Hadith
- Dua
- Rate snapshot
- Achievement
- Reminder
- Quote
- Useful calculation
- Weather snapshot
- Cricket result where appropriate

Each card gets:

- Template
- Content
- Source
- Locale
- Direction
- Brand
- Export size

---

# 17. UX Quality Rules for Every Tool

Lume should reject a design if it has any of these problems:

- Blank screen with no explanation
- Infinite spinner
- Fake live data
- Error with no next action
- Permission request with no explanation
- Auth gate that loses user intent
- Deep link that lands somewhere generic
- Back button that loses form data
- Destructive action with unclear consequence
- Share action that produces unreadable content
- Untranslated server error
- Hard-coded currency
- Hard-coded date format
- Hard-coded English strings
- Wrong RTL behavior
- Hidden feature still leaking into Calendar/Search/notifications
- Tool visible in one surface but absent in another without a deliberate reason
- Cached data presented as live
- Sensitive content exposed in notification previews
- Long forms with no draft recovery
- External action with no return context

---

# 18. Accessibility

Every tool must support:

- Dynamic text sizing
- Screen readers
- Semantic labels
- Sufficient contrast
- Non-color-only status
- Touch targets
- Keyboard correctness
- Reduced motion where applicable
- Haptic feedback only as enhancement
- RTL
- Localization expansion
- Error announcements
- Accessible charts and visualizations

Never communicate meaning through color alone.

---

# 19. Localization

Localization is not just translating strings.

Every tool must account for:

- Language
- Script
- RTL/LTR
- Currency
- Number formatting
- Decimal separators
- Date format
- Time format
- Week start
- Timezone
- Units
- Country-specific terminology
- Local data sources
- Local legal disclaimers
- Local calendar conventions

Quran and Hadith already demonstrate that translation editions and script direction materially affect the UI; the tool system should treat this as a global design requirement rather than a special case.

---

# 20. Design Deliverables Lume Should Produce

For **every tool**, the design output should include:

### A. Information architecture

```text
Entry
 ├── Main
 ├── Secondary
 ├── Settings
 ├── History
 └── Help
```

### B. Screen map

```text
Tool Home
├── Empty
├── Loading
├── Loaded
├── Error
├── Settings
├── Detail
├── Create/Edit
├── Confirmation
└── Success
```

### C. User flows

At minimum:

1. First-time user
2. Returning user
3. Signed-out user
4. Signed-in user
5. Error
6. Offline
7. Permission denied
8. Share/export
9. Delete/reset
10. Deep link

### D. Component inventory

Define reusable:

- App bars
- Search
- Tabs
- Segments
- Cards
- Rows
- Empty states
- Error states
- Bottom sheets
- Dialogs
- Forms
- Date pickers
- Number inputs
- Charts
- Share previews
- Permission prompts
- Auth prompts

### E. State model

Document every state and transition.

### F. Content model

Document:

- Labels
- Empty copy
- Errors
- Helper text
- Success copy
- Accessibility labels
- Localization keys

---

# 21. Suggested Lume Tool Design Workflow

Use this order when designing or implementing a tool:

```text
1. Read feature registry
        ↓
2. Read existing tool behavior
        ↓
3. Identify dependencies
        ↓
4. Identify account/privacy requirements
        ↓
5. Identify location/country/language requirements
        ↓
6. Define user goals
        ↓
7. Design primary happy path
        ↓
8. Design all non-happy states
        ↓
9. Design persistence
        ↓
10. Design notifications
        ↓
11. Design share/export
        ↓
12. Design deep links
        ↓
13. Design accessibility/localization
        ↓
14. Connect to related tools
        ↓
15. Validate against registry visibility
        ↓
16. Test guest + signed-in + offline + permission states
        ↓
17. Test all supported countries/regions/locales
        ↓
18. Test back navigation and return context
        ↓
19. Test destructive/recovery flows
        ↓
20. Only then finalize visual polish
```

---

# 22. QA / Acceptance Checklist

A tool is not complete until:

### Platform parity
- [ ] iOS flow reviewed
- [ ] Android flow reviewed
- [ ] Platform-native back behavior correct
- [ ] Platform-native permission behavior correct
- [ ] Platform-native share behavior correct
- [ ] Safe areas / edge-to-edge correct
- [ ] App lifecycle/resume behavior correct
- [ ] Deep link works on both platforms
- [ ] Notifications work correctly on both platforms

### Navigation
- [ ] Opens from Tools
- [ ] Opens from Search
- [ ] Opens from Home when eligible
- [ ] Deep link works
- [ ] Back navigation is correct
- [ ] External launches return correctly

### Personalization
- [ ] Religion visibility correct
- [ ] Country visibility correct
- [ ] Region visibility correct
- [ ] City behavior correct
- [ ] Language correct
- [ ] Currency correct
- [ ] Units correct
- [ ] Timezone correct

### Account
- [ ] Guest behavior correct
- [ ] Auth gate correct
- [ ] Intent preserved
- [ ] Signed-in sync correct
- [ ] Sign-out behavior correct

### Data
- [ ] Loading
- [ ] Cached
- [ ] Live
- [ ] Stale
- [ ] Empty
- [ ] Error
- [ ] Offline

### Permissions
- [ ] Education
- [ ] Allow
- [ ] Deny
- [ ] Retry
- [ ] Settings recovery

### User data
- [ ] Create
- [ ] Read
- [ ] Update
- [ ] Delete
- [ ] Undo where appropriate
- [ ] Draft recovery where needed

### Sharing
- [ ] Preview
- [ ] Visual card where appropriate
- [ ] Correct localization
- [ ] Correct RTL
- [ ] Native share
- [ ] Save/export

### Notifications
- [ ] Permission
- [ ] Schedule
- [ ] Disable
- [ ] Deep link
- [ ] Duplicate prevention
- [ ] OS-blocked state

### Accessibility
- [ ] Screen reader
- [ ] Dynamic type
- [ ] Contrast
- [ ] Touch target
- [ ] RTL
- [ ] Reduced motion

---

# 23. Important Product Direction

Lume should not become:

> "A collection of 72 utilities placed in a grid."

It should become:

> **One coherent daily-life system where every utility understands the user's context, shares state responsibly with related tools, handles failure honestly, and gives the user a complete journey from discovery to outcome.**

The existing implementation already contains many strong patterns worth preserving:

- Centralized feature registry
- Ranked search
- Two-layer auth gating
- Cached-first data
- Honest source/freshness states
- City-based personalization
- Cross-tool calendar aggregation
- Deep-link-aware notifications
- Visual share cards
- Offline-capable local features
- Device-local handling where appropriate
- Strong failure handling for sensors/network
- Exact validation for calculators
- Explicit privacy boundaries

These should become **system-wide Lume design principles**, not isolated implementation tricks.

---

# 24. Final Rule for Lume

When designing any tool, ask:

> **"If a real person depended on this feature tomorrow, have we designed every step they could realistically encounter?"**

If the answer is no, the feature is not finished.

Design the **whole journey**, not just the screen.

