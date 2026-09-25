# Rollout wave 7 — the gate reopened, on the record

`ROLLOUT_WAVE_6.md` §5: *"Closure does not reopen §8 further than this
scope — a seventh wave is its own decision."* `WAVE_7_DISCOVERY.md`
found no single-decision candidate like waves 5/6; the owner's decision,
dated 2026-09-25, is to reopen two things together rather than wait.

## 0. The decision

> Reopen both together as a bigger wave — pick a persistence approach for
> reminder-shaped data and build the notification infrastructure in the
> same wave.

This wave is **categorically different from waves 4–6**, and is recorded
as such rather than forced into the same template:

- Every prior wave (converter/birthdays/water through goals/subs/mealplan)
  added **zero new dependencies** and **zero native platform code**. This
  one adds both.
- Every prior wave's evidence bar (domain tests + widget tests +
  integrated gate) is achievable entirely in this environment. **This
  wave's central claim — that a notification actually fires — cannot be
  verified here.** There is no device or emulator attached to this
  session. Widget tests can prove the record model, the permission-state
  classification logic, and the scheduling *calculation* are correct;
  they cannot prove Android's `AlarmManager` or iOS's
  `UNUserNotificationCenter` actually deliver anything. That gap is
  named here, not glossed over, and real-device verification is called
  out as an obligation before this wave is treated as trustworthy, the
  same way `ROLLOUT_WAVE_4.md` §1.3 named its own one foreseeable
  blocker rather than discovering it later.

## 1. Architecture decisions, made on the research in `WAVE_7_DISCOVERY.md`

### 1.1 Persistence — scoped to Reminders alone, not project-wide

Confirmed by direct research (not assumed): `DAYROZ_ARCHITECTURE_MAPPING.md`
§3's rejection of `shared_preferences` is reasoned as *"reference state is
fixtures, not persistence"* — a phase-scoped statement, not a ban on any
embedded database, and the same section explicitly anticipates a future
package being *"proposed in its own phase report with platform support,
licence and integration impact stated."* This is that proposal, for
Reminders only.

- **No project-wide durable-storage migration.** Ledger, Installments,
  Committee, Baby Budget, Goals, Subscriptions and Meal Plan all keep
  `LumeMemoryRecordRepository` exactly as they have it. Their own Option B
  disclosures ("kept until you close Lume") are unaffected and remain
  true.
- **Reminders gets its own repository implementation** of the same
  `LumeRecordRepository` interface, wired to a new, Reminders-only
  provider (`reminderRepositoryProvider`) — not the shared
  `recordRepositoryProvider`. This is architecturally anticipated by the
  interface's own `durable` flag (`record_repository.dart`'s own doc
  comment: *"A screen that would claim 'kept on this device' reads that
  flag first"*) and matches this codebase's one-provider-per-concern
  convention already used for `locale_provider.dart`,
  `time_zone_provider.dart`, and others.
- **Package: `sqflite`.** Android/iOS only (matches this project's real
  platform scope — confirmed no `web/`, `windows/`, `macos/`, `linux/`
  directories exist), the most mature and widely-used local-storage
  plugin for exactly this shape of need, and a natural fit for the
  existing `LumeRecord` envelope (`id`, a JSON-encoded `fields` map,
  `version`, `createdAt`, `updatedAt`) as a single simple table rather
  than a relational schema — Reminders needs no joins, no queries beyond
  "all reminders" and "one by id."
- **Licence**: BSD-3-Clause (`sqflite`), permissive, no obligation beyond
  attribution — consistent with every other dependency this project
  already carries.

### 1.2 Notification delivery — `flutter_local_notifications`

The standard, actively-maintained package for Android/iOS local
scheduled notifications. No web story exists for it, which is
irrelevant here since this project has no web target. Licence: BSD-3
-Clause, same profile as every other dependency already in `pubspec.yaml`.

### 1.3 Permission gate — the camera precedent, extended to a platform it hasn't reached yet

