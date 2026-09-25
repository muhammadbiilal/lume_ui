/// A captured page's own file name and extension, worked out from its MIME
/// type and the instant it was captured — nothing here reads a clock or a
/// platform.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/docscan/data/document_page.dart';

LumeDocumentPage _page({
  String mimeType = 'image/jpeg',
  String id = '0',
  bool fromGallery = false,
}) => LumeDocumentPage(
  id: id,
  bytes: Uint8List.fromList(<int>[1]),
  mimeType: mimeType,
  capturedAt: DateTime(2026, 9, 7, 16, 41, 5),
  fromGallery: fromGallery,
);

void main() {
  test('a camera capture is named as a JPEG', () {
    expect(
      _page(mimeType: 'image/jpeg').fileName,
      'lume-docscan-20260907-164105-0.jpg',
    );
  });

  test('a PNG gallery file keeps its own extension', () {
    expect(
      _page(mimeType: 'image/png').fileName,
      'lume-docscan-20260907-164105-0.png',
    );
  });

  test('HEIC and WebP are named for what they are', () {
    expect(_page(mimeType: 'image/heic').fileName, endsWith('.heic'));
    expect(_page(mimeType: 'image/webp').fileName, endsWith('.webp'));
  });

  test('an unrecognised type falls back to JPEG, never invented as PNG', () {
    expect(_page(mimeType: 'image/gif').fileName, endsWith('.jpg'));
  });

  test('two pages captured on the same pinned clock still get distinct '
      'names, by their own id', () {
    expect(_page(id: '0').fileName, isNot(_page(id: '1').fileName));
  });
}
