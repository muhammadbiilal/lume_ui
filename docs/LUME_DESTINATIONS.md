# Home, the Tools hub, and the foundation under them

The two destinations that set the pattern for the other four, and the shared
page furniture, registry and repositories they established.

---

## 1. The page

A primary destination is a [`LumeDestinationPage`]: one scrolling column, its
own `PageStorageKey`, the product's reading measure, and clearance for the
floating navigation bar at compact widths. It carries a `Material` at its root
so text has a default style, and it optionally takes an `onRefresh`.

```dart
LumeDestinationPage(
  storageId: 'home',
  semanticLabel: l.navHome,
  onRefresh: controller.refresh,
  slivers: <Widget>[ … ],
)
```

The furniture it is filled with lives in `core/widgets/lume/`:

| widget | what it is |
|---|---|
| `LumeGreetingBar` | the greeting header — Home's, and Home's alone |
| `LumePageHead` | the title block every other destination wears |
| `LumePageSection` | a block, with its heading and optional "see all" |
| `LumeSectionHeading` | the heading on its own, for a block that is not one |
| `LumeHorizontalStrip` | a row that scrolls sideways and bleeds to the gutter |
| `LumeTileGrid` | a grid whose rows are as tall as their own tallest tile |
| `LumeHeaderButton` | a 38-point control, with a count when it has one |
| `LumeAvatarButton` | initials, or the neutral glyph |
| `LumeContextStrip` | Home's contextual card |
| `LumeHeroCarousel` | the carousel, its slides and its dots |
| `LumeToolTile` / `LumeCatalogueTile` | a quick tile and a catalogue tile |
| `LumeQuickActionPill` / `LumeRecentPill` | the two pill shapes |
| `LumeLiveRow` / `LumeProgressCard` / `LumeStatRow` | the three card shapes |
| `LumeMiniCard` | a card in a horizontal strip |
| `LumeChoiceChip` / `LumeCategoryHeading` | the hub's chrome |

**`LumePageSection` is not `LumeSection`.** The first is a *destination's*
block — a 17-point heading, a 12-point subtitle, 13 points of gap, and children
that carry their own gutters so a strip can bleed. The second is a *tool
screen's* — 15 and 11, its own gutters, `flex-end` alignment. They were
measured side by side rather than assumed to be one thing.

### `LumeTileGrid`, and why not `GridView`

`GridView` takes one aspect ratio for every cell, so the row whose label wraps
to two lines overflows and every other row is padded to match it. A CSS grid's
`align-items: stretch` makes each *row* as tall as its own tallest cell and
leaves the next row alone — which is why "Date Calculator" is allowed to be
taller than "Calculator" beside it without making the row below it taller too.
`LumeTileGrid` is rows of `IntrinsicHeight` with `Expanded` children, which is
that exactly.

---

## 2. The registry

`lib/features/catalogue/` holds the single source of truth for every feature:
85 of them, in six categories, each declaring its identity, its icon, its
category, its interests, its search keywords and its gating.

**Three gates, and none derived from another.**

| gate | source | means |
|---|---|---|
| faith | `LumeFeature.faith` | part of the Islamic experience |
| country | `LumeFeature.countries` | the markets it has launched in |
| preference | `LumeContentPrefs` | content the user switched off |

`LumeEligibility` is the only place any of them is read. Home, the hub, search,
recents, deep links and the notification engine all ask the same
`isVisible()`, so a feature cannot be hidden from one surface and reachable
from another — which is what makes §64's defence in depth hold rather than
being a list of places to remember.

`reasonFor()` returns *why*, not just *whether*, because an honest unavailable
state has to say which wall the user hit, and a test that asserts only "hidden"
cannot tell a faith gate from a country gate.

```dart
eligibility.visibleById('quran', user)   // null unless the experience is on
eligibility.reasonFor(feature, user)     // faith · country · preference
eligibility.recentFeatures(user)         // filtered on the way *out*, too
```

**A country never implies a faith and a faith never implies a country.** A
Muslim user in Japan gets the Islamic experience and no Pakistani service; a
non-Muslim user in Pakistan gets the services and none of the experience. The
same is true of language, of the interest list and of the tools selected — and
`catalogue_test.dart` asserts each of those independently.

---

## 3. Home

Nine blocks in a fixed order, three of which can be absent:

1. the app bar — greeting, date, city, search, notifications, avatar
2. the context strip — the next prayer, or the weather
3. the hero carousel — two to four ranked slides
4. quick actions — hidden below three
5. quick tools — eight tiles
6. **Right now** — hidden when nothing is live
7. **At a glance** — up to three cards, each gated differently
8. **Coming up** — hidden when there is nothing
9. **Discover** — a horizontal strip

The order is fixed and is not personalised (§49). What is personalised is what
goes *in* each block, and every one of those decisions is a pure function in
`LumeHomeComposer` — so the composition can be asserted without pumping a
frame, and a screen cannot quietly acquire an opinion about what it shows.

**Two rules run through every list.**

