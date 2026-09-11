/// Loads the bundled fonts into the test font collection.
///
/// Without this, `flutter test` renders every glyph as a filled box: the test
/// environment ships one fallback face and does not read `pubspec.yaml`'s font
/// declarations. A type golden taken that way is a picture of rectangles — it
/// freezes layout, and proves nothing about the typeface, the weights or the
/// script handling, which is most of what the type system is.
///
/// Call [loadLumeFonts] from `setUpAll` in any suite that renders text it
/// intends to look at.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool _loaded = false;

/// Register every bundled face under the family name `pubspec.yaml` declares.
///
/// The family strings must match the ones in `LumeType`; a mismatch here does
/// not fail loudly, it just quietly renders boxes again.
Future<void> loadLumeFonts() async {
  if (_loaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> family(String name, List<String> files) async {
    final FontLoader loader = FontLoader(name);
    for (final String path in files) {
      final File f = File('assets/fonts/$path');
      if (!f.existsSync()) {
        throw StateError(
          'assets/fonts/$path is missing — text would render as boxes',
        );
      }
      loader.addFont(
        Future<ByteData>.value(ByteData.sublistView(f.readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await family('PlusJakartaSans', <String>[
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
  ]);
  await family('NotoNaskhArabic', <String>['NotoNaskhArabic-Regular.ttf']);

  _loaded = true;
}
