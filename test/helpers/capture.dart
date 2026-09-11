/// Captures a Flutter surface at an exact viewport, with a sidecar of measured
/// facts that lines up with the web capture's.
///
/// The two sides have to be given the same thing before a comparison is
/// evidence: the same logical size, the same device pixel ratio, the same
/// fixture, the same pinned clock, the same theme, the same locale, the same
/// scroll position, and reduced motion on both so nothing is mid-shimmer.
/// [captureLume] takes all of those as arguments so a cell is reproducible from
/// its filename.
///
/// `devicePixelRatio` is 1, so a logical pixel is an image pixel and the two
/// captures are directly comparable without scaling either.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/layout/lume_breakpoint.dart';

import 'load_fonts.dart';
import 'lume_harness.dart';

/// Where captures land. The web capture writes beside them.
const String kShotsDir = 'docs/conversion_archive/shots';

/// Capture [child] and write `<name>_<w>x<h>_<theme>_<lang><suffix>.flutter.png`
/// plus its `.flutter.json` sidecar.
///
/// [suffix] exists so a Flutter capture can be paired with a web capture whose
/// name carries something extra — the onboarding captures carry `_step3` and
/// `_step5`, because the web tool drives the flow to a step and says so in the
/// filename. The comparison pairs on the whole name, so the two have to agree.
///
/// Returns the sidecar, so a test can assert on the measured facts as well as
/// leaving an image behind.
Future<Map<String, Object?>> captureLume(
  WidgetTester tester,
  Widget child, {
  required String name,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  String outDir = kShotsDir,
  String suffix = '',
}) async {
  // `FontLoader.load` does real asynchronous work, and a widget test runs in a
  // fake-async zone where real work never completes. Both this and the image
  // encode below have to step outside it or the test simply hangs.
  await tester.runAsync(loadLumeFonts);

  final GlobalKey key = GlobalKey();
  late LumeWidthClass widthClass;
  late LumeWidthClass measureClass;
  late double shellWidth;
  late double shellHeight;

  await pumpLume(
    tester,
    RepaintBoundary(
      key: key,
      child: Builder(
        builder: (BuildContext context) {
          widthClass = context.widthClass;
          measureClass = context.measureClass;
          shellWidth = context.shellWidth;
          shellHeight = context.shellHeight;
          return child;
        },
      ),
    ),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();

  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late final ui.Image image;
  late final ByteData png;
  await tester.runAsync(() async {
    image = await boundary.toImage();
    png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });

  final String themeName = theme == ThemeMode.dark ? 'dark' : 'light';
  final String cell =
      '${name}_${surface.width.round()}x${surface.height.round()}'
      '_${themeName}_${locale.languageCode}$suffix';

  final Directory dir = Directory('$outDir/$name');
  dir.createSync(recursive: true);
  File(
    '${dir.path}/$cell.flutter.png',
  ).writeAsBytesSync(png.buffer.asUint8List());

  final Map<String, Object?> sidecar = <String, Object?>{
    'requested': <String, Object?>{
      'width': surface.width,
      'height': surface.height,
      'dpr': 1,
      'theme': themeName,
      'lang': locale.languageCode,
      'textScale': textScale,
    },
    'measured': <String, Object?>{
      'imageWidth': image.width,
      'imageHeight': image.height,
      'widthClass': widthClass.name,
      'measureClass': measureClass.name,
      'shell': <String, Object?>{'width': shellWidth, 'height': shellHeight},
      'dir': Directionality.of(key.currentContext!).name,
    },
  };
  File('${dir.path}/$cell.flutter.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sidecar)}\n',
  );

  image.dispose();
  return sidecar;
}

/// Fails when [finder]'s subtree reports a layout overflow.
///
/// Flutter paints an overflow as a yellow-and-black stripe and logs it, but a
/// widget test passes anyway unless something looks. This looks.
void expectNoOverflow(WidgetTester tester) {
  final Object? exception = tester.takeException();
  if (exception == null) return;
  final String text = exception.toString();
  if (text.contains('overflowed')) {
    fail('a widget overflowed its constraints:\n$text');
  }
  // Not an overflow — hand it back rather than swallowing it.
  // ignore: only_throw_errors
  throw exception;
}

/// Measures a widget's bounds, for the component-level comparison the
/// component matrix asks for.
Rect boundsOf(WidgetTester tester, Finder finder) {
  final RenderBox box = tester.renderObject<RenderBox>(finder);
  final Offset topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}

/// The number of lines a `Text` actually laid out.
///
/// "Visible line count" is one of the things a comparison has to match, and it
/// is not the same as `maxLines`: a string that fits on one line in English may
/// take two in German or Urdu.
int lineCountOf(WidgetTester tester, Finder finder) {
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
    finder,
  );
  return paragraph
      .getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.text.toPlainText().length,
        ),
      )
      .map((TextBox b) => b.top.round())
      .toSet()
      .length;
}
