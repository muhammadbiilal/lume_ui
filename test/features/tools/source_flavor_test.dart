/// What a source bar says about itself, per build flavor.
///
/// Two claims were wrong when wave 3 closed, and both were wrong in the same
/// way — one word chosen once for a tool that has two faces.
///
/// **Focus Timer** draws the reference's invented history (75 minutes, a
/// five-day streak, three sessions, a seven-bar week) *only* where the build
/// reproduces the reference. Development and release draw the reader's own
/// session and nothing else, and still said "Sample data" over it — a
/// statement about the reader's screen that was not true of that screen. The
/// disclosure now lives where the sample data lives:
/// [LumeDataCapability.sampleInParityOnly].
///
/// **World Clock** said "Live". Its clock is running, but "Live" beside a
/// named source reads as a feed, and nothing here is fetched: the zone rules
/// are compiled into the binary and named by their version. A tool that is
/// both `isLive` and `computedHere` now says which kind of live it is.
///
/// Each is asserted three ways — the capability, the resolved claim in every
/// language, and the screen the router actually builds — because any of those
/// could drift from the others without a word.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';
import 'package:lume/features/tools/presentation/source_claims.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../focus/focus_harness.dart';
import '../worldclock/worldclock_screen_harness.dart';

/// The three languages Lume ships, so a correction cannot be an English
/// string bolted onto two fallbacks.
const List<String> kLanguages = <String>['en', 'ur', 'ar'];

/// The two builds a reader can actually be running.
const List<LumeBuildProfile> kShipping = <LumeBuildProfile>[
  LumeBuildProfile.development,
  LumeBuildProfile.release,
];

LumeFeature _feature(String id) =>
    kLumeFeatures.firstWhere((LumeFeature f) => f.id == id);

/// The claim a build of [profile] resolves for [id], in [language].
Future<LumeSourceClaim> _claim(
  String id,
  LumeBuildProfile profile, {
  String language = 'en',
}) async {
  final AppLocalizations l = await AppLocalizations.delegate.load(
    Locale(language),
  );
  return LumeSourceClaims.resolve(
    l: l,
    f: LumeFormatting(locale: Locale(language)),
    feature: _feature(id),
    capability: LumeDataCapability.fixture(
      id,
      reproducesReference: profile.reproducesReference,
    ),
    profile: profile,
    now: kFixtureInstant,
    city: 'Islamabad',
  );
}

/// Everything the source bar draws, as one string a reader could read.
String _sourceLine(WidgetTester tester) {
  final LumeSourceLine line = tester.widget<LumeSourceLine>(
    find.byType(LumeSourceLine).first,
  );
  return <String?>[
    line.sample,
    line.source,
    line.updated,
    line.note,
  ].whereType<String>().join(' · ');
}

