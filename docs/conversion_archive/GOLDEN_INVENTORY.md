# The golden inventory

Five different things have been called "goldens" in this conversion's
reports, and two of them were compared against each other. This is the
canonical breakdown, the words for each, and the check that keeps them
honest.

---

## 1. Five artifact types

| term | what it is | where |
|---|---|---|
| **golden test case** | one runtime case in `test/goldens/`, as `flutter test` counts it. A case may compare several images, or none | — |
| **committed Flutter golden** | one PNG in `test/goldens/images/`. This is what `matchesGoldenFile` reads, and what is in the repository | `test/goldens/images/` |
| **Flutter capture** | `*.flutter.png` — evidence written beside a sidecar of measured facts. Compared by nothing | `conversion_archive/shots/` |
| **web capture** | the prototype's own screenshot of the same cell | `conversion_archive/shots/` |
| **side-by-side / diff** | `*.side.png` and `*.diff.png`, generated for a human to look at | `conversion_archive/shots/` |

A golden test case is a *test*. A committed golden is a *file*. They are not
the same number and never have been: a case that writes an evidence capture
without comparing anything contributes a case and no file, and a case that
compares two images contributes one case and two files.

---

## 2. The breakdown

| Category | Golden test cases | Unique committed Flutter PNGs | Web captures | Side-by-sides | Diff images |
|---|---:|---:|---:|---:|---:|
| Foundation | 13 | 10 | — | — | — |
| Components | 29 | 29 | — | — | — |
| Shell/navigation | 11 | 11 | — | — | — |
| Onboarding | 183 | 87 | 19 | 19 | 19 |
| Authentication | 214 | 115 | 9 | 9 | 9 |
| Home/Tools | 37 | 39 | 15 | 8 | 8 |
| Today/Explore | 39 | 37 | 10 | 10 | 10 |
| Trains | 18 | 18 | 1 | 1 | 1 |
| Profile/account | 116 | 116 | 25 | 25 | 25 |
| **Total** | **660** | **462** | **79** | **72** | **72** |

There are also **378** Flutter captures under `shots/`, paired with the web
captures above; they are evidence for the measured comparison, not part of the
golden suite.

`Profile/account` is 85 `account_*` plus 31 `profile_*`. The account section's
twenty-one routes are shot at four cells each — the reference cell, Urdu,
Arabic and 200% type — which is 84, plus the refusal a guest meets on a
protected route.

### Lending Ledger (`test/goldens/ledger_golden_test.dart`)

| | count |
|---|---:|
| golden test cases | 33 |
| unique committed Flutter PNGs (`tool_ledger_*`) | 33 |
| Flutter captures (`shots/tools/tool_ledger_default_pk/*.flutter.png`) | 8 |
| web captures (`*.web.png`, the same folder) | 7 |
| side-by-sides | 7 |
| diff images | 7 |

Eight cells of the reference composition (390×844 light, dark, Urdu,
Arabic, 200% type; 700×900; 1100×900; 852×393) and twenty-five states:
first use (English, Urdu), each filter, settled and archived, credit, mixed
currencies, search, no results, a person, an entry, validation failure,
the keyboard open on the form, the allocation picker, the overpayment
sheet, deleting a paid loan, Undo, the reminder, sharing unavailable,
export, day unknown, a damaged scope, loading and a storage failure. The
200% cell has no web capture: the browser cannot set the reader's text
scale. The diff images are for a person to look at; no percentage in them
is claimed as parity (C90).

### Wave 3 — World Clock, Calculator, Focus Timer, Tasbih, Play

| tool | golden cases | committed PNGs | composition cells | states |
|---|---:|---:|---:|---:|
| World Clock | 18 | 18 | 8 | 10 |
| Calculator | 16 | 16 | 8 | 8 |
| Focus Timer | 15 | 15 | 8 | 7 |
| Tasbih | 14 | 14 | 8 | 6 |
| Play | 9 | 9 | 8 | 1 |
| **total** | **72** | **72** | | |

Each tool's composition is captured in the same eight cells: 390×844
light, dark, Urdu, Arabic and at 200% type; 700×900; 1100×900; 852×393.
Tasbih's are all for a Muslim reader, because the tool is faith-gated and
a default profile is refused at the route.

