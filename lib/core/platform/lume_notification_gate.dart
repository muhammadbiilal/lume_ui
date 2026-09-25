/// Whether Reminders may post a notification, as the platform reports it
/// (`REMINDERS_PROPOSAL.md` §4) — the camera gate's shape
/// (`lume_camera_gate.dart`), extended to a second platform.
///
/// Android and iOS report genuinely different things here, so this is two
/// channels and two fact shapes, not one channel with platform branches
/// inside it — the same choice `lume_camera_gate.dart`'s own comment makes
/// for staying Android-only rather than pretending to be cross-platform.
/// [LumeNotificationAccess.classify] and [LumeNotificationAccess.classifyIos]
/// are pure; nothing about a platform's reply is guessed.
///
/// Exact-alarm scheduling (Android 12+, `AlarmManager.canScheduleExactAlarms`)
/// is a second, independent fact, not a state in the same enum: Android gives
/// it no rationale, no dialog and no request result at all, only a Settings
/// screen and a boolean to poll afterward.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the notification permission is, or what became of asking for it.
enum LumeNotificationAccess {
  granted,

  /// Lume has never asked: [LumeNotificationGate.request] will show the
  /// platform's dialog.
  firstRequest,

  /// Refused, and the platform will still show its own dialog again.
  denied,

  /// Refused for good — only Settings can change it. Every iOS refusal
  /// lands here: iOS shows its permission dialog once per install and
  /// never again on request, so a second `request()` would silently do
  /// nothing rather than honestly reflect what happened.
  blocked,

  /// Refused, and nothing the platform reports says whether it will ask
  /// again. Never a guess.
  undetermined,

  /// The request was cancelled before an answer.
  interrupted,

  /// This platform has no notification gate at all.
  unavailable,

  /// The adapter itself failed.
  failed;

  bool get settingsHelp => this == blocked || this == undetermined;

  /// Android's facts, classified exactly as `LumeCameraAccess.classify` is —
  /// same shape, same reasoning, a different permission.
  static LumeNotificationAccess classify(LumeNotificationFacts f) {
    if (f.granted) return granted;
    if (f.interrupted) return interrupted;
    if (f.rationale) return denied;
    if (!f.requested) {
      if (!f.asked) return firstRequest;
      return f.sawRationale ? blocked : undetermined;
    }
    if (f.rationaleBefore || f.sawRationaleBefore) return blocked;
    return undetermined;
  }

  /// iOS's facts. `UNAuthorizationStatus` is a complete enum on its own —
  /// there is no separate rationale/dialog signal to reconcile it with, and
  /// no "denied, will ask again" state exists on iOS at all.
  static LumeNotificationAccess classifyIos(LumeIosNotificationFacts f) {
    if (f.granted) return granted;
    // Checked before [LumeIosNotificationFacts.notDetermined]: that flag's
    // constructor default is `true` (an unset fact reads as "never asked"),
    // so a fact object built with only `denied: true` set must not be read
    // as undetermined just because nothing overrode the other default.
    if (f.denied) return blocked;
    if (f.notDetermined) return firstRequest;
    return undetermined;
  }
}

/// What Android's native side reports, as it reports it.
@immutable
class LumeNotificationFacts {
  const LumeNotificationFacts({
    this.sdk = 0,
    this.granted = false,
    this.rationale = false,
    this.asked = false,
    this.sawRationale = false,
    this.requested = false,
    this.rationaleBefore = false,
    this.sawRationaleBefore = false,
    this.interrupted = false,
    this.canScheduleExactAlarms = true,
  });

  factory LumeNotificationFacts.fromMap(Map<Object?, Object?> m) {
    bool b(String k, {bool fallback = false}) =>
        m.containsKey(k) ? m[k] == true : fallback;
    return LumeNotificationFacts(
      sdk: (m['sdk'] as num?)?.toInt() ?? 0,
      granted: b('granted'),
      rationale: b('rationale'),
      asked: b('asked'),
      sawRationale: b('sawRationale'),
      requested: b('requested'),
      rationaleBefore: b('rationaleBefore'),
      sawRationaleBefore: b('sawRationaleBefore'),
      interrupted: b('interrupted'),
      canScheduleExactAlarms: b('canScheduleExactAlarms', fallback: true),
    );
  }

  final int sdk;
  final bool granted;
  final bool rationale;
  final bool asked;
  final bool sawRationale;
  final bool requested;
  final bool rationaleBefore;
  final bool sawRationaleBefore;
  final bool interrupted;
  final bool canScheduleExactAlarms;
}

/// What iOS's native side reports, as it reports it.
@immutable
class LumeIosNotificationFacts {
  const LumeIosNotificationFacts({
    this.granted = false,
    this.denied = false,
    this.notDetermined = true,
  });

  factory LumeIosNotificationFacts.fromMap(Map<Object?, Object?> m) =>
      LumeIosNotificationFacts(
        granted: m['granted'] == true,
        denied: m['denied'] == true,
        notDetermined: m['notDetermined'] == true,
      );

