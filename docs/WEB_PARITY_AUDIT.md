# Web parity audit — Flutter against the web design

The web prototype (`D:/lume ui web/assets/js/`) is the design Dayroz builds on. This audit reads each web tool's `build()`, screen and sheet beside its Flutter screen, section by section, and records every difference.

**Scope.** All 85 tools, the six destinations (Home, Tools, Today, Explore, Trains, Profile), Notifications, Search, the tab bar, Account and Auth, Onboarding, every web sheet and the share flow. Ten read-only reviewers ran in parallel on 26 September 2026; the findings below are theirs, with file and line references. Nothing here has been fixed yet unless it is listed under **Fixed since the audit**.

**Kinds.** MISSING (web draws it, Flutter does not) · REPLACED (Flutter draws something else in its place) · BEHAVIOUR (a control does something different) · ORDER · COPY (visible English differs) · EXTRA (Flutter adds it). *(documented)* means the Flutter code explains the difference as a deliberate correction; everything else is undocumented.

## Summary

| Area | Tools | Match fully | Worst gaps |
|---|---|---|---|
| Prayer & Islam | 17 | 0 | Mosques replaced whole (**fixed**); Taraweeh replaced whole; Qur'an reader settings missing; Prayer and Ramadan heroes lost their gradients; Qibla, Prayer chips don't open Personalise |
| Money & rates | 15 | 4 (compound, loan, tax, tipsplit) | Markets reduced to a world board; Fuel lost "Do more with this"; copy drift in six tools |
| Daily life | 18 | 0 | Speed Test, Media Saver, WhatsApp Status replaced whole (**fixed**); Holidays lost "Islamic dates"; Loadshed uses the wrong timeline |
| Everyday & Planning | 13 | 1 (datecalc) | Reminders is a different design; Currency's "1 1 PKR" bug |
| Personal | 22 | 2 (learning, recipes) | Cycle's month grid missing; Health's Related records and Export missing; Goals' contribute/Share buttons missing |
| Screens | — | — | Notifications open the wrong place; Explore navigates where web toasts; Today's Share/Bookmark are dead |
| Account & sheets | — | — | **Sign out doesn't sign out**; **Replay the tour doesn't**; the personalise sheet lost location, content switches and Save; `authlegal` and `market` sheets missing; `notifpush` never opened |

Seven tools match the web fully (compound, loan, tax, tipsplit, datecalc, learning, recipes); many more differ only by documented corrections.

## Fixed since the audit

- **Personalise sheet spun forever** — fixed (`53f701e`): its controller started from a `const` set the load then added to.
- **Tools header "Personalise"** — now opens the sheet, as `tools.screen.js` does (`53f701e`).
- **Nearby Mosques, Speed Test, Media Saver, WhatsApp Status** — rebuilt to the web composition with the web's sample data and a Dayroz note at each control (this change).
- **Sign out** — asks "Log out?", signs the gate out and says "Signed out"; the account store now follows the gate, so Profile shows the account after sign-in and a guest after sign-out. Revoking this device's own session signs out too.
- **Replay the welcome tour** — opens the tour (Profile and Help), over the reader's saved choices.
- **Personalise sheet** — the web's whole sheet: subtitle; Where you are (region warning, Country, Region, City, each opening the location picker); Language & formatting (language applied at once; units, currency and time drafted); Content (Islamic, News, Sport, Financial information, Recommendations — the content switches written at once, as the web's are); Your interests with its hint, filtered to the country; the data-safe note; and **Save preferences**, disabled under five, which saves the draft, closes and says "Your app has been updated". The cap refusal is said. Every tool's place chip now reaches a location editor through it.
- **Markets price overflow at 200 %**, **untranslated source lines**, **headline figures cut off at 200 %** — fixed earlier (`bc223df`, `ded2925`).

---
## Prayer & Islam: ayah, duas, faraid, fasting, hadith, hijri, names99, prayer, praytrack, qibla, quran, quransearch, ramadan, taraweeh, tasbih, zakat

0 of 16 match fully. Hadith and Zakat are closest.

### ayah
- MISSING: the Listen button in the reader card (web toasts "Playing recitation"). Not documented — web `ayah.tool.js:26` / flutter `quran/presentation/ayah_tool.dart:112-133`
- MISSING: the Commentary (tafsir) section (documented: a placeholder sentence that was wrong for 2 of 3 ayat)
- ORDER: translation comes before transliteration; web has transliteration first — web `ayah.tool.js:21-22` / flutter `quran/presentation/quran_text.dart:143-176`
- BEHAVIOUR: web Save (`bookmark:ayah`) favourites the tool; Flutter keeps today's ayah for the session. The comment says web has no handler, which is wrong (`tool.screen.js:242`)
- BEHAVIOUR: web Share always shares the fixed Ar-Ra'd 13:28 card; Flutter shares today's ayah. Not documented
- COPY: web truncates "More verses" subtitles to 62 characters; Flutter shows them in full

