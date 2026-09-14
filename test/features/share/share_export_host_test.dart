/// Share and Export through the tool host, on Tax (D7).
///
/// Every device service is a recording fake, so nothing here opens a share
/// sheet or writes a file; what the tests prove is what was handed over, and
/// that the reader is told only what the platform reported.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/features/share/presentation/share_sheet.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

class TaxServices {
  TaxServices({
    LumeShareOutcome share = LumeShareOutcome.shared,
    LumeImageSaver? saver,
    LumeExportOutcome export = LumeExportOutcome.saved,
  }) : sharer = LumeRecordingSharer(outcome: share),
       saver = saver ?? LumeRecordingImageSaver(),
       exporter = LumeRecordingExporter(outcome: export);

  final LumeRecordingSharer sharer;
  final LumeImageSaver saver;
  final LumeRecordingExporter exporter;

  List<Override> get overrides => <Override>[
    sharerProvider.overrideWithValue(sharer),
    imageSaverProvider.overrideWithValue(saver),
    exporterProvider.overrideWithValue(exporter),
  ];
}

Future<void> pumpTaxWith(
  WidgetTester tester,
  TaxServices services, {
  String state = 'default_pk',
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 900),
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kTaxLocation,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    overrides: services.overrides,
  );
  await tester.pumpAndSettle();
}

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

/// A PNG's width and height, from its IHDR chunk.
(int, int) pngSize(Uint8List png) {
  final ByteData d = ByteData.sublistView(png);
  return (d.getUint32(16), d.getUint32(20));
}

/// Presses a control whose work renders an image — engine work a fake-async
/// test cannot finish — and lets the result land.
Future<void> pressAndRender(WidgetTester tester, Finder control) async {
  await tester.runAsync(() async {
    await tester.tap(control);
    for (int i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pump();
}

void main() {
  setUpAll(loadLumeFonts);

  group('Share', () {
    testWidgets('the tool bar opens the card sheet with what the screen says', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices();
      await pumpTaxWith(tester, s);
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();

      expect(find.byType(LumeShareSheet), findsOneWidget);
      expect(find.text('Your card is ready'), findsOneWidget);
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.reminder);
      // `t('tax.dueAnnual') + ': ' + …` — the result card's own kicker.
      expect(card.text, startsWith('Tax a year: '));
      expect(card.text, contains('Effective rate'));
      expect(card.source, 'FBR salaried slabs · 2025-26');

      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(LumeShareSheet.previewKey)).label,
        'Share card preview: ${card.caption}',
      );
      h.dispose();
    });

    testWidgets(
      'Share hands over the card as a 1080 × 1350 image, then says so',
      (WidgetTester tester) async {
        final TaxServices s = TaxServices();
        await pumpTaxWith(tester, s);
        await tester.tap(toolbarAction('Share'));
        await tester.pumpAndSettle();
        await pressAndRender(tester, find.byKey(LumeShareSheet.sendKey));

        final LumeSharedImage shared = s.sharer.shared.single;
        expect(pngSize(shared.png), (1080, 1350));
        expect(shared.fileName, 'lume-reminder.png');
        expect(shared.caption, contains(' — FBR salaried slabs · 2025-26'));
        expect(find.text('Shared'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets('a dismissed share sheet says nothing', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices(share: LumeShareOutcome.dismissed);
      await pumpTaxWith(tester, s);
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      await pressAndRender(tester, find.byKey(LumeShareSheet.sendKey));

      expect(s.sharer.shared, hasLength(1));
      expect(find.byType(LumeToast), findsNothing);
    });

    testWidgets('a platform without a share sheet is said', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices(share: LumeShareOutcome.unavailable);
      await pumpTaxWith(tester, s);
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      await pressAndRender(tester, find.byKey(LumeShareSheet.sendKey));
      expect(
        find.text('Sharing isn’t available on this device'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Save image says it saved only when it did', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices();
      await pumpTaxWith(tester, s);
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      await pressAndRender(tester, find.byKey(LumeShareSheet.saveKey));
      expect(
        (s.saver as LumeRecordingImageSaver).saved.single.fileName,
        'lume-reminder.png',
      );
      expect(find.text('Image saved'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('the production saver says it cannot save yet', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices(
        saver: const LumeUnavailableImageSaver(),
      );
      await pumpTaxWith(tester, s);
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      await pressAndRender(tester, find.byKey(LumeShareSheet.saveKey));
      expect(
        find.text('Saving images isn’t available yet — use Share to save it'),
        findsOneWidget,
      );
      expect(find.text('Image saved'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('the body’s Share opens the same sheet', (
      WidgetTester tester,
    ) async {
      await pumpTaxWith(tester, TaxServices(), surface: const Size(390, 5000));
      final Finder body = find.widgetWithText(LumeButton, 'Share');
      await tester.ensureVisible(body);
      await tester.tap(body);
      await tester.pumpAndSettle();
      expect(find.byType(LumeShareSheet), findsOneWidget);
    });

    testWidgets('a market with no income tax shares what the screen says', (
      WidgetTester tester,
    ) async {
      await pumpTaxWith(tester, TaxServices(), state: 'default_ae');
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.text, startsWith('No personal income tax · Take-home: '));
    });

    testWidgets('an Urdu card reads right to left', (
      WidgetTester tester,
    ) async {
      await pumpTaxWith(tester, TaxServices(), locale: const Locale('ur'));
      await tester.tap(
        find
            .descendant(
              of: find.byType(LumeToolbar),
              matching: find.byType(LumeIconButton),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(LumeShareCardArt))),
        TextDirection.rtl,
      );
    });
  });

  group('Export', () {
    testWidgets('the bands leave as the reference’s CSV, and it says where', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices();
      await pumpTaxWith(tester, s);
      await tester.tap(toolbarAction('Export'));
      await tester.pump();

      final LumeExportFile file = s.exporter.exported.single;
      expect(file.fileName, 'lume-tax-2026-09-07.csv');
      expect(file.mimeType, 'text/csv;charset=utf-8');
      final List<String> lines = file.text.split('\r\n');
      // The table's own column heads, in the reader's language.
      expect(lines.first, 'Band,Rate,Tax in band');
      expect(lines.length, greaterThan(2));
      expect(find.text('Saved lume-tax-2026-09-07.csv'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a cancelled export says nothing; a failed one says so', (
      WidgetTester tester,
    ) async {
      final TaxServices cancelled = TaxServices(
        export: LumeExportOutcome.cancelled,
      );
      await pumpTaxWith(tester, cancelled);
      await tester.tap(toolbarAction('Export'));
      await tester.pump();
      expect(cancelled.exporter.exported, hasLength(1));
      expect(find.byType(LumeToast), findsNothing);

      final TaxServices failed = TaxServices(export: LumeExportOutcome.failed);
      await pumpTaxWith(tester, failed);
      await tester.tap(toolbarAction('Export'));
      await tester.pump();
      expect(find.text('Couldn’t write the file'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a market with no income tax exports the JSON record', (
      WidgetTester tester,
    ) async {
      final TaxServices s = TaxServices();
      await pumpTaxWith(tester, s, state: 'default_ae');
      await tester.tap(toolbarAction('Export'));
      await tester.pump();
      final LumeExportFile file = s.exporter.exported.single;
      expect(file.fileName, 'lume-tax-2026-09-07.json');
      expect(jsonDecode(file.text), containsPair('currency', 'AED'));
      expect(jsonDecode(file.text), containsPair('locale', 'en-AE'));
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