  final bool granted;
  final bool denied;
  final bool notDetermined;
}

/// What Reminders asks about the notification permission, on either
/// platform: the state, and — Android only — whether exact-time scheduling
/// is available. `canScheduleExact` is always `true` on iOS, where no such
/// restriction exists.
@immutable
class LumeNotificationState {
  const LumeNotificationState(this.access, {this.canScheduleExact = true});

  final LumeNotificationAccess access;
  final bool canScheduleExact;
}

abstract interface class LumeNotificationGate {
  /// The state now. Shows nothing.
  Future<LumeNotificationState> check();

  /// Asks — the platform shows its dialog when it will. Never answers
  /// [LumeNotificationAccess.firstRequest].
  Future<LumeNotificationState> request();

  /// Opens the platform's own exact-alarm Settings screen (Android 12+
  /// only; a no-op on iOS, which has no such restriction). Android gives no
  /// callback for this: call [check] again after the reader returns.
  Future<void> openExactAlarmSettings();
}

/// The Android gate, over `lume/notification_permission`.
class LumeAndroidNotificationGate implements LumeNotificationGate {
  const LumeAndroidNotificationGate([
    this._channel = const MethodChannel('lume/notification_permission'),
  ]);

  final MethodChannel _channel;

  Future<LumeNotificationState> _ask(String method) async {
    try {
      final Map<Object?, Object?>? m = await _channel
          .invokeMapMethod<Object?, Object?>(method);
      if (m == null) {
        return const LumeNotificationState(LumeNotificationAccess.failed);
      }
      final LumeNotificationFacts facts = LumeNotificationFacts.fromMap(m);
      LumeNotificationAccess access = LumeNotificationAccess.classify(facts);
      if (method == 'request' && access == LumeNotificationAccess.firstRequest) {
        access = LumeNotificationAccess.failed;
      }
      return LumeNotificationState(access, canScheduleExact: facts.canScheduleExactAlarms);
    } on PlatformException {
      return const LumeNotificationState(LumeNotificationAccess.failed);
    } on MissingPluginException {
      return const LumeNotificationState(LumeNotificationAccess.failed);
    }
  }

  @override
  Future<LumeNotificationState> check() => _ask('check');

  @override
  Future<LumeNotificationState> request() => _ask('request');

  @override
  Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod<void>('requestExactAlarm');
    } on PlatformException {
      // Nothing to recover: the caller re-checks with [check].
    } on MissingPluginException {
      // Ditto.
    }
  }
}

/// The iOS gate, over `lume/notification_permission_ios`.
class LumeIosNotificationGate implements LumeNotificationGate {
  const LumeIosNotificationGate([
    this._channel = const MethodChannel('lume/notification_permission_ios'),
  ]);

  final MethodChannel _channel;

  Future<LumeNotificationState> _ask(String method) async {
    try {
      final Map<Object?, Object?>? m = await _channel
          .invokeMapMethod<Object?, Object?>(method);
      if (m == null) {
        return const LumeNotificationState(LumeNotificationAccess.failed);
      }
      final LumeIosNotificationFacts facts = LumeIosNotificationFacts.fromMap(m);
      return LumeNotificationState(LumeNotificationAccess.classifyIos(facts));
    } on PlatformException {
      return const LumeNotificationState(LumeNotificationAccess.failed);
    } on MissingPluginException {
      return const LumeNotificationState(LumeNotificationAccess.failed);
    }
  }

  @override
  Future<LumeNotificationState> check() => _ask('check');

  @override
  Future<LumeNotificationState> request() => _ask('request');

  /// No such restriction exists on iOS.
  @override
  Future<void> openExactAlarmSettings() async {}
}

/// Neither Android nor iOS — a build target this feature has no gate for.
class LumeUnavailableNotificationGate implements LumeNotificationGate {
  const LumeUnavailableNotificationGate();

  static const LumeNotificationState _state = LumeNotificationState(
    LumeNotificationAccess.unavailable,
  );

  @override
  Future<LumeNotificationState> check() async => _state;

  @override
  Future<LumeNotificationState> request() async => _state;

  @override
  Future<void> openExactAlarmSettings() async {}
}

/// A gate that answers what it is told and records what it was asked, for
/// tests. Never touches a platform.
class LumeFakeNotificationGate implements LumeNotificationGate {
  LumeFakeNotificationGate({
    this.now = const LumeNotificationState(LumeNotificationAccess.firstRequest),
    this.answer = const LumeNotificationState(LumeNotificationAccess.granted),
  });

  LumeNotificationState now;
  LumeNotificationState answer;
  final List<String> asked = <String>[];

  @override
  Future<LumeNotificationState> check() async {
    asked.add('check');
    return now;
  }

  @override
  Future<LumeNotificationState> request() async {
    asked.add('request');
    now = answer;
    return answer;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    asked.add('openExactAlarmSettings');
  }
}
