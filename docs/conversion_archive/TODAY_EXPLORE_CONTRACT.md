# Today and Explore — the screen contracts

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.
> The product-facing description of what Flutter does is
> `docs/LUME_DESTINATIONS.md`.

Read from the complete current source — `assets/js/screens/today.screen.js`
(390 lines), `assets/js/screens/explore.screen.js` (421), their stylesheets,
`shell.js`'s visibility gates, the catalogue and the tool data — and from the
**running** screens, measured in five profiles each with
`measure_destinations.mjs --screen today|explore`.

**The inventory summary was wrong about Today's order**, which is why this
exists. It listed "a prayer timeline" and "Ayah of the day" as separate
sections after the ring. The source has a *statistics row* there instead, and
the prayers are not a section at all — they are merged into the agenda and
sorted with everything else.

---

## 1. Today

### 1.1 Section order, as the source emits it

| # | section | gate | notes |
|---|---|---|---|
| 1 | `.page-head` | — | title, date line, **Add** icon button |
| 2 | Day progress (`margin-top: 18px`) | — | `.ring-card` |
| 3 | Statistics | — | `.stats`, three `.stat` cards |
| 4 | Ayah of the day | `data-faith="islamic"` | `.quote` with Arabic |
| 5 | Today's thought | `data-faith="none"` | `.quote`, no Arabic |
| 6 | Your day | — | head + **Week** link, `.timeline` |
| 7 | Tasks | — | head + **Add** link, `.list` of `.task` |
| 8 | Habits | — | `.card.habits`, four `.habit` rows |
| 9 | Private | — | locked `.private-card` |

Measured at 390 × 844, Muslim in Pakistan: page-head y 28 h 67 · ring y 113
h 116 · stats y 253 h 91 · Ayah y 368 h 245.5 · Your day y 637.5 h 677 · Tasks
y 1338.5 h 293 · Habits y 1655.5 h 200 · Private y 1879.5 h 138.88.

### 1.2 Information, data and sources

| element | Lume source | value at the pinned instant |
|---|---|---|
| date line | `L.dateLong(now)`, plus `' · 15 Rabi’ al-Awwal'` when Islamic | "Monday, 7 September · 15 Rabi’ al-Awwal" (PK) · "Monday 7 September · …" (GB) |
| ring | `(now.h * 60 + now.m) / 1440`, redrawn every 60 s | 70 % |
| ring title | `today.onTrack` | "You’re on track" |
| ring text | **static markup, never rewritten and never translated** | "2 of 5 tasks done. One meeting left this afternoon." |
| stats, Islamic | `today.prayerStreak` 12 days, `today.readToday` 18 min | |
| stats, otherwise | `today.dailyStreak` 12 days, `today.steps` 4.2 k | |
| stats, always | `today.tasksDone` 2/5 | |
| Ayah | static markup: Ar-Ra’d 13:28, Arabic + translation | |
| thought | static markup: "Small things done consistently…" / "On building habits" | |
| agenda, base | three literals: standup 9:30 (done), review 14:00 (`now`), groceries 18:30 | |
| agenda, outage | `toolCtx('loadshed').loadshed()`, gated by `eligible.visible('loadshed')` | 19:00 "Islamabad · 1h" |
| agenda, prayers | `ctx.prayer.state().main`, when Islamic | PK 4:20 / 12:07 / 15:41 / 18:27 / 19:47 · GB 4:21 / 13:00 / 16:36 / 19:35 / 21:28 |
| tasks | five static rows; row 1 swaps on `data-loc`, row 4 is `data-faith="islamic"` | |
| habits | four static rows; rows 1–2 are `data-faith="islamic"` | |
| private | static copy, `today.privateTitle` / `today.privateText` | |

### 1.3 Rules

* **Agenda ordering.** Everything carries `{h, m}`, is merged, then sorted by
  `h * 60 + m`. Formatting happens only at draw time — *"a locale-formatted
  string cannot be sorted or compared, and the agenda has to do both."*
* **Agenda state.** `is-now` only where the source sets `now: true` (the
  review). `is-done` where `done: true` **or** the time has passed and it is
  not the `now` item. A past prayer reads "Prayed" with a check glyph; a
  future one reads "Adhan · reminder on" with a bell.
* **Eligibility.** The outage joins only when `eligible.visible(loadshed)` —
  the same selector every other surface asks. Prayers join only when
  `profile.islamic`.
* **Agenda subtitle** swaps: `today.agendaMuslim` / `today.agendaGeneral`.

### 1.4 Interaction

