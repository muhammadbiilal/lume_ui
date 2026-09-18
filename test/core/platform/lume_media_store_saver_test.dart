/// Android's Save image, over Lume's own MediaStore channel (C81, F6B
/// closure): the bytes go as they are, under a `.png` name, and "saved" is
/// said only for a published row the platform typed `image/png`.
///
/// The native half is `LumeImageSaver.kt`; it ran on emulators (API 28, 29,
/// 36). This test holds the Dart half and reads the Kotlin as source.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_media_store_saver.dart';
import 'package:lume/core/platform/lume_share.dart';

final Uint8List png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, //
]);

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('lume/image_saver');
  final List<MethodCall> calls = <MethodCall>[];
  tearDown(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  void answer(Object? Function(MethodCall) reply) => binding
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall c) async {
        calls.add(c);
        return reply(c);
      });

  LumeMediaStoreImageSaver saver({bool fail = false}) =>
      LumeMediaStoreImageSaver(
        now: () => DateTime(2026, 9, 7, 16, 41, 5),
        simulateFailure: fail,
      );

  Map<String, Object?> saved({
    String name = 'lume-hadith-20260907-164105.png',
    String mime = 'image/png',
    String? uri = 'content://media/external_primary/images/media/34',
  }) => <String, Object?>{
    'outcome': 'saved',
    'name': name,
    'mime': mime,
    'uri': uri,
  };

  test(
    'the PNG bytes go as they are, under a name with no extension',
    () async {
      answer((MethodCall c) => saved());
      expect(
        await saver().saveImage(png, fileName: 'lume-hadith.png'),
        LumeSaveOutcome.saved,
      );
      expect(calls.single.method, 'savePng');
      final Map<Object?, Object?> args = calls.single.arguments as Map;
      expect(args['bytes'], png);
      expect(args['name'], 'lume-hadith-20260907-164105');
      expect(args['simulateFailure'], isFalse);
    },
  );

  test(
    'never "saved" for a row the platform typed or named otherwise',
    () async {
      for (final Map<String, Object?> row in <Map<String, Object?>>[
        saved(name: 'lume-hadith-20260907-164105.png.jpg', mime: 'image/jpeg'),
        saved(mime: 'image/jpeg'),
        saved(name: 'lume-hadith.jpg'),
        saved(uri: null),
      ]) {
        answer((MethodCall c) => row);
        expect(
          await saver().saveImage(png, fileName: 'lume-hadith.png'),
          LumeSaveOutcome.failed,
          reason: '$row',
        );
      }
    },
  );

  test('a name MediaStore renamed to keep both is still saved', () async {
    answer(
      (MethodCall c) => saved(name: 'lume-hadith-20260907-164105 (1).png'),
    );
    expect(
      await saver().saveImage(png, fileName: 'lume-hadith.png'),
      LumeSaveOutcome.saved,
    );
  });

  test('every other answer is said as what it is', () async {
    for (final (Object? reply, LumeSaveOutcome want)
        in <(Object?, LumeSaveOutcome)>[
          (<String, Object?>{'outcome': 'denied'}, LumeSaveOutcome.denied),
          (<String, Object?>{'outcome': 'noSpace'}, LumeSaveOutcome.noSpace),
          (<String, Object?>{'outcome': 'failed'}, LumeSaveOutcome.failed),
          (<String, Object?>{'outcome': 'odd'}, LumeSaveOutcome.failed),
          (null, LumeSaveOutcome.failed),
        ]) {
      answer((MethodCall c) => reply);
      expect(
        await saver().saveImage(png, fileName: 'x.png'),
        want,
        reason: '$reply',
      );
    }
    answer((MethodCall c) => throw PlatformException(code: 'io'));
    expect(
      await saver().saveImage(png, fileName: 'x.png'),
      LumeSaveOutcome.failed,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    expect(
      await saver().saveImage(png, fileName: 'x.png'),
      LumeSaveOutcome.unavailable,
    );
  });

  test('bytes that are not a PNG never reach the platform', () async {
    answer((MethodCall c) => saved());
    expect(
      await saver().saveImage(
        Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0]),
        fileName: 'x.png',
      ),
      LumeSaveOutcome.failed,
    );
    expect(calls, isEmpty);
  });

  test('a simulated failure is passed on, and only when asked', () async {
    answer((MethodCall c) => <String, Object?>{'outcome': 'failed'});
    await saver(fail: true).saveImage(png, fileName: 'x.png');
    expect((calls.single.arguments as Map)['simulateFailure'], isTrue);
    expect(kLumeSimulateSaveFailure, isFalse, reason: 'not in a test build');
  });

  test('the native half writes a png, typed, pending, and cleans up', () {
    final String kt = File(
      'android/app/src/main/kotlin/com/lume/lume/LumeImageSaver.kt',
    ).readAsStringSync();
    for (final String must in <String>[
      'const val CHANNEL = "lume/image_saver"',
      'MediaStore.MediaColumns.DISPLAY_NAME, "\$name.png"',
      'MediaStore.MediaColumns.MIME_TYPE, MIME',
      'private const val MIME = "image/png"',
      'MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES',
      'MediaStore.MediaColumns.IS_PENDING, 1',
      'MediaStore.MediaColumns.IS_PENDING, 0',
      'resolver.delete(uri, null, null)',
      'createNewFile()',
      'MediaScannerConnection.scanFile',
      'FLAG_DEBUGGABLE',
    ]) {
      expect(kt, contains(must), reason: must);
    }
    expect(kt, isNot(contains('READ_EXTERNAL_STORAGE')));
    expect(kt, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
    expect(kt, isNot(contains('READ_MEDIA_IMAGES')));
  });
}
