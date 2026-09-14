/// QR Scanner, against the running reference, and used — the camera
/// instrument (F6A-D5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_scanner.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/qr/presentation/qr_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kQr = LumeRoutes.tool(LumeRoutes.tools, 'qr');

Future<void> pumpQr(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kQr,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: overrides,
  );
  // The beam sweeps forever: a frame, not a settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Future<String> pressAndHear(WidgetTester tester, Key button) async {
  await tester.ensureVisible(find.byKey(button));
  await tester.tap(find.byKey(button));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final LumeToast toast = tester.widget<LumeToast>(find.byType(LumeToast));
  final String said = toast.data.message;
  await tester.pump(const Duration(seconds: 6));
  return said;
}

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('qr');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'btnrow': find.byKey(LumeQrTool.actionsKey),
    'btn1': find.byKey(LumeQrTool.scanKey),
    'btn2': find.byKey(LumeQrTool.galleryKey),
    'tline': find.byKey(LumeQrTool.stepsKey),
    'rows': find.byKey(LumeQrTool.historyKey),
    'rrow1': inKey(LumeQrTool.historyKey, find.byType(LumeRichRow)).first,
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_qr_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_qr_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_qr_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpQr(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          // `sect1` is the section; the view is its first 232 points.
          noHeight: const <String>{'sect1'},
          drifting: const <String>{
            'tline',
            'rows',
            'rrow1',
            'srcbar',
            'related',
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpQr(tester, state: state);
        final Map<String, dynamic> k =
            webToolCell('tool_qr_${state}_390x844_light_en')!['composition']
                as Map<String, dynamic>;
        expect(
          tester
              .widgetList<LumeButton>(
                inKey(LumeQrTool.actionsKey, find.byType(LumeButton)),
              )
              .map((LumeButton b) => b.label)
              .toList(),
          (k['buttons'] as List<dynamic>).cast<String>(),
        );
        expect(
          <List<String?>>[
            for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
              inKey(LumeQrTool.historyKey, find.byType(LumeRichRow)),
            ))
              <String?>[r.title, r.subtitle],
          ],
          <List<String?>>[
            for (final dynamic r in k['rows'] as List<dynamic>)
              <String?>[
                (r as Map<String, dynamic>)['title'] as String?,
                r['sub'] as String?,
              ],
          ],
        );
        expect(
          tester
              .widget<LumeTimeline>(find.byKey(LumeQrTool.stepsKey))
              .entries
              .map((LumeTimelineEntry e) => e.title)
              .toList(),
          <String>[
            'Point at the code',
            'Lume reads it automatically',
            'Open, copy or save',
          ],
        );
        expect(find.text('Point the camera at a code'), findsOneWidget);
        final List<String> titles = <String>[
          for (final dynamic s in k['sections'] as List<dynamic>)
            if ((s as Map<String, dynamic>)['title'] != null)
              s['title'] as String,
        ];
        expect(<String>[
          for (final LumeToolSection s in tester.widgetList<LumeToolSection>(
            find.byType(LumeToolSection),
          ))
            if (s.title != null) s.title!,
        ], titles);
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
      });
    }
  });

  group('used', () {
    testWidgets('Scan says it cannot scan yet, and nothing reaches a camera '
        '(C78)', (WidgetTester tester) async {
      await pumpQr(tester, surface: const Size(390, 900));
      expect(
        await pressAndHear(tester, LumeQrTool.scanKey),
        "Scanning isn't available in this version yet",
      );
      expect(
        await pressAndHear(tester, LumeQrTool.galleryKey),
        "Scanning isn't available in this version yet",
      );
    });

    for (final (String name, LumeScanResult result, String said)
        in <(String, LumeScanResult, String)>[
          (
            'a code read',
            const LumeScanResult(LumeScanOutcome.read, 'https://lume.app'),
            'Read: https://lume.app',
          ),
          (
            'nothing in view',
            const LumeScanResult(LumeScanOutcome.nothing),
            'No code found',
          ),
          (
            'the camera refused',
            const LumeScanResult(LumeScanOutcome.denied),
            "Lume can't use the camera. You can allow it in Settings.",
          ),
          (
            'a failure',
            const LumeScanResult(LumeScanOutcome.failed),
            "Couldn't scan. Try again.",
          ),
        ]) {
      testWidgets('through the adapter: $name', (WidgetTester tester) async {
        final LumeRecordingScanner scanner = LumeRecordingScanner(
          result: result,
        );
        await pumpQr(
          tester,
          surface: const Size(390, 900),
          overrides: <Override>[scannerProvider.overrideWithValue(scanner)],
        );
        expect(await pressAndHear(tester, LumeQrTool.scanKey), said);
        expect(scanner.requested, <String>['scan']);
      });
    }

    testWidgets('the camera is never asked for at launch', (
      WidgetTester tester,
    ) async {
      final LumeRecordingScanner scanner = LumeRecordingScanner();
      await pumpQr(
        tester,
        overrides: <Override>[scannerProvider.overrideWithValue(scanner)],
      );
      expect(scanner.requested, isEmpty);
    });

    testWidgets('in Urdu', (WidgetTester tester) async {
      await pumpQr(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic', (WidgetTester tester) async {
      await pumpQr(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpQr(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
