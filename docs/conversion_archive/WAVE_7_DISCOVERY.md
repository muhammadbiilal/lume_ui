# Wave 7 discovery — provisional, gate not lifted

**Status: discovery only. Not an approved wave.** `ROLLOUT_WAVE_6.md` §5:
*"Closure does not reopen §8 further than this scope — a seventh wave is
its own decision."* That condition stands. This document is the research
that decision would be made from.

## 0. Where wave 6 left the count

| | |
|---|---:|
| tools in the catalogue | **85** |
| registered after wave 6 | **40** |
| unbuilt | **45** |

Reconciles exactly with history: wave 4 closed at 51 unbuilt; wave 4
itself cleared 3, wave 5 cleared 2, wave 6 cleared 1 → 51−3−2−1 = 45.
Re-checked directly, not assumed: `record-schemas.js` still has exactly
12 real schemas, and a spot-check across three different blocker
categories (`mosques`/Blocker 3, `bmi`/Blocker 6, `quran`/Blocker 7)
confirmed none has quietly gained a schema, a licensed source, or a
ruling. `WAVE_6_DISCOVERY.md` §2's blocker taxonomy is still current.

## 1. The genuinely new question this wave asked

Waves 5 and 6 both found "the one tool blocked by a data-model decision
alone." Nothing left in the unbuilt 45 fits that shape. So this
discovery asked a different question: **could a coding-only wave unblock
a Blocker-5 tool by building the platform infrastructure itself**, rather
than waiting for reminders/alarms' stated blocker ("notification
scheduling and permission") to resolve on its own?

### 1.1 What real notification infrastructure would actually need

Checked directly against this repo, not generically:

- `pubspec.yaml` has exactly 8 dependencies, each with its own
  provenance comment. No `flutter_local_notifications`, no
  `permission_handler`, no equivalent — this would be a new dependency
  category, not a version bump.
