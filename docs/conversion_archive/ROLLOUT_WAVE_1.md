# F6B rollout wave 1

Published before any wave-1 tool is written. Selected from
`TOOL_INVENTORY.md` §4–5 and `measurements/tool_inventory.json`
(`archetypes.map`), not by convenience.

## The rule a tool had to pass

A tool is in this wave only if every one of these is true:

1. It belongs to an archetype whose reference is built and approved in F6A.
2. Its rendered composition is that archetype's — checked against its whole
   module and every builder and `context.js` function it calls, not its
   spec label.
3. It needs no backend, no live or local feed, no map tiles, no camera or
   gallery beyond F6B's scanner, no alarm or download capability, and no
   notification delivery.
4. Every figure it shows is computed from what the reader enters or from
   fixture data already ported and already honest (C61, C71).
5. It invents no personal record or history for the reader.
6. It needs no religious translation that lacks a verified source.
7. It introduces no new screen archetype.

## Wave 1 — six tools

| tool | archetype · reference | reused composition | data | eligibility |
|---|---|---|---|---|
| `age` | Form calculator · **Tax** | field card (`formGrid`) → summary with stats → meter card → compact rows | the reader's date of birth; today from the injected clock | global, no gate; `aware: locale` |
| `datecalc` | Form calculator · **Tax** | segmented mode → field card → summary with stats → compact rows | two dates or a date and a day count; weekday/weekend counts computed; holiday count from `LumeCalendarFixtures.holidaysFor` (C71) | global; `aware: locale, timezone` |
| `tipsplit` | Form calculator · **Tax** | field card with a chip row and a stepper → accent summary with stats → compact rows | bill, tip and people the reader enters; currency from the profile | global; `aware: currency, locale` |
| `loan` | Form calculator · **Tax** | field card → accent summary with stats → donut card → table → compact rows | principal, rate and tenure the reader enters; comparison rows are the same maths at ±2 points | global; `aware: currency, locale`; export |
| `compound` | Form calculator · **Tax** | field card → accent summary with stats → line chart → table | initial, monthly, rate and years the reader enters | global; `aware: currency, locale` |
| `stopwatch` | Clock instrument · **Timer** | clock face (time, hint, primary and reset) → rows or empty state | the session's own elapsed time, from the injected periodic timer | global |

### What each shares, and what is its own

**`age`.** Shares Tax's field card, summary and compact rows. Its own: one
wide date field; the summary's value is years with a "years" unit and a
"*m* months, *d* days" caption; three stats (days, weeks, hours); a single
meter row for the next birthday ("in *n* days", filled by `1 − days/365`);
three milestone rows at 10 000, 15 000 and 20 000 days. Today counts as
today, not a year away.

**`datecalc`.** Shares the field card, summary and rows, and the segmented
control Timer and Flights already draw. Its own: two modes — *Difference*
(from, to) and *Add or subtract* (start, days) — each with its own fields;
headline in days or a long date; weeks, months (÷ 30.44) and years (÷ 365.25)
as stats; a business-days section of weekdays, weekends and the country's
holiday count. The walk is capped at 4000 days, as the reference caps it.

**`tipsplit`.** Shares the field card and accent summary. Its own: a bill
field with a currency prefix; a five-chip tip row (0, 5, 10, 15, 20 %); a
people stepper; per-person value with tip, total and people as stats; one
"Person *n*" row per person. The stepper is the settings stepper Account
already draws.

**`loan`.** Shares Tax's field card, accent summary, donut and table — the
widest reuse of the reference. Its own: principal, rate and tenure fields;
EMI with total interest, total paid and interest share; a principal/interest
donut; an amortisation table capped at eight years; three comparison rows at
your rate and ±2 points. A zero tenure has no payment (the reference's own
guard against `Infinity`). Export writes the schedule.

**`compound`.** Shares the field card, accent summary and table, and the line
chart Currency & Gold draws. Its own: four fields; final value with
contributed, growth and return; a projection line with 0, half and full-term
labels; a by-year table.

**`stopwatch`.** Shares Timer's clock face and its injectable periodic
timer; the face moves to shared widgets now that two real tools draw it.
Its own: counts up from zero; start pauses when pressed again; reset returns
to zero; a laps section.

### Deviations recorded before coding

* **`stopwatch` hundredths.** The reference counts whole seconds and prints a
  literal `.00`, so its hundredths never move. Flutter counts them.
* **`stopwatch` laps.** The reference's laps section can never fill — no
  handler writes a lap — so it is always "no laps yet". Flutter offers Lap
  while running, so the section is not a promise nothing keeps.
* Anything further found while measuring is added here and to
  `KNOWN_DIFFERENCES.md` before the tool is committed.

### Dependencies

Wave 1 needs nothing F6A and F6B do not already provide: the tool host, field
card, summary card, donut, table, line chart, segmented control, chips,
stepper, meter row, compact rows, the clock face and periodic timer, the
calendar holiday port, the currency formatter and the exporter. No new
package, no platform capability, no backend.

## Held back, and why

| tool | archetype | why not now |
|---|---|---|
| `bmi` | Form calculator | its history chart is `value + 1.4 … value`: readings the reader never entered — invented personal health data |
| `focus` | Clock instrument | today's 75 minutes, a 5-day streak and a week of sessions are constants — invented personal activity |
| `fuelcost` | Form calculator | needs the current pump price — a daily regulator feed with no honest source here |
| `zakat` | Form calculator | nisab from live metal rates, and a religious ruling surface that needs its own review |
| `faraid` | Form calculator | classical inheritance rules — religious content needing a verified source |
| `ledger` `installments` `committee` `subs` `goals` `bills` `babybudget` | Records manager / Finance dashboard | record families not yet on the record layer, or provider data (bills) |
| `health` `meds` `vaccines` `pregnancy` `cycle` | Records manager / Context dashboard | sensitive health records; medication reminders need notification delivery |
| `todos` `notes` `reminders` `events` `shopping` | Records manager | record families — a wave of their own on the record layer; reminders need delivery |
| `alarms` `mediasaver` `vehicle` | Records manager | alarms and downloads are platform capabilities; vehicle needs excise records |
| `habits` `water` `praytrack` `fasting` `streak` | Tracker | streaks and history are the reader's own records — none exist to show yet |
| `prayer` `ramadan` `sunmoon` `aqi` `loadshed` `cricket` | Context dashboard | loadshed and cricket need live local feeds; the rest follow Weather in a later wave |
| `currency` `fuel` `natsavings` `prizebonds` `packages` `worldclock` `quransearch` | Data explorer | rates, tariffs and draws are feeds; quransearch is scripture |
| `trains` `parcel` `mosques` `taraweeh` | Live tracking | live feeds and map tiles |
| `quran` `ayah` `duas` `names99` | Scripture reader | no verified translations or originals (C77) |
| `play` | Visual library | a later wave |
| `docscan` | Camera instrument | document capture and cropping, beyond QR scanning |
| `markets` `calculator` `converter` `tasbih` `speedtest` `qibla` | one-offs | converted one by one |
| `hijri` `holidays` `mealplan` `birthdays` `passport` `wastatus` | own compositions | converted one by one |
