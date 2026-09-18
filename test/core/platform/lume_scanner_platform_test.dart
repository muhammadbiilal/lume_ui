/// The scanner adapter's own decisions, without a camera, a picker or a file:
/// which outcome a chosen image is, which a camera error is, and that the
/// picked copy is always removed (C80).
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_scanner.dart';
import 'package:lume/core/platform/lume_scanner_platform.dart';

class _Exception implements Exception {
  const _Exception(this.text);
  final String text;
  @override
  String toString() => text;
}

const LumeDecodedCode qr = LumeDecodedCode(
  text: 'https://lume.app',
  isQr: true,
  isValid: true,
);

/// A picker, a decoder and a file system that record what they were asked.
class _Device {
  _Device({
    this.path = '/cache/abc/pick.jpg',
    this.size = 120000,
    this.image = const LumeDecodedImage(codes: <LumeDecodedCode>[qr]),
    this.pickError,
    this.decodeError,
  });

  final String? path;
  final int size;
  final LumeDecodedImage image;
  final Object? pickError;
  final Object? decodeError;

  int picks = 0;
  final List<String> decoded = <String>[];
  final List<String> removed = <String>[];

  LumePlatformScanner scanner() => LumePlatformScanner(
    navigator: () => null,
    pick: () async {
      picks++;
      if (pickError != null) throw pickError!;
      return path;
    },
    decode: (String p) async {
      decoded.add(p);
      if (decodeError != null) throw decodeError!;
      return image;
    },
    sizeOf: (String p) async => size,
    remove: (String p) async => removed.add(p),
  );
}

