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
    isDurable: durable.contains(toolId),
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
    // Unit Converter: the amount typed, the two units chosen, and an exact
    // rational between them. There is no table behind it that a reader
    // could mistake for data — the factors are the values that define the
    // units (wave 4).
    'converter',
    // BMI Calculator (wave 8): the height/weight the reader typed, and a
    // real BMI/band calculation over it. The reference's five-point
    // "history" is invented offsets from the current reading, not a real
    // past record, and is not reproduced.
    'bmi',
    // Faraid (wave 10): the estate value and heir counts the reader
    // typed, and a real Islamic-inheritance-shares calculation over them
    // — no fixture, unlike Zakat's own nisab lookup.
    'faraid',
    // Document Scanner, Media Saver, Passport Photos (wave 10): every
    // figure is the bytes the reader's own camera/gallery/link action
    // produced this session — nothing sampled. Speed Test (wave 10): the
    // reference's own numbers were never real even once (`Math.random()`
    // output dressed as a measurement); this build shows none of them —
    // no figures, sample or real, at all.
    'docscan',
    'mediasaver',
    'passport',
    'speedtest',
    // Nearby Mosques (wave 10): no places directory exists, so it shows no
    // mosque, distance or facility — only the reader's own place and a
    // hand-off to their maps app. Nothing sampled, like Speed Test.
    'mosques',
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
  ///
  /// Birthdays and Water are here for the same reason, one step earlier:
  /// their seeds are the sample data, and only the parity build has them
  /// ([kLumeParityOnlySeeds]). A shipping build opens both empty, so there
  /// is nothing on either screen to disclose — and every figure above the
  /// list is arithmetic on the reader's own records or is not drawn at all
  /// (wave 4).
  static const Set<String> sampleInParityOnly = <String>{
    'focus',
    'birthdays',
    'water',
  };

  /// Tools whose every figure is worked out on the device for the reader's
  /// city — a calculation, not a fixture. Sun & Moon: the sun from the
  /// city's coordinates and the day, the moon from the instant.
  static const Set<String> computed = <String>{
    'sunmoon',
    // World Clock: every time is worked out from the compiled-in
    // IANA database and the device's own clock (D-W8, wave 3).
    'worldclock',
    // Qibla Compass (wave 8): a real great-circle bearing and distance to
    // the Kaaba from the reader's city coordinates — no live compass
    // sensor, no fixture. `fallbackSource: 'Great-circle bearing'` in the
    // catalogue already says as much.
    'qibla',
    // Prayer Times, Islamic Calendar, Ramadan (wave 10): real solar
    // (`LumeSolar.prayerTimes`, the same calculation Weather/Calendar
    // already use) and real Hijri-calendar arithmetic
    // (`lib/core/time/lume_hijri.dart`) worked out from the reader's
    // city/date — no fixture, no reader record.
    'prayer',
    'hijri',
    'ramadan',
  };

  /// Tools that show only what the reader wrote — nothing seeded, nothing
  /// fetched (Ledger D11, Installments §40.1, Committee §11, Baby Budget
  /// §11). Their storage claim is still the store's.
  static const Set<String> readerRecords = <String>{
    'ledger',
    'installments',
    'committee',
    'babybudget',
    // Birthdays and Water: seeded only in the parity reproduction, so in
    // the build a reader runs there is nothing on either screen that they
    // did not write ([sampleInParityOnly], wave 4).
    'birthdays',
    'water',
    // Goals and Subscriptions (wave 5): the reference's own seed data is
    // 100% hardcoded fixtures with no CRUD at all (GOALS_PROPOSAL.md §0,
    // SUBSCRIPTIONS_PROPOSAL.md §0) — nothing here is reproduced; a
    // reader's build opens both empty.
    'goals',
    'subs',
    // Meal Plan (wave 6): the reference's headline figures are bare
    // literals with no computation behind them (MEALPLAN_PROPOSAL.md
    // §0) — nothing here is reproduced; a reader's build opens empty.
    'mealplan',
    // Reminders (wave 7): the one family whose store actually outlives the
    // app closing — a second, scoped LumeRecordRepository implementation,
    // not a project-wide change (ROLLOUT_WAVE_7.md, REMINDERS_PROPOSAL.md
    // §2). Also in [durable], which every other entry here is not.
    'reminders',
    // Wave 8 — ten tools built in parallel without a per-tool discovery
    // gate. Each of these six is the reader's own entered records, with
    // every derived figure (a streak, a due count, a predicted date, a
    // week number) computed for real over them rather than reproduced from
    // the reference's own bare literals or invented fixtures:
    'streak',
    'habits',
    'meds',
    'vaccines',
    'health',
    'cycle',
    'pregnancy',
    // Wave 10 — three more, resolved the same way: Prayer Tracker,
    // Fasting Tracker and Taraweeh each replace a reference whose own
    // headline figures were bare literals (or, for Prayer Tracker,
    // subtly wrong — it counted prayers whose clock time had passed, not
    // prayers actually prayed) with a real per-day reader check-in and
    // every derived figure (a streak, a rate, a qada count) computed for
    // real over it.
    'praytrack',
    'fasting',
    'taraweeh',
  };

  /// The one family (so far) whose store survives the app closing —
  /// [LumeSqliteRecordRepository], scoped to Reminders alone. Every other
  /// entry in [readerRecords] keeps [isDurable] at its default, `false`.
  static const Set<String> durable = <String>{'reminders'};

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
