# Rollout wave 3 — selected from source, before any of it was written

Five tools. Membership was decided by reading every candidate's **actual
source**, not its name or its archetype, and by re-testing the holds that
waves 1 and 2 recorded against it. Where a hold still stands, it is kept
and the reason is restated. Where later work retired a hold, that is
shown.

The rules are `ROLLOUT_WAVE_2.md`'s twelve, unchanged. What is new is
that a tool failing **rule 1** — *"one-off or own composition — inspected
and converted one by one"* — is not excluded by that alone: rule 1 is an
instruction to inspect, and this wave is that inspection.

## The wave

| tool | reference | why it clears | what it inherits |
|---|---|---|---|
| `worldclock` | `daily/worldclock.tool.js`, 42 lines | wave 2 held it on **rule 8**, *"needs a maintained IANA time-zone database"*. That database has since landed in-tree: `timezone: 0.11.1` pinned, tzdb 2025c, 341 canonical zones, 257 aliases, 1,655 CLDR zone names in en/ur/ar, city→zone and country→zone maps, and typed resolution outcomes. **No new dependency; the hold is retired by work already done.** `WORLD_CLOCK_TIMEZONE.md` pre-approved the package, the data variant and the update process, and names World Clock as the consumer | Sun & Moon's shape: one presentation file, no repository, no records |
| `calculator` | `everyday/calculator.tool.js`, 36 lines + `tool.screen.js:894-957` | rule 1 only. No backend, no feed, no records, no permission, no dependency. Every figure comes from the keypad | the `inputOnly` honesty class |
| `focus` | `everyday/focus.tool.js`, 25 lines | waves 1 and 2 held it on **rule 9**, *"fixture would invent the reader's own data"*. **Timer shipped with exactly that** — a fixture history section, `isSample: true`, and a source bar that says "Lume sample data" in the reader's own language. The honesty mechanism that answers rule 9 for this family is already built and shipped; Focus is its third member | `LumeClockFace`, `LumeTimerController`, the `LumeToolSession` running state, Timer's Start/Pause treatment (C66) |
| `tasbih` | `islamic/tasbih.tool.js`, 48 lines | rule 1 only. Faith-gated, which is not a blocker — `faith: true` in the catalogue is the centralised mechanism working as designed. Contains **no scripture, no citation, no ruling**: five dhikr formulae with their conventional counts, and a counter. Haptics via `HapticFeedback`, already used by `timer_tool.dart:63`, so no new dependency | the counter and ring; **the fixture "Recent sessions" section is dropped**, and `history` with it |
| `play` | `personal/play.tool.js`, 26 lines | rule 11 in wave 2, *"draws only rows of games that open nothing"*. Re-read: it is a fixture grid, which is honest once the source bar says so. No state, no dependency, no permission | `isSample: true`; the tiles do not pretend to open anything |

Play is the weakest member and is named as such: converted faithfully it
is a grid over a four-row fixture. It is in the wave because it is
genuinely free of risk, not because it is valuable.

## Held, with the reason

Each of these was read in full. None is excluded on its name.

| tool | blocker | evidence |
|---|---|---|
| `converter` | **materially ambiguous calculation** | Of 25 factors, seven are rounded short of their international definitions and **visible at the tool's own four decimals** (100 km reads 62.1373; true 62.1371). Three are not roundings but wrong quantities: `GB: 1024` and `TB: 1048576` are binary factors under decimal names (**2.4 % and 4.9 % out**); `gal: 3.78541` is the US gallon shown as bare `gal` to a reader whose gallon is 4.54609 L (**20 % out**); `cup: 0.24` is the labelling cup, not the recipe cup. Deciding truth over parity **reverses a shipped precedent** — `lume_format.dart:476`, `flights_tool.dart:109` and `weather_tool.dart:185` all ship `× 0.621` rather than 0.6213711922 |
| `fuelcost` | **live-feed claim, already ruled on three times** | `ROLLOUT_WAVE_1.md:106`, `ROLLOUT_WAVE_2.md:100` and `RELEASE_HONESTY.md:75` each hold it; the last names it **release-blocking**. The price field opens from the `fuel` fixture under the copy *"Pre-filled from today's published price."* Separately, `context.js:811` is a tautology — both branches of the imperial ternary are byte-identical — so gallons are multiplied by a per-litre price in every market but the US, **a 3.79× error reachable with no user action in Liberia and Myanmar** |
| `bmi` | **medical correctness** | It prints a coloured verdict badge reading *"Obese"*, a "Healthy range" in kilograms and a target weight, with **no source, no disclaimer and no age model** — so a child's figures get adult WHO cut-offs and a confident wrong classification. It is **not** marked `sensitive`, so `lume_share.dart:53-62` would permit a BMI share card. It would be the first health-domain tool converted, with no precedent for wording, sourcing or disclaiming a health verdict, and the conversion would have to author "Underweight / Overweight / Obese" into Urdu and Arabic from nothing. Also held twice already on rule 9 for its invented six-month history |
| `holidays` | **religious calendar, and data sourcing** | Eid al-Fitr, Eid al-Adha and Islamic New Year sit in the AE and SA **public** lists for every reader, Muslim or not, and cannot be derived from a Gregorian rule. `lume_hijri.dart`'s own doc forbids treating its arithmetic as a determination: *"the Hijri date must come from the authority each reader follows … and say which"*. The screen today prints **two different Eid al-Fitr dates at once** (30 Mar in the public list, 20 Mar under "Islamic dates"). Separately, 188 of 194 countries get a three-row fallback asserting Christmas and Labour Day as public holidays — false for Japan, Saudi Arabia, India, Israel and Turkey |
| `water` | **durable records** | Its week chart and six-day streak are claims about the past week over a store whose own header reads *"nothing here outlives the process (C74)"*. Its `+250 ml` tap does not even append to its own timeline, and `week[6]` stays pinned at the literal `1250` |
| `streak` | **durable records, absolutely** | Reads no state at all. Under an in-memory store it is a static poster asserting twelve days of a discipline the app never observed, and its 35-cell heatmap is a seeded PRNG that contradicts that number. There is no honest subset to ship |

## What this says about the remaining inventory

Fifty-six tools were unbuilt when this wave was selected. The low-risk
pool is now close to exhausted, and not because the bar is high:

- **17** are Islamic scripture or ruling tools (rule 2);
- **14** are backed by a live or published feed (rule 5);
- **6** hold sensitive records (rule 3);
- **5** need a camera, the network, or delivered alarms (rules 4, 7, 10);
- **4** are trackers whose whole subject is history the store cannot keep
  (rule 9, and no durable store exists);
- the rest are the five in this wave and the four held above.

The next wave is not a matter of picking more carefully. It needs one of:
a durable record store, a data source with a licence, or a decision on
the four held tools.

## Measurements

**None of the five has ever been measured.** The 282 `tool_*` cells cover
exactly the 30 tools already built. Capture is therefore part of this
wave, not a lookup: `measure_destinations.mjs --screen tools --tool <id>`
was verified against `calculator`, which had no cells, and produced one.
Every wave member gets its cells captured before its parity test is
written.

## How this wave is held

Same bar as Committee and Baby Budget. Per tool during implementation:
domain tests, screen tests, its own golden cases, its localisation keys,
and the analyzer. Once all five are integrated, the complete gate runs
once — localisation generation and parity, formatting, full analysis, the
whole Flutter suite, the complete golden suite and orphan inventory,
debug and release APKs, release-readiness and permission checks, an
emulator walk covering every tool, the measured comparisons, the web
oracle under UTC, America/New_York and Asia/Karachi, the
prototype-unmodified check, and a clean tree.
