/// Runs before every test in this project (`flutter_test`'s own convention:
/// a `flutter_test_config.dart` at the `test/` root wraps every test file's
/// `main()`).
///
/// **Why this exists**: Reminders' durable store
/// (`LumeSqliteRecordRepository`, `ROLLOUT_WAVE_7.md`) is reached through
/// the ordinary `reminderStoreProvider` by anything that pumps the real
/// router without overriding it — not just Reminders' own tests, but every
/// generic "loop over every registered tool" test this project already has
/// (`share_visibility_test.dart`, `release_readiness_test.dart`'s per-tool
/// checks, the golden suite). `sqflite`'s real platform-channel
/// `databaseFactory` is never initialized outside a real Android/iOS run, so
/// any of those would otherwise crash the moment they reach `'reminders'`
/// with `Bad state: databaseFactory not initialized` — not a Reminders bug,
/// a test-environment one. Initializing sqflite's own FFI backend once,
/// globally, here — exactly its documented testing setup — means the real
/// repository (not a mock) runs correctly wherever a test happens to reach
/// it, the same principle every other store in this project's tests
/// already follows.
library;

import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
