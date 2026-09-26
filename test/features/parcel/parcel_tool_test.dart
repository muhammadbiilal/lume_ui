/// Parcel Tracker on screen: opened directly for a reader ([pumpLume]), not
/// through the real router — the shared `tool_registry.dart` this repository
/// routes through is out of scope for this change; it is wired up in the
/// integration pass that follows, the same approach `markets_tool_test.dart`
/// and `qibla_tool_test.dart` take for their own waves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/parcel/presentation/parcel_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

final LumeFeature _parcelFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeParcelTool.id,
);

Future<void> pumpParcel(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
  double textScale = 1,
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeParcelTool(
      request: LumeToolRequest(
        feature: _parcelFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

void main() {
  setUpAll(loadLumeFonts);

  group('the catalogue entry', () {
    test('is the tracking archetype, global, and declares sharing and '
        'search', () {
      expect(_parcelFeature.supports, contains(LumeToolSupport.sharing));
      expect(_parcelFeature.supports, contains(LumeToolSupport.search));
      expect(_parcelFeature.countries, isNull);
    });
  });

  group('what it draws', () {
    testWidgets('both fixture parcels, the first chosen by default', (
      WidgetTester tester,
    ) async {
      await pumpParcel(tester);

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            inKey(LumeParcelTool.listKey, find.byType(LumeRichRow)),
          )
          .toList();
      expect(rows.map((LumeRichRow r) => r.title), <String>[
        'Keyboard',
        'Books',
      ]);
      expect(rows.map((LumeRichRow r) => r.subtitle), <String>[
        'TCS · TCS-8842910',
        'Leopards · LP-5521773',
      ]);
      expect(rows.map((LumeRichRow r) => r.meta), <List<String>>[
        <String>['Islamabad hub', 'Today, by 18:00'],
        <String>['Multan hub', 'Wed, 10 Sep'],
      ]);
      expect(rows.first.selected, isTrue);
      expect(rows.last.selected, isFalse);
      expect(rows.first.badge!.label, 'Out for delivery');
      expect(rows.first.badge!.tone, LumeBadgeTone.live);
      expect(rows.last.badge!.label, 'In transit');
      expect(rows.last.badge!.tone, LumeBadgeTone.info);

      // The detail card and the timeline both describe the same, first,
      // parcel — never the reference's own last-clicked state from a
      // previous session leaking into a first visit.
      expect(find.text('Keyboard'), findsWidgets);
      final LumeMetric carrier = tester
          .widgetList<LumeMetric>(find.byType(LumeMetric))
          .first;
      expect(carrier.value, 'TCS');

      final LumeTimeline tl = tester.widget<LumeTimeline>(
        find.byKey(LumeParcelTool.timelineKey),
      );
      expect(tl.entries.map((LumeTimelineEntry e) => e.title), <String>[
        'Booked',
        'In transit',
        'Arrived',
        'Out for delivery',
        'Delivered',
      ]);
      expect(
        tl.entries.map((LumeTimelineEntry e) => e.state),
        <LumeTimelineState>[
          LumeTimelineState.done,
          LumeTimelineState.done,
          LumeTimelineState.done,
          LumeTimelineState.now,
          LumeTimelineState.upcoming,
        ],
      );
    });
  });

  group('used', () {
    testWidgets('selecting the other parcel swaps the detail and the '
        'timeline to it', (WidgetTester tester) async {
      await pumpParcel(tester);
      await tester.tap(inKey(LumeParcelTool.listKey, find.text('Books')));
      await tester.pumpAndSettle();

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            inKey(LumeParcelTool.listKey, find.byType(LumeRichRow)),
          )
          .toList();
      expect(rows.first.selected, isFalse);
      expect(rows.last.selected, isTrue);

      final LumeTimeline tl = tester.widget<LumeTimeline>(
        find.byKey(LumeParcelTool.timelineKey),
      );
      expect(tl.entries.map((LumeTimelineEntry e) => e.title), <String>[
        'Booked',
        'In transit',
        'Arriving',
      ]);
    });

    testWidgets('Track answers whatever was typed — or nothing — with the '
        'same fixed line, never a result', (WidgetTester tester) async {
      await pumpParcel(tester);
      await tester.enterText(
        inKey(LumeParcelTool.fieldKey, find.byType(EditableText)),
        'ZZ-NOT-A-REAL-NUMBER',
      );
      await tester.pump();
      await tester.tap(inKey(LumeParcelTool.trackKey, find.text('Track')));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text(
            "Lume can't reach couriers yet, so it can't look up this shipment.",
          ),
        ),
        findsOneWidget,
      );
      // No result appeared, and the two fixture parcels are exactly what
      // they were before — the field's text changes nothing about them.
      expect(
        inKey(LumeParcelTool.listKey, find.byType(LumeRichRow)),
        findsNWidgets(2),
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Notify is a toast, not a subscription', (
      WidgetTester tester,
    ) async {
      await pumpParcel(tester);
      final Finder notify = inKey(
        LumeParcelTool.actionsKey,
        find.text('Notify on updates'),
      );
      await tester.ensureVisible(notify);
      await tester.tap(notify);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text(
            "Lume can't follow shipments yet, so it has no updates to send.",
          ),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the share card is the chosen parcel, not the reference’s '
        'unrelated quote', (WidgetTester tester) async {
      await pumpParcel(tester);
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.reminder);
      expect(card.text, 'Keyboard · Out for delivery');
      expect(card.source, 'TCS · TCS-8842910');
    });

    testWidgets('in Urdu the row runs right to left, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpParcel(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(
          tester.element(
            inKey(LumeParcelTool.listKey, find.byType(LumeRichRow)).first,
          ),
        ),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpParcel(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
