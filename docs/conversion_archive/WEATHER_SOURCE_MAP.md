# Weather: the market-to-source map

Conversion evidence for the forecast-fixture audit that closed F5D's open
weather items. Every surface that shows weather now reads one port of the
reference's own code — `lib/core/fixtures/lume_reference_weather.dart` — and
every value below was produced by running the reference, not by reading it.

## How the values were obtained

`weather_truth.mjs` (conversion scratch tooling) imports
`assets/js/data/catalogue.js` and `assets/js/data/tool-data.js` as the ES
modules they are and calls the functions the screens call:

| function | used by | what it is |
|---|---|---|
| `LUME.weatherFor(country, tz)` | Home's live row, Explore's card | `WEATHER_BY_COUNTRY[country]`, else `WEATHER_BY_ZONE[tz prefix]`, else `WEATHER_BY_ZONE.Europe` |
| `LUME_DATA.daily(base, seed)` | Home's forecasts, the notification forecast | five days from a Park–Miller generator seeded with `country.charCodeAt(0) * 17` |

`test/core/fixtures/lume_reference_weather_test.dart` holds that output for all
twenty markets and asserts the Dart port reproduces it exactly: base reading,
today and tomorrow, highs, lows, rain, condition and icon.

## Classification

| class | meaning |
|---|---|
| **reference** | written down in the reference (`WEATHER_BY_COUNTRY`, or a measured value) |
| **derived** | computed by the reference's own rule from reference data (`daily()`, the zone fallback) |
| **fixture-only** | a value the reference renders but this build carries as a pinned literal |
| **unavailable** | not defined for the market by anything this build can reach — `null` through the contract, nothing drawn |

## The twenty markets `WEATHER_BY_COUNTRY` writes down

Base reading is **reference**. Today and tomorrow are **derived** (`daily()`),
shown as high / low / rain % / condition. Temperatures are Celsius; each
surface converts with `LumeFormatting.unitsFor(country)`, so New York reads
Fahrenheit.

| market | base (temp · feels · phrase · rain · wind) | today | tomorrow | Home live row & forecasts | Explore card | notification forecast |
|---|---|---|---|---|---|---|
| PK | 34 · 38 · Hazy sun · humid · 8 · 14 | 34 / 23 / 64 / Mostly clear | 36 / 27 / 1 / Cloud building | yes | yes (sunset measured) | yes |
| IN | 33 · 37 · Humid · light haze · 25 · 12 | 33 / 24 / 70 / Cloud building | 34 / 23 / 16 / Mostly clear | yes | **unavailable** — no sunset | yes |
| GB | 21 · 19 · Mostly clear · 12 · 8 | 21 / 10 / 21 / Cloud building | 25 / 17 / 10 / Cloud building | yes | yes (sunset measured) | yes |
| US | 24 · 24 · Light cloud · 20 · 10 | 24 / 12 / 10 / Mostly clear | 29 / 20 / 50 / Mostly clear | yes | yes (sunset measured) | yes |
| CA | 17 · 15 · Cloudy · 35 · 13 | 17 / 6 / 65 / Mostly clear | 22 / 10 / 69 / Mostly clear | yes | unavailable — no sunset | yes |
| AE | 39 · 44 · Clear · very warm · 0 · 11 | 39 / 30 / 16 / Mostly clear | 41 / 32 / 63 / Mostly clear | yes | **unavailable** — no sunset | yes |
| SA | 40 · 42 · Clear · 0 · 9 | 40 / 30 / 31 / Mostly clear | 42 / 31 / 44 / Mostly clear | yes | **unavailable** — no sunset | yes |
| AU | 26 · 26 · Bright and breezy · 10 · 18 | 26 / 17 / 16 / Mostly clear | 28 / 19 / 63 / Mostly clear | yes | unavailable — no sunset | yes |
| DE | 18 · 17 · Overcast · 40 · 11 | 18 / 6 / 54 / Cloud building | 21 / 10 / 36 / Mostly clear | yes | unavailable — no sunset | yes |
| FR | 21 · 20 · Sunny spells · 15 · 9 | 21 / 11 / 32 / Cloud building | 21 / 12 / 42 / Cloud building | yes | unavailable — no sunset | yes |
| TR | 27 · 27 · Clear · 5 · 12 | 27 / 16 / 21 / Mostly clear | 28 / 18 / 12 / Mostly clear | yes | unavailable — no sunset | yes |
| ID | 31 · 35 · Humid · showers later · 60 · 7 | 31 / 22 / 70 / Cloud building | 32 / 21 / 16 / Mostly clear | yes | unavailable — no sunset | yes |
| MY | 32 · 36 · Humid · afternoon storms · 65 · 6 | 32 / 24 / 26 / Mostly clear | 33 / 21 / 27 / Mostly clear | yes | unavailable — no sunset | yes |
| BD | 32 · 37 · Humid · 45 · 10 | 32 / 22 / 5 / Mostly clear | 33 / 25 / 31 / Mostly clear | yes | unavailable — no sunset | yes |
| EG | 35 · 36 · Clear and dry · 0 · 14 | 35 / 26 / 43 / Cloud building | 37 / 27 / 4 / Cloud building | yes | unavailable — no sunset | yes |
| NG | 30 · 34 · Humid · cloud building · 55 · 9 | 30 / 21 / 16 / Mostly clear | 34 / 23 / 65 / Cloud building | yes | unavailable — no sunset | yes |
| ZA | 22 · 21 · Clear · 10 · 16 | 22 / 13 / 26 / Cloud building | 25 / 16 / 29 / Cloud building | yes | unavailable — no sunset | yes |
| SG | 31 · 36 · Humid · passing showers · 60 · 8 | 31 / 21 / 31 / Mostly clear | 33 / 22 / 44 / Mostly clear | yes | unavailable — no sunset | yes |
| JP | 26 · 27 · Mild and clear · 20 · 10 | 26 / 16 / 59 / Cloud building | 31 / 21 / 53 / Mostly clear | yes | unavailable — no sunset | yes |
| CN | 25 · 26 · Hazy sun · 25 · 11 | 25 / 14 / 65 / Mostly clear | 30 / 18 / 69 / Mostly clear | yes | unavailable — no sunset | yes |

