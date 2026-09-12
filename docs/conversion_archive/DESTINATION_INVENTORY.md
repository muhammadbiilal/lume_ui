# The six destinations, as the running source defines them

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.
> The product-facing description of what Flutter does is
> `docs/LUME_DESTINATIONS.md`.

Read out of the rendered prototype with
`docs/conversion_archive/tool/measure_destinations.mjs`, which drives the shell
to a destination with a known profile and dumps both the element bounds and the
**composition** — which slides survived, which eight tools filled the grid,
which categories rendered and how many tools each holds.

F5A implements **Home** and the **Tools hub**. The other four are inventoried
here so the shared foundation those two establish cannot need re-cutting when
Today, Explore, Trains and Profile arrive.

---

## 1. The shape they share

Every destination is a `.screen`: an absolutely-positioned scroller with
`padding-bottom: 118px` at compact (clearance for the floating bar) and `40px`
once navigation is a rail. Above that sits either

* an **`.appbar`** — greeting, date, city, and up to three 38-point controls.
  Home alone; or
* a **`.page-head`** — a 28-point title, a 13-point supporting line and one
  trailing control. Tools, Today, Explore, Trains and Profile.

and below it a stack of `.section` blocks, each optionally headed by a
`.section__head` of a 17-point title, a 12-point subtitle and a 12-point accent
link.

| piece | measured at 390 × 844 |
|---|---|
| `.screen` | 390 × 816, `0 0 118`, scrolls |
| `.appbar` | 59 tall, `10 20 4` |
| `.page-head` | 67 tall, `12 20 0`; title 28/35/−0.038em |
| `.section` | `margin-top: 24`; children carry the gutters |
| `.section__head` | `margin-bottom: 13`, baseline-aligned |
| `.section__link` | 23 tall, `4 2`, 12/700 accent, 13 px chevron |
| `.hscroll` | 12 px gaps, `2 20 6` |
| `.iconbtn` / `.avatar` | 38 × 38 |
| `#tabbar` | 366 × 62 at `x: 12, y: 770` — floats **over** the screen |

---

## 2. Home

| | |
|---|---|
| route | `/home` |
| destination | first, in every market |
| module | `assets/js/screens/home.screen.js` (949 lines) |
| Flutter | **implemented** — `lib/features/home/` |

**Sections, in order.** App bar · context strip · hero carousel · quick actions
· quick tools · Right now · At a glance · Coming up · Discover.

**Shared components.** `.appbar`, `.ctx`, `.hero`/`.slide`, `.qaction`,
`.tools-grid`/`.tool`, `.livecard`, `.progress-card`, `.stat-row`, `.crow`,
`.hscroll`/`.minicard`, `.section__head`.

**Data.** `catalogue.js` (weather, features), `services/prayer.js`,
`tools/context.js` (markets, loadshedding, bills, subscriptions, birthdays,
documents), `tool-data.js` (exchanges, fuel, cricket, parcels).

**State it depends on.** Country, city, the faith preference, the interest set,
favourites, recents, the four content switches, the display name, the hour.

**Eligibility.** Every candidate goes through `eligible.visible()`. Sensitive
tools are never promoted as a card but may be a quick *action*.

**States.** The prototype has no loading, empty, error, offline or stale state
at all: it renders synchronously from fixtures. Three sections hide when they
have nothing — quick actions below three, Right now with no live card, Coming
up with no item.

**Refresh.** None. `onEnter` restarts a one-second prayer countdown and
`onLeave` stops it.

**Header actions.** Search (a sheet), notifications (a nested destination),
profile (a destination).

**Nested routes.** None of its own; a tool, search and the notification centre
all ride on its branch.

**Responsive.** Sections cap at `--content-max + pad*2` and centre from medium
up. The grid stays four columns, two below 360.

**RTL.** The carousel opens on the last slide unless `scrollLeft` is set to
`scrollWidth`; the chevrons mirror; the strips reverse.

**Localisation.** `home.*`, `greet.*`, `slide.*`, `qa.*` — Urdu and Arabic
carry most of these; `qa.*`, `home.tomorrowIn`, `home.liveNowSub` and the whole
`f.*` status vocabulary are English-only in the prototype.

**Motion.** Slide drag and snap; a pulsing live dot; a bar animated over 1.1 s;
a staggered section entrance.

**Known prototype defects.** C12 (the Discover strip is gated by attribute, not
by eligibility, so a switched-off content type still appears), C15 (the
progress bar is emitted with valid data and never reaches the screen), C16 (the notification badge is a 7-point dot given
a number), C17 (the outage card names a slot that has already ended, in a clock
format the user did not choose), C19 (the quick-action strip cancels its own
padding), C20 (a live card overflows its column by 22.31). The market session
is C11 and has its own section below.

---

## 3. Tools

| | |
|---|---|
| route | `/tools` |
| destination | second, in every market |
| module | `assets/js/screens/tools.screen.js` (266 lines) |
| Flutter | **implemented** — `lib/features/tools/` |

**Sections, in order.** Page head · search · chips · Recently used · the
catalogue · the empty state.

**Shared components.** `.page-head`, `.search`, `.chips`/`.chip`, `.recent`,
`.cat`/`.cat__head`/`.cat-grid`/`.cat-tool`, `.empty`.

**Data.** The catalogue, and two tools that can report a count (`bills`,
`documents`).

**State it depends on.** Country, the faith preference, interests, recents, the
content switches — and two pieces of presentation state it owns: the chip and
the query.

**Eligibility.** The same selector. The heading's count is
`visibleFeatures().length`; a category heading's count is what is *shown*.

