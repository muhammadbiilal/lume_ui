/// The one file that knows how the dialer is opened on a device.
///
/// `url_launcher` hands `tel:<digits>` to the platform: Android resolves it to
/// the dialer (`ACTION_VIEW`, no `CALL_PHONE` permission, nothing dialled until
/// the reader presses call); iOS shows its own call prompt. The dependency is
/// justified in `pubspec.yaml` and reaches nothing else in the app (D6).
library;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'lume_dialer.dart';

/// Asks whether a `tel:` URI can be opened. A parameter so the adapter's own
/// mapping can be tested without a platform.
typedef LumeCanOpen = Future<bool> Function(Uri uri);

/// Opens a `tel:` URI in the platform's dialer.
typedef LumeOpen = Future<bool> Function(Uri uri);

Future<bool> _open(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class LumePlatformDialer implements LumeDialer {
  const LumePlatformDialer({
    LumeCanOpen canOpen = canLaunchUrl,
    LumeOpen open = _open,
  }) : _canOpen = canOpen,
       _openUri = open;

  final LumeCanOpen _canOpen;
  final LumeOpen _openUri;

  /// Never answers [LumeDialOutcome.cancelled]: the plugin reports whether the
  /// hand-off happened, not what the reader did after it.
  @override
  Future<LumeDialOutcome> dial(String shown) async {
    final LumeDialNumber? number = LumeDialNumber.parse(shown);
    if (number == null) return LumeDialOutcome.malformed;
    try {
      if (!await _canOpen(number.uri)) return LumeDialOutcome.unavailable;
      return await _openUri(number.uri)
          ? LumeDialOutcome.opened
          : LumeDialOutcome.failed;
    } on PlatformException {
      return LumeDialOutcome.failed;
    } on MissingPluginException {
      return LumeDialOutcome.unavailable;
    }
  }
}
