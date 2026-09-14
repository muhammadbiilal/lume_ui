/// What a tool's data can truthfully be said to be (F6B decision 5).
///
/// A claim on screen — "Stored on this device", "Encrypted on device",
/// "Live", "Updated 30 sec ago" — is only as true as the adapter behind it.
/// [LumeDataCapability] is that adapter's statement about itself, and the
/// tool frame draws claims from it (`LumeSourceClaims`); no widget works one
/// out for itself. `RELEASE_HONESTY.md` is the matrix.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class LumeDataCapability {
  const LumeDataCapability({
    required this.source,
    this.isDurable = false,
    this.isEncrypted = false,
    this.isLive = false,
    this.computedHere = false,
    this.observedAt,
  });

  /// This build's capability for [toolId]: fixtures and the session, and
  /// nothing more. The only live thing is a clock running on the device.
  factory LumeDataCapability.fixture(String toolId) => LumeDataCapability(
    source: sampleSource,
    isLive: onDeviceClocks.contains(toolId),
  );

  /// A write survives the app being closed.
  final bool isDurable;

  /// What is stored is encrypted at rest.
  final bool isEncrypted;

  /// The figures move with a source that is running now — a feed, or a clock
  /// on the device.
  final bool isLive;

  /// The figures are worked out here, for the reader's place, from a real
  /// calculation rather than read from a fixture.
  final bool computedHere;

  /// When the source was last observed, if it ever was.
  final DateTime? observedAt;

  /// Who or what the figures come from, as the adapter names itself.
  final String source;

  /// The name this build's fixtures give themselves.
  static const String sampleSource = 'Lume sample data';

  /// Tools whose "live" is a clock ticking on the device.
  static const Set<String> onDeviceClocks = <String>{
    'stopwatch',
    'timer',
    'focus',
    'worldclock',
  };
}

/// Each tool's capability. Dayroz overrides this with its adapters'.
final ProviderFamily<LumeDataCapability, String> dataCapabilityProvider =
    Provider.family<LumeDataCapability, String>(
      (Ref ref, String toolId) => LumeDataCapability.fixture(toolId),
    );
