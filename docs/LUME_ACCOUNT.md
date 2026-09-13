# The account section

Twenty-one routes behind Profile, hosted by one widget, reached by one path
shape. This describes what they do in Flutter. The web prototype they were
converted from, and the measurements taken off it, are in
[`conversion_archive/`](conversion_archive/) and are not part of the product.

---

## 1. The shape

`/profile/account/<segment>` — a `StatefulShellRoute` branch route whose path
parameter names one of [`LumeAccountRoute`]'s twenty-one values.
`/profile/account` with no segment redirects to `prefs`, which is a
compatibility alias rather than a route of its own; both aliases are written
down in `account_routes_test.dart`.

Every route renders into a single [`LumeAccountHost`]. The host owns three
things no route owns:

**The gate.** Seven routes need an account. The host asks
`LumeAccountRepository.requiresAccount` before it builds, so a row, a deep
link and a session that expires while the screen is open all arrive at the
same refusal. The routes never check.

**The unsaved-changes guard.** One guard, on the host, in front of every
departure — Back, the system gesture, and any row that navigates. It is not
per-form, because a form does not know it is being left.

**The writes.** A route names what it wants; the host decides what that means
and says what happened. Nothing destructive happens without a second,
deliberate confirmation, and **nothing here connects to a server**: every
repository behind it is a fixture, and each reports `isDurable == false`.

The section keeps its own back stack in `accountStackProvider`, because
`go_router`'s `context.push` silently does nothing inside a shell branch. A
deep link into a leaf therefore still has a way out — up to the route above
it, and out of the section only once there is nothing left to return to.

---

## 2. The twenty-one routes

`•` = an account is required.

| # | route | what it is |
|---|---|---|
| 1 | `prefs` | the index: eight rows into the rest |
| 2 | `language` | the three languages Lume ships, one marked |
| 3 | `region` | country, city and the currency they imply |
| 4 | `currency` | automatic, then the reader's own market, then the rest |
| 5 | `units` | automatic / metric / imperial, each with its examples |
| 6 | `time` | the clock and the zone, as two groups |
| 7 | `appearance` | system / light / dark |
| 8 | `notifications` | five sections over one preference store |
| 9 | `library` | saved tools, then recently opened ones |
| 10 • | `account` | the whole identity on one screen, and the danger zone |
| 11 • | `edit` | display name, first and last name, photo |
| 12 • | `email` | a new address, pending until it is verified |
| 13 • | `phone` | a number, or none |
| 14 • | `security` | the two doors, and what Lume does not protect |
| 15 • | `password` | current, new, confirm |
| 16 • | `sessions` | this device, and every other one |
| 17 | `privacy` | three switches about three different surfaces |
| 18 | `sync` | what is kept here, and what is not kept anywhere |
| 19 | `help` | what the product is, and where to go next |
| 20 | `about` | three facts and a name |
| 21 • | `delete` | the one thing that cannot be undone |

---

## 3. The route-to-test matrix

Fifteen dimensions. A cell names the file that asserts it; `—` means the
dimension does not apply to that route, with the reason given under the
table. **No route is carried by a golden or a bounds test alone**: every row
has at least one behavioural file in it.

Files, abbreviated: **R** `account_routes_test` · **A** `account_reachability_test`
· **B** `account_bounds_test` · **G** `destination_golden_test` ·
**F** `account_forms_test` · **D** `account_destructive_test` ·
**P** `account_preferences_test` · **N** `account_notifications_test` ·
**I** `account_identity_test` · **T** `account_data_test` ·
**L** `account_locale_test`