### duas
- MISSING: the Arabic line in the featured card for non-Arabic readers. Not documented — web `duas.tool.js:28` / flutter `duas/presentation/duas_tool.dart:199-208`
- REPLACED: category tiles (icon, label, "N duas") became count chips, with an "All" chip added and the header "All" link removed (documented)
- MISSING: the trailing Arabic snippet on list rows, and the accent icon tone — web `duas.tool.js:50,53`
- BEHAVIOUR: a row opens a detail sheet instead of `share:duas` (documented)
- BUG: search skips titles (web matches title and translation; the Flutter doc comment says titles are searched) — flutter `duas/data/duas_fixtures.dart:84-96`
- COPY: the Listen toast is "Playing" instead of "Playing recitation"

### faraid
- EXTRA: a context bar with the country chip
- COPY: the note text differs ("This calculator only covers…" vs "This follows the standard Sunni shares…") — web `i18n/tools.js:418` / flutter `app_en.arb:15709`
- MISSING: the 4-step progress list (Estate, Debts, Heirs, Shares). Not documented — web `faraid.tool.js:19-24`
- REPLACED: heir rows with steppers became plain number fields. Not documented — web `faraid.tool.js:31-34` / flutter `faraid_tool.dart:309-341`
- REPLACED: the Distribution donut became a two-column table. Not documented — web `faraid.tool.js:35-43` / flutter `faraid_tool.dart:372-389`
- COPY: heir rules and the "Why these shares" reasons are shorter or different; the no-heirs row is "Unallocated" instead of "Residual estate"
- EXTRA: a net-estate summary card, a remainder warning (documented), and Export/Share

### fasting
- REPLACED: figures come from the reader's own logged fasts (documented: web uses literals and a random heatmap)
- REPLACED: ring centre and value (kept count and rate instead of "8/12" against a target) (documented); ring label "Kept" instead of "Progress"
- MISSING: the heatmap's Less/More legend; 3 state colours instead of 4 levels; not in a card — web `fasting.tool.js:34-35`
- REPLACED: recent rows use medium dates instead of "Today" / "Yesterday" / weekday
- BEHAVIOUR: "Log a fast" saves a record via a sheet (documented); EXTRA: edit/delete, empty, loading and error states

### hadith
- BEHAVIOUR: Save and Share (documented, though "Save does nothing" is inaccurate: `tool.screen.js:242` favourites the tool). Everything else matches.

### hijri
- EXTRA: a "Calculated · tabular Islamic calendar" subtitle and info notice (documented)
- BEHAVIOUR: the month grid always starts on Monday; web uses the locale's `L.weekStart()` — web `tools/context.js:230-231` / flutter `hijri_tool.dart:164-166`
- COPY: "Upcoming dates" vs "Islamic dates"; "Gregorian date" / "Hijri date" vs "Gregorian" / "Hijri"; "The Hijri months" vs "Hijri months"
- REPLACED: 5 fixed events became 6 computed ones; "Laylat al-Qadr (likely)" dropped (documented)
- BEHAVIOUR: the converter is live (documented)

### names99
- Content: 12 of 99 names, the same as web's `NAMES99` (documented)
- COPY: kicker "Names of Allah" vs "Asma ul Husna"; ring label "Names known" vs "Progress"
- REPLACED: caption "Names learned" became "The remaining {n} need a verified source." (documented)
- MISSING: the Practise button and the body Share button (documented)

### prayer
- MISSING: the Hijri-date chip in the context bar — web `prayer.tool.js:74` / flutter `prayer_tool.dart:142-151`
- BEHAVIOUR: the city chip and the Method/Location rows don't open Personalise (web: `sheet:personalise`); the chip reads "City, Country" — web `prayer.tool.js:53,55,72`
- REPLACED: the hero is a plain card; web uses the prayer gradient (`summary--prayer`) — web `prayer.tool.js:21` / flutter `prayer_tool.dart:192-209`
- COPY: "{time} to go" vs bare h:mm:ss; "Progress" vs "Time until the next prayer"; "Today" vs "Today's prayers"; "Sunrise & sunset" vs "Sun & moon"; "Upcoming days" / "Date" vs "Next few days" / "Day"; "Method & location" vs "Calculation"; "Asr calculation" vs "Asr method"
- REPLACED: the next prayer's live badge ("in 1h 05m") became plain text; the sunrise/sunset duo card became metric tiles
- BEHAVIOUR: the countdown doesn't tick (documented); the method is fixed to MWL (documented)
- EXTRA: a notice, empty states, Export and a Share card

### praytrack
- REPLACED: no progress ring on the summary; COPY differences throughout ("Prayed today" → "Today", "Streak" → "Day streak", "Qada" → "To make up", "Mark today" → "Mark today's prayers", "Last five weeks" → "Last 35 days", Qada plan copy)
- REPLACED: prayer rows lost their icon and status badge and became checkboxes (documented: record-backed)
- MISSING: "Log a qada prayer" (documented)

