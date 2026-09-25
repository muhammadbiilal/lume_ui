/// Reminders' own store and scheduler — the one family with either
/// (`REMINDERS_PROPOSAL.md` §2). No other provider here is touched by any
/// other family's tool.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../records/data/sqlite_record_repository.dart';
import '../../records/domain/record_repository.dart';
import '../data/reminder_scheduler.dart';
import '../domain/reminder_repository.dart';

/// Reminders' durable store. Not [recordRepositoryProvider] — a second,
/// independent [LumeRecordRepository] implementation, reachable only from
/// here. Typed to the interface, not [LumeSqliteRecordRepository] itself —
/// the same type-erasure [recordRepositoryProvider] already uses — so a
/// test can override it with any conforming store (a widget test uses the
/// deterministic in-memory one; only the repository-level tests need the
/// real SQLite behind it, `REMINDERS_PROPOSAL.md` §2 §6).
final Provider<LumeRecordRepository> reminderStoreProvider =
    Provider<LumeRecordRepository>((Ref ref) {
      final LumeSqliteRecordRepository store = LumeSqliteRecordRepository(
        path: 'lume_reminders.db',
      );
      ref.onDispose(store.dispose);
      return store;
    });

final Provider<LumeReminderScheduler> reminderSchedulerProvider =
    Provider<LumeReminderScheduler>((Ref ref) => LumeLocalReminderScheduler());

final Provider<ReminderRepository> reminderRepositoryProvider =
    Provider<ReminderRepository>(
      (Ref ref) => ReminderRepository(
        ref.watch(reminderStoreProvider),
        ref.watch(reminderSchedulerProvider),
      ),
    );
