/// What a tool remembers between openings.
///
/// `context.js` keeps each tool's state and fields in a module-level `STATE`
/// object: typed into Tax, left, and opened again, the figure is still there;
/// reload the page and it is gone. This is that store — in memory, for the life
/// of the app, and **not durable**. Nothing here is written anywhere.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-tool values, keyed by tool id and then by the reference's own key
/// (`income`, `deductions`, `period`).
class LumeToolSession {
  final Map<String, Map<String, String>> _values =
      <String, Map<String, String>>{};

  String? read(String tool, String key) => _values[tool]?[key];

  void write(String tool, String key, String value) =>
      (_values[tool] ??= <String, String>{})[key] = value;

  /// `fieldsFor(id, defaults)` — a key the tool has never written takes its
  /// default, and the default is remembered from then on.
  String field(String tool, String key, String Function() fallback) =>
      (_values[tool] ??= <String, String>{}).putIfAbsent(key, fallback);
}

final Provider<LumeToolSession> toolSessionProvider = Provider<LumeToolSession>(
  (Ref ref) => LumeToolSession(),
);
