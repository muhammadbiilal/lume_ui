/// Taraweeh's stored records — one night the reader actually prayed, and
/// their codec to and from the record envelope.
///
/// **The reference is not a personal tracker at all.**
/// `tools/islamic/taraweeh.tool.js` draws a nearby-mosque finder — a rakaat
/// filter (`all` / `8` / `20`), a search box, a map and a list of "nearby"
/// mosques, each with its own Taraweeh start time — fed entirely by
/// `context.js`'s `nearbyMosques()` (`context.js:269-288`). Every field of
/// every mosque it returns is fabricated: four hardcoded names ("Central
/// Mosque", "Jamia Masjid", "Masjid Al-Noor", "Masjid Bilal"), four invented
/// reciters ("Qari Ahmed", "Hafiz Bilal", "Qari Usman", "Hafiz Salman"),
/// distances computed as `0.4 + i * 0.7` from the mosque's *index* rather
/// than any real position, and even the rakaat count and start time are a
/// fixed per-index literal (`rakaat: [20, 8, 20, 8][i]`,
/// `taraweeh: { h: 20, m: [45, 50, 55, 40][i] }`). `tool-specs.js` is honest
/// about the shape this is meant to be — it names the source a "places
/// directory" — but this build has no such directory, real or otherwise, and
/// there is no nearby-mosque feature converted for it to legitimately draw
/// from either. Building the reference's screen faithfully would mean
/// inventing a mosque database this app has no source for; nothing here
/// carries any of that forward.
///
/// What survives is the one real, honest thing the reference's composition
/// was actually pointing at: a reader's own Taraweeh nights during Ramadan.
/// This stores exactly that — same one-entry-per-date shape as Daily
/// Streak's check-ins — plus the two things a Taraweeh night is actually
/// about: how many rakat were prayed ([TaraweehNight.rakaat] — the
/// reference's own real 8-or-20 distinction, now the reader's, not a
/// mosque's) and, optionally, which Juz of the Qur'an the congregation
/// reached that night ([TaraweehNight.juz]) — the collective Khatm
/// (completion of the whole Qur'an) most congregations aim for by the end of
/// Ramadan. Every streak and every completion figure this feature shows is
/// computed from these nights in `taraweeh_book.dart` — never a literal.
///
/// **At most one entry per date.** Logging tonight again replaces its rakaat
/// and Juz; clearing it removes the night entirely — the same rule every
/// other check-in family here keeps.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record.
const String kTaraweehSchema = 'lume.taraweeh/1';

abstract final class TaraweehCollections {
  static const String nights = 'taraweeh.night';
  static const List<String> all = <String>[nights];
}

/// The rakaat counts a Taraweeh night is actually prayed in — the
/// reference's own real binary (`taraweeh.tool.js`'s `rakaat` filter:
/// `all` / `8` / `20`), never a free-typed number a streak calculation could
/// not reason about.
const List<int> kTaraweehRakaatOptions = <int>[8, 20];

/// The Qur'an's 30 Juz — the range a night's optional Juz reading must fall
/// in.
const int kTaraweehJuzMin = 1;
const int kTaraweehJuzMax = 30;

/// One night the reader prayed Taraweeh.
@immutable
class TaraweehNight {
  const TaraweehNight({
    required this.id,
    required this.date,
    required this.rakaat,
    this.juz,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeDate date;

  /// 8 or 20 — how many rakat were prayed. Required: a night is not logged
  /// without saying which.
  final int rakaat;

  /// 1–30 — the Juz the congregation reached that night, when the reader
  /// chose to note one. `null` when they did not.
  final int? juz;

  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kTaraweehSchema,
    'date': date.toIso(),
    'rakaat': rakaat,
    'juz': juz,
  };

  TaraweehNight copyWith({int? rakaat, int? juz, bool clearJuz = false}) =>
      TaraweehNight(
        id: id,
        date: date,
        rakaat: rakaat ?? this.rakaat,
        juz: clearJuz ? null : (juz ?? this.juz),
        createdAt: createdAt,
        version: version,
      );

  static TaraweehNight decode(LumeRecord r) {
    final TaraweehCodec c = TaraweehCodec(TaraweehCollections.nights, r);
    return TaraweehNight(
      id: c.id,
      date: c.date('date'),
      rakaat: c.intIn('rakaat', kTaraweehRakaatOptions),
      juz: c.intInRange(
        'juz',
        kTaraweehJuzMin,
        kTaraweehJuzMax,
        optional: true,
      ),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TaraweehNight &&
      other.id == id &&
      other.date == date &&
      other.rakaat == rakaat &&
      other.juz == juz &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, date, rakaat, juz, version);
}

/// A record that could not be read as a Taraweeh night.
@immutable
class TaraweehDefect {
  const TaraweehDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decode; caught by whoever reads the collection.
@immutable
class TaraweehDefectException implements Exception {
  const TaraweehDefectException(this.defect);
  final TaraweehDefect defect;

  @override
  String toString() => 'TaraweehDefectException($defect)';
}

/// Strict field readers for one record.
class TaraweehCodec {
  TaraweehCodec(this.collection, this.record) {
    if (record['schema'] != kTaraweehSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw TaraweehDefectException(
    TaraweehDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeDate date(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }

  int intIn(String field, List<int> allowed) {
    final Object? v = record[field];
    if (v is! int) fail(field, 'missing');
    if (!allowed.contains(v)) fail(field, 'range');
    return v;
  }

  int? intInRange(String field, int min, int max, {bool optional = false}) {
    final Object? v = record[field];
    if (v == null && optional) return null;
    if (v is! int) fail(field, 'type');
    if (v < min || v > max) fail(field, 'range');
    return v;
  }
}