### qibla
- BEHAVIOUR: the city chip has no tap; web opens `sheet:personalise` — web `qibla.tool.js:18` / flutter `qibla_tool.dart:122-125`
- REPLACED: the live compass became a static dial (documented); MISSING: the Kaaba marker on the rim. Not documented — web `qibla.tool.js:30`
- REPLACED: the 3-tile metrics (Qibla, To the Kaaba, Compass) became a summary card; "Compass · Calibrated" dropped (documented); the calibration note replaced (documented)

### quran
- Content: 12 surahs, the same as web's `D.SURAHS` (documented)
- MISSING: the Continue-reading card, the Surah/Juz/Bookmarks segmented control, and the Juz and Bookmarks views (documented)
- MISSING: the "Reader settings" card (Translation, Reciter, Text size, Transliteration). Not documented — web `quran.tool.js:76-82`
- ORDER: search comes first; COPY: search placeholder, ayah count and empty state differ

### quransearch
- MISSING: the "Search in" and "Revealed" filter bars (documented); COPY: empty text and "Suggested" vs "Try". Results and suggestion chips match.

### ramadan
- REPLACED: summaries lack the "night" gradient. Not documented — web `ramadan.tool.js:23,44`
- MISSING: the "Fasts · 30" stat. Not documented — web `ramadan.tool.js:29`
- MISSING (documented): Key dates, Taraweeh timeline entry, month heatmap, "Your Ramadan" meters
- BEHAVIOUR (documented): real Suhoor/Iftar times, computed timeline states and day count
- EXTRA: a context bar, an estimate note, empty states

### taraweeh — whole screen replaced (documented: its mosque data is invented)
- MISSING: the context bar, "Search mosques", the Rakaat filter (All / 8 / 20), the mosques map, the Nearby mosque list with its empty state, the "Closest" metrics, and the reminder note — web `taraweeh.tool.js:24-58`
- EXTRA: a personal night log (streak, Tonight toggle, rakaat, juz stepper, Qur'an progress, 35-night grid)

### tasbih
- COPY: "Round of {n}" vs "of {n}"; "rounds" vs "sets"; "Round complete" vs "Set complete"
- BEHAVIOUR: Reset asks for confirmation and zeroes both count and rounds; web resets at once and keeps sets. Not documented as a correction — web `tool.screen.js:764-770` / flutter `tasbih_tool.dart:250-262`
- MISSING: Recent sessions (documented); EXTRA: a note and a limit toast

### zakat
- REPLACED: context bar items "Nisab (gold): X" and "Rate: 2.5%" became country and "Open market". Not documented — web `zakat.tool.js:17-19` / flutter `zakat_tool.dart:219-235`
- BEHAVIOUR: the nisab stat is the lower of gold and silver (documented)
- ORDER: buttons are Export then Share; web has Share (accent) then Export

---

## Everyday and Planning: age, calculator, converter, currency, datecalc, focus, stopwatch, timer, calendar, events, notes, reminders, todos

1 of 13 matches fully (datecalc); timer differs only in its preset-strip layout.

- **age** — COPY: plural-aware captions (corrected); EXTRA: a future-date hint; Share (C68)
- **calculator** — REPLACED: "Clear / Clear entry" words instead of the "AC" glyph, and an icon instead of "⌫" (documented); EXTRA: history empty state, sub-line and icons; BEHAVIOUR: precedence, divide-by-zero, precision (documented)
- **converter** — MISSING: "Recent" (documented); EXTRA: unit picker, Data note (documented); BEHAVIOUR: Data opens GB→MB where web opens MB→GB (only partly documented); imperial "to" unit fixed (documented)
- **currency** — BUG: the rate line reads "1 1 PKR = 0.0036 USD" (the template already has "1 {from}" and the code passes "1 $from"), on the card, the Popular toasts and the share text — flutter `currency_tool.dart:237,254,306`; MISSING: chart axis labels "30d / 15d / Today" — flutter `currency_tool.dart:363-367`; MISSING: "Recent" (documented); EXTRA: currency picker (documented)
- **datecalc** — matches
- **focus** — REPLACED: shipping builds draw a real session layout; only parity draws the web's (documented); EXTRA: Pause/Resume labels; ORDER: week labels always start Monday (web follows the locale's `weekStart()`) — web `context.js:210-216`; COPY: "Focus finished" vs "Focus session complete"
- **stopwatch** — REPLACED: Reset becomes "Lap" while running (documented C83); EXTRA: "Pause" label and lap icons; COPY: hint and empty text differ
- **timer** — REPLACED (minor): presets scroll horizontally; web uses a plain chips row
- **calendar** — BEHAVIOUR: "+" opens Events' create form (intended); the agenda is time-sorted and each day's Hijri date is exact (documented); ORDER: always Monday-first (web follows `weekStart()`) — web `context.js:230-231`; EXTRA: export
- **events** — rows open records and Upcoming reads the records (documented C86)
- **notes** — rows open notes and New note opens the form; figures come from records (documented)
- **reminders** — REPLACED: the whole screen is a different design (durable reminders, rows with switches, an in-page Add button); MISSING: the engine's record list (search, chips, rows, detail/form), the "Today" summary ("{label} at {at}" / "Nothing scheduled"), the "Coming up" timeline and the floating "Add a reminder" button — web `reminders.tool.js:12-21`, `engine.js:243-246` / flutter `reminder_tool.dart`; COPY: "Add reminder" vs "Add a reminder"
- **todos** — COPY: the section title follows the When chip (web: always "Today"); MISSING: "Coming up" is hidden when empty (web always draws it); BEHAVIOUR: Coming up rows open records and "Add a task" opens the form (not documented for todos); figures from records (documented C86)