- `android/app/src/main/AndroidManifest.xml` declares `CAMERA`, storage
  permissions, network state, a `tel:` query — nothing notification- or
  alarm-related. Missing, concretely: `POST_NOTIFICATIONS` (Android 13+
  runtime permission), `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (needed
  for a reminder fired at a precise time), a boot receiver + manifest
  entry (without one, every scheduled reminder is silently lost on
  device restart), and notification-channel setup in `MainActivity.kt`.
- `ios/Runner/Info.plist` and `AppDelegate.swift` have no
  `UNUserNotificationCenter` authorization request or delegate hookup.
- This is a from-scratch platform integration on both operating systems,
  not a config tweak.

### 1.2 The existing in-app notification centre is confirmed cosmetic

`lib/features/notifications/` is fixture-driven end to end —
`notification_fixtures.dart`'s own doc comment: *"Nothing here was
delivered."* Its "live" behaviour (`notification_presenter.dart`) is a
plain Dart `Timer` against an injected schedule, not a platform channel;
`KNOWN_DIFFERENCES.md` §C79 documents the one defect this ever had
(a banner re-showing on every launch) as pure in-memory bookkeeping,
nothing about real delivery. It provides no hook a real notification
feature could plug into.

### 1.3 This project's own idiom for "ask the OS for something"

The camera-permission flow (`lib/core/platform/lume_camera_gate.dart` +
a hand-written native `MethodChannel`, `lume/camera_permission`) is the
precedent — **not** a permission plugin. Lume's convention is a
hand-rolled channel returning a raw facts map, classified by pure Dart,
with a fake gate for tests. If a permission flow were built for
notifications, it would likely follow this same shape rather than pull
in `permission_handler`. This solves only the *permission* half, though
— nothing in the repo has any analogue for the *scheduling* half.

### 1.4 The conflict this discovery actually surfaces

Reminders is not blocked by one thing, but two, and the second is new:

- The platform integration Wave 4 already named.
- **A direct conflict with Option B**, the persistence policy Wave 5
  settled two days ago: session-only storage, no persistence package,
  everything "cleared when you close Lume." A reminder set for tomorrow
  from a store that is wiped when the app closes is not a reminder that
  can honestly fire — and if it somehow did (an OS-level alarm surviving
  independently of the record that created it), the app would have no
  memory of what it was for after a restart, which is a different and
  worse kind of dishonesty than anything Option B was written to avoid.

Concrete risks beyond the two blockers themselves: Android 13+ runtime
permission UX (denial/blocked/rationale states, but for a feature that
fires later, out of the request flow, so failures are silent to the
reader); exact-alarm restrictions and Play Store policy scrutiny on that
permission; doze-mode interaction; a boot receiver that is hard to test
without a device farm; iOS's 64-pending-notification limit; and a need
for real-device QA that nothing else in this repo has required, since
every other platform integration here (camera, gallery, share, dialer)
completes synchronously while the app is foregrounded.

### 1.5 The middle ground — checked, and rejected on the reference's own words

Before concluding, checked whether a **session-only Reminders** — a real
record family, typed CRUD, an in-app banner via the notification
centre's already-shipped `Timer`-driven mechanism (`notification_presenter.dart`,
genuinely real Dart, zero new package, zero native code), fired only
while Lume is open, with an explicit disclosure — could honestly sidestep
both blockers at once, the way Option B let Goals/Subscriptions/Meal Plan
sidestep durability.

It cannot, and the reason is the reference's own copy, not this
project's caution. `assets/js/i18n/crud.js`'s `rec.f.remindMe` — the
literal label on the reminder form's field — reads **"Remind me to"**;
`rec.reminders.emptyText` reads **"Set one and Lume will nudge you at the
right time"** (and the same active-delivery promise, unsoftened, in
Urdu and Arabic). The reference frames the entire feature as something
that happens *while the reader is doing something else*. A session-only,
foreground-only substitute cannot fulfill that for anyone who isn't
already looking at the app — which is the one scenario a reminder exists
for. This is a different situation from Water/Birthdays' C100 disclosure:
that discloses data loss on an already-passive record the reader is
looking at when they use it; a reminder's whole stated value is realized
specifically when they are not looking. Wrapping the same schema and the
same "Remind me to…" copy in a foreground-only mechanism is not a smaller
honest version of the feature — it is a different feature wearing the
original's promise. Two of the schema's three `repeat` options (`daily`,
`weekly`) compound this: they are the schema's own vocabulary for
recurring across sessions, which a per-launch wipe cannot honour at all.

The mechanism half of this path is genuinely free (real, shipped,
reusable). The product-honesty half is not — and this document does not
have the authority to rename or reframe a feature away from what the
reference's own strings promise it will do.

## 2. Verdict

**Not a Wave-7-sized effort as scoped, and not resolvable by this
document alone.** Building real Reminders means reopening two decisions
together, not one: the platform-integration blocker Wave 4 named, and
the Option B persistence policy Wave 5 just settled for a different
reason. Every other unbuilt tool is unchanged from `WAVE_6_DISCOVERY.md`
§2 — still blocked on licensed sourcing, a live feed, a medical decision,
or a religious ruling, none of which a coding wave produces on its own.

## 3. What this leaves, if a seventh wave is wanted

Two honest paths, named without recommending between them — both are
decisions for the reader/owner, not this document:

- **(a) A deliberately bigger, two-part wave**: reopen persistence policy
  specifically for reminder-shaped tools (a real question: does *any*
  record family need to survive past a session, or does Reminders alone
  get an exception with its own tradeoffs stated plainly?) and build the
  platform integration together, with its own proposal document in the
  shape Ledger/Installments used for their own hosts — not the
  Goals/Subscriptions/Meal Plan template, which assumed no new
  infrastructure.
- **(b) Wait.** Nothing else in the unbuilt 45 clears without an external
  decision this repo cannot make for itself.

No implementation follows from this document. `ROLLOUT_WAVE_6.md` §5
stands: a seventh wave needs its own explicit decision.
