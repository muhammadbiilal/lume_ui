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

import '../../../core/config/lume_build_profile.dart';

@immutable
class LumeDataCapability {
  const LumeDataCapability({
    required this.source,
    this.isDurable = false,
    this.isEncrypted = false,
    this.isLive = false,
    this.computedHere = false,
    this.isSample = false,
    this.observedAt,
  });

  /// This build's capability for [toolId]: fixtures and the session, and
  /// nothing more. The only live thing is a clock running on the device.
  ///
  /// [reproducesReference] is the build's own answer to
  /// `LumeBuildProfile.reproducesReference`. It matters for exactly one
  /// thing: a tool in [sampleInParityOnly] draws invented figures only in
  /// the parity reproduction, so only there does it have sample data to
  /// disclose. Every other tool's classification is the same in every
  /// build, which is the point of deriving claims from capability rather
  /// than from the build type.
  factory LumeDataCapability.fixture(
    String toolId, {
    bool reproducesReference = false,
  }) => LumeDataCapability(
    source: sampleSource,
    isLive: onDeviceClocks.contains(toolId),
    computedHere: computed.contains(toolId),
    isSample:
        (reproducesReference && sampleInParityOnly.contains(toolId)) ||
        (!inputOnly.contains(toolId) &&
            !computed.contains(toolId) &&
            !readerRecords.contains(toolId)),
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

  /// What the tool shows includes sample data — records, feeds, schedules or
  /// history that no adapter supplied. A tool that does must say so where its
  /// figures are, in its own source bar; About alone does not count.
  final bool isSample;

  /// When the source was last observed, if it ever was.
  final DateTime? observedAt;

  /// Who or what the figures come from, as the adapter names itself.
  final String source;

  /// The name this build's fixtures give themselves.
  static const String sampleSource = 'Lume sample data';

  /// Tools whose every figure comes from the fields on the screen — prefilled
  /// with the reference's example values, visible and editable — or from a
  /// clock on the device. No fixture stands behind them. Date Calculator is
  /// not one: its holiday count is fixture data.
  static const Set<String> inputOnly = <String>{
    'age',
    'tipsplit',
    'loan',
    'compound',
    'stopwatch',
    // Calculator: every figure is what the reader pressed, worked out
    // exactly. Its history holds only sums they finished (wave 3).
    'calculator',
    // Tasbih: the count, the round and the rounds are the reader's own
    // taps. Its five phrases are reference content, not a fixture
    // standing in for anything of theirs (wave 3).
    'tasbih',
    // Focus Timer: the lengths the reader chose and the stretches they
    // actually ran, counted from a boot clock. True of every build that
    // ships; the parity reproduction is the exception, and it is named in
    // [sampleInParityOnly] rather than left to change what this set means.
    'focus',
  };

  /// Tools that have sample data **only** where the build reproduces the
  /// reference.
  ///
  /// Focus Timer's reference prints "75 Minutes today", a five-day streak,
  /// three sessions and a seven-bar week from constants in `context.js`.
  /// The parity build draws them, so the parity build says "Sample data"
  /// over them. Development and release draw the reader's own session and
  /// nothing else, so there is no sample data there to disclose, and
  /// saying otherwise was a claim about the reader's screen that was not
  /// true of it.
  static const Set<String> sampleInParityOnly = <String>{'focus'};

  /// Tools whose every figure is worked out on the device for the reader's
  /// city — a calculation, not a fixture. Sun & Moon: the sun from the
  /// city's coordinates and the day, the moon from the instant.
  static const Set<String> computed = <String>{
    'sunmoon',
    // World Clock: every time is worked out from the compiled-in
    // IANA database and the device's own clock (D-W8, wave 3).
    'worldclock',
  };

  /// Tools that show only what the reader wrote — nothing seeded, nothing
  /// fetched (Ledger D11, Installments §40.1, Committee §11, Baby Budget
  /// §11). Their storage claim is still the store's.
  static const Set<String> readerRecords = <String>{
    'ledger',
    'installments',
    'committee',
    'babybudget',
  };

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
      (Ref ref, String toolId) => LumeDataCapability.fixture(
        toolId,
        reproducesReference: ref
            .watch(buildProfileProvider)
            .reproducesReference,
      ),
    );
