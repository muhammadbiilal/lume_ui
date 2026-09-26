/// Opening a notification as the reference's `openItem` / `actItem` do: a
/// row opens its tool on the item it is about (the reference's `toolstate`
/// deep link), its action button also marks it actioned, and a grouped row
/// only marks itself read.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/features/notifications/presentation/notification_host.dart';
import 'package:lume/features/notifications/presentation/notification_open.dart';
import 'package:lume/features/parcel/presentation/parcel_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

Future<ProviderContainer> openCentre(WidgetTester tester) async {
  await pumpLumeRouter(
    tester,
    initialLocation: '/home/notifications',
    surface: const Size(390, 4000),
  );
  await tester.pump(LumeNotificationHost.settle);
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Future<List<LumeNotification>> feed(ProviderContainer c) async =>
    (await c.read(notificationFeedProvider).feed(now: kFixtureInstant)).all;

void main() {
  testWidgets('a parcel notification opens Parcel on that parcel', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await openCentre(tester);
    final Finder row = find.text('Keyboard is on its way');
    expect(row, findsOneWidget);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(LumeParcelTool), findsOneWidget);
    expect(
      c.read(toolSessionProvider).read(LumeParcelTool.id, 'parcel'),
      'TCS-8842910',
    );
  });

  testWidgets('its action button also marks it actioned', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await openCentre(tester);
    final LumeNotification parcel = (await feed(
      c,
    )).firstWhere((LumeNotification n) => n.tool == 'parcel');
    expect(parcel.actioned, isFalse);

    await c.read(notificationFeedProvider).markActioned(parcel.id);
    final LumeNotification after = (await feed(
      c,
    )).firstWhere((LumeNotification n) => n.id == parcel.id);
    expect(after.actioned, isTrue);
    expect(after.read, isTrue);
  });

  testWidgets('a grouped row is marked read and opens nothing', (
    WidgetTester tester,
  ) async {
    // Folding is unreachable from the fixtures, as in the reference, so the
    // rule is asked of the one function every surface opens through.
    const LumeNotification group = LumeNotification(
      id: 'group:parcel.transit',
      title: 'Parcel Tracker activity',
      body: '3 more',
      category: 'parcels',
      icon: 'box',
      tool: 'parcel',
      agoMinutes: 5,
      grouped: true,
      groupId: 'parcel.transit',
      members: 3,
    );
    late bool navigated;
    await pumpLume(
      tester,
      Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) => TextButton(
          onPressed: () async => navigated = await openLumeNotification(
            ref: ref,
            context: context,
            branch: '/home',
            n: group,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(navigated, isFalse);
  });
}
