# Source to Flutter — Home and the Tools hub

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.

Every value the two destinations quote, where it comes from in the prototype,
what it became in Flutter, which repository supplies it and which widget draws
it. The point of the table is the last column but one: at F6 each tool's own
repository takes its field over, and the identifiers are preserved so that is a
substitution rather than a rewrite.

**Nothing here connects to a backend.** `LumeFakeHomeRepository` is a
deterministic fixture carrying the prototype's own figures; it takes the moment
as an argument and never reads a clock.

---

## The registry

| Lume source | Lume field | Flutter model | Flutter repository | UI consumer |
|---|---|---|---|---|
| `data/catalogue.js` | `FEATURES[]` | `LumeFeature` | `kLumeFeatures` (generated) | every surface |
| `data/catalogue.js` | `f.id` | `LumeFeature.id` | — | route param, recents, favourites |
| `data/catalogue.js` | `f.n` | `fallbackName` + `feature<Id>` ARB | — | `LumeFeatureStrings.name` |
| `data/catalogue.js` | `f.m` | `toolStatus<Id>` ARB | `LumeToolStatuses` for four of them | `LumeFeatureStrings.tileStatus` |
| `data/catalogue.js` | `f.i` | `icon` | — | `LumeIcon` |
| `data/catalogue.js` | `f.c` | `category` | — | the hub's blocks |
| `data/catalogue.js` | `f.g` | `group` | — | — (product taxonomy) |
| `data/catalogue.js` | `f.ints` | `interests` | — | the quick grid, the shortlist |
| `data/catalogue.js` | `f.kw` | `keywords` | — | search |
| `data/catalogue.js` | `f.faith` | `faith` | — | `LumeEligibility` |
| `data/catalogue.js` | `f.countries` | `countries` | — | `LumeEligibility` |
| `data/catalogue.js` | `f.adapts` | `adapts` | — | documentation only |
| `data/catalogue.js` | `f.sens` | `sensitive` | — | §61 — never a Home card |
| `data/catalogue.js` | `f.staple` | `staple` | — | the "For you" shortlist |
| `data/catalogue.js` | `f.shareable` | `shareable` | — | F8's share cards |
| `data/catalogue.js` | `f.reqCity` | `requiresCity` | — | F6 |
| `data/catalogue.js` | `f.android` | `androidOnly` | — | F6 |
| `data/catalogue.js` | `CATEGORIES[]` | `LumeCategory` | `kLumeCategories` | the hub's headings |
| `data/tool-specs.js` | `home` | `homeEligible` | — | the quick grid's last resort |
| `data/tool-specs.js` | `quick` | `quickEligible` | — | quick actions |
| `data/tool-specs.js` | `rel` | `related` | — | F6 |
| `core/eligibility.js` | `visible()` | `LumeEligibility.isVisible` | — | every surface |
| `core/eligibility.js` | `PREF_GATED` | `LumeEligibility._prefAllows` | — | `LumeContentPrefs` |
| `core/app-store.js` | `profile.*` | `LumeProfileRecord` | `LumeProfileRepository` | `LumeUserContext` |

## Home's content

| Lume source | Lume field | Flutter model | Flutter repository | UI consumer |
|---|---|---|---|---|
| `catalogue.js` | `WEATHER_BY_COUNTRY[c]` | `LumeWeatherNow` | `LumeFakeHomeRepository` | the strip, the live row, Discover — **three phrases, see below** |
| `tool-data.js` | `daily(base, seed)` | `LumeDayForecast` | ⤴ | the live row's high/low |
| `services/prayer.js` | `prayerState()` | `LumePrayerTimetable` | ⤴ | the strip, the hero, Coming up, the tile |
| `tool-data.js` | `EXCHANGES[code]` | `LumeExchange` | `LumeExchanges` | the market live card |
| `tools/context.js` | `marketSession(ex)` | `LumeMarketState` | `LumeExchangeHours.stateAt` | the market card's meta line |
| `tool-data.js` | `MARKET_HOLIDAYS` | `LumeHoliday` | `LumeMarketCalendar` | ⤴ |
| `tool-data.js` | `LOADSHED[]` | `LumeOutage` + `LumeOutageSlot` | `LumeFakeHomeRepository` | the outage live card, Discover |
| `tool-data.js` | `BILLS[]` | `LumeBillsSummary`, `LumeBillDue` | ⤴ | the bills live card, Coming up |
| `tools/context.js` | `subscriptions().next` | `LumeSubscriptionRenewal` | ⤴ | Coming up |
| `tools/context.js` | `birthdays().next` | `LumeBirthdayNext` | ⤴ | Coming up |
| `tools/context.js` | `documents()` | `LumeDocumentRenewal` | ⤴ | Coming up (the name, never the number) |
| `home.screen.js` | the Qur'an card | `LumeReadingProgress` | ⤴ | At a glance |
| `home.screen.js` | the tasks card | `LumeTaskSummary` | ⤴ | At a glance, the strip's "next up" |
| `tool-data.js` | `fuelFor(country)` | `LumeFuelPrice` | ⤴ | At a glance |
| `tool-data.js` | `CRICKET` | `LumeCricketScore` | ⤴ | Discover |
| `tool-data.js` | `PARCELS[]` | `LumeParcelStatus` | ⤴ | Discover |
| `services/notifications.js` | `NOTIFY.unreadCount()` | `notificationCount` | `LumeFakeHomeRepository.unreadFor` | the header's badge |


