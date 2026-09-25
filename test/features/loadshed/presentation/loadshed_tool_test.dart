/// Loadshedding on screen: opened directly for a reader ([pumpLume]), not
/// through the real router.
///
/// Unlike most converted tools, this pumps [LumeLoadshedTool] directly
/// rather than through `LumeRoutes.tool(...)`: this wave lands alongside many
/// other tools built in parallel, and the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change — it is wired
/// up in the integration pass that follows (the same approach Qibla's own
/// test takes, `qibla_tool_test.dart`). The screen itself is exercised
/// exactly as the router would host it, with the same provider overrides and
/// the same clock (the fixture instant, Monday 7 September, 16:41).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/loadshed/data/loadshed_fixtures.dart';
import 'package:lume/features/loadshed/presentation/loadshed_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeLoadshedTool.id,
);

Future<void> pumpLoadshed(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeLoadshedTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the catalogue entry', () {
    test('is Pakistan-only and city-aware — not this widget\'s job to '
        're-decide', () {
      expect(_feature.countries, <String>{'PK'});
      expect(_feature.requiresCity, isTrue);
    });
  });

  group('a Pakistani reader', () {
    testWidgets('sees the real five-slot schedule, the reliability figure '
        'and the week chart — the reference\'s own fixture data, not '
        'invented', (WidgetTester tester) async {
      await pumpLoadshed(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Islamabad'),
      );

      expect(find.byKey(LumeLoadshedTool.summaryKey), findsOneWidget);
      expect(find.byType(LumeToolState), findsNothing);

      // At the fixture instant (Monday 16:41) the reader is between the
      // third and fourth slots: nothing is running, the next outage is
      // 19:00–20:00, 2h19m away.
      final LumeLoadshedToday ls = LumeLoadshedToday.at(
        nowMinute: 16 * 60 + 41,
        weekday: DateTime.monday,
      );
      expect(ls.isNow, isFalse);

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeLoadshedTool.summaryKey),
      );
      expect(summary.value, '2h 19m');
      expect(summary.stats, hasLength(3));
      expect(summary.stats[0].value, '6h');
      expect(summary.stats[1].value, '5');
      expect(summary.stats[2].value, '78%');

      final List<LumeAgendaRow> rows = tester
          .widgetList<LumeAgendaRow>(
            find.descendant(
              of: find.byKey(LumeLoadshedTool.scheduleKey),
              matching: find.byType(LumeAgendaRow),
            ),
          )
          .toList();
      expect(rows, hasLength(5));
      expect(rows.map((LumeAgendaRow r) => r.time).toList(), <String>[
        '06:00',
        '10:00',
        '14:00',
        '19:00',
        '23:00',
      ]);
      expect(rows.map((LumeAgendaRow r) => r.tone).toList(), <LumeAgendaTone>[
        LumeAgendaTone.done,
        LumeAgendaTone.done,
        LumeAgendaTone.done,
        LumeAgendaTone.upcoming,
        LumeAgendaTone.upcoming,
      ]);

      final LumeBarChart week = tester.widget(
        find.byKey(LumeLoadshedTool.weekKey),
      );
      expect(week.values, <double>[6, 5, 7, 6, 4, 5, 6]);
      // Monday is the fixture instant's own day, index 0.
      expect(week.highlight, 0);

      expect(
        find.descendant(
          of: find.byKey(LumeLoadshedTool.rowsKey),
          matching: find.byType(LumeCompactRow),
        ),
        findsNWidgets(2),
      );

      // The context bar names the city, not the country.
      expect(find.textContaining('Islamabad'), findsWidgets);
    });

    testWidgets('tapping the notify row toasts, never silently', (
      WidgetTester tester,
    ) async {
      await pumpLoadshed(tester);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byKey(LumeLoadshedTool.rowsKey)),
      );
      await tester.tap(find.text(l.loadshedNotify));
      await tester.pump();
      expect(find.text(l.loadshedNotifyOn), findsOneWidget);
    });
  });

  group('a reader outside Pakistan', () {
    testWidgets('sees the honest unavailable state, never an invented '
        'outage schedule', (WidgetTester tester) async {
      await pumpLoadshed(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
      );

      expect(find.byKey(LumeLoadshedTool.summaryKey), findsNothing);
      expect(find.byKey(LumeLoadshedTool.scheduleKey), findsNothing);
      expect(find.byKey(LumeLoadshedTool.weekKey), findsNothing);
      expect(find.byKey(LumeLoadshedTool.rowsKey), findsNothing);

      final LumeToolState state = tester.widget(find.byType(LumeToolState));
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeToolState)),
      );
      expect(state.title, l.toolUnavailableTitle);
      expect(state.text, l.toolUnavailableText);
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the real schedule, in Urdu, right to left', (
      WidgetTester tester,
    ) async {
      await pumpLoadshed(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Islamabad'),
        locale: const Locale('ur'),
      );
      expect(find.byKey(LumeLoadshedTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeLoadshedTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
    });
  });
}
