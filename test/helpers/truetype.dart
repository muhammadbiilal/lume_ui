/// Just enough TrueType to check that a bundled font is the font it claims.
///
/// A filename is a claim; `OS/2.usWeightClass` is a fact, and it is what
/// Flutter matches a requested weight against. Reading the tables means a file
/// swapped for the wrong cut fails a test rather than turning up in a
/// screenshot three phases later.
///
/// Only four tables are read — `name`, `OS/2`, `head` and `fvar` — because
/// those carry everything the type system depends on.
library;

import 'dart:io';
import 'dart:typed_data';

/// What a font binary says about itself.
class FontFacts {
  const FontFacts({
    required this.family,
    required this.subfamily,
    required this.typographicFamily,
    required this.typographicSubfamily,
    required this.fullName,
    required this.copyright,
    required this.licenceUrl,
    required this.weightClass,
    required this.isItalic,
    required this.unitsPerEm,
    required this.isVariable,
    required this.weightAxis,
  });

  /// `name` ID 1 — the family a legacy consumer sees.
  final String family;

  /// `name` ID 2.
  final String subfamily;

  /// `name` ID 16 — the typographic family, present on static instances that
  /// Google Fonts splits for compatibility.
  final String? typographicFamily;

  /// `name` ID 17.
  final String? typographicSubfamily;

  /// `name` ID 4.
  final String fullName;

  /// `name` ID 0.
  final String copyright;

  /// `name` ID 14.
  final String? licenceUrl;

  /// `OS/2.usWeightClass` — the number Flutter matches against.
  final int weightClass;

  final bool isItalic;
  final int unitsPerEm;

  /// Whether an `fvar` table is present.
  final bool isVariable;

  /// The `wght` axis range, when variable.
  final ({double min, double defaultValue, double max})? weightAxis;

  /// The family name every consumer should see, preferring the typographic
  /// one when the binary carries a split name.
  String get effectiveFamily => typographicFamily ?? family;

  static FontFacts read(String path) {
    final Uint8List bytes = File(path).readAsBytesSync();
    final ByteData d = ByteData.sublistView(bytes);

    final int numTables = d.getUint16(4);
    final Map<String, int> offsets = <String, int>{};
    for (int i = 0; i < numTables; i++) {
      final int o = 12 + i * 16;
      final String tag = String.fromCharCodes(bytes.sublist(o, o + 4));
      offsets[tag] = d.getUint32(o + 8);
    }

    // ---- name
    final Map<int, String> names = <int, String>{};
    final int? nameOff = offsets['name'];
    if (nameOff != null) {
      final int count = d.getUint16(nameOff + 2);
      final int stringOff = nameOff + d.getUint16(nameOff + 4);
      for (int i = 0; i < count; i++) {
        final int r = nameOff + 6 + i * 12;
        final int platform = d.getUint16(r);
        final int nameId = d.getUint16(r + 6);
        final int len = d.getUint16(r + 8);
        final int off = d.getUint16(r + 10);
        if (names.containsKey(nameId)) continue;
        if (platform == 3) {
          // Windows: big-endian UTF-16.
          final StringBuffer b = StringBuffer();
          for (int k = 0; k + 1 < len; k += 2) {
            b.writeCharCode(d.getUint16(stringOff + off + k));
          }
          names[nameId] = b.toString();
        } else {
          names[nameId] = String.fromCharCodes(
            bytes.sublist(stringOff + off, stringOff + off + len),
          );
        }
      }
    }

    // ---- OS/2
    final int os2 = offsets['OS/2']!;
    final int weightClass = d.getUint16(os2 + 4);
    final bool italic = (d.getUint16(os2 + 62) & 1) != 0;

    // ---- head
    final int head = offsets['head']!;
    final int unitsPerEm = d.getUint16(head + 18);

    // ---- fvar
    ({double defaultValue, double max, double min})? axis;
    final int? fvar = offsets['fvar'];
    if (fvar != null) {
      final int axisOff = fvar + d.getUint16(fvar + 4);
      final int axisCount = d.getUint16(fvar + 8);
      final int axisSize = d.getUint16(fvar + 10);
      for (int i = 0; i < axisCount; i++) {
        final int a = axisOff + i * axisSize;
        final String tag = String.fromCharCodes(bytes.sublist(a, a + 4));
        if (tag != 'wght') continue;
        axis = (
          min: d.getInt32(a + 4) / 65536.0,
          defaultValue: d.getInt32(a + 8) / 65536.0,
          max: d.getInt32(a + 12) / 65536.0,
        );
      }
    }

    return FontFacts(
      family: names[1] ?? '',
      subfamily: names[2] ?? '',
      typographicFamily: names[16],
      typographicSubfamily: names[17],
      fullName: names[4] ?? '',
      copyright: names[0] ?? '',
      licenceUrl: names[14],
      weightClass: weightClass,
      isItalic: italic,
      unitsPerEm: unitsPerEm,
      isVariable: fvar != null,
      weightAxis: axis,
    );
  }
}
