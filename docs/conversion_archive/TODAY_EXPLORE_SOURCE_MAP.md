# Source to Flutter — Today and Explore

> **Temporary conversion evidence.** Removed with the prototype at Phase F9.

Every value the two destinations quote, where it comes from in the prototype,
what it became in Flutter, which repository supplies it, which widget draws it,
and **what has to replace it at Dayroz integration**. The point of the table is
the last column: the identifiers are preserved so that is a substitution rather
than a rewrite.

**Nothing here connects to a backend.** `LumeFakeTodayRepository` and
`LumeFakeExploreRepository` are deterministic fixtures carrying the prototype's
own figures; both take the moment as an argument and neither reads a clock.
`LumeTodayDay.durable` is `false`, and every Explore source reports
`LumeSourceFreshness.fixture` — never `live`.

The narrative contract these tables belong to is
[TODAY_EXPLORE_CONTRACT.md](TODAY_EXPLORE_CONTRACT.md); the defect numbers
(T1–T5, E1–E4) and the decisions are there.

---

## Today

| Lume source | Lume field | Flutter model | Fixture | UI consumer | Dayroz source |
|---|---|---|---|---|---|
| `today.screen.js` | `L.dateLong(now)` | `LumeTodayHeader.date` | the injected clock | `LumePageHead.subtitle` | the device clock |
| `today.screen.js` | `' · 15 Rabi’ al-Awwal'` | `LumeTodayHeader.hijri` | literal (T4) | `LumePageHead.subtitle` | a real Hijri conversion — the Islamic Calendar tool, F6 |
| `today.screen.js` | `(h * 60 + m) / 1440` | `LumeDayProgress.minuteOfDay` | the injected clock | `LumeDayRing` | the device clock |
| `today.screen.js` | `#dayRingText`, static | `LumeDaySummary` × 3 | `kReferenceTasksDone`, `kReferenceTaskCount`, `kReferenceMeetingsLeft` (T1, C23) | `LumeRingCard.text` | **derived from the task store and the calendar** |
| `today.screen.js` | `today.prayerStreak` 12 | `LumeTodayStat.prayerStreak` | literal | `LumeStatCard` | the Prayer Tracker's store |
| `today.screen.js` | `today.readToday` 18 | `LumeTodayStat.readToday` | literal | `LumeStatCard` | the Quran reader's session log |
| `today.screen.js` | `today.dailyStreak` 12 | `LumeTodayStat.dailyStreak` | literal | `LumeStatCard` | the Daily Streak tool |
| `today.screen.js` | `today.steps` 4.2 k | `LumeTodayStat.steps` | literal | `LumeStatCard` | the platform's step counter |
| `today.screen.js` | `L.num(2) + '/' + L.num(5)` | `LumeTodayStat.tasksDone` | the same two constants (T2, C23) | `LumeStatCard` | **derived from the task store** |
| `today.screen.js` | the ayah, static | `LumeAyahReflection` | `arabic`, `translation`, `surah`, `chapter`, `verse` | `LumeQuoteCard` | the Quran corpus and the reader's chosen translation |
| `today.screen.js` | the thought, static | `LumeThoughtReflection` | literal | `LumeQuoteCard` | the Daily Quotes tool |
| `today.screen.js` | standup 9:30, review 14:00 | `LumeAgendaEntry` (`event`) | `_baseEvents` (T5) | `LumeAgendaRow` | the device calendar |
| `today.screen.js` | groceries 18:30 | `LumeAgendaEntry` (`errand`) | `_baseEvents` (T5) | `LumeAgendaRow` | the Shopping List tool |
| `today.screen.js` | `toolCtx('loadshed').loadshed()` | `LumeAgendaEntry` (`outage`) | `lumeReferenceOutage` | `LumeAgendaRow` | the Loadshedding service, per area |
| `today.screen.js` | `ctx.prayer.state().main` | `LumeAgendaEntry` (`prayer`) | `_prayerByCity`, measured per city | `LumeAgendaRow` | the real solar calculation for the city, date and method |
| `today.screen.js` | five `.task` rows | `LumeTodayTask` | `_tasks` (T5) | `LumeTaskRow` | the To-do tool's store |
| `today.screen.js` | `data-loc` on row 1 | `LumeTodayTask.countryLabel` | `'PK'` | `LumeTaskRow.label` | the market's own utility naming |
| `today.screen.js` | four `.habit` rows | `LumeHabit` | `_habits` | `LumeHabitRow` | the Habits tool's store |
| `today.screen.js` | `.private` copy | — (no data at all) | — | `LumePrivateCard` | **nothing.** §61/§62: the card names areas and carries no record |
| `today.screen.js` | `.sticker--slow` | — | `assets/images/today/sticker.svg` | `LumeTodaySticker` | — (artwork) |

