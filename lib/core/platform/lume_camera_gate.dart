/// Whether the camera may be used, as the platform says it (C80, F6B closure).
///
/// Android reports two things about a refused permission: whether it is
/// granted, and `shouldShowRequestPermissionRationale` — true once the reader
/// has refused and Android will still ask. On its own that cannot tell a first
/// request from "don't ask again", so the native side (`LumeCameraPermission.kt`)
/// also reports what it has seen on this install. [LumeCameraAccess.classify]
/// turns those facts into a state, and where the facts do not decide it the
/// state is [LumeCameraAccess.undetermined] — never a guess, and never timed.
///
/// Widgets and view models see only a [LumeScanner]; this contract is used by
/// the scanner adapter alone.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the camera permission is, or what became of asking for it.
enum LumeCameraAccess {
  /// The camera may be used.
  granted,

  /// Lume has never asked: pressing Scan will show Android's dialog.
  firstRequest,

  /// Refused, and Android will ask again the next time Scan is pressed.
  denied,

  /// Refused for good ("don't ask again", or Android's second refusal): only
  /// Settings can change it.
  blocked,

  /// A device policy has turned the camera off. Settings cannot change it.
  restricted,

  /// Refused, and nothing Android reports says whether it will ask again —
  /// a dialog dismissed without an answer, or a refusal Android made without
  /// asking. Scan may ask again; Settings certainly can.
  undetermined,

  /// The request was cancelled before an answer (Android's empty result).
  interrupted,

  /// This device has no camera.
  unavailable,

  /// The adapter itself failed.
  failed;

  /// Settings can change this state.
  bool get settingsHelp => this == blocked || this == undetermined;

  /// The state these facts support.
  static LumeCameraAccess classify(LumeCameraFacts f) {
    if (!f.hasCamera) return unavailable;
    if (f.policyDisabled) return restricted;
    if (f.granted) return granted;
    if (f.interrupted) return interrupted;
    // Android will explain and ask again.
    if (f.rationale) return denied;
    if (!f.requested) {
      if (!f.asked) return firstRequest;
      // It said once it would ask again, and now says it will not.
      return f.sawRationale ? blocked : undetermined;
    }
    // A request was refused and Android will not explain. If it would have
    // asked again before this request, it has stopped: that is for good.
    if (f.rationaleBefore || f.sawRationaleBefore) return blocked;
    return undetermined;
  }
}

/// What the native side reports, as it reports it.
@immutable
class LumeCameraFacts {
  const LumeCameraFacts({
    this.sdk = 0,
    this.hasCamera = true,
    this.policyDisabled = false,
    this.granted = false,
    this.rationale = false,
    this.asked = false,
    this.sawRationale = false,
    this.requested = false,
    this.rationaleBefore = false,
    this.sawRationaleBefore = false,
    this.interrupted = false,
  });

  factory LumeCameraFacts.fromMap(Map<Object?, Object?> m) {
    bool b(String k) => m[k] == true;
    return LumeCameraFacts(
      sdk: (m['sdk'] as num?)?.toInt() ?? 0,
      hasCamera: m['hasCamera'] != false,
      policyDisabled: b('policyDisabled'),
      granted: b('granted'),
      rationale: b('rationale'),
      asked: b('asked'),
      sawRationale: b('sawRationale'),
      requested: b('requested'),
      rationaleBefore: b('rationaleBefore'),
      sawRationaleBefore: b('sawRationaleBefore'),
      interrupted: b('interrupted'),
    );
  }

  final int sdk;
  final bool hasCamera;

  /// `DevicePolicyManager.getCameraDisabled`.
  final bool policyDisabled;
  final bool granted;

  /// `shouldShowRequestPermissionRationale`, now.
  final bool rationale;

  /// Lume has asked on this install.
  final bool asked;

  /// Android has said it would ask again, since the last grant.
  final bool sawRationale;

  /// These facts answer a request, not a check.
  final bool requested;
  final bool rationaleBefore;
  final bool sawRationaleBefore;
  final bool interrupted;
}

/// Asks the platform about the camera permission.
abstract interface class LumeCameraGate {
  /// The state now. Shows nothing.
  Future<LumeCameraAccess> check();

  /// Asks — Android shows its dialog when it will — and says what became of
  /// it. Never answers [LumeCameraAccess.firstRequest].
  Future<LumeCameraAccess> request();
}

/// The Android gate, over `lume/camera_permission`.
class LumeAndroidCameraGate implements LumeCameraGate {
  const LumeAndroidCameraGate([
    this._channel = const MethodChannel('lume/camera_permission'),
  ]);

  final MethodChannel _channel;

  Future<LumeCameraAccess> _ask(String method) async {
    try {
      final Map<Object?, Object?>? m = await _channel
          .invokeMapMethod<Object?, Object?>(method);
      if (m == null) return LumeCameraAccess.failed;
      final LumeCameraAccess access = LumeCameraAccess.classify(
        LumeCameraFacts.fromMap(m),
      );
      // A request always asks; a first request is not an answer.
      return method == 'request' && access == LumeCameraAccess.firstRequest
          ? LumeCameraAccess.failed
          : access;
    } on PlatformException {
      return LumeCameraAccess.failed;
    } on MissingPluginException {
      return LumeCameraAccess.failed;
    }
  }

  @override
  Future<LumeCameraAccess> check() => _ask('check');

  @override
  Future<LumeCameraAccess> request() => _ask('request');
}

/// A gate that answers what it is told and records what it was asked, for
/// tests. Never touches a platform.
class LumeFakeCameraGate implements LumeCameraGate {
  LumeFakeCameraGate({
    this.now = LumeCameraAccess.firstRequest,
    this.answer = LumeCameraAccess.granted,
  });

  LumeCameraAccess now;
  LumeCameraAccess answer;
  final List<String> asked = <String>[];

  @override
  Future<LumeCameraAccess> check() async {
    asked.add('check');
    return now;
  }

  @override
  Future<LumeCameraAccess> request() async {
    asked.add('request');
    now = answer;
    return answer;
  }
}
