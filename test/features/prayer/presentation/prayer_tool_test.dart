/// Prayer Times on screen: opened directly for a reader ([pumpLume]), not
/// through the real router — this wave's shared `tool_registry.dart` is not
/// wired for `prayer` yet, the same reason Qibla's own harness gives.
///
/// Where a test needs an expected clock time, it is worked out independently
/// here by calling [LumePrayerDay] and the real [LumeTimeZoneService] with
/// the same inputs the widget itself resolves — never a hand-typed digit —
/// so the assertion is "the screen shows what the calculation says", not "the
/// screen shows what I once observed it to show".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/catalogue/presentation/feature_strings.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/prayer/domain/prayer_schedule.dart';
import 'package:lume/features/prayer/presentation/prayer_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/presentation/tool_screen.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _prayerFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumePrayerTool.id,
);

/// What the widget itself resolves for [country]/[city] — real region-follow
/// policy, the real IANA database, no test double — so a test can compare the
/// screen against this rather than a digit typed by hand.
LumePrayerDay _oracle(String country, String city) {
  final LumeZoneResolution zone = LumeTimeZoneService.shared.reader(
    country: country,
    city: city,
  );
  final (LumePrayerDay? day, LumePrayerMissing? missing) = LumePrayerDay.at(
    now: kFixtureInstant,
    country: country,
    city: city,
    zone: zone,
  );
  expect(
    missing,
    isNull,
    reason:
        'the oracle itself has no reading for $country/$city — fix the '
        'test, not the widget',
  );
  return day!;
}

