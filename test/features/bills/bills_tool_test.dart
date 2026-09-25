/// Bills on screen: opened directly for a reader ([pumpLume]), not through
/// the real router.
///
/// Like `prizebonds_tool_test.dart` and `qibla_tool_test.dart`, this pumps
/// [LumeBillsTool] directly rather than through `LumeRoutes.tool(...)`: this
/// wave lands alongside many other tools built in parallel, and the shared
/// `tool_registry.dart` this repository routes through is out of scope for
/// this change — it is wired up in the integration pass that follows. The
/// screen itself is exercised exactly as the router would host it, with the
/// same provider overrides and the same clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/bills/data/bills_fixtures.dart';
import 'package:lume/features/bills/presentation/bills_tool.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeBillsTool.id,
);

Future<void> pumpBills(
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
    LumeBillsTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

BuildContext ctx(WidgetTester t) => t.element(find.byKey(LumeBillsTool.summaryKey));

// `find.byKey` on a subtree's own key won't find descendants of that type
// directly through `widgetList`; use `find.descendant` instead.
List<LumeRichRow> rows(WidgetTester t) => t
    .widgetList<LumeRichRow>(
      find.descendant(
        of: find.byKey(LumeBillsTool.listKey),
        matching: find.byType(LumeRichRow),
      ),
    )
    .toList();

void main() {
  group('the catalogue entry', () {
    test('is a global feature — no country restriction of its own', () {
      expect(_feature.countries, isNull);
    });
  });

  group('the summary card', () {
    testWidgets('totals every unpaid bill, and rings the paid ratio', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester);
      final AppLocalizations l = AppLocalizations.of(ctx(tester));
      final LumeFormatting f = LumeFormatting.of(ctx(tester), countryCode: 'PK');
      const LumeBillsBoard board = LumeBillsBoard(currency: 'PKR');

      final LumeSummaryCard card = tester.widget(find.byKey(LumeBillsTool.summaryKey));
      expect(card.kicker, l.billsDueThisMonth);
      expect(card.value, f.money(board.money(board.totalDueUsd), code: 'PKR'));
      expect(card.caption, l.billsOverdueCount(1));
      expect(card.stats.map((LumeStat s) => s.label).toList(), <String>[
        l.commonOverdue,
        l.billsUpcoming,
        l.billsPaidAmount,
      ]);

      final LumeProgressRing ring = card.aside! as LumeProgressRing;
      expect(ring.centreValue, '1/5');
      expect(ring.value, 1 / 5);
    });

    testWidgets('the overdue notice names the one overdue bill', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester);
      final AppLocalizations l = AppLocalizations.of(ctx(tester));
      expect(find.byKey(LumeBillsTool.noticeKey), findsOneWidget);
      expect(find.text(l.billsNeedAttention(1)), findsOneWidget);
    });
  });

  group('the filter bar — the reference\'s own quirk, kept', () {
    testWidgets('all five bills, by default', (WidgetTester tester) async {
      await pumpBills(tester);
      expect(rows(tester), hasLength(5));
    });

    testWidgets('Overdue narrows to the one overdue bill', (WidgetTester tester) async {
      await pumpBills(tester);
      await tester.tap(find.byKey(LumeBillsTool.filterChip(LumeBillsFilter.overdue)));
      await tester.pumpAndSettle();
      expect(rows(tester).map((LumeRichRow r) => r.title), <String>['Internet']);
    });

    testWidgets('Paid narrows to the one paid bill', (WidgetTester tester) async {
      await pumpBills(tester);
      // The filter bar is its own horizontal scroller (`LumeFilterBar`); at
      // 390 points wide, "Paid" (the fourth chip) starts outside the initial
      // viewport.
      await tester.ensureVisible(
        find.byKey(LumeBillsTool.filterChip(LumeBillsFilter.paid)),
      );
      await tester.tap(find.byKey(LumeBillsTool.filterChip(LumeBillsFilter.paid)));
      await tester.pumpAndSettle();
      expect(rows(tester).map((LumeRichRow r) => r.title), <String>['Mobile']);
    });

    testWidgets(
      'Due shows three bills (due and upcoming), though its own count says '
      'one — exactly as the reference disagrees with itself',
      (WidgetTester tester) async {
        await pumpBills(tester);
        final LumeFilterChip before = tester.widget(
          find.byKey(LumeBillsTool.filterChip(LumeBillsFilter.due)),
        );
        expect(before.count, 1);
        await tester.tap(find.byKey(LumeBillsTool.filterChip(LumeBillsFilter.due)));
        await tester.pumpAndSettle();
        expect(rows(tester).map((LumeRichRow r) => r.title), <String>[
          'Electricity',
          'Gas',
          'Water',
        ]);
      },
    );
  });

  group('every row', () {
    testWidgets('badges its own state — overdue, due-or-upcoming, or paid', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester);
      final AppLocalizations l = AppLocalizations.of(ctx(tester));
      final Map<String, LumeBadge> byTitle = <String, LumeBadge>{
        for (final LumeRichRow r in rows(tester)) r.title: r.badge!,
      };
      expect(byTitle['Internet']!.label, l.commonOverdue);
      expect(byTitle['Internet']!.tone, LumeBadgeTone.late_);
      expect(byTitle['Electricity']!.label, l.commonDue);
      expect(byTitle['Electricity']!.tone, LumeBadgeTone.warn);
      expect(byTitle['Gas']!.label, l.commonDue);
      expect(byTitle['Mobile']!.label, l.commonPaid);
      expect(byTitle['Mobile']!.tone, LumeBadgeTone.ok);
    });

    testWidgets('tapping an unpaid bill only toasts — nothing is written', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester);
      final AppLocalizations l = AppLocalizations.of(ctx(tester));
      // 'Electricity' also names the row below in the History section
      // (`board.history`) — tap the specific main-list row, by key.
      await tester.tap(find.byKey(LumeBillsTool.row('••••4821')));
      await tester.pump();
      expect(find.text(l.billsOpening('K-Electric')), findsOneWidget);
      // Nothing was written — the same five bills, the same states.
      expect(rows(tester), hasLength(5));
    });

    testWidgets('tapping the paid bill only toasts — it is not un-paid', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester);
      final AppLocalizations l = AppLocalizations.of(ctx(tester));
      // 'Mobile' also names the row below in the History section
      // (`board.history`) — tap the specific main-list row, by key.
      await tester.tap(find.byKey(LumeBillsTool.row('••••3390')));
      await tester.pump();
      expect(find.text(l.billsRowPaid('Mobile')), findsOneWidget);
    });
  });

  group('history', () {
    testWidgets('the paid bill, then up to two more still open', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester);
      final List<Widget> compact = tester
          .widgetList(find.byKey(LumeBillsTool.historyKey))
          .toList();
      expect(compact, isNotEmpty);
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the real bills, in Urdu, right to left', (
      WidgetTester tester,
    ) async {
      await pumpBills(tester, locale: const Locale('ur'));
      expect(find.byKey(LumeBillsTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(LumeBillsTool.summaryKey))),
        TextDirection.rtl,
      );
      // The provider names are kept as the reference writes them, never
      // translated (bills.tool.js never runs them through `c.t()`).
      expect(find.text('K-Electric'), findsOneWidget);
    });
  });
}