**States.** Two empty states with different copy — a search that matched
nothing, and a shortlist that is empty. No loading or error state: the
catalogue is a constant.

**Refresh.** None. Opening a tool anywhere writes it to recents and every
arrival re-reads them.

**Header actions.** Personalise (a sheet).

**Responsive.** Three columns, two below 360.

**RTL.** The chips and the recents strip reverse; the tiles mirror.

**Known prototype defects.** C13 (the "local service" marker tests a field the
catalogue renamed, so it never renders), C14 (a marker overwrites a count
rather than taking precedence), C18 (search indexes the English name, so an
Urdu reader cannot find a tool by the name on the tile).

---

## 4. Today — *not implemented in F5A*

| | |
|---|---|
| route | `/today` |
| destination | fourth in Pakistan, third elsewhere |
| module | `assets/js/screens/today.screen.js` (390 lines) |

**Sections, in order.** Page head · a progress ring card ("You're on track") ·
a prayer timeline (faith) · Ayah of the day (faith) **or** Today's thought ·
Your day (an agenda with a Week link) · Tasks (with an Add link) · Habits (a
seven-day heat strip) · Private (a locked summary card).

**What it needs from the foundation.** `.page-head`, `.section__head` with a
link, `.ring-card`, `.timeline`, `.quote`, `.list-row`, `.private-card`, the
progress bar — of which the section chrome, the row and the bar are already
shared, and the ring, the timeline and the quote are Today's own.

**Why it matters here.** Today is the only destination with a *faith-swapped
pair of sections* rather than a swapped card, and the only one that draws a
private summary. Neither changes the foundation.

---

## 5. Explore — *not implemented in F5A*

| | |
|---|---|
| route | `/explore` |
| destination | fourth outside Pakistan; reachable by link in Pakistan |
| module | `assets/js/screens/explore.screen.js` (421 lines) |

**Sections, in order.** Page head · a faith-swapped feature banner · Weather
(with a Refresh link) · Around you (hidden when the market has no local
service) · Cricket (interest-gated) · Today's reads (interest-gated) ·
Collections · Nearby.

**What it adds.** A **Refresh** link in a section head — the first section
action that re-fetches rather than navigates — and `data-int`, a *soft* gate
that re-orders relevance rather than hiding a feature.

**Why it matters here.** `LumeSectionHeading` already takes a `linkIcon`, so
the refresh variant needs no new component.

---

## 6. Trains — *not implemented in F5A*

| | |
|---|---|
| route | `/trains` |
| destination | third, **in Pakistan only** |
| module | `assets/js/screens/trains.screen.js` (178 lines) |

**Sections, in order.** Page head · a route search card · You are tracking
(with Refresh) · Today's departures (with All) · Popular routes.

**Why it matters here.** It is the proof that a *destination* can be
country-scoped while the *feature* behind it is merely country-restricted —
`LumeDestinations.orderFor` decides the first and `LumeEligibility` the second,
and F3 already separated them.

---

## 7. Profile — *not implemented in F5A*

| | |
|---|---|
| route | `/profile` |
| destination | fifth, in every market |
| module | `assets/js/screens/profile.screen.js` (46 lines) + `ui/account-ui.js` |

**Composition (binding, §123).** identity · Your Lume · account · support.

**Why it matters here.** Profile renders entirely from the account system, so
it is the one destination whose body is not composed from catalogue data. Its
page head is the shared one.

---

## 8. What is wrong in the reference

Everything below was found by driving the prototype and measuring it. Each is
recorded in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) with the correction.

| # | what | evidence |
|---|---|---|
| C11 | the market session reads the device's clock, closes inclusively, never consults the holiday table it ships, and gives every exchange a Monday–Friday week | `tools/context.js:734`; `MARKET_HOLIDAYS` and `isMarketHoliday` are defined in `tool-data.js:264` and called from nowhere |
| C12 | the Discover strip is gated by `data-loc`/`data-faith` only, so a user who switched cricket off still sees a cricket score | measured: `prefs_off_pk` still lists `PAK 214/4` |
| C13 | the "local service" dot tests `f.loc`; no catalogue entry declares it, and `countries` is the field carrying the same meaning | live probe: `#toolCats .cat-tool__pin` → `{ found: 0 }` |
| C14 | a marker *overwrites* a count rather than taking precedence over it | `tools.screen.js:69` — `badge = …` rather than a branch |
| C15 | the progress bar never renders: `.bar` is a `<span>` left out of the rule block that blockifies `.bar__fill`, so `height` does not apply to it | measured 0 × 0, with its fill 74.47 × 0, `offsetWidth` 196 |
| C16 | the notification badge is a 7-point dot given `n > 99 ? '99+' : n` | measured: `.iconbtn` reports the text "13" |
| C17 | the Discover outage card is fixed markup reading "Next outage 14:00" while the schedule it comes from ends that slot at 16:00 | `LOADSHED` in `tool-data.js:882`, captured at 16:41 |
| C18 | search indexes the English name, so an Urdu reader cannot find a tool by what the tile says | `data-hay = (f.n + ' ' + f.kw).toLowerCase()` |
| C19 | `.qactions` cancels its own padding with a negative margin, so the first pill sits flush against the screen edge while the rest of the page is at 20 — an intentional full-bleed pattern, reproduced | measured: `.qactions` x −20 w 430, first `.qaction` x 0; at 1100, x 237 w 870 against a section of 269 by 806 |
| C20 | a live card overflows its column: 20 + 372.31 = 392.31 in a 390 viewport | measured `#liveNow .livecard` |
| D22 | the status line under every tool is English in all three languages | `f.m` is a catalogue string and no dictionary overrides it |
