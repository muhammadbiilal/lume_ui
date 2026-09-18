/// Opening Lume's own page in the system's Settings (C80).
///
/// Android (`LumeAppSettings.kt`) opens `ACTION_APPLICATION_DETAILS_SETTINGS`
/// for Lume; iOS (`AppDelegate.swift`) opens
/// `UIApplication.openSettingsURLString`. Both answer whether the page opened,
/// and a failure is said, never assumed away. Widgets reach this only through
/// `LumeScanner.openSettings`.
library;

import 'package:flutter/services.dart';

/// Opens Lume's page in Settings.
abstract interface class LumeAppSettings {
  /// Whether the system opened it.
  Future<bool> open();
}

/// The platform's page, over `lume/app_settings`.
class LumeChannelAppSettings implements LumeAppSettings {
  const LumeChannelAppSettings([
    this._channel = const MethodChannel('lume/app_settings'),
  ]);

  final MethodChannel _channel;

  @override
  Future<bool> open() async {
    try {
      return await _channel.invokeMethod<bool>('open') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// Records each request and answers [opens], for tests.
class LumeRecordingAppSettings implements LumeAppSettings {
  LumeRecordingAppSettings({this.opens = true});

  bool opens;
  int opened = 0;

  @override
  Future<bool> open() async {
    opened++;
    return opens;
  }
}
