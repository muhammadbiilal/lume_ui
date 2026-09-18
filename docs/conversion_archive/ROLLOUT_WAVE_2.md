# F6B closure: rollout wave 2 — provisionally approved, not built

Published before any of it is written, as wave 1 was, and **provisionally
approved** — to be built only once the corrected F6B gate is green. **Nothing
here is implemented.** Membership is derived mechanically from
`measurements/tool_inventory.json` (the data behind `TOOL_INVENTORY.md`):
each of the 65 tools not yet built is put through the rules below in order,
and the first rule it fails is recorded. A tool that fails none is in the
wave. One-offs and tools on their own composition are never picked by rule —
each is inspected and converted on its own.

## The rules, in order

1. **A proven archetype.** A member of one of the 14 archetypes whose
   reference is built. One-offs and own compositions stop here.
2. **No religious text or ruling** without a verified source (C77, C82).
3. **No sensitive records.**
4. **No new native permission** (`needs` names a permission or location).
5. **No live or published feed**: freshness `live`, `delayed`, `daily`,
   `weekly`, `draw` or `cached`, unless the only live thing is a clock on
   the device.
6. **No map tiles.**
7. **No network or backend.**
8. **No new dependency.**
9. **Honest, deterministic fixture data**: a fixture that would stand in for
   the reader's own history fails.
10. **Nothing that must be delivered** (notifications, alarms).
11. **No new composition** under an archetype's name.
12. **No data-model decision**: a records or finance tool the reference keeps
    outside its record layer.

## Wave 2 — five tools

| tool | archetype · reference | reused composition | data | new in Flutter |
|---|---|---|---|---|
| `notes` | Records manager · **Documents** | summary, rows, compact rows, empty state, FAB, a horizontal strip, metrics | a record family on the record layer, seeded deterministically and marked "Sample data" (C85) | the `notes` family's fields |
| `todos` | Records manager · **Documents** | summary with a progress ring, filter bar, rows with a status badge, empty state, FAB | the `todos` family | the family; done/undone as a field |
| `events` | Records manager · **Documents** | rows, empty state | the `events` family | the family |
| `shopping` | Records manager · **Documents** | summary with a progress ring, rows, button row | the `shopping` family | the family; bought as a field |
| `sunmoon` | Context dashboard · **Weather** | context bar, summary, timeline | computed for the reader's city with `LumeSolar` (the same maths Prayer's reference uses, already tested); no fixture figures | a moon-phase function, tested against published phases |

**Reconfirmed before implementation** (reference read in the F6B closure):

- **Events implies no delivery.** `events.tool.js` draws rows and says the
  title on a press; the `events` record schema (`record-schemas.js`) holds
  title, date, time, place, people and notes — no reminder, repeat or alert
  field. Its detail states which time zone the time is in, which Lume will
  answer from the reader's country through `LumeZone`, not a fixed offset. Nothing
  schedules a notification. (Reminders, which do, stay out of the wave.)
- **Sun & Moon is computed, not fabricated.** `c.sunTimes()` takes sunrise
  and sunset from the solar calculation for the profile's city and the moon's
  age from a known new moon (6 Jan 2000 18:14 UTC) and the synodic month; no
  location is read and nothing is live. Lume computes the same for the
  reader's city with `LumeSolar`, and says so where the city is not in its
  table. **To decide in the wave:** the reference puts dawn one hour before
  sunrise and dusk one hour after sunset — fixed offsets, not twilight. Lume
  either computes civil twilight (sun 6° below the horizon) or keeps the
  offsets and labels them; it will not show an offset as a measurement.

**Dependencies.** Nothing native, no package, no network. The record layer
(`LumeRecordRepository`, in memory and declared not durable, C74) takes four
more families. Sun & Moon needs the reader's city coordinates, which
`LumeSolar.coordsFor` holds for the catalogue's cities; a city it does not
know is said, not guessed.

**Held to the same bar as wave 1**: parity cells and counts against the
running reference, localisation parity (en, ur, ar), goldens, the
release-honesty gate (all five are sample-backed except Sun & Moon, which is
computed), and an Android emulator walk.

## Everything else, and the first rule each fails

