/// The one file that knows how a checked address leaves Lume.
///
/// `url_launcher` hands the address to another app
/// (`LaunchMode.externalApplication`): the reader's browser, mail or messages
/// app. Never an in-app web view, so a page from a code cannot draw inside
/// Lume's frame.
library;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'lume_link_opener.dart';

/// Opens a URI in another app. A parameter so the mapping can be tested
/// without a platform.
typedef LumeLaunch = Future<bool> Function(Uri uri);

Future<bool> _launch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class LumePlatformLinkOpener implements LumeLinkOpener {
  const LumePlatformLinkOpener({LumeLaunch launch = _launch})
    : _launchUri = launch;

  final LumeLaunch _launchUri;

  @override
  Future<LumeOpenOutcome> open(Uri uri) async {
    if (!LumeLinkOpener.allows(uri)) return LumeOpenOutcome.refused;
    try {
      return await _launchUri(uri)
          ? LumeOpenOutcome.opened
          : LumeOpenOutcome.unavailable;
    } on MissingPluginException {
      return LumeOpenOutcome.unavailable;
    } on PlatformException {
      return LumeOpenOutcome.failed;
    }
  }
}
