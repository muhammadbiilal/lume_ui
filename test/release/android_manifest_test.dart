/// Which Android permissions Lume asks for, and which it removes (C80, C81,
/// F6B closure).
///
/// The source manifest is read on every run. The merged manifests are what
/// actually ships, and they exist only after a build: each is checked where
/// `flutter build apk` has written it, and the test says it was skipped where
/// it has not — a missing file is never a pass.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _android = 'http://schemas.android.com/apk/res/android';
const String _tools = 'http://schemas.android.com/tools';

/// `uses-permission` names, and the `tools:node` each carries.
Map<String, String?> _permissions(String xml) {
  final Map<String, String?> out = <String, String?>{};
  final RegExp element = RegExp(r'<uses-permission\b([^>]*)/?>', dotAll: true);
  for (final RegExpMatch m in element.allMatches(xml)) {
    final String attrs = m.group(1)!;
    final String? name = RegExp(
      r'android:name="([^"]+)"',
    ).firstMatch(attrs)?.group(1);
    final String? node = RegExp(
      r'tools:node="([^"]+)"',
    ).firstMatch(attrs)?.group(1);
    if (name != null) out[name] = node;
  }
  return out;
}

String? _maxSdk(String xml, String permission) => RegExp(
  '<uses-permission\\b[^>]*android:name="${RegExp.escape(permission)}"'
  '[^>]*android:maxSdkVersion="(\\d+)"',
  dotAll: true,
).firstMatch(xml)?.group(1);

/// Storage permissions Lume never declares. `apkanalyzer manifest
/// permissions` lists `READ_EXTERNAL_STORAGE` for the APK all the same: it
/// shows the read Android implies for any storage write. The packaged
/// manifest (`apkanalyzer manifest print`, `aapt2 dump permissions`) does not
/// declare it, and those are authoritative.
const List<String> _broadStorage = <String>[
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.MANAGE_EXTERNAL_STORAGE',
  'android.permission.READ_MEDIA_IMAGES',
  'android.permission.READ_MEDIA_VIDEO',
  'android.permission.READ_MEDIA_AUDIO',
  'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
  'android.permission.ACCESS_MEDIA_LOCATION',
];

void main() {
  test('the source manifest asks for the camera and removes the rest', () {
    final String xml = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(xml, contains('xmlns:android="$_android"'));
    expect(xml, contains('xmlns:tools="$_tools"'));
    final Map<String, String?> p = _permissions(xml);
    expect(
      <String>[
        for (final MapEntry<String, String?> e in p.entries)
          if (e.value != 'remove') e.key,
      ]..sort(),
      <String>[
        'android.permission.CAMERA',
        'android.permission.WRITE_EXTERNAL_STORAGE',
      ],
    );
    expect(_maxSdk(xml, 'android.permission.WRITE_EXTERNAL_STORAGE'), '28');
    expect(
      <String>[
        for (final MapEntry<String, String?> e in p.entries)
          if (e.value == 'remove') e.key,
      ]..sort(),
      <String>[
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.RECORD_AUDIO',
      ],
    );
    for (final String broad in _broadStorage) {
      if (broad == 'android.permission.READ_EXTERNAL_STORAGE') continue;
      expect(p.keys, isNot(contains(broad)), reason: broad);
    }
  });

  // What the merger may add that is not a request to the reader: Flutter's
  // tooling needs the network in a debug build only, and androidx.core
  // declares a signature permission for its own receivers.
  const String ownReceivers =
      'com.lume.lume.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION';

  for (final (String variant, String path, List<String> allowed)
      in <(String, String, List<String>)>[
        (
          'debug',
          'build/app/intermediates/merged_manifests/debug/'
              'processDebugManifest/AndroidManifest.xml',
          <String>[
            'android.permission.CAMERA',
            'android.permission.INTERNET',
            'android.permission.WRITE_EXTERNAL_STORAGE',
            ownReceivers,
          ],
        ),
        (
          'release',
          'build/app/intermediates/merged_manifests/release/'
              'processReleaseManifest/AndroidManifest.xml',
          <String>[
            'android.permission.CAMERA',
            'android.permission.WRITE_EXTERNAL_STORAGE',
            ownReceivers,
          ],
        ),
      ]) {
    final File merged = File(path);
    test(
      'the merged $variant manifest asks for exactly what Lume uses',
      () {
        final String xml = merged.readAsStringSync();
        final Map<String, String?> p = _permissions(xml);
        expect(p.keys.toList()..sort(), allowed..sort());
        expect(
          p.keys,
          isNot(contains('android.permission.ACCESS_NETWORK_STATE')),
        );
        expect(
          p.keys,
          isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
        );
        expect(p.keys, isNot(contains('android.permission.RECORD_AUDIO')));
        // No broad storage access of any generation: the write permission
        // is the only storage entry, and only through API 28.
        for (final String broad in _broadStorage) {
          expect(p.keys, isNot(contains(broad)), reason: broad);
        }
        expect(_maxSdk(xml, 'android.permission.WRITE_EXTERNAL_STORAGE'), '28');
      },
      skip: merged.existsSync()
          ? false
          : 'no $variant build: run `flutter build apk --$variant` first',
    );
  }
}
