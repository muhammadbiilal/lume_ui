/// Document Scanner on screen: opened directly for a reader ([pumpLume]), not
/// through the real router — `tool_registry.dart` is a shared file this wave
/// leaves for the integration pass that wires every parallel tool up at once
/// (the same approach `duas_tool_test.dart` and `qibla_tool_test.dart` take).
///
/// Capture and From gallery go through [documentCameraProvider], overridden
/// here with [LumeRecordingDocumentCamera] — the same recording-fake pattern
/// `qr_test.dart` uses for [LumeRecordingScanner], its closest precedent for a
/// real camera capability faked deterministically. Share goes through
/// [documentSharerProvider], overridden with [LumeRecordingDocumentSharer].
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/docscan/data/document_capture.dart';
import 'package:lume/features/docscan/data/document_sharer.dart';
import 'package:lume/features/docscan/presentation/docscan_providers.dart';
import 'package:lume/features/docscan/presentation/docscan_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';

final LumeFeature _docscanFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeDocScanTool.id,
);

// A real, decodable 1x1 PNG — not a fake byte run. The row's thumbnail goes
// through `Image.memory`, which throws on invalid data, so the fixture has to
// be an image codecs can actually open, the same reasoning `passport_tool_
// test.dart` settled on for its own capture fixtures.
final Uint8List _jpeg = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

