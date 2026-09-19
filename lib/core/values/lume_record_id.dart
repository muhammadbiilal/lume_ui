/// A record's identity: a UUID, written in its canonical lowercase form.
///
/// **Made once.** An id is generated when its record is created
/// ([LumeRecordId.generate]) and never derived from what the record says or
/// where it sits in a list. Reading one back ([LumeRecordId.parse]) accepts
/// the 8-4-4-4-12 hexadecimal form in either case and keeps it lowercase;
/// braces, `urn:uuid:`, missing hyphens and anything else are refused, so one
/// record never has two spellings.
///
/// **Ordered by its text.** Equality, hashing and order are those of the
/// canonical string, compared by code unit — the tiebreak a deterministic
/// ordering falls back on.
///
/// Whether an id has been used before is the store's to know: a store that
/// has deleted a record refuses to create another with its id.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

/// A value that is not a UUID.
@immutable
class LumeRecordIdException implements Exception {
  const LumeRecordIdException(this.text);

  final String text;

  @override
  String toString() => 'LumeRecordIdException("$text")';
}

@immutable
class LumeRecordId implements Comparable<LumeRecordId> {
  const LumeRecordId._(this.value);

  /// [text] as an id, lowercased; a typed [LumeRecordIdException] when it
  /// is not an 8-4-4-4-12 hexadecimal UUID.
  factory LumeRecordId.parse(String text) {
    final LumeRecordId? id = tryParse(text);
    if (id == null) throw LumeRecordIdException(text);
    return id;
  }

  /// [LumeRecordId.parse], or `null`.
  static LumeRecordId? tryParse(String text) =>
      _shape.hasMatch(text) ? LumeRecordId._(text.toLowerCase()) : null;

  /// A new random (version 4) id from [random] — `Random.secure()` unless a
  /// test supplies a seeded one.
  factory LumeRecordId.generate([Random? random]) {
    final Random r = random ?? _secure;
    final List<int> b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
    final String hex = b
        .map((int x) => x.toRadixString(16).padLeft(2, '0'))
        .join();
    return LumeRecordId._(
      '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}',
    );
  }

  static final Random _secure = Random.secure();

  static final RegExp _shape = RegExp(
    r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-'
    r'[0-9A-Fa-f]{12}$',
  );

  /// The canonical lowercase form.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is LumeRecordId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(LumeRecordId other) => value.compareTo(other.value);

  @override
  String toString() => value;
}