* Nothing sensitive is promoted. A private tool can be a quick *action*,
  because adding an expense is a task; it is never a card that says what is in
  it (§61).
* Nothing hidden can leak in. Every candidate goes through `LumeEligibility`,
  so a faith or country feature that is off cannot arrive through the carousel,
  the grid, the live row, upcoming or Discover (§64).

**The carousel** caps at four (§26), so the six slides compete. The scores are
the design's: the next prayer 100, planning 80, trains 74 or 78 with the
interest, reading 70, money 45 or 62, tools 40. A slide's gate is the gate on
what it opens, asked of the catalogue rather than restated on the slide.

**The quick grid** round-robins across the user's interests — one tool per
interest per pass, four passes — because without it a single interest fills all
eight tiles on its own. Favourites come first, then recents, then the
round-robin, then the fallbacks, then anything Home-eligible, then anything at
all; a hidden favourite is skipped without leaving a gap.

### States

Home models seven, and each is independently reachable because the repository
can be told to fail one section and answer another:

| state | what it draws |
|---|---|
| loading | Home's own shape in skeletons, not a spinner |
| ready | the composition |
| empty | the sections with nothing in them simply absent |
| partial | one section's notice beside the others' content |
| stale | a "Not current" line above the section |
| offline | an "Offline" line above the section |
| failed | the error state, with one way back |

§108's rule holds throughout: a cached figure and a live one do not look the
same.

---

## 4. The Tools hub

Five blocks: the page head, search, the chips, "Recently used" (hidden below
two — one pill is not a history) and the catalogue, or one of two empty states.

Three things narrow it, and they compose in a deliberate order:

1. **search**, which always looks across the whole visible catalogue — being on
   "For you" must never stop someone finding a tool by name;
2. **the category chips**;
3. **"For you"**, a shortlist rather than a straitjacket: an interest match,
   something reached for recently, or a tool nearly everyone wants.

**Two counts, deliberately different.** The heading counts what this user can
*reach* — 68 in Pakistan without the Islamic experience, 85 with it — so it
agrees with the catalogue below it in every market. A category heading counts
what is *shown*, which a chip or a query changes. Conflating them is the defect
the registry tests exist to catch, along with the other one: five destinations
and eighty-five tools are not the same number either.

**One corner, three markers, declared precedence.** A sensitive tool wears a
lock, a tool with something needing attention wears a count, a
country-restricted tool wears a dot. Privacy wins over a number: a lock is a
promise and the count can wait for the tool itself.

---

## 5. Is the market open?

`lib/features/markets/` answers it, and the answer is four corrections to the
prototype's six-line version.

| | prototype | here |
|---|---|---|
| clock | the **device's** | the exchange's, through `LumeZone` |
| close | inclusive — 15:30 reads as open | exclusive |
| holidays | a table it ships and never reads | consulted, and the floating ones derived |
| week | Monday–Friday for every exchange | the exchange's own |

```dart
LumeExchanges.psx.stateAt(instant)
// → isOpen, closure (outsideHours · weekend · holiday), localTime, holiday
```

The clock is injected and the comparison is on whole minutes, so every boundary
is a test rather than a coin toss: a minute before the open, the opening
minute, a minute after, a minute before the close, the close, a minute after,
the weekend, a fixed holiday, a floating one, Easter, a device in another zone,
and both halves of the daylight-saving year.

**Thanksgiving is the fourth Thursday of November**, not 28 November. The
prototype's pinned date is right in about one year in seven; in 2026 it trades
through Thanksgiving and shuts on an ordinary Saturday.

### The zone is an interface, and the table behind it is not production code

`lume_zone.dart` declares the whole of what the product asks of a timezone:

```dart
abstract interface class LumeZone {
  String get id;
  Duration offsetAt(DateTime instant);
  DateTime wallClockAt(DateTime instant);
}

abstract interface class LumeZoneDatabase {
  LumeZone? zoneFor(String id);
  Iterable<String> get ids;
}
```

Two methods and one lookup. `LumeExchangeHours` takes a `LumeZone` and has
never seen a daylight-saving rule.

`LumeTimeZone` is one implementation: six zones, two rule families, no package,
chosen so the fixtures are deterministic and the tests run the same in Karachi
and in Auckland. **It is reference infrastructure and it is not fit to be a
production timezone authority.** It has no history, so a date before the rule
it encodes is wrong. It has no future beyond today's legislation, so a
jurisdiction that moves or abolishes its change makes it wrong without telling
anyone. It knows six zones and there are hundreds. It cannot express a zone
being renamed, split or redefined, all of which happen.

**Copying this table into Dayroz would be a decision, not a port, and this
phase has not made it.** What Dayroz installs is a maintained IANA database —
the `timezone` package, or the platform's own — behind `LumeZoneDatabase`.
`LumeRuleTableZones` is the single binding that hands the conversion's table to
something that asked for a database, and `exchange_fixtures.dart` is the only
file under `lib/` that names the table at all.

`market_zone_boundary_test.dart` holds the seam shut: the calculator answers
correctly for a `+05:45` zone declared inside the test file, its source
contains none of `lume_time_zone`, `LumeTimeZones` or `LumeDstRule`, and a
three-line database with no rules satisfies the interface.

