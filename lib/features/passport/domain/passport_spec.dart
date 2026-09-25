/// What one passport-style photo must measure — `passportSpecs()` in
/// `tools/context.js`, and the static size table `passport.tool.js` draws
/// beside it.
///
/// The reference asks exactly one question of the reader's country: is it
/// the United States? If so the photo is 2 × 2 in with a 1 – 1⅜ in head
/// height; every other country it has ever shipped a profile for gets the
/// same 35 × 45 mm figure, 32 – 36 mm head height. That binary rule is
/// ported verbatim here (`forCountry`) — not expanded, because a bigger
/// table would be this build's own invention, not the reference's. It is
/// also not universal: several real national authorities differ from the
/// reference's "everyone else" default (Canada's own passport photo is
/// 50 × 70 mm, for one), which the tool's own doc comment discloses rather
/// than silently overstating what this table actually covers.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumePassportSpec {
  const LumePassportSpec({
    required this.id,
    required this.widthMm,
    required this.heightMm,
    required this.dpi,
    required this.sizeLabel,
    required this.headHeightLabel,
  });

  /// `35 × 45 mm` (US visa's own 2 × 2 in aside) — the reference's own
  /// document, for [LumePassportProcessor] and the reference's DPI table.
  static const LumePassportSpec us = LumePassportSpec(
    id: 'us',
    widthMm: 50.8, // 2 in
    heightMm: 50.8, // 2 in
    dpi: 600,
    sizeLabel: '2 × 2 in',
    headHeightLabel: '1 – 1⅜ in',
  );

  static const LumePassportSpec intl = LumePassportSpec(
    id: 'intl',
    widthMm: 35,
    heightMm: 45,
    dpi: 600,
    sizeLabel: '35 × 45 mm',
    headHeightLabel: '32 – 36 mm',
  );

  /// `P().country === 'US' ? … : …` (`passportSpecs()`), unchanged.
  static LumePassportSpec forCountry(String country) =>
      country.toUpperCase() == 'US' ? us : intl;

  final String id;
  final double widthMm;
  final double heightMm;
  final int dpi;

  /// The reference's own spelling — `2 × 2 in` or `35 × 45 mm` — never a
  /// figure converted into the other system.
  final String sizeLabel;
  final String headHeightLabel;

  static const double _mmPerInch = 25.4;

  /// The pixel canvas [LumePassportProcessor] actually crops and resizes
  /// onto, so an exported file genuinely measures [widthMm] × [heightMm] at
  /// [dpi] rather than merely being labelled that. 35 × 45 mm at 600 dpi
  /// rounds to 827 × 1063 px, the figure quoted across print labs and photo
  /// tools for that document size; 2 × 2 in at 600 dpi is exactly 1200 ×
  /// 1200 px.
  int get widthPx => (widthMm / _mmPerInch * dpi).round();
  int get heightPx => (heightMm / _mmPerInch * dpi).round();

  @override
  bool operator ==(Object other) => other is LumePassportSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