This project's own idiom for "ask the OS for something" is a hand-written
native `MethodChannel`, not a permission-plugin package
(`lume_camera_gate.dart` + `LumeCameraPermission.kt` + `MainActivity.kt`
wiring — raw platform facts in, a pure-Dart `classify()` out, a fake gate
for tests). A notification-permission gate follows the same shape:
`LumeNotificationGate` (interface), `LumeAndroidNotificationGate` +
`LumeIosNotificationGate` (real), `LumeFakeNotificationGate` (test
double), a `LumeNotificationFacts` raw-map class, and
`LumeNotificationAccess.classify()`.

**This is not a copy-paste of existing code.** The camera gate's native
implementation is Android-only today — no iOS Swift permission-channel
precedent exists anywhere in this repo. The iOS half of this gate is
genuinely new native code, written for the first time, not an extension
of a proven pattern. That risk is named here rather than assumed away by
analogy to the camera gate's success.

### 1.4 What Android/iOS specifics this needs

- **Android**: `POST_NOTIFICATIONS` (API 33+ runtime permission),
  `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` (API 31+, and subject to
  Play Store policy review — a fallback to inexact scheduling
  (`AlarmManager.setAndAllowWhileIdle`) is the safer default unless exact
  timing is genuinely required), a `RECEIVE_BOOT_COMPLETED` receiver to
  re-arm reminders after a device restart (without one, every scheduled
  reminder is silently lost on reboot — this is not optional for
  `repeat: daily`/`weekly` reminders to be honest), and a notification
  channel declared in `MainActivity.kt`. This project's manifest is
  already hand-curated to actively remove permissions it doesn't want
  (`tools:node="remove"` on `RECORD_AUDIO`, storage, network-state) —
  the two new permissions this adds should be held to the same scrutiny,
  not added reflexively.
- **iOS**: a `UNUserNotificationCenter.requestAuthorization` call, an
  `AppDelegate.swift` hookup for `UNUserNotificationCenterDelegate`
  (foreground presentation), and (per the discovery's own note) new
  native Swift permission-gate code where none existed before. iOS 13.0
  deployment target (confirmed in `project.pbxproj`) is old enough that
  none of this is version-gated.
- **Android SDK thresholds**: this project does not pin
  `minSdk`/`targetSdk`/`compileSdk` explicitly — it inherits the
  installed Flutter SDK's defaults. Confirming the actual numbers before
  implementation starts is part of this wave's own work, not assumed
  here; recent Flutter defaults very likely place `targetSdk` at 33+,
  meaning `POST_NOTIFICATIONS` almost certainly applies, and this wave is
  scoped assuming it does.

## 2. What this wave does, and does not, do

- **Builds**: a real `Reminder` record family (the schema already exists,
  `record-schemas.js:196-241`, and Events already shares its shape per
  `ROLLOUT_WAVE_4.md` §5), backed by the new durable, Reminders-only
  store; a real notification-permission gate; real scheduled local
  notifications for `once` reminders, and — because `repeat: daily`/
  `weekly` genuinely need reboot-survival to be honest — the boot
  receiver required to re-arm them.
- **Does not** touch any other family's persistence. Does not add a
  project-wide database. Does not attempt Alarms (still no schema at
  all, per `WAVE_6_DISCOVERY.md` §2 — a separate decision, not inferred
  from this one).
- **Does not** claim verified delivery until real-device testing has
  happened. This document's own evidence bar for closure includes that
  step explicitly, not implicitly.

## 3. Process

`REMINDERS_PROPOSAL.md` (design before implementation, including the
typed model, the permission-state machine, and the scheduling/reboot
behaviour) → implementation → the integrated gate (widget/unit-testable
parts only) → **explicit real-device verification, named as a real
obligation rather than assumed** → a coherent commit, no attribution
trailers.

## 4. Closure

Closes when Reminders is registered, its record layer and permission
classification are tested, and real-device delivery has been confirmed —
not merely when `flutter test` passes, since that alone cannot prove this
wave's central claim.
