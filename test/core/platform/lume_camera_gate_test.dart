/// The camera permission's state, from what Android reports and nothing else
/// (C80, F6B closure). No state here is inferred from how long anything took:
/// [LumeCameraAccess.classify] is a function of the facts alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_camera_gate.dart';
import 'package:lume/core/platform/lume_capture_page.dart';
import 'package:lume/core/platform/lume_scanner.dart';
import 'package:lume/core/platform/lume_scanner_platform.dart';

import '../../helpers/lume_harness.dart';

/// Android's own behaviour, step by step, as the native side records it: a
/// refusal on API 29 and below sets the rationale; "Don't ask again" (29 and
/// below) or a second refusal (30 and above) clears it; a dialog dismissed on
/// 30 and above leaves it as it was.
class _Android {
  _Android({this.autoBlocksAfterTwo = true});

  final bool autoBlocksAfterTwo;
  bool granted = false;
  bool rationale = false;
  bool asked = false;
  bool sawRationale = false;
  int refusals = 0;
  bool blocked = false;

  LumeCameraFacts facts({
    bool requested = false,
    bool rationaleBefore = false,
    bool sawRationaleBefore = false,
    bool interrupted = false,
  }) {
    if (granted) sawRationale = false;
    if (rationale) sawRationale = true;
    return LumeCameraFacts(
      granted: granted,
      rationale: rationale,
      asked: asked,
      sawRationale: sawRationale,
      requested: requested,
      rationaleBefore: rationaleBefore,
      sawRationaleBefore: sawRationaleBefore,
      interrupted: interrupted,
    );
  }

  /// One press of Scan. [answer] is what the reader does with the dialog, if
  /// Android shows one: 'allow', 'deny', 'never' (API ≤ 29's box), 'dismiss'.
  LumeCameraAccess request(String answer) {
    final LumeCameraFacts before = facts();
    asked = true;
    if (!blocked) {
      switch (answer) {
        case 'allow':
          granted = true;
          rationale = false;
        case 'deny':
          refusals++;
          if (autoBlocksAfterTwo && refusals >= 2) {
            blocked = true;
            rationale = false;
          } else {
            rationale = true;
          }
        case 'never':
          blocked = true;
          rationale = false;
        case 'dismiss':
          break;
      }
    }
    return LumeCameraAccess.classify(
      facts(
        requested: true,
        rationaleBefore: before.rationale,
        sawRationaleBefore: before.sawRationale,
      ),
    );
  }

  LumeCameraAccess check() => LumeCameraAccess.classify(facts());
}