Home's live row shows the phrase's first clause (`desc.split(' · ')[0]`);
Explore's card shows the whole phrase. All 26 phrases are ARB keys in English,
Urdu and Arabic.

## Every other market

The reference derives a climate from the reader's IANA zone prefix —
`Africa`, `Asia`, `Europe`, `America`, `Pacific`, `Indian`, `Atlantic` —
falling back to `Europe`. The table is ported and asserted. It is **derived**
where a zone is supplied; this build knows a zone for only the six markets
`LumeTimeZones` names, all of which are in the twenty, so for every other
country it is **unavailable**: Home draws no live weather, Explore no card,
and the feed builds no forecast row.

## Values that are not the weather

| value | class | surface | record |
|---|---|---|---|
| "34° and hazy / Feels like 38°" | fixture-only (reference literal) | Home's Discover card, every market | C21 — reproduced; Dayroz supplies a real display condition |
| "updated 4 min ago" | fixture-only (reference literal) | Explore's weather subtitle | E1 — reproduced as a timestamp; Dayroz supplies a real observation time |
| Sunset 18:27 · 19:35 · 19:20 | reference (measured) | Explore's card, PK · GB · US | Maghrib from the measured timetable; any other market is unavailable |

## Defects this audit removed

| where | was | now |
|---|---|---|
| Home fixture, Pakistan | tomorrow's low 25 | 27, as `daily()` computes and the running prototype renders |
| Home fixture, India / UK / US / UAE / Saudi Arabia | today and tomorrow typed by hand — e.g. UK tomorrow "overcast 20 / 12, 55 %", US today 26 / 17 | `daily()`'s own days |
| Home fixture, India | live row "Hazy sun" | "Humid", the first clause of its own phrase |
| Home fixture, any other market | an invented overcast 18° climate with invented days | unavailable |
| Explore fixture, any market outside six | Germany's reading ("Overcast 18°") | the reference's own, where defined; unavailable otherwise |
| Explore fixture, India / UAE / Saudi Arabia | sunset at an invented 18:30 | card unavailable until a real sunset exists |
| Notification fixture, any market but PK / GB / US | Pakistan's tomorrow | the market's own `daily()` tomorrow in its own units; no row where undefined |

**Dayroz obligation.** Replace `lume_reference_weather.dart` with the weather
adapter, carrying provenance and observation time through the same nullable
contracts, and supply sunset from the solar calculation the prayer schedule
uses.
