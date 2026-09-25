# Rollout wave 10 — fifteen tools, the last of the catalogue

Continues straight from Wave 9's own precedent, on the same standing
instruction: build the remaining tools in parallel, optimize for
throughput, exercise judgment on scope without waiting for
per-tool authorization. Unlike Wave 9 (sixteen fixture-display tools, one
architecture shape), this batch is deliberately heterogeneous — real
astronomical/calendar computation, from-scratch reader-record trackers,
religiously sensitive inheritance law, and a run of device-capability
tools with no live network access to fall back on. Fifteen agents ran
concurrently, each confined to its own `lib/features/<id>/` and
`test/features/<id>/`, told to investigate the reference honestly before
building rather than assume a shape.

**This wave completes the catalogue.** `tool_registry.dart` now names all
85 of the reference's own modules — every catalogue id is a real,
converted tool. There is no more "not yet converted" tool left anywhere
in the app.

## 1. The fifteen

| id(s) | shape |
|---|---|
| `prayer` | real solar computation (Qibla/Sun & Moon archetype) |
| `praytrack`, `fasting`, `taraweeh` | from-scratch reader-record trackers (Habits/Streak archetype) |
| `ramadan` | seasonal dashboard, real Hijri/solar computation, fixed two real reference bugs |
| `faraid` | real Islamic inheritance law, three heir categories, one honest disclosure the reference itself lacks |
| `hijri` | real Hijri calendar conversion, reusing the existing tabular engine |
| `mosques` | no real places directory exists — honest empty state + a real "Open in Maps" hand-off |
| `docscan`, `mediasaver`, `speedtest`, `vehicle`, `wastatus`, `passport` | device/platform-capability tools, each investigated for what is genuinely buildable without new native code |
| `alarms` | honest no-op — the reference's own alarms are hardcoded, cosmetic-only |

## 2. What was dropped, corrected, or found, tool by tool

- **Prayer Times**: reused the existing, previously-unused
  `LumeSolar.prayerTimes()` (standard MWL/standard-Asr, the same family as
  PrayTimes.org/Aladhan) rather than reimplementing solar math. Triple
  cross-validated: matches `today_fixtures.dart`'s own pre-existing
  hardcoded Islamabad/London/US tables to the minute, and an independent
  transcription of the reference's own `solar.js`. Dropped the
  reference's method/madhab preference read (no settings store exists for
  it) and discloses the fixed MWL/Standard defaults plainly rather than
  presenting an unmade choice as picked.
- **Prayer Tracker**: the reference's `doneToday` counts prayers whose
  clock time has passed, not prayers actually prayed — a subtly wrong
  real-ish field, not a bare literal. Replaced with a real per-(day,
  prayer) check-in over the shared record repo; streak, month rate, qada
  and the by-prayer heat are all computed for real. Qada in particular:
  the reference's bare `7` is replaced with a real count of unmarked
  prayers since the reader's first check-in — zero with no history, never
  a fabricated starting balance.
- **Fasting Tracker**: the reference's `fasting()` is 100% bare literals
  plus a seeded heat grid and hand-typed recent rows — the same
  fabrication class as Cycle/Streak. Replaced with a real fast-entry log
  (date, sunnah/qada, kept) over the shared record repo; streak,
  completion rate and the 30-day heat are all computed for real. Dropped
  the reference's `target: 12` outright — no honest denominator exists for
  it.
- **Ramadan**: a two-state seasonal dashboard, not a record family. Found
  and fixed two real reference bugs, both independently verified: (1) the
  days-until-Ramadan count treated every Hijri month as a flat 29 days —
  wrong by 26 days on the fixture date — replaced with a real forward
  day-scan; (2) the named Hijri year was off by one for every month
  leading up to Ramadan. Replaced the reference's crude Suhoor formula
  (sunrise minus a fixed hour and a hardcoded `:42` minute) with the real
  Fajr/Maghrib, the same solar calculation Weather/Calendar already use.
  Dropped a fabricated progress section (fasts/juz/charity bare literals),
  a seeded-random heatmap, and a hardcoded "Taraweeh 20:45" row —
  independently confirmed fabricated by the taraweeh agent's own finding
  below.