### Weather: three levels of detail, three fields

The one thing on Home that is *not* one value rendered three ways. Lume gives
each surface its own phrase, and flattening them would be the conversion
making a composition decision it was not asked to make.

| what | Lume | Flutter field | rendered by |
|---|---|---|---|
| the raw condition | `WEATHER_BY_COUNTRY.PK[2]` — `'Hazy sun · humid'` | `LumeWeatherNow.conditionKey` (`hazySun`) | the live row, the "Right now" card, the Weather tile |
| the Discover card's shorter phrase | `home.screen.js:837`, a fixed literal — `34° and hazy` | `LumeWeatherNow.discoverConditionKey` (`hazy`) | the Discover minicard only |
| the localized copy | none — the literal is English in every language | `AppLocalizations.weatherHazy` → `homeWeatherAnd(temp, condition)` | ⤴ |

The reference's live row reads "Mostly clear · Rain 64%" in the same state, so
three surfaces genuinely say three different things about one city's weather.
`discoverConditionKey` is a key rather than a transformation of
`conditionKey` for exactly that reason: which phrase a surface uses is
composition, not formatting.

A country with no short form of its own falls back to the full condition,
lower-cased into "{temp} and {condition}". The reference cannot do this — its
literal says "hazy" in London too, because the markup never varies.

### The badge: a count of surviving sources, not a number

`NOTIFY.unreadCount()` is `build()` filtered by `!read && !expired`, and
`build()` drops every source whose *tool* the user cannot see (`allowed(src)`
asks the catalogue's own gate) and then the ones their preferences switch off.
So the badge is a function of the profile, and the fixture carries it per
state rather than flat. Measured with
`docs/conversion_archive/tool/probe_notifications.mjs`:

| state | badge | what dropped |
|---|---|---|
| `default_pk`, `muslim_pk`, `named_pk`, `no_interests_pk` | 13 | — |
| `prefs_off_pk` | 12 | `markets.move` |
| `muslim_gb`, `default_us` | 10 | also `loadshed.next` and `trains.delay`, whose tools are `countries: ['PK']` |

## Home's selections

Each of these is a *decision* rather than a value, and each is a pure function
in `LumeHomeComposer` so it can be asserted without a frame.

| Lume source | what it decides | Flutter |
|---|---|---|
| `slideScore()` | which slides, and in what order | `LumeHomeComposer.heroScore` / `.hero` |
| `renderQuickTools()` | the eight tiles | `.quickTools` |
| `QUICK_ACTIONS` + `spec.quickEligible` | the five pills | `.quickActions` |
| `liveCards()` | the "Right now" row | `.live` |
| `upcomingItems()` | the "Coming up" rows | `.upcoming` |
| the `data-faith` / `data-loc` attributes | which cards exist | `.glance`, `.discover` — asked of the catalogue instead |
| `greetingKey(hour)` | the greeting | `LumeGreeting.forHour` |

## The hub's selections

| Lume source | what it decides | Flutter |
|---|---|---|
| `renderChips()` | which chips | `LumeToolsQuery.build` |
| `applyFilter()` | which tools survive the chip and the query | ⤴ |
| the "For you" branch | the shortlist | `LumeToolsQuery._isShortlisted` |
| `badgeCount()` | which tiles carry a count | `LumeToolsScreen.attention` |
| `renderRecents()` | the recents strip | `LumeEligibility.recentFeatures` |

## What a screen never touches

* the clock — `LumeClockScope`, injected;
* the locale — `LumeFormatting`, built from the profile and the widget tree;
* the country, the city, the faith preference, the interests — `LumeUserContext`,
  read through `LumeProfileScope`;
* a global — there is none; the fixture repository is a provider.
