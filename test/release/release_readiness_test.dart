/// The release-honesty gate (F6B decision 5, F6B closure, `RELEASE_HONESTY.md`).
///
/// Every catalogue tool's source bar is resolved as a release build would
/// resolve it over this build's capabilities: nothing may claim storage,
/// encryption, liveness or an update that no capability supports, and every
/// tool that shows sample data must say so *in its own source bar*. About's
/// Data row is not looked at here on purpose — a reader who never opens About
/// must still be told. The reference build draws what the reference draws,
/// with the sample mark leading the source line.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/application/tool_registry.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';
import 'package:lume/features/tools/presentation/source_claims.dart';
import 'package:lume/features/tools/presentation/tool_strings.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../features/tax/tax_harness.dart';
import '../features/tools/tool_parity.dart';
import '../features/wave1/wave1_tools_test.dart' show pumpTool;
import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';

/// What is wrong with [c] as a release claim over [cap], or nothing.
List<String> releaseFaults(
  AppLocalizations l,
  LumeFeature feature,
  LumeDataCapability cap,
  LumeSourceClaim c,
) {
  final List<String> out = <String>[];
  void flag(bool bad, String what) {
    if (bad) out.add('${feature.id}: $what');
  }

  final RegExp recency = RegExp(
    '^(${RegExp.escape(l.freshAgoSec(0)).replaceAll('0', r'\d+')}|'
    '${RegExp.escape(l.freshAgoMin(0)).replaceAll('0', r'\d+')})\$',
  );
  flag(
    cap.isSample && !c.discloses(l),
    'sample data with no disclosure in the source bar',
  );
  flag(
    cap.isSample && (c.updated != null || c.label != l.freshSample),
    'sample data drawn with a claim ("${c.label}", "${c.updated}")',
  );
  flag(
    c.label == l.freshLocal && !cap.isDurable,
    '"${l.freshLocal}" with nothing durable',
  );
  flag(
    (c.source ?? '').contains('Encrypted') && !cap.isEncrypted,
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
    c.updated != null && recency.hasMatch(c.updated!) && cap.observedAt == null,
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
  return out;
}

void main() {
  final DateTime now = DateTime(2026, 9, 7, 16, 41);
  LumeFeature byId(String id) =>
      kLumeFeatures.firstWhere((LumeFeature x) => x.id == id);

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

  test('only tools whose figures are the reader\'s own, or worked out on '
      'the device, are sample-free', () {
    expect(
      <String>[
        for (final LumeFeature f in kLumeFeatures)
          if (!LumeDataCapability.fixture(f.id).isSample) f.id,
      ]..sort(),
      // Ledger shows only what the reader wrote: nothing is seeded (D11).
      <String>[
        'age',
        'compound',
        'ledger',
        'loan',
        'stopwatch',
        'sunmoon',
        'tipsplit',
      ],
    );
    // Sun & Moon is the one computed tool: a calculation for the reader's
    // city, never live and never stored (C86).
    final LumeDataCapability sky = LumeDataCapability.fixture('sunmoon');
    expect(sky.computedHere, isTrue);
    expect(sky.isLive || sky.isDurable || sky.isEncrypted, isFalse);
  });

  testWidgets('a release says Sun & Moon is calculated for the reader\'s '
      'place, and claims no sample, feed or storage', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);
    final LumeSourceClaim c = claim(
      l,
      f,
      byId('sunmoon'),
      LumeBuildProfile.release,
    );
    expect(c.label, l.freshComputed);
    expect(c.discloses(l), isFalse);
    // The place it was worked out for, never an "Updated …" time.
    expect(c.updated, l.freshForCity('Islamabad'));
  });

  testWidgets('a release over this build claims nothing it cannot support, '
      'and says "Sample data" wherever it shows it', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);
    final List<String> faults = <String>[
      for (final LumeFeature feature in kLumeFeatures)
        ...releaseFaults(
          l,
          feature,
          LumeDataCapability.fixture(feature.id),
          claim(l, f, feature, LumeBuildProfile.release),
        ),
    ];
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  testWidgets('the gate catches a sample tool that does not say so', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);
    final LumeFeature trains = byId('trains');
    final LumeDataCapability cap = LumeDataCapability.fixture('trains');
    // What the reference draws, handed to a release: a live, recent feed.
    final LumeSourceClaim reference = claim(
      l,
      f,
      trains,
      LumeBuildProfile.reference,
    );
    final LumeSourceClaim hidden = LumeSourceClaim(
      quality: reference.quality,
      label: reference.label,
      source: reference.source,
      updated: reference.updated,
    );
    expect(
      releaseFaults(l, trains, cap, hidden),
      containsAll(<String>[
        'trains: sample data with no disclosure in the source bar',
        'trains: Live with nothing live',
      ]),
    );
  });

  testWidgets('a release draws a claim once an adapter supports it', (
    WidgetTester tester,
  ) async {
    final (AppLocalizations l, LumeFormatting f) = await strings(tester);

    final LumeSourceClaim stored = claim(
      l,
      f,
      byId('expenses'),
      LumeBuildProfile.release,
      capability: const LumeDataCapability(source: 'Dayroz', isDurable: true),
    );
    expect(stored.label, l.freshLocal);
    expect(stored.discloses(l), isFalse, reason: 'an adapter is not sample');

    final LumeSourceClaim notStored = claim(
      l,
      f,
      byId('expenses'),
      LumeBuildProfile.release,
      capability: const LumeDataCapability(source: 'Dayroz'),
    );
    expect(notStored.label, l.freshSession);

    expect(
      claim(l, f, byId('expenses'), LumeBuildProfile.release).label,
      l.freshSample,
      reason: 'the fixture records are sample data',
    );

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

  testWidgets('the reference build draws what the reference draws, led by '
      'the sample mark', (WidgetTester tester) async {
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
      expect(
        c.sample,
        LumeDataCapability.fixture(feature.id).isSample ? l.freshSample : null,
        reason: feature.id,
      );
    }
  });

  // What a reader actually sees: every converted tool, opened through its
  // route, with only its own source bar looked at.
  group('in the tool itself', () {
    setUpAll(() async {
      await loadLumeFonts();
    });

    for (final LumeBuildProfile profile in LumeBuildProfile.values) {
      for (final String id in kLumeToolRegistry.keys) {
        testWidgets('${profile.name}: $id', (WidgetTester tester) async {
          await pumpTool(
            tester,
            id,
            // Hadith is for a reader who has the Islamic experience.
            state: id == 'hadith' ? 'muslim_pk' : 'default_pk',
            overrides: <Override>[
              buildProfileProvider.overrideWithValue(profile),
            ],
          );
          final bool sample = LumeDataCapability.fixture(id).isSample;
          final Finder bar = find.byType(LumeSourceBar);
          expect(bar, findsOneWidget, reason: '$id draws no source bar');
          final List<String> said = textsUnder(tester, bar);
          if (profile == LumeBuildProfile.release) {
            expect(said.contains('Sample data'), sample, reason: '$said');
            expect(
              find.descendant(
                of: bar,
                matching: find.byKey(LumeSourceLine.sampleKey),
              ),
              findsNothing,
            );
          } else {
            final Finder mark = find.descendant(
              of: bar,
              matching: find.byKey(LumeSourceLine.sampleKey),
            );
            expect(mark, sample ? findsOneWidget : findsNothing);
            if (sample) {
              expect(
                textsUnder(
                  tester,
                  find.descendant(
                    of: bar,
                    matching: find.byType(LumeSourceLine),
                  ),
                ).first,
                'Sample data',
                reason: 'it leads the source line',
              );
              expect(
                tester.getSemantics(mark).label,
                'Sample data. The figures in this tool are examples, not '
                'your own.',
              );
            }
          }
        });
      }
    }
  });

  group('the fixture harness', () {
    for (final LumeBuildProfile profile in LumeBuildProfile.values) {
      testWidgets('${profile.name}: /tools/tool/ready', (
        WidgetTester tester,
      ) async {
        await pumpLumeRouter(
          tester,
          initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'ready'),
          profile: taxProfile('default_pk'),
          overrides: <Override>[
            buildProfileProvider.overrideWithValue(profile),
          ],
        );
        await tester.pumpAndSettle();
        final Finder mark = find.byKey(LumeSourceLine.sampleKey);
        if (profile == LumeBuildProfile.release) {
          expect(find.byType(LumeSourceBar), findsNothing);
          expect(find.text('Not part of your setup'), findsWidgets);
          expect(mark, findsNothing);
        } else {
          expect(mark, findsOneWidget);
        }
      });
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