void main() {
  group('every state, from the facts', () {
    LumeCameraAccess of(LumeCameraFacts f) => LumeCameraAccess.classify(f);

    test('no camera, a policy, a grant and an interrupted request', () {
      expect(
        of(const LumeCameraFacts(hasCamera: false)),
        LumeCameraAccess.unavailable,
      );
      expect(
        of(const LumeCameraFacts(policyDisabled: true, granted: true)),
        LumeCameraAccess.restricted,
        reason: 'a device policy wins over a grant',
      );
      expect(
        of(const LumeCameraFacts(granted: true)),
        LumeCameraAccess.granted,
      );
      expect(
        of(const LumeCameraFacts(requested: true, interrupted: true)),
        LumeCameraAccess.interrupted,
      );
    });

    test('a check: first request, denied, blocked, undetermined', () {
      expect(of(const LumeCameraFacts()), LumeCameraAccess.firstRequest);
      expect(
        of(const LumeCameraFacts(asked: true, rationale: true)),
        LumeCameraAccess.denied,
      );
      expect(
        of(const LumeCameraFacts(asked: true, sawRationale: true)),
        LumeCameraAccess.blocked,
      );
      expect(
        of(const LumeCameraFacts(asked: true)),
        LumeCameraAccess.undetermined,
      );
    });

    test('a request refused: will ask again, stopped asking, or unknown', () {
      expect(
        of(
          const LumeCameraFacts(requested: true, asked: true, rationale: true),
        ),
        LumeCameraAccess.denied,
      );
      expect(
        of(
          const LumeCameraFacts(
            requested: true,
            asked: true,
            rationaleBefore: true,
          ),
        ),
        LumeCameraAccess.blocked,
      );
      expect(
        of(
          const LumeCameraFacts(
            requested: true,
            asked: true,
            sawRationaleBefore: true,
          ),
        ),
        LumeCameraAccess.blocked,
      );
      expect(
        of(const LumeCameraFacts(requested: true, asked: true)),
        LumeCameraAccess.undetermined,
      );
    });

    test('Settings is offered only where it can change the state', () {
      expect(
        <LumeCameraAccess>[
          for (final LumeCameraAccess a in LumeCameraAccess.values)
            if (a.settingsHelp) a,
        ],
        <LumeCameraAccess>[
          LumeCameraAccess.blocked,
          LumeCameraAccess.undetermined,
        ],
      );
    });
  });

  group('Android, as it behaves', () {
    test('API 30 and above: refused, refused again — blocked', () {
      final _Android a = _Android();
      expect(a.check(), LumeCameraAccess.firstRequest);
      expect(a.request('deny'), LumeCameraAccess.denied);
      expect(a.check(), LumeCameraAccess.denied);
      expect(a.request('deny'), LumeCameraAccess.blocked);
      expect(a.check(), LumeCameraAccess.blocked);
      // Android shows nothing now, and still it is known.
      expect(a.request('deny'), LumeCameraAccess.blocked);
    });

    test('API 29 and below: refused, then "Don\'t ask again" — blocked', () {
      final _Android a = _Android(autoBlocksAfterTwo: false);
      expect(a.request('deny'), LumeCameraAccess.denied);
      expect(a.request('deny'), LumeCameraAccess.denied);
      expect(a.request('never'), LumeCameraAccess.blocked);
      expect(a.check(), LumeCameraAccess.blocked);
    });

    test('a first dialog dismissed is undetermined, and asked again', () {
      final _Android a = _Android();
      expect(a.request('dismiss'), LumeCameraAccess.undetermined);
      expect(a.check(), LumeCameraAccess.undetermined);
      expect(a.request('deny'), LumeCameraAccess.denied);
    });

    test('allowed after a refusal: the history starts again', () {
      final _Android a = _Android();
      expect(a.request('deny'), LumeCameraAccess.denied);
      expect(a.request('allow'), LumeCameraAccess.granted);
      expect(a.sawRationale, isFalse);
    });
  });

  group('the Android gate, over its channel', () {
    const MethodChannel channel = MethodChannel('lume/camera_permission');
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    tearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    void answer(Object? Function(MethodCall call) reply) =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (MethodCall call) async => reply(call),
        );

    test('a request is classified from what the channel reports', () async {
      final List<String> calls = <String>[];
      answer((MethodCall c) {
        calls.add(c.method);
        return <String, Object?>{
          'sdk': 36,
          'hasCamera': true,
          'granted': false,
          'rationale': false,
          'asked': true,
          'requested': true,
          'rationaleBefore': true,
        };
      });
      expect(
        await const LumeAndroidCameraGate().request(),
        LumeCameraAccess.blocked,
      );
      expect(calls, <String>['request']);
    });

    test('a check can say "first request"; a request never does', () async {
      answer((MethodCall c) => <String, Object?>{'asked': false});
      expect(
        await const LumeAndroidCameraGate().check(),
        LumeCameraAccess.firstRequest,
      );
      expect(
        await const LumeAndroidCameraGate().request(),
        LumeCameraAccess.failed,
      );
    });

    test('a channel that throws, or answers nothing, is a failure', () async {
      answer((MethodCall c) => throw PlatformException(code: 'busy'));
      expect(
        await const LumeAndroidCameraGate().request(),
        LumeCameraAccess.failed,
      );
      answer((MethodCall c) => null);
      expect(
        await const LumeAndroidCameraGate().request(),
        LumeCameraAccess.failed,
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      expect(
        await const LumeAndroidCameraGate().request(),
        LumeCameraAccess.failed,
        reason: 'no handler at all',
      );
    });
  });

  group('the scanner asks the gate before the camera', () {
    Future<(LumePlatformScanner, NavigatorState)> scanner(
      WidgetTester tester,
      LumeCameraGate? gate,
    ) async {
      late BuildContext host;
      await pumpLume(tester, LumeProbe(onBuild: (BuildContext c) => host = c));
      final NavigatorState nav = Navigator.of(host);
      return (
        LumePlatformScanner(
          navigator: () => nav,
          gate: gate,
          camera: (BuildContext c, LumeCameraEvents e, double s) =>
              const SizedBox(),
        ),
        nav,
      );
    }

    for (final (LumeCameraAccess access, LumeScanOutcome outcome)
        in <(LumeCameraAccess, LumeScanOutcome)>[
          (LumeCameraAccess.denied, LumeScanOutcome.denied),
          (LumeCameraAccess.blocked, LumeScanOutcome.blocked),
          (LumeCameraAccess.restricted, LumeScanOutcome.restricted),
          (LumeCameraAccess.undetermined, LumeScanOutcome.undetermined),
          (LumeCameraAccess.interrupted, LumeScanOutcome.cancelled),
          (LumeCameraAccess.unavailable, LumeScanOutcome.unavailable),
          (LumeCameraAccess.failed, LumeScanOutcome.failed),
          (LumeCameraAccess.firstRequest, LumeScanOutcome.failed),
        ]) {
      testWidgets('$access: said as $outcome, and no camera opens', (
        WidgetTester tester,
      ) async {
        final LumeFakeCameraGate gate = LumeFakeCameraGate(answer: access);
        final (LumePlatformScanner s, _) = await scanner(tester, gate);
        expect((await s.scan()).outcome, outcome);
        await tester.pump();
        expect(find.byType(LumeCapturePage), findsNothing);
        expect(gate.asked, <String>['request']);
      });
    }

    testWidgets('granted: the capture page opens', (WidgetTester tester) async {
      final LumeFakeCameraGate gate = LumeFakeCameraGate();
      final (LumePlatformScanner s, NavigatorState nav) = await scanner(
        tester,
        gate,
      );
      final Future<LumeScanResult> result = s.scan();
      // The gate answers first; the page is pushed on the frame after.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LumeCapturePage), findsOneWidget);
      nav.pop();
      expect((await result).outcome, LumeScanOutcome.cancelled);
    });
  });
}