| tool | archetype | rule | why |
|---|---|---|---|
| `calculator` | — | 1 | one-off or own composition — inspected and converted one by one |
| `converter` | — | 1 | one-off or own composition — inspected and converted one by one |
| `currency` | Data explorer | 5 | a live or published feed (`delayed`, "Interbank composite") |
| `focus` | Clock instrument | 9 | fixture would invent the reader's own data: today's minutes, a streak and a week of sessions are constants — activity the reader never had |
| `reminders` | Records manager | 10 | a reminder must be delivered — notifications |
| `prayer` | Context dashboard | 2 | religious text or ruling — needs a verified source |
| `qibla` | — | 1 | one-off or own composition — inspected and converted one by one |
| `mosques` | Live tracking | 2 | religious text or ruling — needs a verified source |
| `praytrack` | Tracker | 2 | religious text or ruling — needs a verified source |
| `ramadan` | Context dashboard | 2 | religious text or ruling — needs a verified source |
| `fasting` | Tracker | 2 | religious text or ruling — needs a verified source |
| `taraweeh` | Live tracking | 2 | religious text or ruling — needs a verified source |
| `ayah` | Scripture reader | 2 | religious text or ruling — needs a verified source |
| `quran` | Scripture reader | 2 | religious text or ruling — needs a verified source |
| `quransearch` | Data explorer | 2 | religious text or ruling — needs a verified source |
| `duas` | Scripture reader | 2 | religious text or ruling — needs a verified source |
| `names99` | Scripture reader | 2 | religious text or ruling — needs a verified source |
| `hijri` | — | 1 | one-off or own composition — inspected and converted one by one |
| `tasbih` | — | 1 | one-off or own composition — inspected and converted one by one |
| `zakat` | Form calculator | 2 | religious text or ruling — needs a verified source |
| `faraid` | Form calculator | 2 | religious text or ruling — needs a verified source |
| `markets` | — | 1 | one-off or own composition — inspected and converted one by one |
| `fuel` | Data explorer | 5 | a live or published feed (`daily`, "Regulator notification") |
| `fuelcost` | Form calculator | 5 | a live or published feed (`daily`, "Current pump price") |
| `natsavings` | Data explorer | 5 | a live or published feed (`weekly`, "National Savings schedule") |
| `prizebonds` | Data explorer | 5 | a live or published feed (`draw`, "Official draw results") |
| `bills` | Finance dashboard | 5 | a live or published feed (`daily`, "On device + provider") |
| `packages` | Data explorer | 5 | a live or published feed (`weekly`, "Operator tariffs") |
| `ledger` | Records manager | 12 | the reference keeps it in tool state, not the record layer — putting it there is a data-model decision |
| `installments` | Records manager | 12 | the reference keeps it in tool state, not the record layer — putting it there is a data-model decision |
| `committee` | Records manager | 12 | the reference keeps it in tool state, not the record layer — putting it there is a data-model decision |
| `aqi` | Context dashboard | 5 | a live or published feed (`delayed`, "Monitoring stations") |
| `worldclock` | Data explorer | 8 | needs a maintained IANA time-zone database; the build has a six-zone reference table (`lume_time_zone.dart`) |
| `holidays` | — | 1 | one-off or own composition — inspected and converted one by one |
| `loadshed` | Context dashboard | 5 | a live or published feed (`daily`, "Distribution company") |
| `trains` | Live tracking | 5 | a live or published feed (`live`, "Operator live feed") |
| `cricket` | Context dashboard | 5 | a live or published feed (`live`, "Match feed") |
| `docscan` | Camera instrument | 4 | a new native permission (permission) |
| `passport` | — | 1 | one-off or own composition — inspected and converted one by one |
| `vehicle` | Records manager | 5 | a live or published feed (`daily`, "Excise records") |
| `mediasaver` | Records manager | 7 | reaches the network (http) |
| `wastatus` | — | 1 | one-off or own composition — inspected and converted one by one |
| `speedtest` | — | 1 | one-off or own composition — inspected and converted one by one |
| `parcel` | Live tracking | 5 | a live or published feed (`delayed`, "Carrier tracking") |
| `birthdays` | — | 1 | one-off or own composition — inspected and converted one by one |
| `streak` | Tracker | 9 | a tracker's history is the reader's own record — none exists to show |
| `mealplan` | — | 1 | one-off or own composition — inspected and converted one by one |
| `alarms` | Records manager | 10 | an alarm must ring — exact alarms and notifications |
| `vaccines` | Records manager | 3 | sensitive records |
| `health` | Records manager | 3 | sensitive records |
| `play` | Visual library | 11 | draws only rows of games that open nothing — not the visual library's composition, and nothing to make work |
| `babybudget` | Finance dashboard | 12 | the reference keeps it in tool state, not the record layer — putting it there is a data-model decision |
| `habits` | Tracker | 9 | a tracker's history is the reader's own record — none exists to show |
| `water` | Tracker | 9 | a tracker's history is the reader's own record — none exists to show |
| `bmi` | Form calculator | 9 | fixture would invent the reader's own data: its history chart is `value + 1.4 … value` — readings the reader never entered |
| `cycle` | — | 1 | one-off or own composition — inspected and converted one by one |
| `pregnancy` | Context dashboard | 3 | sensitive records |
| `goals` | Finance dashboard | 3 | sensitive records |
| `subs` | Records manager | 3 | sensitive records |
| `meds` | Records manager | 3 | sensitive records |

## Decisions this raises

- **Ledger, Installments, Committee, Baby Budget** are **not in wave 2**.
  They pass every rule but the last; their typed family models — identity,
  money and currency, parties, schedules, contributions, derived balances,
  status transitions, validation, privacy, conflicts, import/export and
  migration — are designed in `FINANCIAL_RECORD_FAMILIES.md`, never as
  generic maps, and wait on that design's approval.
- **World Clock** waits on a maintained IANA database: the package, version,
  licence, tzdb version, update process, size, offline behaviour and testing
  are set out in `WORLD_CLOCK_TIMEZONE.md`. Fixed UTC offsets are not a
  substitute.
- **The one-offs** (`calculator`, `converter`, `tasbih`, `speedtest`,
  `qibla`, `markets`) and own compositions (`hijri`, `holidays`, `mealplan`,
  `cycle`, `birthdays`, `passport`, `wastatus`) are not chosen by rule;
  Calculator and Unit Converter look dependency-safe and are the obvious
  first inspections.
