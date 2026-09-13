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
