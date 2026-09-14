/// The release-honesty gate (F6B decision 5, `RELEASE_HONESTY.md`).
///
/// Every catalogue tool's source bar is resolved as a release build would
/// resolve it over this build's capabilities, and nothing may claim storage,
/// encryption, liveness or an update that no capability supports. The
/// reference build is held to drawing exactly what the reference draws, so
/// the goldens stay as they are.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';
import 'package:lume/features/tools/presentation/source_claims.dart';
import 'package:lume/features/tools/presentation/tool_strings.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../helpers/lume_harness.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 7, 16, 41);

  Future<(AppLocalizations, LumeFormatting)> strings(
    WidgetTester tester,
  ) async {
    late AppLocalizations l;
    late LumeFormatting f;
    await pumpLume(
      tester,
      LumeProbe(
        onBuild: (BuildContext c) {
          l = AppLocalizations.of(c);
          f = LumeFormatting.of(c, countryCode: 'PK');
        },
      ),
    );
    return (l, f);
  }

  LumeSourceClaim claim(
    AppLocalizations l,
    LumeFormatting f,
    LumeFeature feature,
    LumeBuildProfile profile, {
    LumeDataCapability? capability,
  }) => LumeSourceClaims.resolve(
    l: l,
    f: f,
    feature: feature,
    capability: capability ?? LumeDataCapability.fixture(feature.id),
    profile: profile,
    now: now,
    city: 'Islamabad',
  );

  test('the build is the reference build unless it is told otherwise', () {
    expect(lumeBuildProfileFrom(''), LumeBuildProfile.reference);
    expect(lumeBuildProfileFrom('debug'), LumeBuildProfile.reference);
    expect(lumeBuildProfileFrom('release'), LumeBuildProfile.release);
    expect(
      lumeBuildProfileFrom(kLumeBuildName),
      LumeBuildProfile.reference,
      reason: 'the test run is not a release build',
    );
  });

  testWidgets('a release over this build claims nothing it cannot support', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);
    final List<String> false_ = <String>[];
    final RegExp updated = RegExp(
      '^(${RegExp.escape(l.freshAgoSec(0)).replaceAll('0', r'\d+')}|'
      '${RegExp.escape(l.freshAgoMin(0)).replaceAll('0', r'\d+')})\$',
    );
    for (final LumeFeature feature in kLumeFeatures) {
      final LumeDataCapability cap = LumeDataCapability.fixture(feature.id);
      final LumeSourceClaim c = claim(l, f, feature, LumeBuildProfile.release);
      void flag(bool bad, String what) {
        if (bad) false_.add('${feature.id}: $what');
      }

      flag(
        c.label == l.freshLocal && !cap.isDurable,
        '"${l.freshLocal}" with nothing durable',
      );
      flag(
        c.source.contains('Encrypted') && !cap.isEncrypted,
        'an encryption claim with nothing encrypted',
      );
      flag(c.label == l.freshLive && !cap.isLive, 'Live with nothing live');
      flag(
        c.label == l.freshDelayed && cap.observedAt == null,
        'a delay with nothing observed',
      );
      flag(
        c.updated != null &&
            cap.observedAt == null &&
            feature.freshness != LumeFreshnessKind.computed,
        'an update ("${c.updated}") with nothing observed',
      );
      flag(
        c.updated != null &&
            updated.hasMatch(c.updated!) &&
            cap.observedAt == null,
        'a recency with nothing observed',
      );
      flag(
        c.label == l.freshComputed && !cap.computedHere,
        'a calculation with nothing calculated here',
      );
      flag(
        !LumeSourceClaims.staticSources.contains(feature.fallbackSource) &&
            feature.fallbackSource != LumeSourceClaims.encryptedSource &&
            c.source == feature.fallbackSource,
        'the feed name "${feature.fallbackSource}" with no feed',
      );
    }
    expect(false_, isEmpty, reason: false_.join('\n'));
  });

  testWidgets('a release draws a claim once an adapter supports it', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);
    LumeFeature byId(String id) =>
        kLumeFeatures.firstWhere((LumeFeature x) => x.id == id);

    final LumeSourceClaim stored = claim(
      l,
      f,
      byId('expenses'),
      LumeBuildProfile.release,
      capability: const LumeDataCapability(source: 'Dayroz', isDurable: true),
    );
    expect(stored.label, l.freshLocal);

    final LumeSourceClaim notStored = claim(
      l,
      f,
      byId('expenses'),
      LumeBuildProfile.release,
    );
    expect(notStored.label, l.freshSession);

    final LumeSourceClaim encrypted = claim(
      l,
      f,
      byId('documents'),
      LumeBuildProfile.release,
      capability: const LumeDataCapability(
        source: 'Dayroz',
        isDurable: true,
        isEncrypted: true,
      ),
    );
    expect(encrypted.source, LumeToolStrings.source(l, byId('documents')));
    expect(
      claim(l, f, byId('documents'), LumeBuildProfile.release).source,
      l.toolSourceOnDevice,
    );

    final LumeSourceClaim live = claim(
      l,
      f,
      byId('trains'),
      LumeBuildProfile.release,
      capability: LumeDataCapability(
        source: 'Pakistan Railways',
        isLive: true,
        observedAt: now.subtract(const Duration(seconds: 42)),
      ),
    );
    expect(live.label, l.freshLive);
    expect(live.updated, l.freshAgoSec(42));
    expect(live.source, 'Pakistan Railways');
    expect(
      claim(l, f, byId('trains'), LumeBuildProfile.release).label,
      l.freshSample,
    );

    expect(
      claim(l, f, byId('stopwatch'), LumeBuildProfile.release).label,
      l.freshLive,
      reason: 'a clock on the device is live',
    );
    expect(
      claim(l, f, byId('stopwatch'), LumeBuildProfile.release).updated,
      isNull,
      reason: 'and was never "updated 30 sec ago"',
    );
  });

  testWidgets('the reference build draws exactly what the reference draws', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);
    for (final LumeFeature feature in kLumeFeatures) {
      final LumeSourceClaim c = claim(
        l,
        f,
        feature,
        LumeBuildProfile.reference,
      );
      expect(c.label, LumeToolStrings.freshness(l, feature.freshness));
      expect(c.source, LumeToolStrings.source(l, feature));
      expect(
        c.updated,
        LumeToolStrings.updated(
          l,
          f,
          feature.freshness,
          now: now,
          city: 'Islamabad',
        ),
      );
    }
  });

  test('every freshness kind has a release rule', () {
    // The switch in `LumeSourceClaims.resolve` is exhaustive over the enum;
    // this names the kinds so a new one is a decision, not a default.
    expect(
      LumeFreshnessKind.values.map((LumeFreshnessKind k) => k.name),
      <String>[
        'live',
        'cached',
        'delayed',
        'daily',
        'weekly',
        'annual',
        'draw',
        'computed',
        'reference',
        'local',
      ],
    );
  });
}
