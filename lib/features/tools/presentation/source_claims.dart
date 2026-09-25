/// What a tool's source bar may say (F6B decision 5), by build flavor
/// ([LumeBuildProfile]).
///
/// **A parity build** draws what the reference draws — every freshness word,
/// "Stored on this device", "Updated 30 sec ago" and "Encrypted on device"
/// included — because it is a controlled reproduction for visual comparison.
/// A screen reader hears each reproduced claim as reference copy
/// (`freshReferenceCopy`), and a parity build never ships
/// ([lumeRefuseUnshippable]). A tool whose capability is
/// [LumeDataCapability.isSample] also leads its source line with "Sample
/// data", so the reader learns it where the figures are, not only in About.
///
/// **A development or a release build** derives every claim from capability
/// metadata, never from the build type. Over sample data it says "Sample
/// data" as the freshness itself and claims nothing else: no storage,
/// encryption, liveness, update or feed. Otherwise it draws a claim only
/// when the tool's capability supports it:
///
/// | claim | needs |
/// |---|---|
/// | "Stored on this device" | `isDurable` — otherwise "Kept until you close Lume" |
/// | "Encrypted on device" | `isEncrypted` — otherwise "On device" |
/// | "Live" | `isLive` |
/// | "Calculated live" | `isLive` **and** `computedHere` — the figure moves, but it is worked out here from data compiled in, not fetched |
/// | any "Updated …" | `observedAt`, and it is worked out from it |
/// | "Delayed 15 min" | `isLive` and `observedAt` |
/// | "Calculated for your location" | `computedHere` |
/// | a feed's name as the source | the capability's own `source` replaces it |
///
/// Anything such a build cannot support reads "Sample data", which is what it
/// is.
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
    this.sample,
    this.labelSemantics,
  });

  final LumeFreshnessQuality quality;
  final String label;

  /// What a screen reader hears for [label], where it differs: a parity
  /// build's reproduced claim is announced as reference copy.
  final String? labelSemantics;
  final String? source;
  final String? updated;

  /// The parity build’s sample-data mark, drawn first in the source line.
  final String? sample;

  /// This claim tells the reader the tool shows sample data.
  bool discloses(AppLocalizations l) =>
      sample == l.freshSample || label == l.freshSample;
}

abstract final class LumeSourceClaims {
  /// Sources that name a way of working a figure out, not a feed. True in any
  /// build, so a release keeps them.
  static const Set<String> staticSources = <String>{
    'On device',
    'Statutory slabs',
    'Great-circle bearing',
    'Astronomical calculation',
    // Compiled into the binary and named by its version, exactly as the
    // astronomical tables are. Without it here a tool worked out from a
    // static database is called sample data (wave 3).
    'IANA time zones',
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
    // Wave 10.
    'Tabular Islamic calendar',
    'ICAO + national specs',
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
    if (profile.reproducesReference) {
      final String label = LumeToolStrings.freshness(l, kind);
      return LumeSourceClaim(
        quality: LumeToolStrings.quality(kind),
        label: label,
        // Heard as what it is: the reference's words, not this build's.
        labelSemantics: l.freshReferenceCopy(label),
        source: LumeToolStrings.source(l, feature),
        updated: LumeToolStrings.updated(l, f, kind, now: now, city: city),
        sample: capability.isSample ? l.freshSample : null,
      );
    }

    // Sample data in a release says so, and claims nothing it cannot keep.
    if (capability.isSample) {
      return LumeSourceClaim(
        quality: LumeFreshnessQuality.cached,
        label: l.freshSample,
        source: _method(l, feature),
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
      // "Live" over a figure worked out here would read as a feed. World
      // Clock's clock is running — the row ticks on the minute — but the
      // zone rules behind it are compiled into the binary and named by
      // their version, and nothing is fetched. So a tool that is both live
      // and computed says which kind of live it is.
      LumeFreshnessKind.live =>
        capability.isLive
            ? LumeSourceClaim(
                quality: LumeFreshnessQuality.live,
                label: capability.computedHere
                    ? l.freshComputedLive
                    : l.freshLive,
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
      // "updated" is shown only when it was observed. Tax's own wording is
      // Tax-specific reference copy — a tool other than Tax with annual
      // freshness (Public Holidays, wave 9) gets the generic label instead.
      LumeFreshnessKind.annual => LumeSourceClaim(
        quality: LumeFreshnessQuality.cached,
        label: feature.id == 'tax' ? l.freshAnnual : l.freshAnnualGeneric,
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

  /// A source that names a way of working figures out — as true of sample
  /// data as of any — or nothing.
  static String? _method(AppLocalizations l, LumeFeature feature) {
    final String declared = feature.fallbackSource;
    if (declared == encryptedSource) return l.toolSourceOnDevice;
    return staticSources.contains(declared)
        ? LumeToolStrings.source(l, feature)
        : null;
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