The states are reached by driving the tool's own controls, not by
building a widget to force one. World Clock: the converter with an
answer, a place added by search, a place removed, an alias row showing
both names, an unknown zone, the database unavailable, the device zone
missing, a country needing a selection, no match, and the empty list.
Calculator: digits, a pending operator, a finished sum in History, the
empty History, divide by zero, a non-terminating division, overflow and
the entry-length refusal. Focus Timer: ready, running, paused, a
finished stretch offering the break, the break running, and the honest
"this session" state with nothing counted and with a session counted —
its **composition cells are the parity/sample state**, which is the only
place the reference's fabricated figures appear. Tasbih: part-way
through a round, a completed round, the reset confirmation, the phrase
picker, the switch confirmation and the ceiling.

**World Clock's goldens are pinned to a UTC instant**, not to
`kFixtureInstant`. That constant is a local `DateTime`, and every row is
it converted into another zone, so the whole list would have drawn
different times on a machine in a different zone. `captureLumeRoute` now
forwards a clock for exactly this; the set is verified green under
`TZ=America/New_York` as well as the host zone.

Play's "not playable yet" state is captured at the 200% cell rather than
the phone cell: at ordinary text size the notice already sits on the
390×844 screen, so a phone capture was byte-identical to the
composition. No duplicate images in the 72.

The notification presenter is turned off in all five files. It fires at
2.5 seconds and every 45 thereafter, and any state that takes several
pumps to drive was landing under a banner covering the tool header. The
cell is then of the tool, which is what it is for.

`LumeNotificationSchedule.off()` is **declared** in
`lib/app/providers/notification_feed.dart` and **called** nowhere in
`lib/` — its only five call sites are the five golden files above, and
no integration or widget test that is not taking a picture uses it. `notificationScheduleProvider` still defaults to
`const LumeNotificationSchedule()`, which is enabled, first tick at
2,500 ms, every 45 seconds after. Production is unchanged, and so is
every test that exercises the feed.

**No percentage of differing pixels is offered as parity evidence for
any of the five.** The measured comparison is
`docs/conversion_archive/parity/tool_<id>.md` — 877 named values.

### Baby Budget (`test/goldens/babybudget_golden_test.dart`)

| | count |
|---|---:|
| golden test cases | 31 |
| unique committed Flutter PNGs (`tool_babybudget_*`) | 31 |
| Flutter captures (`shots/tools/tool_babybudget_default_pk/*.flutter.png`) | 8 |
| web captures (`*.web.png`, the same folder) | 7 |
| side-by-sides | 7 |
| diff images | 7 |

Eight cells of the reference composition (390×844 light, dark, Urdu,
Arabic, 200% type; 700×900; 1100×900; 852×393) and twenty-three states:
first use, the list, the Archived filter, no match, a budget with no plan
at all, a month over its plan, a budget whose start has not arrived, an
archived budget keeping its figures, a category and its own spends, a
month's spending with its month picker, the budget form, the form
refusing a plan of zero, the form with its currency fixed by a spend,
the spend form, the planned-purchase form whose day may be empty, the
sheet that turns a plan into a spend, the archive confirmation, the
delete confirmation saying what would go, the day unavailable, a record
that cannot be read, loading, a storage failure, and two budgets in two
currencies. The 200% cell has no web capture: the browser cannot set the
reader's text scale.

The diff images are for a person to look at. Baby Budget's differ by
41–56 % of their pixels because the tool is functionally corrected — a
reader's own records where the reference converts one USD fixture, real
dates where it prints weekday names off the device clock, and a donut
that adds to 100 rather than 101 (C97) — and no percentage in them is
claimed as parity either way. The measured comparison is
`babybudget_parity_test.dart`: 352 named values across all eleven
measured cells, with the 59 deliberate differences named.

### Committee (`test/goldens/committee_golden_test.dart`)

| | count |
|---|---:|
| golden test cases | 27 |
| unique committed Flutter PNGs (`tool_committee_*`) | 27 |
| Flutter captures (`shots/tools/tool_committee_default_pk/*.flutter.png`) | 8 |
| web captures (`*.web.png`, the same folder) | 7 |
| side-by-sides | 7 |
| diff images | 7 |

