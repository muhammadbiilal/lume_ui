/// How a zone is shown — presentation only, never its identity.
///
/// A zone is stored and compared by its canonical IANA identifier. What a
/// reader sees is CLDR's localized location label for it: the country's name
/// where the zone is the country's only or primary one ("Pakistan",
/// "باكستان"), else the zone's exemplar city ("New York", "نیو یارک"),
/// shown in CLDR's generic location pattern ("Pakistan Time", "پاکستان
/// وقت", "توقيت باكستان") so it reads as a time zone beside the reader's
/// country rather than a second "Pakistan". The text and the pattern are
/// CLDR's own (`lume_zone_labels_data.dart`), never a translation made
/// here, and where CLDR has none the identifier itself shows.
///
/// **The reader's country decides the name, not the rules.** Kuwait's clock
/// is kept under Riyadh's identifier (`Asia/Kuwait` is a link to it), so a
/// Kuwait reader's zone is `Asia/Riyadh` — and is shown as "Kuwait", from
/// the identifier CLDR lists for Kuwait. The link is a label, never a second
/// identity: selecting, storing and comparing all use the canonical one.
library;

import 'package:flutter/foundation.dart';

import 'lume_country_zones.dart';
import 'lume_zone_aliases.dart';
import 'lume_zone_labels_data.dart';

/// One zone as a reader sees it.
@immutable
class LumeZoneLabel {
  const LumeZoneLabel._(this.id, this.text, this._format);

  /// The canonical identifier — the identity.
  final String id;

  /// CLDR's localized location — the country or the exemplar city — or
  /// `null` where it has none.
  final String? text;

  /// The language's generic location pattern, `{0} Time`.
  final String _format;

  /// What a screen shows: "Pakistan Time", else the identifier.
  String get display => text == null ? id : _format.replaceAll('{0}', text!);

  /// What a screen reader says: the label and, where there is one, the
  /// identifier it stands for.
  String get semantics => text == null ? id : '$display, $id';

  @override
  bool operator ==(Object other) =>
      other is LumeZoneLabel &&
      other.id == id &&
      other.text == text &&
      other._format == _format;

  @override
  int get hashCode => Object.hash(id, text, _format);

  @override
  String toString() => 'LumeZoneLabel($id, $text)';
}

abstract final class LumeZoneLabels {
  /// The label of [id] (canonical, or a link — it is shown as the zone it
  /// names) for a reader in [country], in [language].
  ///
  /// In order: the identifier CLDR lists for [country] under this zone
  /// (Kuwait's for a Kuwait reader); else [requested], a link the reader
  /// stored for this zone; else the zone's own. A country listing several
  /// identifiers for one zone with different labels gets none — the
  /// identifier shows rather than one of them chosen.
  static LumeZoneLabel of(
    String id, {
    required String language,
    String country = '',
    String? requested,
  }) {
    final String canonical = _canonical(id);
    final String lang = kLumeZoneLabelText.containsKey(language)
        ? language
        : 'en';
    final Map<String, String> text = kLumeZoneLabelText[lang]!;
    final String format = kLumeZoneLabelFormat[lang]!;
    final List<String> listed = <String>[
      for (final String z in kLumeCountryZoneIds[country] ?? const <String>[])
        if (_canonical(z) == canonical) z,
    ];
    if (listed.isNotEmpty) {
      final Set<String?> names = <String?>{
        for (final String z in listed) text[z],
      };
      return LumeZoneLabel._(
        canonical,
        names.length == 1 ? names.single : null,
        format,
      );
    }
    if (requested != null && _canonical(requested) == canonical) {
      final String? own = text[requested];
      if (own != null) return LumeZoneLabel._(canonical, own, format);
    }
    return LumeZoneLabel._(canonical, text[canonical], format);
  }

  /// Whether [query] finds [label]: its label or its identifier, ignoring
  /// case, isolation marks, and `_` for a space. An empty query finds all.
  static bool matches(String query, LumeZoneLabel label) {
    final String q = _fold(query);
    if (q.isEmpty) return true;
    return _fold(label.id).contains(q) || _fold(label.display).contains(q);
  }

  static String _canonical(String id) =>
      kLumeCanonicalZones.contains(id) ? id : (kLumeZoneAliases[id] ?? id);

  static final RegExp _marks = RegExp('[\u2066-\u2069\u200e\u200f]');

  static String _fold(String s) =>
      s.replaceAll(_marks, '').replaceAll('_', ' ').trim().toLowerCase();
}