void main() {
  group('what a chosen image is', () {
    LumeScanOutcome of(LumeDecodedImage image) =>
        LumePlatformScanner.interpret(image).outcome;

    test('one QR code is read, with its text', () {
      expect(
        LumePlatformScanner.interpret(
          const LumeDecodedImage(codes: <LumeDecodedCode>[qr]),
        ),
        const LumeScanResult(LumeScanOutcome.read, 'https://lume.app'),
      );
    });

    test('the same code found twice is one code', () {
      expect(
        of(const LumeDecodedImage(codes: <LumeDecodedCode>[qr, qr])),
        LumeScanOutcome.read,
      );
    });

    test('two different QR codes: Lume does not guess', () {
      expect(
        of(
          const LumeDecodedImage(
            codes: <LumeDecodedCode>[
              qr,
              LumeDecodedCode(text: 'other', isQr: true, isValid: true),
            ],
          ),
        ),
        LumeScanOutcome.multiple,
      );
    });

    test('no code', () {
      expect(of(const LumeDecodedImage()), LumeScanOutcome.nothing);
    });

    test('a barcode that is not a QR code', () {
      expect(
        of(
          const LumeDecodedImage(
            codes: <LumeDecodedCode>[
              LumeDecodedCode(
                text: '5012345678900',
                isQr: false,
                isValid: true,
              ),
            ],
          ),
        ),
        LumeScanOutcome.unsupported,
      );
    });

    test('a damaged QR code, or an image that is not an image', () {
      expect(
        of(
          const LumeDecodedImage(
            codes: <LumeDecodedCode>[
              LumeDecodedCode(text: null, isQr: true, isValid: false),
            ],
          ),
        ),
        LumeScanOutcome.unreadable,
      );
      expect(
        of(const LumeDecodedImage(error: 'Failed to decode image')),
        LumeScanOutcome.unreadable,
      );
    });
  });

  group('From gallery', () {
    test('a code is read, and the copy is removed', () async {
      final _Device d = _Device();
      expect(
        await d.scanner().pickImage(),
        const LumeScanResult(LumeScanOutcome.read, 'https://lume.app'),
      );
      expect(d.decoded, <String>['/cache/abc/pick.jpg']);
      expect(d.removed, <String>['/cache/abc/pick.jpg']);
    });

    test('an image with no code in it', () async {
      final _Device d = _Device(image: const LumeDecodedImage());
      expect((await d.scanner().pickImage()).outcome, LumeScanOutcome.nothing);
      expect(d.removed, hasLength(1));
    });

    test('choosing nothing is cancelled, not a failure', () async {
      final _Device d = _Device(path: null);
      expect(
        (await d.scanner().pickImage()).outcome,
        LumeScanOutcome.cancelled,
      );
      expect(d.decoded, isEmpty);
      expect(d.removed, isEmpty);
    });

    test('photos refused', () async {
      final _Device d = _Device(
        pickError: PlatformException(code: 'photo_access_denied'),
      );
      expect((await d.scanner().pickImage()).outcome, LumeScanOutcome.denied);
    });

    test('the picker failing', () async {
      expect(
        (await _Device(
          pickError: PlatformException(code: 'invalid_image'),
        ).scanner().pickImage()).outcome,
        LumeScanOutcome.failed,
      );
      expect(
        (await _Device(
          pickError: MissingPluginException(),
        ).scanner().pickImage()).outcome,
        LumeScanOutcome.unavailable,
      );
    });

    test('too large is never decoded, and still removed', () async {
      final _Device d = _Device(size: LumePlatformScanner.maxImageBytes + 1);
      expect((await d.scanner().pickImage()).outcome, LumeScanOutcome.tooLarge);
      expect(d.decoded, isEmpty);
      expect(d.removed, hasLength(1));
    });

    test('an empty file is unreadable', () async {
      final _Device d = _Device(size: 0);
      expect(
        (await d.scanner().pickImage()).outcome,
        LumeScanOutcome.unreadable,
      );
      expect(d.removed, hasLength(1));
    });

    test(
      'the decoder throwing is a failure, and the copy is removed',
      () async {
        final _Device d = _Device(decodeError: StateError('ffi'));
        expect((await d.scanner().pickImage()).outcome, LumeScanOutcome.failed);
        expect(d.removed, hasLength(1));
      },
    );

    test('a copy that cannot be removed does not change the answer', () async {
      final LumePlatformScanner s = LumePlatformScanner(
        navigator: () => null,
        pick: () async => '/cache/pick.jpg',
        decode: (String p) async =>
            const LumeDecodedImage(codes: <LumeDecodedCode>[qr]),
        sizeOf: (String p) async => 10,
        remove: (String p) async => throw const _Exception('busy'),
      );
      expect((await s.pickImage()).outcome, LumeScanOutcome.read);
    });
  });

  group('Scan', () {
    test('with nowhere to show the camera, scanning is unavailable', () async {
      expect(
        (await _Device().scanner().scan()).outcome,
        LumeScanOutcome.unavailable,
      );
    });

    for (final bool promptsOnce in <bool>[true, false]) {
      test("the camera plugin's errors, "
          '${promptsOnce ? 'on iOS (one prompt, ever)' : 'on Android'}', () {
        LumeScanOutcome trouble(Object e) =>
            lumeCameraTrouble(e, promptsOnce: promptsOnce);
        expect(
          trouble(
            const _Exception('CameraException(CameraAccessDenied, denied)'),
          ),
          promptsOnce ? LumeScanOutcome.blocked : LumeScanOutcome.denied,
        );
        expect(
          trouble(
            const _Exception(
              'CameraException(CameraAccessDeniedWithoutPrompt, go to '
              'Settings)',
            ),
          ),
          LumeScanOutcome.blocked,
        );
        expect(
          trouble(
            const _Exception(
              'CameraException(CameraAccessRestricted, parental)',
            ),
          ),
          LumeScanOutcome.restricted,
        );
        expect(
          trouble(const _Exception('CameraException(cameraNotFound, none)')),
          LumeScanOutcome.unavailable,
        );
        expect(trouble(MissingPluginException()), LumeScanOutcome.unavailable);
        expect(
          trouble(const _Exception('CameraException(setup, broke)')),
          LumeScanOutcome.failed,
        );
      });
    }
  });
}