| route | manifest | reachable | back | protected | bounds | golden | composition | form | validation | dirty guard | destructive | session state | writes | empty/slow | a11y · RTL · 200% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `prefs` | R | A | A | — | B | G | P | — | — | F | — | — | — | — | L A |
| `language` | R | A | A | — | B | G | P | — | — | F | — | — | P | — | L A |
| `region` | R | A | A | — | B | G | P | — | — | F | — | — | P† | P | L A |
| `currency` | R | A | A | — | B | G | P | — | — | F | — | — | P | — | L A |
| `units` | R | A | A | — | B | G | P | — | — | F | — | — | P | — | L A |
| `time` | R | A | A | — | B | G | P | — | — | F | — | — | P | — | L A |
| `appearance` | R | A | A | — | B | G | P | — | — | F | — | — | P | — | L A |
| `notifications` | R | A | A | — | B | G | N | — | — | F | — | N | N | N | L N |
| `library` | R | A | A | — | B | G | T | — | — | F | — | — | — | T | L T |
| `account` | R | A | A | R A | B | G | I | — | — | F | I | I | — | — | L I |
| `edit` | R | A | A | R A | B | G | F | F | F | F | — | F | F | F | L F |
| `email` | R | A | A | R A | B | G | F | F | F | F | — | F | F | F | L F |
| `phone` | R | A | A | R A | B | G | F | F | F | F | — | F | F | F | L F |
| `security` | R | A | A | R A | B | G | I | — | — | F | I | I | I | — | L I |
| `password` | R | A | A | R A | B | G | F | F | F | F | F | F | F | F | L F |
| `sessions` | R | A | A | R A | B | G | D | — | — | F | D | D | D | D | L D |
| `privacy` | R | A | A | — | B | G | T | — | — | F | — | T | T | — | L A |
| `sync` | R | A | A | — | B | G | T | — | — | F | — | T | — | T | L T |
| `help` | R | A | A | — | B | G | T | — | — | F | — | — | T | — | L T |
| `about` | R | A | A | — | B | G | T | — | — | F | — | — | — | — | L T |
| `delete` | R | A | A | R A | B | G | D | D | D | F | D | D | D | D | L D |

**Where a dimension does not apply.**

*Protected* — fourteen routes are open on purpose, and that is asserted, not
assumed: `account_reachability_test.dart` walks all twenty-one and requires
exactly the seven marked `•` to refuse a guest. Privacy and Data & sync are
open **because** they describe this device rather than an account, and
`account_routes_test.dart` says so by name.

*Form / validation* — five routes carry fields. The other sixteen declare no
`initialValues`, and `account_forms_test.dart` asserts that the guard fires on
exactly the five and on nothing else, so "no form" is a tested property rather
than an omission.

*Destructive* — four routes can take something away: `delete` ends the
account, `password` signs every other device out, `sessions` and `security`
revoke. Each asks first.

*Writes* — a route that only describes writes nothing, and that is the
assertion: Data & sync, About and the library are read-only, and the library's
tap opens a tool rather than saving one.

*a11y · RTL · 200%* — **L** is on every row because
`account_locale_test.dart` sweeps all twenty-one: three languages at 100%, at
200%, at 359 points, and as a guest at 200%, asserting that nothing overflows
and that each is laid out in the direction its language reads. The second
letter is the route's own semantic assertion, where it has one.

*Empty / slow* — asserted where a route has a state to be in. `sync`,
`sessions` and `library` each have one, and each says something true while it
waits rather than an empty card that reads like a finished one.

† *Region writes nothing itself.* Country, city and region move together or
not at all, so the route has no chooser: all three rows and its button open
the one location editor that can change them consistently, and the test
asserts the editor opens and the record is untouched on the way there.

---

## 4. Counts

Two numbers, because a test file has two, and an earlier version of this table
mixed them without saying so.

**Declaration** — one `testWidgets(` or `test(` call site written in the file.
**Runtime case** — one unit `flutter test` counts, and one tick of its `+N`. A
declaration inside a `for` produces several; one outside a loop produces one.
The difference between the columns is exactly the cases the loops add.

| file | declarations | + from loops | runtime cases |
|---|---:|---:|---:|
| `account_forms_test.dart` | 41 | — | 41 |
| `account_data_test.dart` | 37 | — | 37 |
| `account_preferences_test.dart` | 31 | — | 31 |
| `account_notifications_test.dart` | 25 | — | 25 |
| `account_identity_test.dart` | 23 | — | 23 |
| `account_destructive_test.dart` | 21 | — | 21 |
| `account_reachability_test.dart` | 12 | 39 | 51 |
| `account_routes_test.dart` | 11 | — | 11 |
| `account_locale_test.dart` | 6 | 11 | 17 |
| `account_bounds_test.dart` | 1 | 20 | 21 |
| **total** | **208** | **70** | **278** |

| | |
|---|---:|
| routes | 21 |
| protected routes | 7 |
| account test files | 10 |
| declarations | 208 |
| runtime cases | 278 |
| account golden comparisons | 85 |

Four loops walk the whole route list rather than naming routes one at a time.
They are not the same shape, so they are written out rather than summed:

