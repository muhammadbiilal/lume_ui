# Reminders — implementation proposal

`ROLLOUT_WAVE_7.md` records the decision (scoped durable store, real
scheduled delivery, Android + iOS together). This is the design that
implementation follows, in the shape `GOALS_PROPOSAL.md`/
`SUBSCRIPTIONS_PROPOSAL.md`/`MEALPLAN_PROPOSAL.md` used before it.

## 1. Model — `record-schemas.js:196-241`, unchanged

One flat collection, `reminders`. Fields: `label` (text, required),
`at` (time-of-day, required), `repeat` (`once` | `daily` | `weekly`,
default `once`), `notes` (optional). No parent record, no money, no
cross-family reference — the same shape as Meal Plan, not as
Installments.

`ReminderEntry`: `id`, `label`, `at` (`LumeTimeOfDay` — a new small value
type: hour/minute, no date, no zone, matching `at: time` in the schema),
`repeat` (`ReminderRepeat` enum), `notes`, `enabled` (bool — pausing a
reminder without deleting it, needed once delivery is real: the reference
schema has no such field, but every delivered reminder needs a way to be
silenced without losing its configuration, and "delete it" is not that),
`createdAt`, `updatedAt`. Codec follows every other family's strict
decode-or-defect pattern.

## 2. Persistence — `LumeSqliteRecordRepository`, scoped to `reminders` alone

A second implementation of `LumeRecordRepository`
(`lib/features/records/data/sqlite_record_repository.dart`), wired to its
own `reminderRepositoryProvider` — not the shared
`recordRepositoryProvider` every other family uses. No other family's
provider or store changes.

**Package: `sqflite`** (BSD-3-Clause, Android/iOS only — matches this
project's real platform scope). Dev-only: `sqflite_common_ffi`
(BSD-3-Clause), sqflite's own documented FFI backend for testing outside
a device, used exactly the way `flutter_test` already runs everything
else in this repo: `databaseFactory = databaseFactoryFfi` in a test
`setUpAll`, an in-memory (`:memory:`) database per test, no real disk, no
real platform channel — the durable repository is exercised for real,
not mocked, the same principle `LumeMemoryRecordRepository`'s own tests
already follow.

**Why not extend `LumeMemoryRecordRepository`**: its transaction/undo
engine is private to that file and correct precisely because it is
tested; subclassing across the library boundary can't reach it, and
duplicating persistence into it would put a durability decision inside
code every session-only family also depends on. A dedicated
implementation keeps the blast radius to one file plus one provider,
exactly as `ROLLOUT_WAVE_7.md` §1.1 records.

**Shape**: one table, `reminders(id TEXT PRIMARY KEY, fields TEXT,
version INTEGER, created_at TEXT, updated_at TEXT)` — `fields` is the
same JSON-encoded map every other collection already keeps in memory,
so the table mirrors the existing `LumeRecord` envelope rather than
inventing a relational schema for four form fields.

**Concurrency model**: the interface's `create`/`update`/`remove` are
synchronous (the reference is synchronous `localStorage`; nothing in
`LumeRecordRepository` returns a `Future`). This repository keeps an
in-memory cache as the synchronous source of truth — mutations apply to
it and return immediately, `notifyListeners()` fires immediately — and
persists to SQLite as a write-behind: the SQL statement is issued
right after the cache update and awaited internally, but the caller
never waits on it. **Named plainly, not glossed over**: a hard kill of
the process between the in-memory write and that statement reaching disk
could in theory lose the very last write. sqflite writes are typically
sub-millisecond to a local SQLite file and are issued synchronously in
program order on its single worker, so the exposure is a narrow race,
not a routine one — but it is a real, different failure mode from
Option B's "everything is lost by design," and this document says so
rather than presenting the store as unconditionally safe. Reads
(`open`) are genuinely async underneath: the existing "first open is a
loading state" pattern already in `LumeMemoryRecordRepository` (an
artificial 220 ms delay, replaced here by an awaited `SELECT`) means no
new UI state is needed — a real load is exactly the state the loading
skeleton already exists for.

