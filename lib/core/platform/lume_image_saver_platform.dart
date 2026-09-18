/// How a card reaches the photo library on iOS, and what every saver shares
/// (F6B, C81).
///
/// **Android does not use `gal`.** `gal` 2.3.3 inserts a MediaStore row with a
/// `.png` name and no MIME type; Android 10 then types it `image/jpeg` and
/// renames it `….png.jpg` (reproduced on API 29 in the F6B closure). Android
/// saves through Lume's own channel instead (`lume_media_store_saver.dart`).
///
/// On iOS `gal` adds one picture and asks for no more than that:
///
/// * **iOS 14 and later** — add-only Photos access
///   (`NSPhotoLibraryAddUsageDescription`): Lume can put a picture in and can
///   see none. **Below iOS 14** Photos can only grant the whole library, so
///   Save image reports unavailable and the share sheet — whose own "Save
///   Image" needs no grant of Lume's — stays the way to keep a card.
///
/// Saved is reported only when the platform has written the file.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import 'lume_share.dart';

/// What every saver checks and how it names a card.
abstract final class LumePngFile {
  static const List<int> _signature = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  ];

  static bool isPng(Uint8List bytes) {
    if (bytes.length <= _signature.length) return false;
    for (int i = 0; i < _signature.length; i++) {
      if (bytes[i] != _signature[i]) return false;
    }
    return true;
  }

  /// `lume-hadith.png` saved at 16:41:05 on 7 September 2026 is
  /// `lume-hadith-20260907-164105`; the platform adds the extension.
  static String nameFor(String fileName, DateTime at) {
    final String base = fileName
        .replaceFirst(RegExp(r'\.png$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '-');
    String two(int n) => n.toString().padLeft(2, '0');
    return '${base.isEmpty ? 'lume' : base}-'
        '${at.year}${two(at.month)}${two(at.day)}-'
        '${two(at.hour)}${two(at.minute)}${two(at.second)}';
  }
}

typedef LumeGalleryAccess = Future<bool> Function();
typedef LumeGalleryPut = Future<void> Function(Uint8List bytes, String name);

/// The iOS saver, over `gal`.
class LumeGalImageSaver implements LumeImageSaver {
  const LumeGalImageSaver({
    LumeGalleryAccess hasAccess = _hasAccess,
    LumeGalleryAccess requestAccess = _requestAccess,
    LumeGalleryPut put = _put,
    int? Function() iosMajorVersion = _iosMajor,
    DateTime Function() now = DateTime.now,
  }) : _has = hasAccess,
       _request = requestAccess,
       _write = put,
       _ios = iosMajorVersion,
       _now = now;

  final LumeGalleryAccess _has;
  final LumeGalleryAccess _request;
  final LumeGalleryPut _write;
  final int? Function() _ios;
  final DateTime Function() _now;

  /// The first iOS with add-only access.
  static const int addOnlyFromIos = 14;

  @override
  Future<LumeSaveOutcome> saveImage(
    Uint8List png, {
    required String fileName,
  }) async {
    final int? ios = _ios();
    if (ios != null && ios < addOnlyFromIos) return LumeSaveOutcome.unavailable;
    if (!LumePngFile.isPng(png)) return LumeSaveOutcome.failed;
    try {
      if (!await _has() && !await _request()) return LumeSaveOutcome.denied;
      await _write(png, LumePngFile.nameFor(fileName, _now()));
      return LumeSaveOutcome.saved;
    } on GalException catch (e) {
      return switch (e.type) {
        GalExceptionType.accessDenied => LumeSaveOutcome.denied,
        GalExceptionType.notEnoughSpace => LumeSaveOutcome.noSpace,
        GalExceptionType.notSupportedFormat ||
        GalExceptionType.unexpected => LumeSaveOutcome.failed,
      };
    } on MissingPluginException {
      return LumeSaveOutcome.unavailable;
    } on PlatformException {
      return LumeSaveOutcome.failed;
    }
  }
}

Future<bool> _hasAccess() => Gal.hasAccess();

Future<bool> _requestAccess() => Gal.requestAccess();

Future<void> _put(Uint8List bytes, String name) =>
    Gal.putImageBytes(bytes, name: name);

int? _iosMajor() {
  if (!Platform.isIOS) return null;
  final RegExpMatch? m = RegExp(
    r'(\d+)',
  ).firstMatch(Platform.operatingSystemVersion);
  return m == null ? null : int.parse(m.group(1)!);
}