Future<void> pumpDocscan(
  WidgetTester tester, {
  Size surface = const Size(390, 3000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeDocScanTool(
      request: LumeToolRequest(
        feature: _docscanFeature,
        user: const LumeUserContext(),
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: overrides,
  );
  await tester.pump();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Future<String?> pressAndHear(WidgetTester tester, Key button) async {
  await tester.ensureVisible(find.byKey(button));
  await tester.tap(find.byKey(button));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final Finder toast = find.byType(LumeToast);
  final String? said = toast.evaluate().isEmpty
      ? null
      : tester.widget<LumeToast>(toast).data.message;
  await tester.pump(const Duration(seconds: 6));
  return said;
}

void main() {
  group('the catalogue entry', () {
    test('is global: no faith gate, no country restriction', () {
      expect(_docscanFeature.faith, isFalse);
      expect(_docscanFeature.countries, isNull);
    });
  });

  group('used', () {
    testWidgets('the camera is never asked for at launch', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera();
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      expect(camera.requested, isEmpty);
      expect(find.byKey(LumeDocScanTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeDocScanTool.pagesKey), findsNothing);
    });

    testWidgets('where nothing can capture, both actions say so', (
      WidgetTester tester,
    ) async {
      // `documentCameraProvider`'s own default resolves on
      // `defaultTargetPlatform`, which Flutter's test binding reports as
      // `android` regardless of the host OS — not the "unavailable" branch
      // this test means to exercise. Force it explicitly rather than
      // relying on a platform default the test environment doesn't share.
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(
            const LumeUnavailableDocumentCamera(),
          ),
        ],
      );
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      expect(
        await pressAndHear(tester, LumeDocScanTool.captureKey),
        l.scanUnavailable,
      );
      expect(
        await pressAndHear(tester, LumeDocScanTool.galleryKey),
        l.scanUnavailable,
      );
    });

    testWidgets('Capture: a real photo becomes a page, and the empty state '
        'is gone', (WidgetTester tester) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/jpeg',
        ),
      );
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(camera.requested, <String>['capture']);
      expect(find.byKey(LumeDocScanTool.emptyKey), findsNothing);
      expect(
        inKey(LumeDocScanTool.pagesKey, find.byType(LumeRichRow)),
        findsOneWidget,
      );
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      final LumeRichRow row = tester.widget(
        inKey(LumeDocScanTool.pagesKey, find.byType(LumeRichRow)),
      );
      expect(row.title, l.docscanPageN(1));
      expect(row.meta, <String>[l.docscanSourceCamera]);
    });

    testWidgets('From gallery: a chosen photo is marked as from the gallery', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/png',
        ),
      );
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.galleryKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(camera.requested, <String>['pickImage']);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      final LumeRichRow row = tester.widget(
        inKey(LumeDocScanTool.pagesKey, find.byType(LumeRichRow)),
      );
      expect(row.meta, <String>[l.docscanSourceGallery]);
    });

    testWidgets('capturing twice adds two pages, in order', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/jpeg',
        ),
      );
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      expect(
        tester
            .widgetList<LumeRichRow>(
              inKey(LumeDocScanTool.pagesKey, find.byType(LumeRichRow)),
            )
            .map((LumeRichRow r) => r.title),
        <String>[l.docscanPageN(1), l.docscanPageN(2)],
      );
    });

    for (final (Key button, LumeCaptureOutcome outcome)
        in <(Key, LumeCaptureOutcome)>[
          (LumeDocScanTool.captureKey, LumeCaptureOutcome.cancelled),
          (LumeDocScanTool.captureKey, LumeCaptureOutcome.denied),
          (LumeDocScanTool.captureKey, LumeCaptureOutcome.blocked),
          (LumeDocScanTool.captureKey, LumeCaptureOutcome.undetermined),
          (LumeDocScanTool.captureKey, LumeCaptureOutcome.restricted),
          (LumeDocScanTool.captureKey, LumeCaptureOutcome.failed),
          (LumeDocScanTool.galleryKey, LumeCaptureOutcome.cancelled),
          (LumeDocScanTool.galleryKey, LumeCaptureOutcome.denied),
          (LumeDocScanTool.galleryKey, LumeCaptureOutcome.failed),
        ]) {
      final String which = button == LumeDocScanTool.captureKey
          ? 'Capture'
          : 'Gallery';
      testWidgets('$which: ${outcome.name}', (WidgetTester tester) async {
        final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
          result: LumeCaptureResult(outcome),
        );
        await pumpDocscan(
          tester,
          overrides: <Override>[
            documentCameraProvider.overrideWithValue(camera),
          ],
        );
        final AppLocalizations l = AppLocalizations.of(
          tester.element(find.byType(LumeDocScanTool)),
        );
        final bool camera_ = button == LumeDocScanTool.captureKey;
        final String? expected = LumeDocScanTool.saying(
          l,
          outcome,
          camera: camera_,
        )?.$1;
        expect(await pressAndHear(tester, button), expected);
        expect(find.byKey(LumeDocScanTool.emptyKey), findsOneWidget);
      });
    }

    for (final (LumeCaptureOutcome outcome, bool offered)
        in <(LumeCaptureOutcome, bool)>[
          (LumeCaptureOutcome.blocked, true),
          (LumeCaptureOutcome.undetermined, true),
          (LumeCaptureOutcome.denied, false),
          (LumeCaptureOutcome.restricted, false),
          (LumeCaptureOutcome.failed, false),
        ]) {
      testWidgets('Capture: ${outcome.name} '
          '${offered ? 'offers' : 'does not offer'} Settings', (
        WidgetTester tester,
      ) async {
        final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
          result: LumeCaptureResult(outcome),
          settings: const <LumeCaptureOutcome>{
            LumeCaptureOutcome.blocked,
            LumeCaptureOutcome.undetermined,
          },
        );
        await pumpDocscan(
          tester,
          overrides: <Override>[
            documentCameraProvider.overrideWithValue(camera),
          ],
        );
        await tester.tap(find.byKey(LumeDocScanTool.captureKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final LumeToastData data = tester
            .widget<LumeToast>(find.byType(LumeToast))
            .data;
        final AppLocalizations l = AppLocalizations.of(
          tester.element(find.byType(LumeDocScanTool)),
        );
        expect(data.actionLabel, offered ? l.scanOpenSettings : isNull);
        if (offered) {
          await tester.tap(
            find.descendant(
              of: find.byType(LumeToast),
              matching: find.text(l.scanOpenSettings),
            ),
          );
          await tester.pump();
          expect(camera.requested, <String>['capture', 'openSettings']);
        }
        await tester.pump(const Duration(seconds: 7));
      });
    }

    testWidgets('removing a page takes only that one out', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/jpeg',
        ),
      );
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final Finder rows = inKey(
        LumeDocScanTool.pagesKey,
        find.byType(LumeRichRow),
      );
      expect(rows, findsNWidgets(2));
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      expect(
        tester.widgetList<LumeRichRow>(rows).map((LumeRichRow r) => r.title),
        <String>[l.docscanPageN(1), l.docscanPageN(2)],
      );

      final Finder removeButtons = inKey(
        LumeDocScanTool.pagesKey,
        find.byType(LumeIconButton),
      );
      expect(removeButtons, findsNWidgets(2));
      await tester.tap(removeButtons.first);
      await tester.pump();

      expect(rows, findsOneWidget);
      // The remaining page keeps its own title — nothing was renumbered from
      // whichever page was removed, because there is nothing to renumber:
      // each row's number is worked out fresh from its position each build.
      expect(
        tester.widget<LumeRichRow>(rows).title,
        l.docscanPageN(1),
      );
    });

    testWidgets('Clear all empties the pages and says so', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/jpeg',
        ),
      );
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(LumeDocScanTool.pagesKey), findsOneWidget);

      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      expect(await pressAndHear(tester, LumeDocScanTool.clearKey), l.docscanCleared);
      expect(find.byKey(LumeDocScanTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeDocScanTool.pagesKey), findsNothing);
    });

    testWidgets('Share: shared, dismissed, unavailable and failed', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/jpeg',
        ),
      );
      final LumeRecordingDocumentSharer sharer = LumeRecordingDocumentSharer();
      await pumpDocscan(
        tester,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
          documentSharerProvider.overrideWithValue(sharer),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeDocScanTool)),
      );
      sharer.outcome = LumeDocShareOutcome.shared;
      expect(await pressAndHear(tester, LumeDocScanTool.shareKey), l.shareShared);
      expect(sharer.shared, hasLength(1));
      expect(sharer.shared.single, hasLength(1));

      sharer.outcome = LumeDocShareOutcome.dismissed;
      expect(await pressAndHear(tester, LumeDocScanTool.shareKey), isNull);

      sharer.outcome = LumeDocShareOutcome.unavailable;
      expect(
        await pressAndHear(tester, LumeDocScanTool.shareKey),
        l.shareUnavailable,
      );

      sharer.outcome = LumeDocShareOutcome.failed;
      expect(
        await pressAndHear(tester, LumeDocScanTool.shareKey),
        l.docscanShareFailed,
      );
    });

    testWidgets('the result in Urdu, right to left, at 200 %', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDocumentCamera camera = LumeRecordingDocumentCamera(
        result: LumeCaptureResult(
          LumeCaptureOutcome.captured,
          bytes: _jpeg,
          mimeType: 'image/jpeg',
        ),
      );
      await pumpDocscan(
        tester,
        locale: const Locale('ur'),
        textScale: 2,
        overrides: <Override>[
          documentCameraProvider.overrideWithValue(camera),
        ],
      );
      await tester.tap(find.byKey(LumeDocScanTool.captureKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic', (WidgetTester tester) async {
      await pumpDocscan(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpDocscan(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