---

## 6. Data

Nothing connects to a backend. `LumeHomeRepository` is a contract;
`LumeFakeHomeRepository` is a deterministic fixture carrying the prototype's
own figures, and it

* takes the moment as an argument — nothing in it reads a clock;
* returns numbers, dates and **keys** — nothing in it holds a sentence, so the
  same content renders in three languages;
* can be told to be slow, to fail a section, to come back stale or offline, or
  to hold a user with nothing recorded.

At Dayroz integration each tool's own repository takes its field over;
`docs/conversion_archive/HOME_SOURCE_MAP.md` pairs every field with its source
so that is a substitution rather than a rewrite.

One question is answered synchronously rather than fetched:
`statusesFor(user, now: …)` returns the handful of tile status lines the device
can answer — the next prayer and the weather — so Home's strip and the hub's
tile cannot name two different prayers.

---

## 7. Navigation

* Home and the hub are branch roots, built from the same
  `LumeDestinations` definition as every other destination.
* A tool opens **on the branch it was opened from**: `/home/tool/calculator`
  from Home, `/tools/tool/calculator` from the hub. Back therefore lands where
  the user actually was, and nothing has to remember anything.
* A tool selects **no** destination — the pill hides — because
  `LumeRoutes.destinationAt` answers for the location, not the branch.
* Opening a tool writes it to recents, and the hub re-reads them on every
  arrival; the list is filtered again on the way out, so a feature that has
  since been hidden cannot resurface through history.
* **A tool route asks the catalogue before it draws anything.** A deep link is
  the one surface with no tile to hide, so `/branch/tool/:id` resolves the id
  against the same `LumeEligibility` reading the same profile, and hands the
  verdict to the frame. A tool the user may not have and an id that does not
  exist produce an identical refusal — same title, same subtitle, same copy —
  because "you may not have this" and "there is no such thing" must not be
  distinguishable, or the refusal is itself the disclosure (§64).
* The tab set is personalised by country, which lives on the profile. Changing
  it re-presents the bar in the same frame and rebuilds no branch — Trains
  leaves the bar and Explore takes the slot, and every other branch keeps its
  stack, its scroll and its position.

---

## 8. Accessibility

* Every section title is a heading, so a reader can jump between them.
* A tile announces its name and its status once — the visual composition is
  excluded and the container carries the label.
* A marker announces what it means: "Private", "2 need attention". (There is
  no "Local service" marker — the prototype draws none, and Flutter does not
  invent one. See `KNOWN_DIFFERENCES.md` D28.)
* The hub announces how many tools are showing after a search.
* A chip announces that it is selected.
* Numerals are isolated so a time or an amount does not reorder in an RTL
  sentence.
* At 200 % text the hero grows rather than clipping its own words, every card's
  figure ellipsises rather than pushing the card off the screen, and the
  notification badge falls back to a plain dot rather than covering the control
  it belongs to — the count stays in that control's accessible name, which is
  where a screen reader reads it from at every scale.

**Two recorded exceptions to §9's 44-point target.**

* The header's three controls are 38 with 12 between them, which is the
  design's geometry; the reachable area is 50 wide inside a 59-tall bar, and
  padding each to 44 would push the avatar off a 359-point phone.
* A section's "see all" link is 23 tall. Padding it to 44 would add five points
  to every section head and move the whole page down; the link is a shortcut to
  a destination the tab bar already carries at full size.

Both are deliberate, both are recorded here, and neither is a full-width
primary action.

---

## 9. Where the evidence is

| | |
|---|---|
| element positions against the prototype | `docs/conversion_archive/DESTINATION_PARITY.md` |
| what the comparison caught | `docs/conversion_archive/DESTINATION_VISUAL.md` |
| the six destinations' contracts | `docs/conversion_archive/DESTINATION_INVENTORY.md` |
| every value's source | `docs/conversion_archive/HOME_SOURCE_MAP.md` |
| permitted differences and corrections | `docs/conversion_archive/KNOWN_DIFFERENCES.md` |

---

## 10. What is not done

* **Today, Explore, Trains and Profile** are still the F3 fixture screen. The
  foundation above was cut against all six contracts so they need no new
  chrome, but they are not implemented.
* **A tool screen** is still the F3 fixture. Home and the hub navigate to it
  correctly; what it draws is F6.
* **The zone database.** The interface is in place and the calculator depends
  on nothing else; what sits behind it is a six-zone rule table that is not
  production-grade. See §5.
* **The notification engine.** The badge's number is fixture data carrying the
  reference's value per state — 13 in Pakistan, 12 with the content switches
  off, 10 abroad, which is a count of the notification sources a profile
  leaves standing. Deriving it from sixteen live sources is §48's work.
* **A tool's own status line** — four of them would be live in the prototype
  and two are here (the prayer and the weather). The money figures follow the
  market's budget and arrive with their tools at F6.
* **The first-run gate** remains off, because no repository in this build is
  durable. Unchanged from F4C.