**What ticking a task does.** `LumeTodayRepository.setTaskDone` returns a fresh
`LumeTodayDay` with `durable: false`. The list moves; the ring's sentence and
the statistic do not, because they are the reference's literals (C23).

**The Dayroz obligation, stated once.** The ring's sentence, the tasks
statistic and the task rows must be derived from **one eligible task query** —
the same query, asked once, filtered by the same eligibility the rows are
filtered by. Three independent reads would reproduce the reference's defect in
production: a count that disagrees with the list beneath it. Until that query
exists, `kReferenceTasksDone`, `kReferenceTaskCount` and
`kReferenceMeetingsLeft` hold the reference's figures in the fixture, and
`stage_one_fixtures_test.dart` asserts they are not derived, so nobody can
mistake the reproduction for working software.

---

## Explore

| Lume source | Lume field | Flutter model | Fixture | UI consumer | Dayroz source |
|---|---|---|---|---|---|
| `explore.screen.js` | `#exploreSub` | `LumeExploreData.localised` | `eligibility.localisedCountries` | `LumePageHead.subtitle` | the capability registry |
| `explore.screen.js` | `#exploreBack`, hidden unless off-tab | `LumeExploreScreen.onBack` | `LumeDestinations.orderFor` | `LumePageHead.leading` | the same, unchanged (D34) |
| `explore.screen.js` | `.feature`, faith-swapped | `LumeFeaturedCollection` | `LumeFeatureId` + its target | `LumeFeatureCard` | an editorial collections service |
| `explore.screen.js` | `weatherFor(country, tz).temp` | `LumeExploreWeather.temperature` | `_weather`, per market | `LumeWeatherCard` | the weather adapter |
| `explore.screen.js` | `.desc` | `LumeExploreWeather.conditionKey` | `_weather`, a whole phrase per market | `LumeWeatherCard.description` | the weather adapter |
| `explore.screen.js` | rain, wind | `rainPercent`, `windKph` | `_weather`, per market | `LumeWeatherStat` | the weather adapter |
| `explore.screen.js` | sunset | `LumeExploreWeather.sunsetMinute` | `_sunsetByCountry`, the prayer calculation's | `LumeWeatherStat` | the same solar calculation |
| `explore.screen.js` | `L.num(4)` | `LumeExploreWeather.observedAt` | `now - kReferenceWeatherAgeMinutes` (E1, C24) | the weather section head, via `minutesAgoAt(clock.now())` | **a real observation time.** The label is already computed from a timestamp, so this is a change of value, not of screen |
| `explore.screen.js` | six `LOCAL_SERVICES` | `LumeAroundService` | `_around`, per market, gated by `LumeEligibility` | `LumeListRow` | each tool's own repository |
| `explore.screen.js` | `.score`, `data-int="cricket"` | `LumeExploreScore` | literal (E3) | `LumeScoreCard` | a live cricket feed |
| `explore.screen.js` | `NEWS.PK` / `NEWS.GLOBAL` | `LumeNewsArticle` | `_newsPk`, `_newsGlobal` | `LumeArticleRow` | the News service, per country |
| `explore.screen.js` | `renderNews` art | `LumeArticleTone` | painted from three colours | `LumeArticleArt` | — (the rule, not the files) |
| `explore.screen.js` | four `.minicard`s | `LumeCollectionCard` | `_collections`, first faith-gated | `LumeMiniCard` | an editorial collections service |
| `explore.screen.js` | three `.list-row`s | `LumeNearbyPlace` | `_nearby` — Karachi, everywhere (E2, C22) | `LumeListRow`, or a notice when the source is `unavailable` | **a real places source keyed to the city.** The section-level unavailable state already exists, so a source that cannot locate the reader can say nothing rather than fall back |

**What "freshness" means here.** `LumeExploreSnapshot.freshness` carries one
`LumeSourceFreshness` per `LumeExploreSource` — weather, around, score, news,
collections and **nearby**. The fixture reports `fixture` for every source it
answers and `unavailable` for every source it is told to fail; it never reports
`live` or `cached`, because it is neither, and a test asserts that it cannot.
A section whose source is `unavailable` draws a notice in its place rather than
disappearing, and the other sections are unaffected.

---

## What neither repository does

* read a clock — both take `now`;
* hold a sentence — both return numbers, keys and structured fields, so the
  same content renders in three languages;
* claim freshness it does not have;
* persist anything.
