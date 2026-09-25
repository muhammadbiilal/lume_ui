/// Everything Reminders shows, derived from the stored records — never
/// stored itself (`REMINDERS_PROPOSAL.md` §1).
library;

import 'package:flutter/foundation.dart';

import 'reminder_model.dart';

@immutable
class ReminderBook {
  const ReminderBook(this.entries);

  final List<ReminderEntry> entries;

  /// Enabled first, then by time of day, then by label — a reader with a
  /// full list can scan it and know where a new one will land.
  List<ReminderEntry> get sorted {
    final List<ReminderEntry> out = List<ReminderEntry>.of(entries);
    out.sort((ReminderEntry a, ReminderEntry b) {
      if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
      final int byTime = a.minuteOfDay.compareTo(b.minuteOfDay);
      return byTime != 0 ? byTime : a.label.compareTo(b.label);
    });
    return out;
  }

  int get enabledCount => entries.where((ReminderEntry e) => e.enabled).length;

  bool get isEmpty => entries.isEmpty;
}