Eight cells of the reference composition (390×844 light, dark, Urdu,
Arabic, 200% type; 700×900; 1100×900; 852×393) and nineteen states: first
use, the list, the Late filter, no match, a completed committee, a
cancelled one with what was unpaid at cancellation, a member and their
cycles, one member holding two shares, the form, the form refusing what
cannot be saved, the form with the terms locked, the contribution sheet,
the payout sheet, the cancel confirmation, the delete confirmation naming
every record, the day unavailable, a record that cannot be read, loading
and a storage failure. The 200% cell has no web capture: the browser
cannot set the reader's text scale.

The diff images are for a person to look at. Committee's differ by 33–61 %
of their pixels because the tool is functionally corrected — five cycles
where the reference draws ten months, real states, and a pool of
Rs 141,500 rather than Rs 142,000 (C96) — and no percentage in them is
claimed as parity either way. The measured comparison is
`committee_parity_test.dart`: 63 named values across seven cells, with the
9 deliberate differences named.

---

## 3. Reconciling 526 and 462

They count different things, and neither number was wrong about what it
counted.

| | end of F5B (`8376054`) | end of F5C (`17007eb`) |
|---|---:|---:|
| golden test cases | **526** | **660** |
| committed Flutter PNGs | **328** | **462** |
| destination golden cases | **76** | 210 |

**526 is F5B's golden test-case count.** Measured, not inferred: a detached
worktree at `8376054` runs `test/goldens/` and reports 526.

**462 is F5C's committed-PNG count**, which at F5B was 328.

The F5C report set "462 golden captures" beside F5B's "526 golden tests" as
though the second had fallen to the first. It had not. Both went **up**:
+134 cases and +134 files, which are the same 134 because every golden added
since F5B compares exactly one image in exactly one case.

"Captures" was also the wrong noun for the 462 — a capture is what
`shots/` holds. They are committed Flutter goldens.

**F5B's "76 destination cells"** is `destination_golden_test.dart`'s runtime
case count at `8376054`, which then equalled its 76 committed PNGs
(home 23, explore 19, today 18, tools 16) because each case compared one
image. Two numbers that coincided once and have since diverged.

### Nothing was removed

The committed golden count has only ever risen:

| commit | PNGs | |
|---|---:|---|
| `89bc7a0` | 291 | F5A close |
| `f4f4c5c` · `85f0324` · `8376054` | 328 | F5B |
| `c1e10cc` | 343 | Trains |
| `0c3982f` | 346 | Trains R2/R3 |
| `63ebdd0` | 377 | Profile and the 21 routes |
| `7fac339` · `1a69ea1` · `13a367e` · `a5630c4` | 399 | measurement, decisions, behaviour tests |
| `e66aa17` | 462 | the account section's RTL and 200% cells |
| `d29a89c` · `17007eb` | 462 | regenerated in place, none added or removed |

`d29a89c` rewrote 99 images and added none: the toolbar moved by a point and
every capture containing one moved with it. No screen, state, locale or
breakpoint lost coverage at any commit.

---

## 4. The inventory check

A missing golden already fails loudly — `matchesGoldenFile` cannot read a file
that is not there. An **orphan** failed silently: a committed image that no
test compares any more is a case deleted or renamed without anybody noticing,
and it sits in the repository looking like coverage.

`test/goldens/flutter_test_config.dart` wraps the golden comparator so every
comparison records the key it was asked about. It delegates everything; it
decides nothing. `scripts/check_goldens.py` clears the records, runs the
suite, unions them and diffs against `test/goldens/images/`:

```
python scripts/check_goldens.py            # run the suite, then check
python scripts/check_goldens.py --no-run   # check the last run's records
```

```
golden inventory
  compared by the suite    462
  committed on disk        462
  orphans                    0
  compared but absent        0
  ok — every committed golden is compared, and every comparison has a file
```

It exits 1 on either failure, and both were provoked to confirm it: an extra
PNG is reported as `ORPHAN`, a deleted one as `MISSING`, and each exits 1.

The config applies to `test/goldens/` only, because that is the directory it
sits in, and it does nothing at all unless `build/golden_keys/` exists — which
the checker creates. An ordinary `flutter test` is unaffected.