- **Taraweeh**: the reference's own `taraweeh.tool.js` turned out not to
  be a personal tracker at all — it is a nearby-mosque finder over the
  same fabricated `nearbyMosques()` data `mosques.tool.js` also draws from
  (fake names, fake reciters, index-derived fake distances). Declined to
  duplicate mosques' build or invent a mosque database; kept the one
  honest thing worth keeping — a reader's real Taraweeh nights — and
  built a from-scratch tracker around it: rakaat prayed (8 or 20, the
  reference's own real binary) plus an optional Juz reached, with streak,
  best streak and Juz/Khatm progress all computed for real.
- **Faraid**: the reference is a three-heir-category calculator only
  (wife/wives, sons, daughters — never father, mother, husband, siblings,
  grandchildren). Every supported combination was verified by hand
  against the Qur'an's own classical fixed shares (4:11-12); the
  arithmetic holds even where a label is fiqh-loose (a daughters-only case
  labelled "Residuary" whose total still matches the real fixed-share-plus-
  radd result). **Found a real reference bug**: the wife-alone-with-no-
  children case gives her 1/4 and never mentions the other 3/4 anywhere.
  Fixed honestly — this build does not invent who receives the remainder
  (no father, siblings or extended family is modelled); it discloses an
  explicit "Unallocated" row and a note naming the gap instead. Proved
  `awl` (fixed shares exceeding the whole estate) is structurally
  unreachable from only three heir categories by property test, not by
  comment claim alone. Declined to guess Urdu/Arabic for inheritance-law
  terminology, asking for a dedicated translation pass instead.
- **Islamic Calendar (Hijri)**: reused the existing tabular Hijri engine
  rather than reimplementing it. Rejected the reference's own
  `ISLAMIC_EVENTS` fixture — hardcoded literal dates for one specific
  year — and wrote a real day-walk-forward algorithm finding the next
  real occurrence of six calendar transitions instead. Dropped the
  reference's seventh row, "Laylat al-Qadr (likely)" — a traditional
  estimate, not a calculable transition. Verified the calendar's own
  epoch against an external source (Dershowitz & Reingold, JDN
  1,948,440), catching and fixing a one-day error in its own first recall
  by deriving the date programmatically rather than trusting memory.
- **Nearby Mosques**: confirmed the reference's `nearbyMosques()` is 100%
  procedurally generated — template names, an `i*0.7km` distance formula,
  canned reciter names. No real substitute data exists to port. Ships an
  honest "no live mosque search" state plus a real, working "Open in
  Maps" hand-off through the already-wired link opener.
- **Document Scanner**: not a simple reuse of the QR pipeline — the
  existing scanner contract is decode-specific and structurally can't
  carry image bytes, so a small new parallel contract was built,
  reusing every existing platform primitive (camera gate, settings,
  image picker, share) as-is. Declined to fake perspective crop/enhance
  (no image-processing package exists), PDF export (no `pdf` package —
  shares each page as a separate image instead), and a "Save to Photos"
  button (the existing image saver is PNG-only and would fail every real
  JPEG capture).
- **Media Saver**: the reference's own "Fetch" is a fixed toast, never a
  real request, and its 3-item library plus storage figures are invented
  with nothing behind them. Built: a permanent on-screen notice that Lume
  has no network access, a fixed honest response to Save, and an empty
  library with zero fabricated items.
- **Mobile Speed Test**: the reference's numbers are pure random output,
  never real even once — no honest fixture exists to port at all. Built a
  permanent "can't measure this here" state with no numbers, gauge or
  Start button anywhere, plus one real, honest addition: a hand-off to
  fast.com through the existing link opener.
- **Vehicle & Fines**: the reference has a real fleet search (genuinely
  filters) alongside a no-op "Check any registration" (a fixed toast
  regardless of input) — kept both distinctions faithfully. The
  reference's own ~190-currency conversion table is unreachable here
  (catalogue restricts this tool to Pakistan), so only the one reachable
  rate was ported rather than 189 unreachable entries.
- **WhatsApp Status Saver**: confirmed the reference itself is a static
  non-functional mockup — its own "Grant folder access" button is a fixed
  toast. Confirmed via the Android manifest that the storage permission
  this would need is deliberately absent and no folder-picker package
  exists — no honest interactive capability is buildable at all. Built
  real instructional content (WhatsApp's own built-in save icon, which
  works today and needs nothing from Lume) instead of reproducing the
  fake permission flow.
- **Passport Photos**: confirmed the reference is a static mockup (its
  Capture/Import buttons are fixed toasts, no camera ever touched). Built
  a real capability instead: real pixel work via `dart:ui` (decode,
  centre-crop, resize, re-encode), reusing every existing platform
  primitive. Country sizing was ported exactly as the reference has it
  (a binary US-vs-everyone-else rule) rather than inventing a fuller
  per-country table the reference itself doesn't have.
- **Alarms**: verified from the actual reference that there is no schema
  at all — `alarms()` rebuilds three hardcoded alarms on every call, the
  toggle is a cosmetic class flip with no persistence (reopen the tool, it
  silently resets), and the "next alarm" card is a literal constant, not
  a clock read. Correctly declined to build real alarm scheduling — that
  would be inventing a feature the reference never had — and ported the
  fixture plus the toggle's own cosmetic-only behaviour faithfully.

Three independent agents (mosques, taraweeh, ramadan) converged on the
same finding from different directions — the reference's shared
`nearbyMosques()` fixture is entirely fabricated — without being told
about each other's work. Two more (ramadan, hijri) independently arrived
at the identical day-walk-forward technique for finding the next
occurrence of a calendar transition.

## 3. Integration pass

### ARB merge

275 new keys landed across `app_en.arb`/`app_ur.arb`/`app_ar.arb`. Two
placeholder-type bugs were caught by the analyzer immediately after
`flutter gen-l10n`: `hijriYearAh`'s and `ramadanDay`'s year/day
placeholders were declared `int` in the ARB metadata, but both call sites
pass a pre-formatted `String` via `LumeFormatting.integer()` — this
codebase's own convention for locale-aware digit formatting. Both fixed
to `String`. A real C49 violation was also caught by
`arb_parity_test.dart`'s own existing check: `speedtestUnavailableText`
and two related keys said "browser" despite this being a native app —
reworded in English, Urdu and Arabic to drop the reference while keeping
the meaning.

### Registry and capability

`tool_registry.dart` gained 15 entries. Three tools (`fasting`,
`praytrack`, `taraweeh`) expose a separate `abstract final class` holder
distinct from the widget itself — confirmed each one's real shape by
grep before wiring, not assumed. `tool_capability.dart`: `computed`
gained `prayer`, `hijri`, `ramadan` (real math, no fixture, same bucket
as Qibla/Sun & Moon/World Clock); `readerRecords` gained `praytrack`,
`fasting`, `taraweeh` (real per-entry logs, same bucket as Habits/
Streak); `inputOnly` gained `faraid`, `docscan`, `mediasaver`, `passport`,
`speedtest`.

### Stale catalogue metadata, found and fixed

- **Islamic Calendar**: `fallbackSource: 'Umm al-Qura calculation'` was
  false — this build implements the tabular calendar, not Saudi Arabia's
  officially adopted lookup-table calendar, and the source bar prints
  this string verbatim. Changed to a new, honest `'Tabular Islamic
  calendar'` entry.
- **Taraweeh**: its catalogue entry still described the reference's old
  mosque-finder shape (`archetype: tracking`, `fallbackSource: 'Places
  directory'`, `freshness: cached`, `supports: {filters, notifications,
  search}`) — updated to the real reader-record tracker's shape
  (`archetype: tracker`, `fallbackSource: 'On device'`, `freshness:
  local`, filters/search dropped), matching Habits/Streak's own
  convention exactly.
- **Mobile Speed Test** and **Document Scanner**: both declared
  `freshness: live` with a fallback source implying a real measurement —
  inherited from the reference's own fake framing. Both tools show zero
  figures of any kind, so `live` would make `LumeDataCapability` show a
  false "Sample data" claim over a screen with nothing to sample. Fixed
  to `fallbackSource: 'On device'` / `freshness: local`, the same fit
  BMI/Age/Tip & Split already use for a pure on-device calculation.
- **Passport Photos**: `fallbackSource: 'ICAO + national specs'` wasn't
  registered as a static source, so its `reference` freshness kind would
  also have shown a false "Sample data" claim. Added the string to
  `source_claims.dart`'s static-source set — the real specs are a fixed
  reference fact, the same hybrid computed-plus-static-source pattern
  Faraid and Qibla already use.

### Real bugs the test gate found

`flutter test`, run clean, found 36 real failures. One was a genuine
test-fixture defect: `docscan_tool_test.dart` used non-decodable garbage
bytes as a stand-in JPEG, but the row's own thumbnail renders through a
real image decoder that throws on invalid data — replaced with a real,
valid minimal PNG. The rest resolved to five shared-widget and
integration bugs, all newly surfaced by this wave's own content rather
than regressions in what Wave 9 already shipped:

- **Faraid's explain-row header** used a bare, unstyled `Text` for both
  the heir label and the trailing fraction/amount — with no ambient
  `DefaultTextStyle` in scope at that exact point in the tree, both
  fell back to Flutter's absolute default style (48-point monospace),
  ballooning the trailing text to hundreds of pixels wide and overflowing
  the row. Every other caller of the same shared expand-row widget
  (Meal Plan, Mobile Packages) explicitly styles both texts — Faraid's
  was the one spot in the file that hadn't. Fixed by applying the same
  explicit `Theme.of(context).textTheme` styling its siblings already
  use; this single fix cleared all nine of Faraid's own reported
  failures at once.
- **A fixed circular cell can't reflow at 200% text scale.** Two separate
  shared widgets share this shape — a day-grid cell (`lume_month_grid.
  dart`, exercised for the first time with a two-line Gregorian/Hijri
  cell by the Islamic Calendar's own month grid) and the progress ring
  (`lume_progress.dart`, exercised by Prayer's own countdown circle).
  Both are fixed-geometry circles/squares with no room to grow; at 200%
  scale their centred text simply doesn't fit. Fixed both the same way —
  wrapping the centred content in `FittedBox(fit: BoxFit.scaleDown)` — a
  no-op at normal scale (content already fits) and a graceful shrink
  rather than an overflow at large scale.
- **A context-bar item can't wrap its own label.** `LumeContextBar`'s
  items sit inside a `Wrap`, which — unlike common assumption — does
  constrain each child to its own available width, not to infinity; a
  single item's content can still overflow if it doesn't fit that width.
  Every existing caller's label was short enough not to notice. Mosques'
  own context item is the first to concatenate city and country into one
  label ("Islamabad, Pakistan"), long enough at 200% scale to overflow.
  Fixed by wrapping the label in `Flexible` with ellipsis — safe here
  specifically because this row has no competing `Expanded` sibling,
  unlike the `LumeRichRow`/`LumeCompactRow` end columns Wave 9 already
  learned the hard way not to touch that way.
- **Prayer's method-disclosure rows** put a full sentence ("Standard
  (Shafi'i, Maliki, Hanbali)") in `LumeCompactRow`'s fixed `value:` slot,
  the same slot class Wave 9's Loadshedding fix already moved a
  full-sentence hint out of. Moved all four method/Asr/location/timezone
  rows to the `subtitle:` slot instead, which sits under the label at the
  row's own full width — the same fix, applied for the same reason.
- **Wastatus's related-tool tap** targeted a row that renders below the
  test's own default viewport fold, and `tester.tap()` does not scroll to
  find its target. Fixed with the established `ensureVisible`-before-tap
  idiom already used elsewhere (Documents' own `tapVisible` helper).

Two tests asserted a truth that this integration pass itself changed,
rather than describing a bug:

- **Ramadan's own capability test** explicitly asserted the *pre-
  integration* state (`isSample: true`, not yet in `computed`) with a
  comment saying so plainly — correct until this pass actually added
  `ramadan` to `tool_capability.dart`'s `computed` set, at which point the
  assertion became stale by design. Updated to assert the now-true state.
- **Tax's own gate test** pointed at `alarms` as "a tool that is not
  converted yet" — true when written, false now that this wave converted
  it. With all 85 catalogue ids now registered, there is no real
  still-unconverted id left to point this at anywhere in the app; the
  test now uses a made-up id instead, which exercises the identical
  fallback path the router's own code comment already documents (an
  unknown id and a known-but-unregistered id are refused identically, on
  purpose, so the refusal itself can't leak which is which).

One test needed a hardcoded-string fix, not a logic fix: two apostrophes
in `mosques_tool_test.dart` were typed as the typographic `'` where the
ARB source (and every other contraction in it) uses the plain `'`.

### Hijri's year needed a locale-aware assertion, not a bugfix

`hijri_tool_test.dart` asserted a bare `'1448'` where the screen's own
`f.integer()` formatting — the same convention every other four-digit
figure in this app already follows — correctly renders `'1,448'`. Fixed
the assertions, not the tool.

### A new, permanent exception in the release-honesty gate

`release_readiness_test.dart`'s "every tool draws a source bar" check
had never met a whole-screen `bare: true` tool before — `documents`,
`expenses` and `record_tool` also use `bare: true`, but only for a
sub-state the gate's own default route never lands on. Wastatus is bare
unconditionally (it has no figure of any kind to make a claim about,
`wastatus_capability_test.dart`'s own documented reasoning), so it is the
first tool to actually trip the blanket assumption. Added a small,
explicitly-commented exception set rather than weakening the check for
everyone else.

Full suite, run clean after every fix above: 6,628 tests, 0 failures.

## 4. Closure

Closes when the full project test suite is green, `flutter analyze`
reports nothing across `lib/` and `test/`, and the shared files this wave
touched — `tool_registry.dart` (15 entries, completing all 85),
`tool_capability.dart`, `feature_catalogue.dart` (Islamic Calendar,
Taraweeh, Mobile Speed Test, Document Scanner, Passport Photos),
`source_claims.dart` (the new tabular-calendar and passport-specs static
sources), the three ARB files, `lume_month_grid.dart` and
`lume_progress.dart` (the same defensive, no-op-at-normal-scale
`FittedBox` fix), `lume_header.dart` (one scoped `Flexible`), and
`release_readiness_test.dart` (the new bare-tool exception) — are wired
for all fifteen. With this wave, `tool_registry.dart` names every one of
the reference's 85 modules: the catalogue conversion this whole archive
has tracked wave by wave is complete. Not part of this wave, same as
every prior one: the golden-image matrix and a web-reference parity
capture set for any tool whose reference composition isn't rich enough to
make one meaningful yet.
