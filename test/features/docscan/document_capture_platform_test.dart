/// The document camera adapter's own decisions, without a camera, a picker or
/// a permission gate: which outcome a camera refusal is, which an
/// `image_picker` denial code is, and what MIME a gallery file with no
/// reported type is guessed to be (C80). Mirrors
/// `test/core/platform/lume_scanner_platform_test.dart`'s own shape for the
/// QR scanner.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:lume/core/platform/lume_camera_gate.dart';
import 'package:lume/features/docscan/data/document_capture.dart';
import 'package:lume/features/docscan/data/document_capture_platform.dart';

/// A picker that records what it was asked and answers with [file], or
/// throws [error].
class _Device {
  _Device({this.file, this.error});

  final picker.XFile? file;
  final Object? error;

  final List<picker.ImageSource> asked = <picker.ImageSource>[];

  LumePlatformDocumentCamera camera({LumeCameraGate? gate}) =>
      LumePlatformDocumentCamera(
        gate: gate,
        pick: (picker.ImageSource source) async {
          asked.add(source);
          if (error != null) throw error!;
          return file;
        },
      );
}

void main() {
  group('what a camera refusal means', () {
    LumeCaptureOutcome? of(LumeCameraAccess a) =>
        LumePlatformDocumentCamera.refusal(a);

    test('granted opens the camera', () {
      expect(of(LumeCameraAccess.granted), isNull);
    });

    test('every other state is told for what it is', () {
      expect(of(LumeCameraAccess.denied), LumeCaptureOutcome.denied);
      expect(of(LumeCameraAccess.blocked), LumeCaptureOutcome.blocked);
      expect(of(LumeCameraAccess.restricted), LumeCaptureOutcome.restricted);
      expect(
        of(LumeCameraAccess.undetermined),
        LumeCaptureOutcome.undetermined,
      );
      expect(of(LumeCameraAccess.interrupted), LumeCaptureOutcome.cancelled);
      expect(of(LumeCameraAccess.unavailable), LumeCaptureOutcome.unavailable);
      expect(of(LumeCameraAccess.failed), LumeCaptureOutcome.failed);
    });

    test('a request never honestly answers "first request"', () {
      expect(of(LumeCameraAccess.firstRequest), LumeCaptureOutcome.failed);
    });
  });

  group("image_picker's own denial codes", () {
    test('the camera source', () {
      expect(
        LumePlatformDocumentCamera.trouble(
          'camera_access_denied',
          isCamera: true,
        ),
        LumeCaptureOutcome.denied,
      );
      expect(
        LumePlatformDocumentCamera.trouble('invalid_image', isCamera: true),
        LumeCaptureOutcome.failed,
      );
    });

    test('the gallery source', () {
      expect(
        LumePlatformDocumentCamera.trouble(
          'photo_access_denied',
          isCamera: false,
        ),
        LumeCaptureOutcome.denied,
      );
      expect(
        LumePlatformDocumentCamera.trouble('invalid_image', isCamera: false),
        LumeCaptureOutcome.failed,
      );
    });
  });

  group('guessing a gallery file\'s MIME type', () {
    test('from its own extension', () {
      expect(LumePlatformDocumentCamera.mimeOf('page.png'), 'image/png');
      expect(LumePlatformDocumentCamera.mimeOf('PAGE.HEIC'), 'image/heic');
      expect(LumePlatformDocumentCamera.mimeOf('page.webp'), 'image/webp');
    });

    test('defaults to JPEG, what a camera capture always is', () {
      expect(LumePlatformDocumentCamera.mimeOf('page.jpg'), 'image/jpeg');
      expect(LumePlatformDocumentCamera.mimeOf('noextension'), 'image/jpeg');
    });
  });

  group('capture', () {
    test('the gate refusing means the camera never opens', () async {
      final _Device d = _Device();
      final LumeFakeCameraGate gate = LumeFakeCameraGate(
        answer: LumeCameraAccess.blocked,
      );
      final LumeCaptureResult r = await d.camera(gate: gate).capture();
      expect(r.outcome, LumeCaptureOutcome.blocked);
      expect(d.asked, isEmpty);
    });

    test(
      'the gate granting opens the camera and hands back the photo',
      () async {
        final picker.XFile file = picker.XFile.fromData(
          Uint8List.fromList(<int>[1, 2, 3]),
          mimeType: 'image/jpeg',
          name: 'photo.jpg',
        );
        final _Device d = _Device(file: file);
        final LumeFakeCameraGate gate = LumeFakeCameraGate(
          answer: LumeCameraAccess.granted,
        );
        final LumeCaptureResult r = await d.camera(gate: gate).capture();
        expect(r.outcome, LumeCaptureOutcome.captured);
        expect(r.bytes, <int>[1, 2, 3]);
        expect(r.mimeType, 'image/jpeg');
        expect(d.asked, <picker.ImageSource>[picker.ImageSource.camera]);
      },
    );

    test('no gate (iOS) opens the camera directly', () async {
      final picker.XFile file = picker.XFile.fromData(
        Uint8List.fromList(<int>[9]),
        name: 'photo.jpg',
      );
      final _Device d = _Device(file: file);
      final LumeCaptureResult r = await d.camera().capture();
      expect(r.outcome, LumeCaptureOutcome.captured);
      // No `mimeType` reported by the file: guessed from its own name.
      expect(r.mimeType, 'image/jpeg');
    });

    test('choosing nothing is cancelled, not a failure', () async {
      final _Device d = _Device();
      expect(
        (await d.camera().capture()).outcome,
        LumeCaptureOutcome.cancelled,
      );
    });

    test('an empty file is a failure', () async {
      final picker.XFile file = picker.XFile.fromData(
        Uint8List(0),
        name: 'x.jpg',
      );
      final _Device d = _Device(file: file);
      expect((await d.camera().capture()).outcome, LumeCaptureOutcome.failed);
    });

    test("image_picker's own denial, on iOS with no gate", () async {
      final _Device d = _Device(
        error: PlatformException(code: 'camera_access_denied'),
      );
      expect((await d.camera().capture()).outcome, LumeCaptureOutcome.denied);
    });

    test('no plugin registered is unavailable', () async {
      final _Device d = _Device(error: MissingPluginException());
      expect(
        (await d.camera().capture()).outcome,
        LumeCaptureOutcome.unavailable,
      );
    });
  });

  group('pickImage', () {
    test('a chosen file is handed back as captured', () async {
      final picker.XFile file = picker.XFile.fromData(
        Uint8List.fromList(<int>[4, 5]),
        mimeType: 'image/png',
        name: 'page.png',
      );
      final _Device d = _Device(file: file);
      final LumeCaptureResult r = await d.camera().pickImage();
      expect(r.outcome, LumeCaptureOutcome.captured);
      expect(r.mimeType, 'image/png');
      expect(d.asked, <picker.ImageSource>[picker.ImageSource.gallery]);
    });

    test('the gate is never consulted for the gallery', () async {
      final _Device d = _Device();
      final LumeFakeCameraGate gate = LumeFakeCameraGate(
        answer: LumeCameraAccess.blocked,
      );
      await d.camera(gate: gate).pickImage();
      expect(gate.asked, isEmpty);
    });

    test('photos refused', () async {
      final _Device d = _Device(
        error: PlatformException(code: 'photo_access_denied'),
      );
      expect((await d.camera().pickImage()).outcome, LumeCaptureOutcome.denied);
    });
  });

  group('Settings', () {
    test('offered only for blocked and undetermined', () {
      const LumePlatformDocumentCamera camera = LumePlatformDocumentCamera();
      for (final LumeCaptureOutcome o in LumeCaptureOutcome.values) {
        expect(
          camera.offersSettings(o),
          isFalse,
          reason: 'no settings adapter configured',
        );
      }
    });
  });
}