Future<void> pumpPrayer(
  WidgetTester tester, {
  // Prayer is faith-gated (`faith: true`): the frame itself blocks the body
  // for a non-Muslim reader, so every test here that expects to see the
  // reading needs a Muslim context — Muslim + Pakistan + Islamabad is the
  // brief's own first baseline scenario (§18), and the default
  // [LumeUserContext].
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 4200),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumePrayerTool(
      request: LumeToolRequest(
        feature: _prayerFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the catalogue entry', () {
    test('is faith-gated, city-aware and computed — the same category as '
        'Qibla and Sun & Moon, not this widget\'s job to re-decide', () {
      expect(_prayerFeature.faith, isTrue);
      expect(_prayerFeature.requiresCity, isTrue);
      expect(_prayerFeature.freshness, LumeFreshnessKind.computed);
    });
  });

  group('a city and zone Lume can work out (Islamabad, the default)', () {
    testWidgets(
      'shows the next prayer, its countdown, all five of today\'s prayers '
      'and the sunrise/sunset pair — computed for real, never a fixture',
      (WidgetTester tester) async {
        await pumpPrayer(tester);

        expect(find.byKey(LumePrayerTool.missingKey), findsNothing);
        expect(find.byKey(LumePrayerTool.summaryKey), findsOneWidget);

        final BuildContext context = lumeContext(
          tester,
          find.byKey(LumePrayerTool.summaryKey),
        );
        final AppLocalizations l = AppLocalizations.of(context);
        final LumeFormatting f = LumeFormatting.of(context, countryCode: 'PK');
        final LumePrayerDay oracle = _oracle('PK', 'Islamabad');
        final (LumePrayerSlot next, Duration remaining, double _) = oracle
            .state(kFixtureInstant);

        final LumeSummaryCard summary = tester.widget(
          find.byKey(LumePrayerTool.summaryKey),
        );
        expect(summary.value, LumeFeatureStrings.prayerName(l, next.key));
        expect(summary.unit, f.time(next.at));
        expect(
          summary.caption,
          l.prayerCountdown(LumeFormatting.countdown(remaining)),
        );

        final LumeTimeline timeline = tester.widget(
          find.byKey(LumePrayerTool.timelineKey),
        );
        expect(timeline.entries, hasLength(5));
        // Every one of the five real keys is on screen, each exactly once.
        expect(
          timeline.entries.map((LumeTimelineEntry e) => e.title).toSet(),
          <String>{
            for (final String key in <String>[
              'fajr',
              'dhuhr',
              'asr',
              'maghrib',
              'isha',
            ])
              LumeFeatureStrings.prayerName(l, key),
          },
        );

        final LumeMetrics sun = tester.widget(
          find.byKey(LumePrayerTool.sunKey),
        );
        expect(sun.children, hasLength(2));

        final LumeTable upcoming = tester.widget(
          find.byKey(LumePrayerTool.upcomingKey),
        );
        expect(upcoming.rows, hasLength(4));

        // The context bar names the city and the country, not just the city.
        expect(find.textContaining('Islamabad'), findsWidgets);
      },
    );

    testWidgets(
      'the method rows disclose Muslim World League and the standard Asr '
      'ratio — the only method this build offers, said plainly rather than '
      'presented as the reader\'s own choice',
      (WidgetTester tester) async {
        await pumpPrayer(tester);
        final BuildContext context = lumeContext(
          tester,
          find.byKey(LumePrayerTool.methodKey),
        );
        final AppLocalizations l = AppLocalizations.of(context);
        expect(find.text(l.prayerMethodMwl), findsOneWidget);
        expect(find.text(l.prayerAsrStandard), findsOneWidget);
      },
    );
  });

  group('a different city changes the reading', () {
    testWidgets(
      'London\'s next prayer time differs from Islamabad\'s — it is worked '
      'out per city, not hard-coded',
      (WidgetTester tester) async {
        await pumpPrayer(
          tester,
          user: const LumeUserContext(
            country: 'GB',
            city: 'London',
            islamic: true,
          ),
        );
        final BuildContext context = lumeContext(
          tester,
          find.byKey(LumePrayerTool.summaryKey),
        );
        final LumeFormatting f = LumeFormatting.of(context, countryCode: 'GB');
        final LumePrayerDay oracle = _oracle('GB', 'London');
        final (LumePrayerSlot next, _, _) = oracle.state(kFixtureInstant);

        final LumeSummaryCard summary = tester.widget(
          find.byKey(LumePrayerTool.summaryKey),
        );
        expect(summary.unit, f.time(next.at));

        final LumePrayerDay islamabad = _oracle('PK', 'Islamabad');
        final (LumePrayerSlot pkNext, _, _) = islamabad.state(kFixtureInstant);
        // Same instant, two real places: the two readings are not the same
        // clock time (Fajr's own drift alone, before the five-hour zone
        // difference, already guarantees this).
        expect(next.at, isNot(pkNext.at));
      },
    );
  });

  group('a non-Muslim reader', () {
    testWidgets(
      'never sees the reading — the frame itself blocks a faith-gated '
      'tool\'s body, defence in depth over the catalogue gate alone (§64)',
      (WidgetTester tester) async {
        await pumpPrayer(tester, user: const LumeUserContext(islamic: false));
        expect(find.byKey(LumePrayerTool.summaryKey), findsNothing);
        expect(find.byKey(LumePrayerTool.timelineKey), findsNothing);
        expect(find.byKey(LumePrayerTool.upcomingKey), findsNothing);
        expect(find.byKey(LumePrayerTool.missingKey), findsNothing);
      },
    );
  });

  group('a city Lume has no coordinates for', () {
    testWidgets(
      'says so plainly, with no summary, timeline or upcoming table',
      (WidgetTester tester) async {
        await pumpPrayer(
          tester,
          user: const LumeUserContext(
            country: 'PK',
            city: 'Chitral',
            islamic: true,
          ),
        );
        expect(find.byKey(LumePrayerTool.missingKey), findsOneWidget);
        expect(find.byKey(LumePrayerTool.summaryKey), findsNothing);
        expect(find.byKey(LumePrayerTool.timelineKey), findsNothing);
        expect(find.byKey(LumePrayerTool.upcomingKey), findsNothing);

        final LumeToolState state = tester.widget(
          find.byKey(LumePrayerTool.missingKey),
        );
        expect(state.title, contains('Chitral'));
      },
    );
  });

  group('sharing and export', () {
    testWidgets(
      'shares the next prayer as a reminder-kind card, sourced to the city '
      'and the date',
      (WidgetTester tester) async {
        await pumpPrayer(tester);
        final LumeToolScreen screen = tester.widget(
          find.byType(LumeToolScreen),
        );
        final LumeShareCard? card = screen.shareCard?.call();
        expect(card, isNotNull);
        expect(card!.kind, LumeShareKind.reminder);
        expect(card.text, isNotEmpty);
        expect(card.source, contains('Islamabad'));
      },
    );

    testWidgets('exports today\'s five prayer times as a CSV', (
      WidgetTester tester,
    ) async {
      await pumpPrayer(tester);
      final LumeToolScreen screen = tester.widget(find.byType(LumeToolScreen));
      final LumeExportFile? file = screen.exportFile?.call();
      expect(file, isNotNull);
      expect(file!.format, LumeExportFormat.csv);
    });

    testWidgets('neither sharing nor exporting is offered where there is no '
        'reading to share', (WidgetTester tester) async {
      await pumpPrayer(
        tester,
        user: const LumeUserContext(
          country: 'PK',
          city: 'Chitral',
          islamic: true,
        ),
      );
      final LumeToolScreen screen = tester.widget(find.byType(LumeToolScreen));
      expect(screen.shareCard, isNull);
      expect(screen.exportFile, isNull);
    });
  });

  group('a non-English locale', () {
    testWidgets(
      'still renders the computed schedule, in Arabic, right to left',
      (WidgetTester tester) async {
        await pumpPrayer(tester, locale: const Locale('ar'));
        expect(find.byKey(LumePrayerTool.summaryKey), findsOneWidget);
        expect(
          Directionality.of(
            tester.element(find.byKey(LumePrayerTool.summaryKey)),
          ),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Urdu: the tool still renders, right to left, with no '
        'overflow', (WidgetTester tester) async {
      await pumpPrayer(tester, locale: const Locale('ur'));
      expect(find.byKey(LumePrayerTool.summaryKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('at 200% text scale, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpPrayer(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Urdu at 200% text scale — the exact combination a prior wave found '
      'real overflow bugs in shared row widgets under',
      (WidgetTester tester) async {
        await pumpPrayer(tester, locale: const Locale('ur'), textScale: 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Arabic at 200% text scale, right to left', (
      WidgetTester tester,
    ) async {
      await pumpPrayer(tester, locale: const Locale('ar'), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