**No cross-family transaction coupling** — checked directly: nothing
outside `lib/features/records/` and `mealplan`/`goals`/`subscriptions`'
own repositories calls `LumeRecordTransactions` methods across
collections belonging to different families, and Reminders introduces no
family that references another's records. Scoping durability to this one
collection carries no hidden dependency on the shared in-memory store.

## 3. Notification delivery — `flutter_local_notifications`

`LumeReminderScheduler` (`lib/features/reminders/data/reminder_scheduler.dart`)
wraps the plugin behind a small interface (`LumeReminderScheduler`
abstract + a real implementation + a fake for tests, the same
real/fake split every platform adapter in this repo already uses —
`LumeCameraGate`, `LumeDialer`, `LumeSharer`). It exposes exactly what
Reminders needs: `schedule(ReminderEntry)`, `cancel(ReminderId)`,
`rescheduleAll(List<ReminderEntry>)` — never the plugin's full API
surface. `daily`/`weekly` use the plugin's `matchDateTimeComponents`
recurrence (`DateTimeComponents.time` / `.dayOfWeekAndTime`), which the
plugin itself re-arms after a reboot via its own bundled Android
receiver — no bespoke boot receiver is written here, since adding one
would either duplicate or race the plugin's own.

## 4. Permission gate — `LumeNotificationGate`, the camera gate's shape

`lib/core/platform/lume_notification_gate.dart`: `LumeNotificationAccess`
(`granted` / `firstRequest` / `denied` / `blocked` / `undetermined` /
`unavailable` / `failed`, matching `LumeCameraAccess`'s own vocabulary
rather than inventing a new one), `LumeNotificationFacts` (raw platform
booleans), `classify()` (pure), `LumeAndroidNotificationGate` +
`LumeIosNotificationGate` (real, each its own native channel —
`lume/notification_permission_android`, `lume/notification_permission_ios`,
kept separate rather than one channel with platform branching inside it,
matching how the camera gate is Android-only rather than one channel
pretending to be cross-platform), `LumeFakeNotificationGate` (test
double). Exact alarm permission (Android 12+) is asked for through the
same gate as a second, explicit fact — a reminder that silently falls
back to inexact timing without telling the reader is a worse outcome
than asking once.

**iOS has no existing native-channel precedent in this repo.** The
`LumeIosNotificationGate`'s Swift handler
(`ios/Runner/LumeNotificationPermission.swift`) is new code, written for
this feature, not an extension of a proven pattern — named here per
`ROLLOUT_WAVE_7.md` §0's own caveat, not discovered later.

## 5. What Home/Today/Tools do with this

Registered as a Tools-category feature (Planning), not Home-eligible —
matching `WAVE_5_DISCOVERY.md`'s own reasoning for Goals/Subscriptions:
a record family a reader sets up once and rarely revisits from Home.
No hero slide, no Quick Tool by default. `LumeDataCapability` for
`reminders` records `durable: true` — the one family, so far, for which
that flag is actually load-bearing rather than a placeholder read by
nothing.

## 6. Evidence bar

Domain tests (codec, repository CRUD + undo + conflict, against the real
FFI-backed SQLite, not a mock), permission-classification tests (pure
function, exhaustive fact combinations, exactly like
`lume_camera_gate_test.dart`), scheduler tests (against the fake
scheduler — asserting Reminders calls it correctly, not that the OS
delivers), widget tests (list/sheet/enable-disable/delete, English +
Urdu + Arabic, light + dark), the integrated gate.

**Explicitly not covered by that bar, and not claimed to be**: that a
scheduled Android or iOS notification is actually delivered by the OS.
That requires a real device or emulator, which this environment does not
have. `ROLLOUT_WAVE_7.md` §0 names this as an obligation before the wave
is trusted, not a step this proposal can discharge on paper.