## Money & rates: bills, committee, compound, fuel, fuelcost, goldrates, installments, ledger, loan, markets, natsavings, packages, prizebonds, tax, tipsplit

4 of 15 match fully (compound, loan, tax, tipsplit).

- **bills** — REPLACED: badge tones (Due = warn instead of info; Overdue = late ▲ instead of warn !); COPY: note title and text, empty state, trend caption (plus an average), paid-row toast; REPLACED: trend labels are the last six months instead of fixed Apr–Sep
- **committee** — rebuilt around records (documented): a new list screen, a progress bar instead of the ring, "cycle" wording instead of "month", member/payout/chart/history re-specified, action buttons added
- **fuel** — REPLACED: the summary has the accent gradient (web: no tone); grade cells on one line; MISSING: the chart's "Now" label and the **"Do more with this" section** (Fuel cost, Vehicle) — web `fuel.tool.js:43-48`; COPY: "since last update", "All Grades", "Price trend", "Fuel price, last 24 months", "Midgrade" (web: "since last revision", "All grades", "Price history", "Published price, last six months", "Mid-grade"); EXTRA: a source chip and a share card
- **fuelcost** — EXTRA: a country context bar; MISSING: History (documented); REPLACED: 2 decimals instead of 0, and a unit on the fuel cell; COPY: eight labels differ ("People sharing" → "People", "Trip cost" → "Total cost", "Driving alone" → "Solo trip", "There and back" → "Round trip", …)
- **goldrates** — BEHAVIOUR: "Worth" recalculates (documented); EXTRA: share and search. Otherwise matches.
- **installments** — record-backed (documented), with the summary, 5-chip filter, sort (web's "Progress" sort missing), rows, empty state, "Coming up", chart and history all re-specified beyond the general note
- **ledger** — record-backed (documented); COPY: "Owed to you / You owe" instead of "Lent / Borrowed"; EXTRA: search, sort, archived; rows open screens (documented)
- **markets** — reduced to a fixed world board (documented). MISSING: the market chip and `sheet:market`, the freshness line and Change, asset-class tabs, the hero with its chart and 1D–5Y ranges, search/filter/sort, the "Top …" list with See all, the market overview card, and the asset detail view — web `markets.tool.js:43-410`
- **natsavings** — REPLACED: the summary has the accent gradient; the product select became a segmented control (documented); BEHAVIOUR: estimate metrics follow the input (web: fixed) — not documented; COPY: "Best rate", "per year", "Estimate" (web: "Best current rate", "a year", "Estimate a return")
- **packages** — BEHAVIOUR: compare-table rows don't toast (web: `toast:<op> <name>`); REPLACED: the first cell is on one line; COPY: unavailable state, no-match text, "Package details" vs "Full details"
- **prizebonds** — EXTRA: "Change country" on the unavailable state (not documented here); REPLACED: accent gradient on the summary, a segmented denomination, no tint on the draw logo; COPY: empty-state text
- **compound, loan, tax, tipsplit** — match (Share and export additions only)

---

## Daily life (1 of 2): aqi, cricket, docscan, emergency, flights, holidays, loadshed

0 of 7 match fully. Emergency is closest (one documented change).

### aqi
- EXTRA: context bar reads "city, country", adds today's date, and the city opens Personalise; web shows the city only, with no tap — web `tools/daily/aqi.tool.js:18` / flutter `lib/features/aqi/presentation/aqi_tool.dart:110-117`
- REPLACED: the summary caption is the "Estimated for {city} — not measured by a monitoring station" sentence; web's caption is the band badge, which Flutter moves to a full-width footer (documented) — web `aqi.tool.js:22` / flutter `aqi_tool.dart:126-148`
- EXTRA: the summary value carries the unit "AQI"; web shows the number alone — web `aqi.tool.js:21` / flutter `aqi_tool.dart:125`
- REPLACED: the advice card uses `LumeNotice` (no success tone, so a good band shows blue "info"); web uses `UI.noteCard` with a green "ok" tone for good bands — web `aqi.tool.js:25-26` / flutter `aqi_tool.dart:152-157`
- EXTRA: a share card (documented C68) — flutter `aqi_tool.dart:94-102`

### cricket
- MISSING: the green "Live" pill under the overs (documented §45) — web `cricket.tool.js:25` / flutter `cricket_tool.dart:119-149`
- REPLACED: the score card is a plain card; web uses the sport gradient (`tone: 'sport'`), with white text and tinted tiles. Not documented — web `cricket.tool.js:19,35` / flutter `cricket_tool.dart:107`
- MISSING: bowler names are not bold (web wraps them in `<b>`) — web `cricket.tool.js:73` / flutter `cricket_tool.dart:304-312`
- EXTRA: a share card (documented C68)

### docscan
- REPLACED: the animated viewfinder (frame, beam, hint) is a still panel (documented) — web `tools/shared/scanner.js:17-22` / flutter `docscan_tool.dart:316-383`
- COPY: hint reads "Lay the page flat and capture" instead of "Fit the page inside the frame" (not documented) — web `i18n/tools.js:784` / flutter `app_en.arb:15678`
- REPLACED: the Capture icon is a camera; web uses `i-scan` — flutter `docscan_tool.dart:225`
- BEHAVIOUR: Capture and "From gallery" open the real camera and picker; web only showed a toast (documented, made real)
- REPLACED: "How it works" has 3 steps instead of web's 4 (crop, enhance and PDF export dropped) (documented)
- REPLACED: "History" (Tenancy agreement, Utility bill) became a "Pages" list of this session's captures (documented)
- ORDER: the pages section comes before "How it works"; web has it after (not documented)
- EXTRA: thumbnails, remove, Share and Clear

### emergency
- BEHAVIOUR: "Share my location" copies city and country to the clipboard before the toast (documented C67). Everything else matches.

### flights
- BEHAVIOUR: the empty board's "Arrivals" button also clears the search (documented C73)
- BEHAVIOUR: the "Tracked" view ignores whether the tool is a favourite; web lists every flight when `flights` is favourited — web `flights.tool.js:29` / flutter `flights_tool.dart:87-89`
- EXTRA: a header search action; extra gutter on the search field (C69); a flight share card (C68)

### holidays
- MISSING: the month grid (documented) — web `holidays.tool.js:36`
- MISSING: the "Islamic dates" section, shown when Islamic is on (`D.ISLAMIC_EVENTS` rows). Not documented — web `holidays.tool.js:43-45`
- MISSING: the "All" reset button on the no-match state — web `holidays.tool.js:41-42` / flutter `holidays_tool.dart:276-281`
- BEHAVIOUR: "Next holiday" is the nearest date, not the first row (documented, corrected)
- EXTRA: a warning note, "Reference dates, not this year's calendar" (documented)
- COPY: stat "Listed here" instead of "This year"; section "Holidays" instead of "Public holidays"; empty state "No holidays found / Try a different search or type" instead of "No holidays match / Try another type or clear the search."
- EXTRA: CSV export, a header search action, and search that also matches English names

### loadshed
- REPLACED: the schedule uses `LumeAgendaRow` instead of the rail timeline (`UI.timeline` → `LumeTimeline`). Not documented — web `loadshed.tool.js:32-35` / flutter `loadshed_tool.dart:134-155`
- MISSING: each slot's duration ("2h") on the right (`loadshedSlotDuration` exists but is never used) — flutter `loadshed_tool.dart:141-153`
- REPLACED: every slot shows a bolt; web shows it only on the current slot — web `loadshed.tool.js:34`
- REPLACED: the Bills hint moved into the subtitle (documented, 200 % overflow)

## Personal (1 of 2): alarms, babybudget, birthdays, bmi, cycle, documents, expenses, goals, habits, health, learning

1 of 11 matches fully (learning); documents differs only by a documented date fix.

- **alarms** — BEHAVIOUR: on web the whole row is the toggle (`alarmtoggle:id`); in Flutter only the switch is — web `alarms.tool.js:22-23` / flutter `alarms_tool.dart:137-151`
- **babybudget** — REPLACED: opens on a list of budgets, with the dashboard as a second screen (documented, record-backed); the ring shows only with a plan; legend shows percentages (documented); Coming up and One-off rows restyled (documented); EXTRA: stats, action buttons, Categories/Spending sections, notices; COPY: chart caption
- **birthdays** — REPLACED: caption wording, anniversary "{n} years", one-initial discs (all documented); BEHAVIOUR: rows open records and the FAB creates one (documented C86); COPY: "Today" at 0 days
- **bmi** — REPLACED: the band badge moved to the aside and the ring became a bar; no accent gradient — web `bmi.tool.js:22-26` / flutter `bmi_tool.dart:215-226`; REPLACED: the scale is a vertical badge list, not a horizontal segmented bar — web `:28-32`; COPY: "BMI scale" vs "Where that sits", "Healthy weight for you" vs "Healthy", "Ideal weight" vs "Middle of the range", "Healthy weight" vs "Healthy", and the band ranges in words; MISSING: History (documented)
- **cycle** — REPLACED: no `lock` tone, conditional caption; **MISSING: the month grid** (the library doc says a month view is kept) — web `cycle.tool.js:22`; COPY: "History" vs "Recent cycles", phase names shortened; MISSING: the privacy note (documented); EXTRA: stats, current period, estimate, Log button, empty state
- **documents** — REPLACED: expiry dates computed (documented); otherwise matches
- **expenses** — REPLACED: derived "when" labels; Monday-first chart (documented C65); BEHAVIOUR: Add opens the form (documented C74); otherwise matches
- **goals** — REPLACED: empty state without its own action; ring centre without "%" and no "Progress" label; stats "This month" / "Next to complete" vs "Monthly" / "Next completes" (a date); ORDER: the saved line sits below the bar; no per-goal icon tone; COPY: projection text; **MISSING: the "Add a contribution" and "Share" buttons** — web `goals.tool.js:51-53`; EXTRA: a completed/abandoned section
- **habits** — ORDER: summary before the list (web: list first); MISSING: the list search bar; REPLACED: summary (documented); MISSING: the 7-day grid, the heatmap and insights (documented); REPLACED: rows with check toggles (documented)
- **health** — MISSING: the people switcher (documented); REPLACED: summary (documented) and the timeline became a list; **MISSING: the Vitals chart (documented), "Related records" (Vaccines / Meds / Documents) and "Export summary"** — web `health.tool.js:52-62`
- **learning** — matches

## Personal (2 of 2): mealplan, meds, parcel, play, pregnancy, recipes, shopping, streak, subs, vaccines, water

1 of 11 matches fully (recipes). Structural note: on the web, meds, water and shopping are record tools, so the engine puts a records list (search, chips, rows, bulk clear) above `build()` and an "Add" action in the header.

### mealplan
- MISSING: the three summary stats and the "Calories by day" chart (documented D-M2: hard-coded)
- REPLACED: day and slot rows show the reader's own text instead of recipe names and kcal (documented); the dinner icon is `moonStar` instead of `i-moon`
- EXTRA: an edit/clear sheet on slots (documented)

### meds
- MISSING: the records search bar the web engine adds — web `crud-engine.js:176-177`
- REPLACED: Add is a block button at the bottom instead of the header "Add" action — web `engine.js:264-273`
- ORDER: web puts records first and the summary after; Flutter has the summary first — web `engine.js:246`
- REPLACED: the row uses a pill icon with sub = dose and meta = schedule; web uses an initial avatar with sub = "dose · schedule"
- REPLACED: the summary (web: lock tone, "Next dose", name, time, adherence ring; Flutter: a count and "running low") (documented D-Md1)
- MISSING: the "Today" dose timeline, the "Active medication" section with progress bars, and "Needs a refill" (documented D-Md1; the per-row bar is not mentioned)
- REPLACED: the empty state isn't `emptyCollection` with its "Add your first…" call to action and footnote

### parcel
- REPLACED: the Track button sits outside the tracking card; web has field and button in one card. Not documented. Everything else matches.

### play
- BEHAVIOUR: tiles aren't buttons (web: `toast:<name>`); MISSING: best scores and "Recently played"; emoji drawn as icons (all documented)

### pregnancy
- EXTRA: an LMP date field and an empty state (documented)
- REPLACED: the summary lacks the `lock` gradient — web `pregnancy.tool.js:15`
- COPY: "Due {date}" vs "due {date}"
- MISSING: the "This week" card (documented) and the "Appointments" timeline (only half-documented) — web `pregnancy.tool.js:22-31`
- EXTRA: 3 summary stats, a "Milestones" section, a Clear button

### recipes — matches (only the Share card differs, documented C68)

### shopping
- BEHAVIOUR: reads and writes records instead of the 6-item fixture (documented); Share and Clear checked are real (documented C86), and disabled when empty (not documented)
- REPLACED: price is blank when 0 or missing; EXTRA: a "—" group for items with no aisle

### streak
- REPLACED: the summary lacks the `flame` gradient — web `streak.tool.js:15`
- COPY: "Best: {n} days" vs "Best so far: {n} days"; "Consistency" vs "Completion"; "Calendar" vs "Last five weeks"; milestones "{n}-day streak" vs "One week / Two weeks / One month / 100 days"
- REPLACED: the heatmap is a bare 2-state grid, with no card and no Less/More key (2-state documented, card and key not)
- EXTRA: a "Today" check-in row (documented)

### subs
- REPLACED: the third summary stat has an empty label (web: "Renews in") — flutter `subscriptions_tool.dart:667-672`
- MISSING: the sort bar's "Sort" label — web `components.js:307`
- REPLACED: every donut slice is accent; web cycles accent/violet/amber/sky/rose — web `context.js:1396,1402`
- MISSING: category and price on "Coming up" entries — web `subs.tool.js:58`
- BEHAVIOUR: rows open a detail view (documented CRUD); valueSub follows the cycle (documented)
- EXTRA: Active/Cancelled/All chips, a no-match state, an Add button

### vaccines
- MISSING: the person switcher (documented)
- REPLACED: the summary lacks the `lock` tone and its kicker reads "Vaccinations" instead of "Schedule"; COPY: "{n} still due" / "All up to date" vs "{n} due soon" / "Up to date"
- MISSING: the "Records" section title
- REPLACED: row layout; EXTRA: filter chips, an Overdue badge, a detail view
- REPLACED: the empty state hides the summary (web keeps it and shows "No records for this person")
- MISSING: "Set a reminder" (documented D-V3)

### water
- REPLACED: an empty state on an empty day (documented); COPY: "goal" vs "target"; "Logged" stat vs "Day streak" (documented)
- BEHAVIOUR: +250/+500 create records (documented); MISSING: the "This week" chart (documented); EXTRA: the goal editor

---

## Daily life (2 of 2): news, passport, qr, sunmoon, trains, vehicle, weather, worldclock

No tool matches fully; QR is closest (a documented real scanner).

### news — only documented differences (C68, C69). Everything else matches.
### passport
- REPLACED: web draws a small 92×118 dashed frame with a head outline, the specs stacked beside it; Flutter draws a full-width 200-tall tinted frame with the specs below. Not documented — web `passport.tool.js:17-22` / flutter `passport_tool.dart:296-323,448-483`
- REPLACED: button icons (Take a photo `i-image` → camera; Import `i-download` → image)
- BEHAVIOUR: real camera and picker, with a preview and save (documented)
### qr — only the documented real scanner and result sheet
### sunmoon
- BEHAVIOUR: civil twilight for dawn and dusk, computed timeline states, polar wording, unknown-city state (documented C86)
- BEHAVIOUR: Share shares daylight; web falls back to the generic quote card (not documented)
### trains (tool)
- COPY: context bar "Pakistan Railways" vs "National railway"; delay "35 min late" vs "+35m" (not documented)
- REPLACED: From/To are read-only (documented C73); map route reshaped (documented); no-operator state (documented); Share (C68)
### vehicle — documented no-match state and PKR conversion; everything else matches
### weather — MISSING the whole dashboard for a market with no weather entry (documented); everything else matches
### worldclock
- REPLACED (documented, defects 1–20): the "Your time" kicker, zone names, row layout, ahead/behind meta, reader's own clock row, add/move/remove, a real converter, per-minute ticking, error states
- COPY: section "Clocks" vs "Cities"; no-match state "Nothing matches" (search icon) vs "No city matches" (clock icon) (not documented)
- MISSING: the AM/PM period under each time (not documented)

## Home, Tools, Today, Explore, Trains tab, Notifications, Search, tab bar

### Home — block order matches
- EXTRA/BEHAVIOUR: the prayer hero slide opens the prayer tool; on web it has no action. Not documented — web `screens/home.screen.js:546` / flutter `home_composer.dart:99`
- BEHAVIOUR: the "Water" quick action opens the tool; web adds 250 ml in place with a toast. Not documented — web `home.screen.js:265`, `tool.screen.js:249-256` / flutter `home_composer.dart:219`
- BEHAVIOUR: the Discover "Forty duas" card opens Duas; web shows a toast. Not documented — web `home.screen.js:850`
- BEHAVIOUR: the bell badge is a fixed number; web's is the live unread count and respects the badge preference (documented stand-in) — web `services/notifications.js:106-113`
### Tools
- BEHAVIOUR: tile attention counts are hard-coded (bills 1, documents 2); web computes them — web `screens/tools.screen.js:55-64` / flutter `tools_host.dart:43`
- MISSING: a chip for a category with nothing visible in it; web draws every category except faith for non-Islamic readers — web `tools.screen.js:39-42`
### Today
- BEHAVIOUR: the ayah/thought Bookmark and Share buttons do nothing (`onPressed: () {}`); web toggles a bookmark and opens the share sheet — web `today.screen.js:203-204,226-227` / flutter `today_screen.dart:319-328`
- BEHAVIOUR: the stand-up and review agenda cards do nothing; web toasts their titles — web `today.screen.js:110` / flutter `today_fixtures.dart:128,135`
### Explore
- BEHAVIOUR: the featured collection, news rows, news "All", Collections "All" and three collection cards open tools; web shows toasts — web `explore.screen.js:166,207,232,324,338,348,355,362`
- BEHAVIOUR: Nearby rows do nothing (`onTap: () {}`); web toasts each row — web `explore.screen.js:382-398` / flutter `explore_screen.dart:598`
- MISSING: "Today's reads" ignores the news-interest gate (`data-int="news"`) — web `explore.screen.js:318`
### Trains tab — documented real query, swap and date chips (R2/R3); the search toast always says "today"
### Notifications centre
- BEHAVIOUR: every row and banner opens the tool's start screen; web deep-links into the item (`toolstate:…`) and a grouped row only marks read — web `services/notifications.js:258-272` / flutter `notification_host.dart:98-105`
- BEHAVIOUR: the action button never marks the item actioned; `_act` is the same as `_open` — web `notifications.js:274-283` / flutter `notification_host.dart:107`
### Search — the index matches; the Dark mode result gives no "Appearance: {mode}" toast — web `shell.js:529-536`
### Tab bar — matches (plus re-tap pops to the tab's root)

---

## Profile, Account, Auth, Onboarding, sheets, share

### Profile
- BEHAVIOUR: **Sign out doesn't sign out.** It only toasts "Signed out", with no confirmation and no `startupController.signOut()`; `acctLogoutTitle` / `acctLogoutText` are unused — web `services/account-forms.js:345-356` / flutter `account/presentation/profile_host.dart:154`
- BEHAVIOUR: **"Replay the welcome tour" doesn't replay it.** It toasts its own title (also on Help), breaking onboarding's "revisit from Profile" promise — web `account-forms.js:303` / flutter `profile_host.dart:155`, `account_host.dart:618`
- BEHAVIOUR: Sign in / Create account return to Home, not the tab they came from, and the "Welcome back, {name}" toast never shows — flutter `app_router.dart:561-564`
- BEHAVIOUR: the Appearance icon follows rendered brightness, not the stored mode; a guest's photo is never shown

### Account
- REPLACED: Language offers 3 (en, ur, ar); web lists 8 (en, ur, ar, fr, es, tr, id, hi) — flutter `account_routes.dart:967-971`
- BEHAVIOUR: Notifications "Restore dismissed" only toasts (the prefs sheet's Restore does work) — flutter `account_host.dart:590`
- BEHAVIOUR: the Push toggle never asks for permission (documented)
- BEHAVIOUR: Edit profile's Add/Replace photo only toasts; web opens a picker — flutter `account_host.dart:620`
- MISSING/BEHAVIOUR: email change never reaches the verify screen, the pending "Verify" button is missing, and verify's Cancel doesn't cancel — flutter `account_host.dart:301-306`
- MISSING: the dialling-code placeholder on Phone
- BEHAVIOUR: revoking this device's session doesn't sign out — flutter `account_host.dart:422-427`
- EXTRA: a "Send feedback" button that only toasts
- COPY: the signed-out refusal's title and text are swapped — flutter `account_routes.dart:294-311`

### Auth — all eleven screens match
- MISSING: the sign-up "How Lume handles your data" link is dead (no `authlegal` sheet; `onOpenLegal` not passed) — flutter `app_router.dart:523-566`
- BEHAVIOUR: after verifying, Flutter goes Home; web opens Account and toasts "Email changed"
- BEHAVIOUR: auth opened from Profile is never modal (no close, no "Continue as a guest")

### Onboarding — all nine steps match
- MISSING: the closing toasts ("Welcome to Lume" / defaults applied / tour skipped) — flutter `app_router.dart:186-196`
- BEHAVIOUR: the Done step never shows the faith copy (`nextPrayerName` not passed) — flutter `app_router.dart:184-197`
- MISSING: horizontal swipe between steps

### Personalise sheet (web `ui/sheets-markup.js:67-192`, `ui/pickers.js`)
Flutter splits it into an interests-only picker and a location picker (documented D41). Against the web sheet, the interests picker is:
- MISSING: the subtitle "Change any of this whenever you like"
- MISSING: the "Where you are" section (warning card, Country, Region, City); only Account → Region reaches the location picker, so **every tool's city or country chip opens interests, with no way to change location there**
- MISSING: the "Language & formatting" rows (documented D41: own account routes)
- MISSING: the Content switches News, Sport and Financial information, which have no UI anywhere (`persNews` / `persSport` / `persFinance` unused)
- MISSING: the "Your interests" heading, the "Pick at least 5" hint and the data-safe note
- BEHAVIOUR: **there is no "Save preferences" button.** Web's Save stays disabled below 5 interests, then saves and toasts "Your app has been updated". Flutter saves on every tap, so 0–4 interests can be saved. Its comment "the reference's sheet has no Save" is wrong — web `pickers.js:446-475`
- BEHAVIOUR: a tap at the 10-interest cap is silently ignored (web toasts "Up to 10 — remove one first")
- BEHAVIOUR: interests aren't filtered by the chosen country; the sheet isn't `tall`

### Other sheets
- `authlegal`: missing in Flutter
- `notifpush`: built (`showLumeNotificationPushSheet`) but never opened
- `market` (Change market): missing; Markets is reduced to the world board (documented)
- `recdelete`, `search`, `notifprefs`, `confirm`, `share`: exist (the `confirm` sheet's logout use is missing)

### Share flow — matches, with honest outcome toasts (documented D7)
- BEHAVIOUR: a tool with no card opens nothing (web falls back to a stock card)
- MISSING: Today's ayah and thought Share (and Bookmark) are `onPressed: () {}`
