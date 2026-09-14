/// What a tool's source bar may say (F6B decision 5).
///
/// **The reference build** draws what the reference draws — every freshness
/// word, "Updated 30 sec ago" and "Encrypted on device" included — because it
/// is a reproduction, and About says its data is sample data.
///
/// **A release build** draws a claim only when the tool's
/// [LumeDataCapability] supports it:
///
/// | claim | needs |
/// |---|---|
/// | "Stored on this device" | `isDurable` — otherwise "Kept until you close Lume" |
/// | "Encrypted on device" | `isEncrypted` — otherwise "On device" |
/// | "Live" | `isLive` |
/// | any "Updated …" | `observedAt`, and it is worked out from it |
/// | "Delayed 15 min" | `isLive` and `observedAt` |
/// | "Calculated for your location" | `computedHere` |
/// | a feed's name as the source | the capability's own `source` replaces it |
///
/// Anything a release cannot support reads "Sample data", which is what it is.
library;

import 'package:flutter/foundation.dart';

import '../../../core/config/lume_build_profile.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../domain/tool_capability.dart';
import 'tool_strings.dart';

@immutable
class LumeSourceClaim {
  const LumeSourceClaim({
    required this.quality,
    required this.label,
    required this.source,
    this.updated,
  });

  final LumeFreshnessQuality quality;
  final String label;
  final String source;
  final String? updated;
}

abstract final class LumeSourceClaims {
  /// Sources that name a way of working a figure out, not a feed. True in any
  /// build, so a release keeps them.
  static const Set<String> staticSources = <String>{
    'On device',
    'Statutory slabs',
    'Great-circle bearing',
    'Astronomical calculation',
    'Places directory',
    'Hijri calendar + solar times',
    'Qur’an text',
    'Hadith collections',
    'Dua collection',
    'Asma ul Husna',
    'Umm al-Qura calculation',
    'Classical faraid rules',
    'National Savings schedule',
    'Operator tariffs',
  };

  static const String encryptedSource = 'Encrypted on device';

  static LumeSourceClaim resolve({
    required AppLocalizations l,
    required LumeFormatting f,
    required LumeFeature feature,
    required LumeDataCapability capability,
    required LumeBuildProfile profile,
    required DateTime now,
    required String city,
  }) {
    final LumeFreshnessKind kind = feature.freshness;
    if (profile == LumeBuildProfile.reference) {
      return LumeSourceClaim(
        quality: LumeToolStrings.quality(kind),
        label: LumeToolStrings.freshness(l, kind),
        source: LumeToolStrings.source(l, feature),
        updated: LumeToolStrings.updated(l, f, kind, now: now, city: city),
      );
    }

    final DateTime? seen = capability.observedAt;
    final LumeSourceClaim sample = LumeSourceClaim(
      quality: LumeFreshnessQuality.cached,
      label: l.freshSample,
      source: _source(l, feature, capability),
    );
    String? ago() {
      if (seen == null) return null;
      final Duration d = now.difference(seen);
      return d.inMinutes < 1
          ? l.freshAgoSec(d.inSeconds < 0 ? 0 : d.inSeconds)
          : l.freshAgoMin(d.inMinutes);
    }

    return switch (kind) {
      LumeFreshnessKind.local => LumeSourceClaim(
        quality: capability.isDurable
            ? LumeFreshnessQuality.local
            : LumeFreshnessQuality.computed,
        label: capability.isDurable ? l.freshLocal : l.freshSession,
        source: _source(l, feature, capability),
      ),
      LumeFreshnessKind.live =>
        capability.isLive
            ? LumeSourceClaim(
                quality: LumeFreshnessQuality.live,
                label: l.freshLive,
                source: _source(l, feature, capability),
                updated: ago(),
              )
            : sample,
      LumeFreshnessKind.delayed =>
        capability.isLive && seen != null
            ? LumeSourceClaim(
                quality: LumeFreshnessQuality.delayed,
                label: l.freshDelayed,
                source: _source(l, feature, capability),
                updated: ago(),
              )
            : sample,
      LumeFreshnessKind.daily ||
      LumeFreshnessKind.weekly ||
      LumeFreshnessKind.draw ||
      LumeFreshnessKind.cached =>
        seen != null
            ? LumeSourceClaim(
                quality: LumeFreshnessQuality.cached,
                label: LumeToolStrings.freshness(l, kind),
                source: _source(l, feature, capability),
                updated: l.freshOn(f.dateShort(seen)),
              )
            : sample,
      // "Current tax year" describes a schedule, not a moment; the date it was
      // "updated" is shown only when it was observed.
      LumeFreshnessKind.annual => LumeSourceClaim(
        quality: LumeFreshnessQuality.cached,
        label: l.freshAnnual,
        source: _source(l, feature, capability),
        updated: seen == null ? null : l.freshOn(f.dateShort(seen)),
      ),
      LumeFreshnessKind.computed =>
        capability.computedHere
            ? LumeSourceClaim(
                quality: LumeFreshnessQuality.computed,
                label: l.freshComputed,
                source: _source(l, feature, capability),
                updated: l.freshForCity(city),
              )
            : sample,
      LumeFreshnessKind.reference => LumeSourceClaim(
        quality: LumeFreshnessQuality.cached,
        label: l.freshStatic,
        source: _source(l, feature, capability),
      ),
    };
  }

  static String _source(
    AppLocalizations l,
    LumeFeature feature,
    LumeDataCapability capability,
  ) {
    final String declared = feature.fallbackSource;
    if (declared == encryptedSource) {
      return capability.isEncrypted
          ? LumeToolStrings.source(l, feature)
          : l.toolSourceOnDevice;
    }
    if (staticSources.contains(declared)) {
      return LumeToolStrings.source(l, feature);
    }
    return capability.source == LumeDataCapability.sampleSource
        ? l.freshSample
        : capability.source;
  }
}
