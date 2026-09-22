/// Driving a widget through the app going away and coming back.
///
/// `AppLifecycleListener` asserts on the order: a state may only follow
/// certain others, so the short hops a test reaches for — `inactive` to
/// `paused`, or `paused` straight back to `resumed` — trip the framework
/// rather than the tool. Three wave-3 tools each wrote their own walk and
/// each got it wrong in the same way, so the walk lives here once.
///
/// Android and iOS both pass through `hidden` in each direction; these
/// are the sequences the framework's own assertions describe.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Away: `inactive` → `hidden` → `paused`.
const List<AppLifecycleState> kLumeGoingAway = <AppLifecycleState>[
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];

/// Back: `hidden` → `inactive` → `resumed`.
const List<AppLifecycleState> kLumeComingBack = <AppLifecycleState>[
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

/// Send [states] to the binding, pumping once at the end.
Future<void> lumeLifecycle(
  WidgetTester tester,
  List<AppLifecycleState> states, {
  bool pump = true,
}) async {
  for (final AppLifecycleState state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  if (pump) await tester.pump();
}

/// Put the app in the background.
Future<void> lumeGoAway(WidgetTester tester, {bool pump = true}) =>
    lumeLifecycle(tester, kLumeGoingAway, pump: pump);

/// Bring it back.
Future<void> lumeComeBack(WidgetTester tester, {bool pump = true}) =>
    lumeLifecycle(tester, kLumeComingBack, pump: pump);

/// Away and back, with [whileAway] run in between — advance a clock
/// there to prove what a tool does with the time it could not see.
Future<void> lumeRoundTrip(
  WidgetTester tester, {
  Future<void> Function()? whileAway,
}) async {
  await lumeGoAway(tester);
  await whileAway?.call();
  await lumeComeBack(tester);
}
