/// Handing a checked address to the app that opens it — on a press, never by
/// itself (C80).
///
/// A [LumeLinkOpener] opens only what [LumeLinkOpener.allows]: a web address
/// with a host, a `mailto:` to one address, an `sms:` to one number. The
/// dialer has its own contract (`LumeDialer`). Everything else is refused
/// before a platform is asked, whoever asks.
library;

import 'package:flutter/foundation.dart';

enum LumeOpenOutcome {
  /// The platform took the address. What the reader then does is theirs.
  opened,

  /// Nothing on this device opens it.
  unavailable,

  /// Not an address Lume opens; the platform was not asked.
  refused,

  /// The platform was asked and threw.
  failed,
}

abstract interface class LumeLinkOpener {
  Future<LumeOpenOutcome> open(Uri uri);

  /// The allowlist, checked again at the door whatever the caller checked.
  static bool allows(Uri uri) => switch (uri.scheme) {
    'https' || 'http' => uri.host.isNotEmpty && uri.userInfo.isEmpty,
    'mailto' => uri.path.contains('@') && !uri.hasQuery,
    'sms' => RegExp(r'^\+?[0-9]{2,15}$').hasMatch(uri.path) && !uri.hasQuery,
    _ => false,
  };
}

/// Records every request and answers with [outcome]. Never touches the
/// platform.
class LumeRecordingLinkOpener implements LumeLinkOpener {
  LumeRecordingLinkOpener({this.outcome = LumeOpenOutcome.opened});

  LumeOpenOutcome outcome;

  /// Every address that passed the allowlist, in order.
  final List<Uri> opened = <Uri>[];

  /// Every request, refused ones included.
  final List<Uri> requested = <Uri>[];

  @override
  Future<LumeOpenOutcome> open(Uri uri) async {
    requested.add(uri);
    if (!LumeLinkOpener.allows(uri)) return LumeOpenOutcome.refused;
    opened.add(uri);
    return outcome;
  }
}

@visibleForTesting
const Set<String> lumeOpenableSchemes = <String>{
  'https',
  'http',
  'mailto',
  'sms',
};