| control | behaviour |
|---|---|
| task row | toggles `is-done`, toasts `today.taskDone` / `today.taskUndone`. **Client-side only — no persistence.** |
| page-head **Add** | toast "New task added" |
| Tasks **Add** link | toast "New task added" |
| Your day **Week** link | toast "Switched to week view" |
| agenda card | `data-act` where it has one (`tool:prayer`, `tool:shopping`, `tool:loadshed`), otherwise `toast:<title>` |
| private card | toast "Unlock to see private records" |
| Ayah / thought | bookmark and share buttons |

**There is no Week screen and no Add-task screen.** Both are toasts. Nothing in
Today navigates to a nested route except the agenda's tool links.

### 1.5 States

Lume defines **none** of loading, empty, error, offline or stale for Today.
Every section is static markup or a synchronous read; the screen has no
repository, no fetch and no failure path. The only variance is the faith
gate, the country gate on one task label, and eligibility on the outage row.

### 1.6 Motion

The ring animates its `stroke-dashoffset` over 1.2 s and is redrawn on a
60-second interval that starts on `onEnter` and is cleared on `onLeave`. The
task checkbox transitions on a spring. A `.sticker--slow` drifts behind the
ring card.

### 1.7 Known source defects

| # | defect |
|---|---|
| T1 | The ring text is static English markup — "2 of 5 tasks done. One meeting left this afternoon." — never rewritten and never translated, and it contradicts the task list whenever a task is ticked. |
| T2 | The tasks statistic is the literal `2/5` and does not follow the list either. |
| T3 | Ticking a task persists nothing; leaving and returning restores all five. |
| T4 | The Hijri date is the literal `15 Rabi’ al-Awwal` for every day of the year. |
| T5 | Agenda times are computed from the real solar calculation, but the three base events and all five tasks are fixed literals with no data behind them. |

**T1 and T2 need a decision rather than a note** — see §3.

---

## 2. Explore

### 2.1 Section order

| # | section | gate | notes |
|---|---|---|---|
| 1 | `.page-head` | — | back button (hidden unless off-tab), title, sub, **Search** |
| 2 | Featured, Islamic | `data-faith="islamic"` | `.feature`, "Forty duas for ordinary days" |
| 3 | Featured, otherwise | `data-faith="none"` | `.feature`, "A calmer week, in seven steps" |
| 4 | Weather | — | head + **Refresh**, `.weather` card |
| 5 | Around you | `#aroundWrap` hidden when fewer than two rows | head + country tag, `.list` |
| 6 | Cricket | `data-int="cricket"` | head + **Scorecard**, `.score` card |
| 7 | Today's reads | `data-int="news"` | head + **All**, `.list` of `.article` |
| 8 | Collections | — | head + **All**, `.hscroll` of four `.minicard` |
| 9 | Nearby | — | head, `.list` of three `.list-row` |

Measured, Muslim in Pakistan: page-head 28/67 · Featured 113/216 · Weather
353/137 · Around you 514/419 · Cricket **hidden** · reads 957/332.94 ·
Collections 1313.94/200.25 · Nearby 1538.19/236.

### 2.2 Data and sources

| element | Lume source | honest? |
|---|---|---|
| sub | `explore.subLocal` / `subGlobal` by `localisedCountries()` | yes |
| featured | static markup, faith-swapped | fixture |
| weather temp, desc, rain, wind | `catalogue.weatherFor(country, tz)` in the user's units | **yes, per country** |
| weather sunset | the solar calculation the prayer times use | yes |
| weather "updated 4 min ago" | `L.num(4)` — **a literal** | **no** |
| Around you | six declared services, each asking `eligible.visible` and its own tool context | **yes, per country** |
| cricket | static markup, `data-int="cricket"` | fixture |
| news | `catalogue.NEWS.PK` when country is PK, else `NEWS.GLOBAL` | fixture, per country |
| collections | four static cards, first `data-faith="islamic"` | fixture |
| nearby | **three hard-coded Karachi venues with distances**, first faith-gated | **no** |

### 2.3 Around you, in detail

