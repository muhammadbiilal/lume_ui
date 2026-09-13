/// Notification preferences, for as long as the process lives.
///
/// A [ChangeNotifier] rather than a value, because two screens read it — the
/// Profile row that counts what is on, and the Notifications route that
/// switches them — and a change on one has to reach the other in the same
/// frame. **Not durable**, and [isDurable] says so: nothing here tells the
/// reader a preference is saved when it will not survive the process.
library;

import 'package:flutter/foundation.dart';

import '../domain/notification_prefs.dart';

/// The in-memory store.
class LumeMemoryNotificationPrefs extends ChangeNotifier
    implements LumeNotificationPrefsStore {
  LumeMemoryNotificationPrefs([
    LumeNotificationPrefs initial = const LumeNotificationPrefs(),
  ]) : _prefs = initial;

  LumeNotificationPrefs _prefs;

  /// How many writes were attempted. A duplicate submission shows up here.
  int writes = 0;

  @override
  LumeNotificationPrefs get prefs => _prefs;

  @override
  bool get isDurable => false;

  @override
  Future<void> write(LumeNotificationPrefs next) async {
    writes++;
    if (next == _prefs) return;
    _prefs = next;
    notifyListeners();
  }
}
