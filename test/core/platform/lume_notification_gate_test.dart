/// The notification permission's state, from what each platform reports and
/// nothing else — the camera gate's own discipline
/// (`REMINDERS_PROPOSAL.md` §4), extended to a second platform with its own,
/// genuinely different fact shape.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_notification_gate.dart';

void main() {
  group('Android facts, classified', () {
    LumeNotificationAccess of(LumeNotificationFacts f) =>
        LumeNotificationAccess.classify(f);

    test('granted and interrupted', () {
      expect(
        of(const LumeNotificationFacts(granted: true)),
        LumeNotificationAccess.granted,
      );
      expect(
        of(const LumeNotificationFacts(requested: true, interrupted: true)),
        LumeNotificationAccess.interrupted,
      );
    });

    test('a check: first request, denied, blocked, undetermined', () {
      expect(
        of(const LumeNotificationFacts()),
        LumeNotificationAccess.firstRequest,
      );
      expect(
        of(const LumeNotificationFacts(asked: true, rationale: true)),
        LumeNotificationAccess.denied,
      );
      expect(
        of(const LumeNotificationFacts(asked: true, sawRationale: true)),
        LumeNotificationAccess.blocked,
      );
      expect(
        of(const LumeNotificationFacts(asked: true)),
        LumeNotificationAccess.undetermined,
      );
    });

    test('a request refused: will ask again, stopped asking, or unknown', () {
      expect(
        of(
          const LumeNotificationFacts(
            requested: true,
            asked: true,
            rationale: true,
          ),
        ),
        LumeNotificationAccess.denied,
      );
      expect(
        of(
          const LumeNotificationFacts(
            requested: true,
            asked: true,
            rationaleBefore: true,
          ),
        ),
        LumeNotificationAccess.blocked,
      );
      expect(
        of(const LumeNotificationFacts(requested: true, asked: true)),
        LumeNotificationAccess.undetermined,
      );
    });

    test(
      'below API 33: granted is reported true unconditionally by the native side, not guessed here',
      () {
        // classify() only ever sees what the platform reports; a pre-33
        // device's native side is expected to send granted: true itself.
        expect(
          of(const LumeNotificationFacts(granted: true, sdk: 30)),
          LumeNotificationAccess.granted,
        );
      },
    );
  });

  group('iOS facts, classified', () {
    LumeNotificationAccess of(LumeIosNotificationFacts f) =>
        LumeNotificationAccess.classifyIos(f);

    test('granted, not determined, denied', () {
      expect(
        of(const LumeIosNotificationFacts(granted: true)),
        LumeNotificationAccess.granted,
      );
      expect(
        of(const LumeIosNotificationFacts(notDetermined: true)),
        LumeNotificationAccess.firstRequest,
      );
      expect(
        of(const LumeIosNotificationFacts(denied: true)),
        LumeNotificationAccess.blocked,
      );
    });
  });

  group('Settings is offered only where it can change the state', () {
    test('blocked and undetermined, and nothing else', () {
      expect(
        <LumeNotificationAccess>[
          for (final LumeNotificationAccess a in LumeNotificationAccess.values)
            if (a.settingsHelp) a,
        ],
        <LumeNotificationAccess>[
          LumeNotificationAccess.blocked,
          LumeNotificationAccess.undetermined,
        ],
      );
    });
  });

  group('the Android gate, over its channel', () {
    const MethodChannel channel = MethodChannel('lume/notification_permission');
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

    test(
      'a request is classified from what the channel reports, exact-alarm carried through',
      () async {
        final List<String> calls = <String>[];
        answer((MethodCall c) {
          calls.add(c.method);
          return <String, Object?>{
            'granted': false,
            'asked': true,
            'requested': true,
            'rationaleBefore': true,
            'canScheduleExactAlarms': false,
          };
        });
        final LumeNotificationState s =
            await const LumeAndroidNotificationGate().request();
        expect(s.access, LumeNotificationAccess.blocked);
        expect(s.canScheduleExact, isFalse);
        expect(calls, <String>['request']);
      },
    );

    test('a check can say "first request"; a request never does', () async {
      answer((MethodCall c) => <String, Object?>{'asked': false});
      expect(
        (await const LumeAndroidNotificationGate().check()).access,
        LumeNotificationAccess.firstRequest,
      );
      expect(
        (await const LumeAndroidNotificationGate().request()).access,
        LumeNotificationAccess.failed,
      );
    });

    test('a channel that throws, or answers nothing, is a failure', () async {
      answer((MethodCall c) => throw PlatformException(code: 'busy'));
      expect(
        (await const LumeAndroidNotificationGate().request()).access,
        LumeNotificationAccess.failed,
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      expect(
        (await const LumeAndroidNotificationGate().request()).access,
        LumeNotificationAccess.failed,
        reason: 'no handler at all',
      );
    });

    test(
      'openExactAlarmSettings calls the channel and never throws outward',
      () async {
        final List<String> calls = <String>[];
        answer((MethodCall c) {
          calls.add(c.method);
          return null;
        });
        await const LumeAndroidNotificationGate().openExactAlarmSettings();
        expect(calls, <String>['requestExactAlarm']);
      },
    );
  });

  group('the iOS gate, over its own channel', () {
    const MethodChannel channel = MethodChannel(
      'lume/notification_permission_ios',
    );
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    tearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    test(
      'classified from the channel, and exact-alarm is always available',
      () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (MethodCall call) async => <String, Object?>{'denied': true},
        );
        final LumeNotificationState s = await const LumeIosNotificationGate()
            .check();
        expect(s.access, LumeNotificationAccess.blocked);
        expect(s.canScheduleExact, isTrue);
      },
    );

    test('openExactAlarmSettings is a no-op on iOS', () async {
      await const LumeIosNotificationGate().openExactAlarmSettings();
    });
  });

  group('the fake gate, for tests', () {
    test('records what it was asked and answers what it is told', () async {
      final LumeFakeNotificationGate gate = LumeFakeNotificationGate(
        now: const LumeNotificationState(LumeNotificationAccess.firstRequest),
        answer: const LumeNotificationState(LumeNotificationAccess.granted),
      );
      expect((await gate.check()).access, LumeNotificationAccess.firstRequest);
      expect((await gate.request()).access, LumeNotificationAccess.granted);
      expect((await gate.check()).access, LumeNotificationAccess.granted);
      expect(gate.asked, <String>['check', 'request', 'check']);
    });
  });

  group('unavailable — a platform this feature has no gate for', () {
    test(
      'always reports unavailable, and openExactAlarmSettings is a no-op',
      () async {
        const LumeUnavailableNotificationGate gate =
            LumeUnavailableNotificationGate();
        expect((await gate.check()).access, LumeNotificationAccess.unavailable);
        expect(
          (await gate.request()).access,
          LumeNotificationAccess.unavailable,
        );
        await gate.openExactAlarmSettings();
      },
    );
  });
}
