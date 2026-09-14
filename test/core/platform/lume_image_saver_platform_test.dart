/// Save image asks for no more than it needs, writes once, and says saved
/// only when the platform has written it (F6B). Nothing here touches a real
/// photo library.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:lume/core/platform/lume_image_saver_platform.dart';
import 'package:lume/core/platform/lume_share.dart';

final Uint8List png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, //
]);

/// A photo library that records every question and every write.
class _Library {
  _Library({
    this.granted = true,
    this.grants = true,
    this.ios,
    this.writeError,
  });

  final bool granted;
  final bool grants;
  final int? ios;
  final Object? writeError;

  int asked = 0;
  int requested = 0;
  final List<(Uint8List, String)> written = <(Uint8List, String)>[];

  LumePlatformImageSaver saver() => LumePlatformImageSaver(
    hasAccess: () async {
      asked++;
      return granted;
    },
    requestAccess: () async {
      requested++;
      return grants;
    },
    put: (Uint8List bytes, String name) async {
      if (writeError != null) throw writeError!;
      written.add((bytes, name));
    },
    iosMajorVersion: () => ios,
    now: () => DateTime(2026, 9, 7, 16, 41, 5),
  );
}

GalException gal(GalExceptionType type) => GalException(
  type: type,
  platformException: PlatformException(code: type.code),
  stackTrace: StackTrace.empty,
);

void main() {
  test(
    'with access, the picture is written once, under its own name',
    () async {
      final _Library lib = _Library();
      expect(
        await lib.saver().saveImage(png, fileName: 'lume-hadith.png'),
        LumeSaveOutcome.saved,
      );
      expect(lib.written, hasLength(1));
      expect(lib.written.single.$1, png);
      expect(lib.written.single.$2, 'lume-hadith-20260907-164105');
      expect(
        lib.requested,
        0,
        reason: 'access already held is not asked again',
      );
    },
  );

  test('without access, it is asked once; granted, it saves', () async {
    final _Library lib = _Library(granted: false);
    expect(
      await lib.saver().saveImage(png, fileName: 'lume-quote.png'),
      LumeSaveOutcome.saved,
    );
    expect(lib.requested, 1);
  });

  test('refused: denied, and nothing is written', () async {
    final _Library lib = _Library(granted: false, grants: false);
    expect(
      await lib.saver().saveImage(png, fileName: 'lume-quote.png'),
      LumeSaveOutcome.denied,
    );
    expect(lib.written, isEmpty);
  });

  test('a write that throws is never reported as saved', () async {
    for (final (Object error, LumeSaveOutcome outcome)
        in <(Object, LumeSaveOutcome)>[
          (gal(GalExceptionType.accessDenied), LumeSaveOutcome.denied),
          (gal(GalExceptionType.notEnoughSpace), LumeSaveOutcome.noSpace),
          (gal(GalExceptionType.notSupportedFormat), LumeSaveOutcome.failed),
          (gal(GalExceptionType.unexpected), LumeSaveOutcome.failed),
          (PlatformException(code: 'io'), LumeSaveOutcome.failed),
          (MissingPluginException(), LumeSaveOutcome.unavailable),
        ]) {
      expect(
        await _Library(
          writeError: error,
        ).saver().saveImage(png, fileName: 'lume-dua.png'),
        outcome,
        reason: '$error',
      );
    }
  });

  test(
    'below iOS 14 nothing is asked: Photos could only grant everything',
    () async {
      final _Library lib = _Library(ios: 13);
      expect(
        await lib.saver().saveImage(png, fileName: 'lume-dua.png'),
        LumeSaveOutcome.unavailable,
      );
      expect(lib.asked, 0);
      expect(lib.requested, 0);
      expect(
        await _Library(
          ios: 14,
        ).saver().saveImage(png, fileName: 'lume-dua.png'),
        LumeSaveOutcome.saved,
      );
    },
  );

  test(
    'bytes that are not a PNG are refused before anything is asked',
    () async {
      final _Library lib = _Library();
      expect(
        await lib.saver().saveImage(
          Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'lume-dua.png',
        ),
        LumeSaveOutcome.failed,
      );
      expect(lib.asked, 0);
      expect(lib.written, isEmpty);
    },
  );

  test('names are deterministic and carry nothing but the card kind', () {
    final DateTime at = DateTime(2026, 1, 2, 3, 4, 5);
    expect(
      LumePlatformImageSaver.nameFor('lume-reminder.png', at),
      'lume-reminder-20260102-030405',
    );
    expect(
      LumePlatformImageSaver.nameFor('../a b.PNG', at),
      '---a-b-20260102-030405',
    );
    expect(LumePlatformImageSaver.nameFor('', at), 'lume-20260102-030405');
  });
}