| loop | over | cases |
|---|---|---:|
| `account_bounds_test.dart` | all 21 routes | 21 |
| `account_reachability_test.dart` | 21 routes, then the 7 protected and the 14 open | 42 of its 51 |
| `account_locale_test.dart` | 3 languages × 5 conditions, then 2 languages | 17 |
| `destination_golden_test.dart` | 21 routes × 4 cells, plus the guest refusal | 85 |

`account_routes_test.dart` is **not** one of them: it walks all twenty-one
*inside* single cases, so its eleven declarations are eleven runtime cases.

Both columns are produced mechanically — declarations by scanning the source
with strings and comments skipped, runtime cases by `flutter test --reporter
json` — so the rows with no loop agreeing is a check on both counters.

---

## 5. What the tests hold the section to

These are the claims that would matter if they broke, in the order they were
worth making.

**A hidden feature stays hidden through every door.** §64 is not only about
the entry point. The library filters favourites and recents through
`LumeEligibility.visibleById` on the way *out*, so a faith-gated tool a reader
once saved does not come back through their own saved list. The Notifications
route derives its categories from the same question, so a tool that is not
visible takes its alerts with it — and a switch for a category that has since
been hidden cannot be flipped by a stale tap.

**Nothing claims a server.** No route says "last synced", "backed up" or "up
to date". Data & sync says nothing syncs and says why, in place of an empty
card that would read like one that had not loaded. The Security route names
what Lume protects and, in the same breath, that there is no two-factor or
biometric unlock in this build — a row reading "Off" for something that was
never built still advertises it.

**A destructive act is asked twice, and the second question is a sentence.**
Deletion asks for the password, then asks again with what it takes and what it
leaves; the confirmation says it cannot be undone. Signing other devices out
asks first. Nothing destructive is a single tap, and Back cannot reopen the
form that did it.

**A secret never reaches the semantics tree.** The password form's fields are
obscured with a per-field reveal, and the whole semantics tree is walked to
assert no typed password reaches a label, value or hint. The sessions list is
walked the same way for device identifiers.

**A value the product holds and knows to be empty says so.** "Not set" is a
statement; a blank row is a gap. The two are different, and
`LumeSettingsRow` distinguishes them: `null` is a value the product does not
have, `''` is one it has and knows to be empty.

**Nothing is claimed about a reader's identity that the reader did not
supply.** Religion is never inferred from country or language; the
Notifications route offers the faith category only to a reader who asked for
the Islamic experience, and the language routes assert that choosing Urdu says
nothing about either.

---

## 6. Fixtures, and what they are not

| fixture | stands for | says it is not durable |
|---|---|---|
| `LumeFakeAccountRepository` | the account, its sessions, its stored-data summary | yes |
| `LumeMemoryNotificationPrefs` | the notification preference store | yes |
| `LumeMemoryProfileRepository` | the saved profile record | yes |

`kNotificationSources` is the reference's own fifteen rows of id, tool,
category and type, carried as a fixture. It is a **list of what could notify**,
not a notification engine: there is no build function, no schedule and no
delivery behind it, and nothing on screen says otherwise.

The account deletion path is fake and nondurable. It removes the identity from
a process-lifetime fixture and reports that it did. It is not connected to
anything, and the future Dayroz contract for these tables is documented in
[`conversion_archive/DAYROZ_ARCHITECTURE_MAPPING.md`](conversion_archive/DAYROZ_ARCHITECTURE_MAPPING.md)
rather than applied.

---

## 7. The host's own contracts

**A route opens on its own values.** `_openRoute` resets the form to the
route's `initialValues` whenever the route changes, so a draft cannot follow
a reader from one screen to the next.

**A rebuild is not an edit.** Changing the locale or the theme rebuilds every
route; the guard compares against the values the route opened with, so a
rebuild does not make a clean form dirty.

**A form in flight is inert.** Fields are disabled while a write is pending,
and a second tap on a submit is not a second write — `LumeFakeAccountRepository.writes`
counts attempts, so a duplicate submission is observable rather than inferred.

**A form is wiped when its work is done.** `LumeAccountForm.wipe()` clears
values, errors, touched state and reveal flags after a password change, after
a deletion, and after a deletion the reader cancelled. `dispose()` calls it,
so nothing typed outlives the screen.
