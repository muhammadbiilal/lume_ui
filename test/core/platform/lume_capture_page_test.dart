/// The capture page decides when a camera may exist: only while the page is
/// seen, in Lume's own states, and never kept past a result (C80).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_capture_page.dart';
import 'package:lume/core/platform/lume_scanner.dart';

import '../../helpers/lume_harness.dart';

/// Stands in for the camera package: counts each camera opened and hands the
/// test the page's events.
class _Camera {
  int opened = 0;
  LumeCameraEvents? events;

  static const Key key = ValueKey<String>('fake.camera');

  Widget view(BuildContext context, LumeCameraEvents e, double side) {
    events = e;
    return _View(onOpen: () => opened++);
  }
}

class _View extends StatefulWidget {
  const _View({required this.onOpen});
  final VoidCallback onOpen;
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  @override
  void initState() {
    super.initState();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(key: _Camera.key, color: Color(0xFF223344));
}

Future<(Future<LumeScanResult>, _Camera, NavigatorState)> open(
  WidgetTester tester, {
  Duration startLimit = LumeCapturePage.defaultStartLimit,
}) async {
  late BuildContext host;
  await pumpLume(tester, LumeProbe(onBuild: (BuildContext c) => host = c));
  addTearDown(
    () => tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    ),
  );
  final _Camera camera = _Camera();
  final NavigatorState navigator = Navigator.of(host);
  final Future<LumeScanResult> result = showLumeCapture(
    navigator,
    camera: camera.view,
    startLimit: startLimit,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return (result, camera, navigator);
}

String status(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(LumeCapturePage.statusKey),
        matching: find.byType(Text),
      ),
    )
    .data!;

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('starts, then says what to do once the camera shows', (
    WidgetTester tester,
  ) async {
    final (_, _Camera camera, _) = await open(tester);
    expect(find.byKey(_Camera.key), findsOneWidget);
    expect(camera.opened, 1);
    expect(status(tester), 'Starting the camera…');
    expect(find.text('Scan a QR code'), findsOneWidget);
    // A route of its own still sets text in Lume's type, not Flutter's
    // no-Material error style (the yellow underline a device showed).
    for (final String text in <String>[
      'Scan a QR code',
      'Starting the camera…',
    ]) {
      final Element e = tester.element(find.text(text));
      final TextStyle effective = DefaultTextStyle.of(
        e,
      ).style.merge(tester.widget<Text>(find.text(text)).style);
      expect(
        effective.decoration,
        isNot(TextDecoration.underline),
        reason: text,
      );
      expect(
        find.ancestor(of: find.text(text), matching: find.byType(Material)),
        findsWidgets,
        reason: text,
      );
    }

    camera.events!.onLive();
    await tester.pump();
    expect(status(tester), 'Point the camera at a code');
  });

  testWidgets('a QR code ends the page with its text, and the camera goes', (
    WidgetTester tester,
  ) async {
    final (Future<LumeScanResult> result, _Camera camera, _) = await open(
      tester,
    );
    camera.events!.onLive();
    camera.events!.onCode('https://lume.app', isQr: true);
    await settle(tester);
    expect(
      await result,
      const LumeScanResult(LumeScanOutcome.read, 'https://lume.app'),
    );
    expect(find.byType(LumeCapturePage), findsNothing);
    expect(find.byKey(_Camera.key), findsNothing);
  });

  testWidgets('a code that is not a QR code is said, and scanning goes on', (
    WidgetTester tester,
  ) async {
    final (_, _Camera camera, _) = await open(tester);
    camera.events!.onLive();
    camera.events!.onCode('5012345678900', isQr: false);
    await tester.pump();
    expect(status(tester), "That isn't a QR code. Lume reads QR codes.");
    expect(find.byType(LumeCapturePage), findsOneWidget);
    expect(camera.opened, 1);
  });

  testWidgets('Close and Back are cancelled, not failures', (
    WidgetTester tester,
  ) async {
    final (Future<LumeScanResult> closed, _, _) = await open(tester);
    await tester.tap(find.byKey(LumeCapturePage.closeKey));
    await settle(tester);
    expect((await closed).outcome, LumeScanOutcome.cancelled);

    final (Future<LumeScanResult> back, _, _) = await open(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect((await back).outcome, LumeScanOutcome.cancelled);
  });

  testWidgets('in the background the camera is closed, and a new one opens '
      'on return', (WidgetTester tester) async {
    final (_, _Camera camera, _) = await open(tester);
    camera.events!.onLive();
    await tester.pump();

    for (final AppLifecycleState s in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(find.byKey(_Camera.key), findsNothing);
    expect(status(tester), 'Camera paused');

    for (final AppLifecycleState s in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(find.byKey(_Camera.key), findsOneWidget);
    expect(camera.opened, 2);
    expect(status(tester), 'Starting the camera…');
  });

  testWidgets('a permission prompt does not close the camera', (
    WidgetTester tester,
  ) async {
    final (_, _Camera camera, _) = await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(_Camera.key), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(camera.opened, 1);
  });

  testWidgets('a page over it closes the camera until it is seen again', (
    WidgetTester tester,
  ) async {
    final (_, _Camera camera, NavigatorState navigator) = await open(tester);
    navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => const SizedBox.expand()),
    );
    await settle(tester);
    expect(find.byKey(_Camera.key, skipOffstage: false), findsNothing);

    navigator.pop();
    await settle(tester);
    expect(find.byKey(_Camera.key), findsOneWidget);
    expect(camera.opened, 2);
  });

  // Android makes Lume inactive for a refused prompt and for a refusal it
  // no longer asks about alike (the F6B device walk: 4.7 s and 0.53 s), so
  // the page guesses neither way: a refusal is what the camera said.
  for (final bool prompted in <bool>[true, false]) {
    for (final LumeScanOutcome said in <LumeScanOutcome>[
      LumeScanOutcome.denied,
      LumeScanOutcome.blocked,
    ]) {
      testWidgets('refused as $said, prompt shown: $prompted — passed on as '
          'said', (WidgetTester tester) async {
        final (Future<LumeScanResult> result, _Camera camera, _) = await open(
          tester,
        );
        if (prompted) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
        camera.events!.onTrouble(said);
        await settle(tester);
        expect((await result).outcome, said);
      });
    }
  }

  testWidgets('a camera that fails to start ends the page', (
    WidgetTester tester,
  ) async {
    final (Future<LumeScanResult> result, _Camera camera, _) = await open(
      tester,
    );
    camera.events!.onTrouble(LumeScanOutcome.failed);
    await settle(tester);
    expect((await result).outcome, LumeScanOutcome.failed);
  });

  testWidgets('a camera that never shows a picture is unavailable', (
    WidgetTester tester,
  ) async {
    final (Future<LumeScanResult> result, _, _) = await open(
      tester,
      startLimit: const Duration(seconds: 2),
    );
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect((await result).outcome, LumeScanOutcome.unavailable);
  });

  testWidgets('time away does not count against the start', (
    WidgetTester tester,
  ) async {
    final (_, _Camera camera, _) = await open(
      tester,
      startLimit: const Duration(seconds: 2),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LumeCapturePage), findsOneWidget);
    camera.events!.onLive();
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(LumeCapturePage), findsOneWidget);
  });

  testWidgets('in Urdu, at 200 %', (WidgetTester tester) async {
    late BuildContext host;
    await pumpLume(
      tester,
      LumeProbe(onBuild: (BuildContext c) => host = c),
      locale: const Locale('ur'),
      textScale: 2,
    );
    final _Camera camera = _Camera();
    showLumeCapture(Navigator.of(host), camera: camera.view);
    await settle(tester);
    camera.events!.onCode('123', isQr: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