Six candidates in a fixed order — fuel, loadshed, goldrates, trains,
emergency, holidays — each dropped when its feature is not visible **or** when
its tool context throws (*"a service that cannot answer right now is left out
rather than shown with a blank where its number should be"*). The section
hides itself below two rows: *"one local service is not a section."*

Measured: Pakistan 6 rows, the United Kingdom 4 (no loadshed, no trains), the
United States 4, Pakistan with the content switches off 5 (no goldrates).

### 2.4 Interaction

| control | behaviour |
|---|---|
| back | `tab:home`, hidden unless Explore is open without a tab selected |
| search | opens the search sheet |
| Refresh | toast "Weather refreshed" |
| Around row | `tool:<id>` |
| Scorecard | `tool:cricket` |
| article | toast "Opening the story" |
| collection card | `tool:quran` for the first, toasts for the rest |
| nearby row | toast |

### 2.5 States

As with Today, Lume defines no loading, error, offline or stale state. The one
conditional presentation is **Around you hiding itself** below two rows.

### 2.6 Known source defects

| # | defect |
|---|---|
| E1 | "updated 4 min ago" is a literal. It is a freshness claim with nothing behind it, and it never changes. |
| E2 | **Nearby is fabricated.** Masjid-e-Tooba, Chai Shai and Hill Park with metre distances are shown to a reader in London and New York exactly as they are in Karachi. The section has no city gate, no source and no unavailable state. |
| E3 | The cricket card's "Live · 2nd Test, day 2" is a literal live claim. |
| E4 | Collections and Featured carry durations and counts ("40 duas", "12 min") for content that does not exist. |

**E2 is the one that needs a decision rather than a note** — see §3.

---

## 3. The three decisions that were taken, and what they cost

Per the visual-authority rule these were traced, classified and **put to a
decision rather than settled here**. All three came back the same way:
reproduce what Lume renders, and record the defect for Dayroz.

### E2 — Nearby. **Decision: reproduce Lume exactly.**

Traced: `explore.screen.js:376–407`, three `.list-row`s in static markup, no
`data-loc`, no city read, no source attribution, no unavailable state.
Classification: fabricated content with a data-accuracy failure — it states a
false fact about the reader's surroundings, and the distance makes the
falsehood specific.

Flutter therefore renders Masjid-e-Tooba · 650 m, Chai Shai · 1.1 km and Hill
Park · 1.4 km in every market, faith-gating the first row exactly as Lume does.
A reader in London is told a Karachi mosque is 650 m away, because that is what
the reference tells them.

**Dayroz obligation.** Nearby must be backed by a real places source keyed to
the user's city, with distances computed from a real location, or it must not
ship. These three rows are a reference fixture reproducing a prototype's bug.

**The Stage 1 boundary, added in the closure pass.** Nearby is a
`LumeExploreSource` of its own: it reports `fixture`, never `live`, and it can
report `unavailable`, in which case the section says so rather than naming a
city the reader is not in. The rows reproduce Lume exactly while the source
answers; the shape Dayroz needs is already there.

### E1 — "updated 4 min ago". **Decision: reproduce it exactly.**

`L.num(4)` is a literal: the same claim in every state, never changing, with no
fetch behind it. Reproduced verbatim, and recorded.

**Dayroz obligation.** The weather adapter must supply a real observation time
and the label must follow it. The values *around* the claim are already honest
— temperature, condition, rain, wind and sunset are all per-country and
per-city — so this is the one part of the weather card that lies.

**The Stage 1 boundary, added in the closure pass.** The claim is reproduced
through a *timestamp*, not a number: `LumeExploreWeather.observedAt` is pinned
four minutes before the injected clock and the screen subtracts. The sentence
appears nowhere in the widget, a later clock reads a larger age, and a real
observation time makes the label true with no change to the screen.

### T1 and T2 — Today's task counts. **Decision: reproduce Lume exactly.**

**This section previously said "nothing in Today needed a decision", and that
was wrong.** T1 and T2 are not reproducible without asserting something false
about the reader: the ring's sentence and the tasks statistic are the literals
5 and 2/5, and a reader outside the Islamic experience has four tasks. The two
halves of the screen contradict each other, on the screen, at the same moment.

The first F5B implementation resolved that by counting the list. That was a
correction rather than a reproduction, it made the Pakistani Muslim cell agree
by coincidence and every other cell disagree with the reference, and it was
never approved. Traced, classified and put to a decision.

Flutter now carries `kReferenceTasksDone = 2`, `kReferenceTaskCount = 5` and
`kReferenceMeetingsLeft = 1`, and both figures are fixed in every state:
ticking a task moves the list and leaves the sentence above it alone, exactly
as the reference does. They are carried as **numbers**, not as a finished
English sentence, so the copy is still translated and the digits are still the
reader's — which is the one part of T1 that is not reproduced, because §11 does
not allow shipping untranslated English.

**Dayroz obligation.** Both must be derived from the task store — from **one
eligible task query**, asked once and filtered by the same eligibility the rows
are filtered by — so the sentence above the list agrees with the list. Three
independent reads would reproduce this defect in production.

**The Stage 1 boundary, added in the closure pass.** The figures are named
constants in `today_fixtures.dart`, not literals in a widget, and
`stage_one_fixtures_test.dart` asserts that they do not follow the list in any
market — so the reproduction is visible as a reproduction rather than looking
like a count that happens to be wrong.

### T3–T5 needed no decision

They are reproducible without asserting anything false about the reader: a
write that does not persist reports `durable: false`, a literal Hijri date is a
date, and a fixed event is a fixed event.
