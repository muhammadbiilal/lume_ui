/// Sheets the web opens that the conversion had left unreachable, now
/// wired: sign-up's "How Lume handles your data" (`#sheet-authlegal`), the
/// push ask (`#sheet-notifpush`) behind the Push switch, and Restore
/// dismissed on the account route.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/platform/lume_notification_gate.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/auth/application/auth_flow_controller.dart';
import 'package:lume/features/auth/presentation/auth_flow.dart';
import 'package:lume/features/auth/presentation/auth_legal_sheet.dart';
import 'package:lume/features/notifications/presentation/notification_sheets.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

ProviderContainer container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

void main() {
  testWidgets('sign-up’s legal link opens its sheet, over the form', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.authRoute(LumeAuthRoute.signUp.segment),
      profile: taxProfile('default_pk'),
    );
    await tester.pumpAndSettle();
    final LumeAuthFlow flow = tester.widget<LumeAuthFlow>(
      find.byType(LumeAuthFlow),
    );
    expect(flow.onOpenLegal, isNotNull);
    flow.onOpenLegal!();
    await tester.pumpAndSettle();
    expect(find.byType(LumeAuthLegalSheet), findsOneWidget);
    expect(find.text('How Lume handles your data'), findsWidgets);
    // Under the sheet, the flow is still there.
    expect(find.byType(LumeAuthFlow), findsOneWidget);
  });

  group('the Push switch asks the platform', () {
    Future<LumeFakeNotificationGate> pumpNotifications(
      WidgetTester tester,
      LumeNotificationState now, {
      LumeNotificationState answer = const LumeNotificationState(
        LumeNotificationAccess.granted,
      ),
    }) async {
      final LumeFakeNotificationGate gate = LumeFakeNotificationGate(
        now: now,
        answer: answer,
      );
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.accountRoute(
          LumeRoutes.profile,
          LumeAccountRoute.notifications.segment,
        ),
        profile: taxProfile('default_pk'),
        surface: const Size(390, 3000),
        overrides: <Override>[notificationGateProvider.overrideWithValue(gate)],
      );
      await tester.pumpAndSettle();
      return gate;
    }

    bool pushOn(WidgetTester tester) =>
        container(tester).read(notificationPrefsProvider).prefs.push;

    Future<void> tapPush(WidgetTester tester) async {
      await tester.tap(find.text('Push notifications').first);
      await tester.pumpAndSettle();
    }

    testWidgets('not yet asked: the push sheet, then the platform, then on', (
      WidgetTester tester,
    ) async {
      final LumeFakeNotificationGate gate = await pumpNotifications(
        tester,
        const LumeNotificationState(LumeNotificationAccess.firstRequest),
      );
      if (pushOn(tester)) await tapPush(tester); // start from off
      await tapPush(tester);
      expect(find.byType(LumeNotificationPushAsk), findsOneWidget);
      await tester.tap(find.byKey(LumeNotificationPushAsk.allowKey));
      await tester.pumpAndSettle();
      expect(gate.asked, contains('request'));
      expect(pushOn(tester), isTrue);
    });

    testWidgets('"Not now" leaves it off, and asks the platform nothing', (
      WidgetTester tester,
    ) async {
      final LumeFakeNotificationGate gate = await pumpNotifications(
        tester,
        const LumeNotificationState(LumeNotificationAccess.firstRequest),
      );
      if (pushOn(tester)) await tapPush(tester);
      await tapPush(tester);
      await tester.tap(find.byKey(LumeNotificationPushAsk.laterKey));
      await tester.pumpAndSettle();
      expect(gate.asked, isNot(contains('request')));
      expect(pushOn(tester), isFalse);
    });

    testWidgets('blocked: it stays off and says where to allow it', (
      WidgetTester tester,
    ) async {
      await pumpNotifications(
        tester,
        const LumeNotificationState(LumeNotificationAccess.blocked),
      );
      if (pushOn(tester)) await tapPush(tester);
      await tapPush(tester);
      expect(find.byType(LumeNotificationPushAsk), findsNothing);
      expect(pushOn(tester), isFalse);
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.textContaining('device settings'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('Restore dismissed brings every dismissed row back', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.accountRoute(
        LumeRoutes.profile,
        LumeAccountRoute.notifications.segment,
      ),
      profile: taxProfile('default_pk'),
      surface: const Size(390, 3000),
    );
    await tester.pumpAndSettle();
    final ProviderContainer c = container(tester);
    final String first =
        (await c.read(notificationFeedProvider).feed(now: kFixtureInstant))
            .all
            .first
            .id;
    await c.read(notificationFeedProvider).dismiss(first);

    final Finder restore = find.text('Restore dismissed').first;
    await tester.ensureVisible(restore);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final List<String> ids = <String>[
      for (final n
          in (await c.read(notificationFeedProvider).feed(now: kFixtureInstant))
              .all)
        n.id,
    ];
    expect(ids, contains(first));
    await tester.pump(const Duration(seconds: 4));
  });
}
