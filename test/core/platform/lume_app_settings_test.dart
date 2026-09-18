/// The Settings action: offered only where Lume's own Settings page can change
/// the camera, and honest about whether the page opened (C80, F6B closure).
///
/// The native halves are checked as source: this runs on neither Android nor
/// iOS. The Android half ran on emulators (API 29 and 36); the iOS half has
/// not run anywhere yet.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_app_settings.dart';
import 'package:lume/core/platform/lume_scanner.dart';
import 'package:lume/core/platform/lume_scanner_platform.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('lume/app_settings');
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );
  void answer(Object? Function(MethodCall) reply) => binding
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall c) async => reply(c));

  test('the channel: opened, not opened, threw, or absent', () async {
    final List<String> calls = <String>[];
    answer((MethodCall c) {
      calls.add(c.method);
      return true;
    });
    expect(await const LumeChannelAppSettings().open(), isTrue);
    expect(calls, <String>['open']);
    answer((MethodCall c) => false);
    expect(await const LumeChannelAppSettings().open(), isFalse);
    answer((MethodCall c) => null);
    expect(await const LumeChannelAppSettings().open(), isFalse);
    answer((MethodCall c) => throw PlatformException(code: 'x'));
    expect(await const LumeChannelAppSettings().open(), isFalse);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    expect(
      await const LumeChannelAppSettings().open(),
      isFalse,
      reason: 'no handler on this platform',
    );
  });

  LumePlatformScanner scanner(LumeAppSettings? settings) =>
      LumePlatformScanner(navigator: () => null, settings: settings);

  test('offered for blocked and undetermined only, and only with a page to '
      'open', () async {
    final LumeRecordingAppSettings page = LumeRecordingAppSettings(
      opens: false,
    );
    expect(
      <LumeScanOutcome>[
        for (final LumeScanOutcome o in LumeScanOutcome.values)
          if (scanner(page).offersSettings(o)) o,
      ],
      <LumeScanOutcome>[LumeScanOutcome.blocked, LumeScanOutcome.undetermined],
    );
    for (final LumeScanOutcome never in <LumeScanOutcome>[
      LumeScanOutcome.cancelled,
      LumeScanOutcome.denied,
      LumeScanOutcome.restricted,
      LumeScanOutcome.unavailable,
      LumeScanOutcome.failed,
    ]) {
      expect(scanner(page).offersSettings(never), isFalse, reason: '$never');
    }
    expect(LumeScanOutcome.values.where(scanner(null).offersSettings), isEmpty);
    expect(await scanner(page).openSettings(), isFalse, reason: 'honest');
    expect(page.opened, 1);
    expect(await scanner(null).openSettings(), isFalse);
  });

  test('both native halves answer the same channel and method', () {
    final String kotlin = File(
      'android/app/src/main/kotlin/com/lume/lume/LumeAppSettings.kt',
    ).readAsStringSync();
    expect(kotlin, contains('"lume/app_settings"'));
    expect(kotlin, contains('call.method != "open"'));
    expect(kotlin, contains('Settings.ACTION_APPLICATION_DETAILS_SETTINGS'));
    expect(
      File(
        'android/app/src/main/kotlin/com/lume/lume/MainActivity.kt',
      ).readAsStringSync(),
      contains('LumeAppSettings.CHANNEL'),
    );
    final String swift = File(
      'ios/Runner/AppDelegate.swift',
    ).readAsStringSync();
    expect(swift, contains('"lume/app_settings"'));
    expect(swift, contains('call.method == "open"'));
    expect(swift, contains('UIApplication.openSettingsURLString'));
    expect(swift, contains('result(opened)'), reason: 'says whether it opened');
    expect(swift, contains('LumeAppSettings.register('));
  });

  test('the platforms that have a page get the channel', () {
    // `platform_services.dart` gives Android and iOS the channel; a platform
    // without one gets no Settings action at all.
    final String services = File(
      'lib/app/providers/platform_services.dart',
    ).readAsStringSync();
    expect(services, contains('const LumeChannelAppSettings()'));
    expect(services, contains('TargetPlatform.iOS'));
  });
}