void main() {
  group('Focus Timer discloses sample data where the sample data is', () {
    test('the capability says so only for a build that reproduces it', () {
      expect(
        LumeDataCapability.fixture('focus', reproducesReference: true).isSample,
        isTrue,
        reason: "the parity build draws the reference's invented history",
      );
      for (final LumeBuildProfile build in kShipping) {
        expect(
          LumeDataCapability.fixture(
            'focus',
            reproducesReference: build.reproducesReference,
          ).isSample,
          isFalse,
          reason: "${build.name} draws only the reader's own session",
        );
      }
      expect(
        LumeDataCapability.inputOnly,
        contains('focus'),
        reason: "the lengths chosen and the stretches run are the reader's",
      );
      expect(LumeDataCapability.onDeviceClocks, contains('focus'));
    });

    test('no other tool changed meaning with the build', () {
      for (final LumeFeature feature in kLumeFeatures) {
        if (LumeDataCapability.sampleInParityOnly.contains(feature.id)) {
          continue;
        }
        expect(
          LumeDataCapability.fixture(
            feature.id,
            reproducesReference: true,
          ).isSample,
          LumeDataCapability.fixture(feature.id).isSample,
          reason:
              '${feature.id}: a claim that moves with the build type is the '
              'defect this correction exists to remove',
        );
      }
    });

    test('parity keeps the mark, in every language', () async {
      for (final String language in kLanguages) {
        final AppLocalizations l = await AppLocalizations.delegate.load(
          Locale(language),
        );
        final LumeSourceClaim c = await _claim(
          'focus',
          LumeBuildProfile.parity,
          language: language,
        );
        expect(c.sample, l.freshSample, reason: language);
        expect(c.discloses(l), isTrue, reason: language);
      }
    });

    test('development and release say what it really is', () async {
      for (final LumeBuildProfile build in kShipping) {
        for (final String language in kLanguages) {
          final AppLocalizations l = await AppLocalizations.delegate.load(
            Locale(language),
          );
          final LumeSourceClaim c = await _claim(
            'focus',
            build,
            language: language,
          );
          expect(c.sample, isNull, reason: '${build.name}/$language');
          expect(c.discloses(l), isFalse, reason: '${build.name}/$language');
          // A clock running on the device, and the device is the source.
          expect(c.label, l.freshLive, reason: '${build.name}/$language');
          expect(
            c.source,
            l.toolSourceOnDevice,
            reason: '${build.name}/$language',
          );
          expect(c.quality, LumeFreshnessQuality.live);
        }
      }
    });

    testWidgets('and the screen the router builds agrees', (
      WidgetTester tester,
    ) async {
      for (final LumeBuildProfile build in kShipping) {
        await pumpFocus(tester, FocusWorld(), profile: build);
        expect(
          find.byKey(LumeSourceLine.sampleKey),
          findsNothing,
          reason: '${build.name}: nothing on this screen is a sample',
        );
        expect(_sourceLine(tester), 'On device', reason: build.name);
      }
      await pumpFocus(tester, FocusWorld(), profile: LumeBuildProfile.parity);
      expect(find.byKey(LumeSourceLine.sampleKey), findsOneWidget);
      // The parity line also carries the reference's own "Updated …", which
      // is reference copy and not this build's claim.
      expect(_sourceLine(tester), startsWith('Sample data · On device'));
    });
  });

  group('World Clock says which kind of live it is', () {
    test('a live figure worked out here is calculated live', () async {
      for (final LumeBuildProfile build in kShipping) {
        for (final String language in kLanguages) {
          final AppLocalizations l = await AppLocalizations.delegate.load(
            Locale(language),
          );
          final LumeSourceClaim c = await _claim(
            'worldclock',
            build,
            language: language,
          );
          expect(
            c.label,
            l.freshComputedLive,
            reason: '${build.name}/$language',
          );
          expect(
            c.label,
            isNot(l.freshLive),
            reason: '${build.name}/$language',
          );
          expect(c.source, l.toolSourceIana);
          expect(c.sample, isNull);
          expect(c.discloses(l), isFalse);
          expect(c.updated, isNull, reason: 'nothing was ever fetched');
        }
      }
    });

    test(
      'the wording is translated, not one English label in three places',
      () async {
        final Set<String> labels = <String>{};
        for (final String language in kLanguages) {
          final LumeSourceClaim c = await _claim(
            'worldclock',
            LumeBuildProfile.release,
            language: language,
          );
          labels.add(c.label);
        }
        expect(labels, hasLength(3));
      },
    );

    test('a tool that is live but not computed still says Live', () async {
      final AppLocalizations l = await AppLocalizations.delegate.load(
        const Locale('en'),
      );
      for (final String id in <String>['stopwatch', 'focus']) {
        final LumeSourceClaim c = await _claim(id, LumeBuildProfile.release);
        expect(c.label, l.freshLive, reason: id);
      }
      // Timer is the other on-device clock and is deliberately *not* here:
      // its presets are fixture data, so it is sample-marked in every build
      // and never reaches the live branch at all. Naming it keeps that a
      // decision rather than an oversight.
      expect(LumeDataCapability.fixture('timer').isSample, isTrue);
      expect(
        (await _claim('timer', LumeBuildProfile.release)).label,
        l.freshSample,
      );
    });

    test('the capability classification is unchanged', () {
      expect(LumeDataCapability.computed, contains('worldclock'));
      final LumeDataCapability c = LumeDataCapability.fixture('worldclock');
      expect(c.computedHere, isTrue);
      expect(c.isLive, isTrue);
      expect(c.isSample, isFalse);
    });

    test("parity still reproduces the reference's own word", () async {
      final AppLocalizations l = await AppLocalizations.delegate.load(
        const Locale('en'),
      );
      final LumeSourceClaim c = await _claim(
        'worldclock',
        LumeBuildProfile.parity,
      );
      expect(
        c.label,
        l.freshLive,
        reason:
            'a parity capture is the reference, corrections included nowhere '
            '— the reference says "Live", so the capture must',
      );
      expect(
        c.labelSemantics,
        l.freshReferenceCopy(l.freshLive),
        reason: 'and a screen reader is told whose claim it is',
      );
    });

    testWidgets('and the screen the router builds agrees', (
      WidgetTester tester,
    ) async {
      for (final LumeBuildProfile build in kShipping) {
        await pumpWorldClock(
          tester,
          extra: <Override>[buildProfileProvider.overrideWithValue(build)],
        );
        expect(
          _sourceLine(tester),
          'IANA time zones',
          reason:
              '${build.name}: the source names a database, not a feed, '
              'and nothing was fetched, so nothing was "updated"',
        );
        expect(find.byKey(LumeSourceLine.sampleKey), findsNothing);
        expect(
          find.text('Calculated live'),
          findsOneWidget,
          reason: build.name,
        );
        expect(find.text('Live'), findsNothing, reason: build.name);
      }
    });
  });
}
