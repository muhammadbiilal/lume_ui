/// QR Scanner, against the running reference, and used — the camera
/// instrument (F6A-D5), scanning for real behind its adapter (C80).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_dialer.dart';
import 'package:lume/core/platform/lume_link_opener.dart';
import 'package:lume/core/platform/lume_scanner.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/qr/presentation/qr_result_sheet.dart';
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

/// Presses Scan with [value] as the code the camera reads, and leaves the
/// result sheet open.
Future<void> scanRead(
  WidgetTester tester,
  String value, {
  List<Override> overrides = const <Override>[],
  Locale locale = const Locale('en'),
}) async {
  await pumpQr(
    tester,
    surface: const Size(390, 900),
    locale: locale,
    overrides: <Override>[
      scannerProvider.overrideWithValue(
        LumeRecordingScanner(
          result: LumeScanResult(LumeScanOutcome.read, value),
        ),
      ),
      ...overrides,
    ],
  );
  await tester.tap(find.byKey(LumeQrTool.scanKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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
    testWidgets('where nothing can scan, both say so', (
      WidgetTester tester,
    ) async {
      await pumpQr(tester, surface: const Size(390, 900));
      expect(
        await pressAndHear(tester, LumeQrTool.scanKey),
        "Scanning isn't available on this device",
      );
      expect(
        await pressAndHear(tester, LumeQrTool.galleryKey),
        "Scanning isn't available on this device",
      );
    });

    for (final (Key button, LumeScanOutcome outcome, String? said)
        in <(Key, LumeScanOutcome, String?)>[
          (LumeQrTool.scanKey, LumeScanOutcome.cancelled, null),
          (
            LumeQrTool.scanKey,
            LumeScanOutcome.denied,
            "Lume can't use the camera. Press Scan to be asked again.",
          ),
          (
            LumeQrTool.scanKey,
            LumeScanOutcome.blocked,
            'Camera access for Lume is off. Turn it on in Settings to scan.',
          ),
          (
            LumeQrTool.scanKey,
            LumeScanOutcome.undetermined,
            "Lume can't use the camera. Press Scan to be asked again, or turn "
                "it on in Settings if Android doesn't ask.",
          ),
          (
            LumeQrTool.scanKey,
            LumeScanOutcome.restricted,
            'The camera is turned off on this device by a restriction or its '
                'administrator.',
          ),
          (
            LumeQrTool.scanKey,
            LumeScanOutcome.failed,
            "Couldn't scan. Try again.",
          ),
          (LumeQrTool.galleryKey, LumeScanOutcome.cancelled, null),
          (LumeQrTool.galleryKey, LumeScanOutcome.nothing, 'No code found'),
          (
            LumeQrTool.galleryKey,
            LumeScanOutcome.denied,
            "Lume can't open your photos. You can allow it in Settings.",
          ),
          (
            LumeQrTool.galleryKey,
            LumeScanOutcome.multiple,
            'That image has more than one QR code. Choose one with a single '
                'code.',
          ),
          (
            LumeQrTool.galleryKey,
            LumeScanOutcome.unsupported,
            "That code isn't a QR code",
          ),
          (
            LumeQrTool.galleryKey,
            LumeScanOutcome.unreadable,
            "Lume couldn't read that image",
          ),
          (
            LumeQrTool.galleryKey,
            LumeScanOutcome.tooLarge,
            'That image is too large to read',
          ),
          (
            LumeQrTool.galleryKey,
            LumeScanOutcome.failed,
            "Couldn't scan. Try again.",
          ),
        ]) {
      final String which = button == LumeQrTool.scanKey ? 'Scan' : 'Gallery';
      testWidgets('$which: ${outcome.name}', (WidgetTester tester) async {
        final LumeRecordingScanner scanner = LumeRecordingScanner(
          result: LumeScanResult(outcome),
        );
        await pumpQr(
          tester,
          surface: const Size(390, 900),
          overrides: <Override>[scannerProvider.overrideWithValue(scanner)],
        );
        expect(await pressAndHear(tester, button), said);
        expect(scanner.requested, <String>[
          button == LumeQrTool.scanKey ? 'scan' : 'pickImage',
        ]);
        expect(find.byType(LumeQrResultSheet), findsNothing);
      });
    }

    // C80, F6B closure: a Settings action only where Settings can change the
    // permission, and only where the scanner can open it.
    for (final (LumeScanOutcome outcome, bool offered)
        in <(LumeScanOutcome, bool)>[
          (LumeScanOutcome.blocked, true),
          (LumeScanOutcome.undetermined, true),
          (LumeScanOutcome.denied, false),
          (LumeScanOutcome.restricted, false),
          (LumeScanOutcome.failed, false),
        ]) {
      testWidgets('Scan: ${outcome.name} '
          '${offered ? 'offers' : 'does not offer'} Settings', (
        WidgetTester tester,
      ) async {
        final LumeRecordingScanner scanner = LumeRecordingScanner(
          result: LumeScanResult(outcome),
          settings: const <LumeScanOutcome>{
            LumeScanOutcome.blocked,
            LumeScanOutcome.undetermined,
          },
        );
        await pumpQr(
          tester,
          surface: const Size(390, 900),
          overrides: <Override>[scannerProvider.overrideWithValue(scanner)],
        );
        await tester.tap(find.byKey(LumeQrTool.scanKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final LumeToastData data = tester
            .widget<LumeToast>(find.byType(LumeToast))
            .data;
        expect(data.actionLabel, offered ? 'Settings' : isNull);
        if (offered) {
          await tester.tap(
            find.descendant(
              of: find.byType(LumeToast),
              matching: find.text('Settings'),
            ),
          );
          await tester.pump();
          expect(scanner.requested, <String>['scan', 'openSettings']);
        }
        await tester.pump(const Duration(seconds: 7));
      });
    }

    testWidgets('a scanner that offers nothing draws no Settings action', (
      WidgetTester tester,
    ) async {
      final LumeRecordingScanner scanner = LumeRecordingScanner(
        result: const LumeScanResult(LumeScanOutcome.blocked),
      );
      await pumpQr(
        tester,
        surface: const Size(390, 900),
        overrides: <Override>[scannerProvider.overrideWithValue(scanner)],
      );
      await tester.tap(find.byKey(LumeQrTool.scanKey));
      await tester.pump();
      expect(
        tester.widget<LumeToast>(find.byType(LumeToast)).data.actionLabel,
        isNull,
      );
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('Settings that will not open is said', (
      WidgetTester tester,
    ) async {
      final LumeRecordingScanner scanner = LumeRecordingScanner(
        result: const LumeScanResult(LumeScanOutcome.blocked),
        settings: const <LumeScanOutcome>{LumeScanOutcome.blocked},
        settingsOpen: false,
      );
      await pumpQr(
        tester,
        surface: const Size(390, 900),
        overrides: <Override>[scannerProvider.overrideWithValue(scanner)],
      );
      await tester.tap(find.byKey(LumeQrTool.scanKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Settings'),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<LumeToast>(find.byType(LumeToast)).data.message,
        "Settings didn't open. You'll find Lume under Apps in your phone's "
        'Settings.',
      );
      await tester.pump(const Duration(seconds: 7));
    });

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

    testWidgets('a link read is shown first, and opens only on a press', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLinkOpener opener = LumeRecordingLinkOpener();
      await scanRead(
        tester,
        'https://lume.app/tools',
        overrides: <Override>[linkOpenerProvider.overrideWithValue(opener)],
      );
      expect(find.byType(LumeQrResultSheet), findsOneWidget);
      expect(tester.widget<LumeSheet>(find.byType(LumeSheet)).title, 'Website');
      expect(
        tester
            .widget<LumeRichRow>(find.byKey(LumeQrResultSheet.destinationKey))
            .title,
        contains('lume.app'),
      );
      expect(find.text('https://lume.app/tools'), findsOneWidget);
      expect(opener.requested, isEmpty, reason: 'nothing opens by itself');

      await tester.tap(find.byKey(LumeQrResultSheet.openKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opener.opened, <Uri>[Uri.parse('https://lume.app/tools')]);
      expect(find.byType(LumeQrResultSheet), findsNothing);
    });

    testWidgets('an http link says it is not secure', (
      WidgetTester tester,
    ) async {
      await scanRead(tester, 'http://example.com');
      expect(
        tester
            .widget<LumeRichRow>(find.byKey(LumeQrResultSheet.destinationKey))
            .subtitle,
        "Not secure — this site's connection isn't encrypted",
      );
    });

    testWidgets('a link nothing on the device opens says so, and stays', (
      WidgetTester tester,
    ) async {
      await scanRead(
        tester,
        'https://lume.app',
        overrides: <Override>[
          linkOpenerProvider.overrideWithValue(
            LumeRecordingLinkOpener(outcome: LumeOpenOutcome.unavailable),
          ),
        ],
      );
      await tester.tap(find.byKey(LumeQrResultSheet.openKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<LumeToast>(find.byType(LumeToast)).data.message,
        'Nothing on this device can open it',
      );
      expect(find.byType(LumeQrResultSheet), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a refused scheme is shown and cannot be opened', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLinkOpener opener = LumeRecordingLinkOpener();
      await scanRead(
        tester,
        'javascript:alert(1)',
        overrides: <Override>[linkOpenerProvider.overrideWithValue(opener)],
      );
      expect(
        tester.widget<LumeSheet>(find.byType(LumeSheet)).title,
        "A link Lume won't open",
      );
      expect(find.byKey(LumeQrResultSheet.openKey), findsNothing);
      expect(
        find.text("Lume doesn't open this kind of link. You can copy it."),
        findsOneWidget,
      );
      expect(find.text('javascript:alert(1)'), findsOneWidget);
      expect(opener.requested, isEmpty);
    });

    testWidgets('Wi-Fi: the network is shown, the password never is, and '
        'Copy copies the network name', (WidgetTester tester) async {
      final List<String?> copied = <String?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text'] as String?,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await scanRead(tester, 'WIFI:T:WPA;S:Home-WiFi;P:hunter22;;');
      expect(
        tester.widget<LumeSheet>(find.byType(LumeSheet)).title,
        'Wi-Fi network',
      );
      expect(find.textContaining('hunter22'), findsNothing);
      expect(find.byKey(LumeQrResultSheet.openKey), findsNothing);
      await tester.tap(find.byKey(LumeQrResultSheet.copyKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(copied, <String?>['Home-WiFi']);
      expect(
        tester.widget<LumeToast>(find.byType(LumeToast)).data.message,
        'Copied',
      );
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a number goes to the dialer, never a call, only on a press', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDialer dialer = LumeRecordingDialer();
      await scanRead(
        tester,
        'tel:+923001234567',
        overrides: <Override>[dialerProvider.overrideWithValue(dialer)],
      );
      expect(dialer.requested, isEmpty);
      expect(
        tester.widget<LumeButton>(find.byKey(LumeQrResultSheet.openKey)).label,
        'Open in Phone',
      );
      await tester.tap(find.byKey(LumeQrResultSheet.openKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(dialer.dialled.map((LumeDialNumber n) => n.dialable), <String>[
        '+923001234567',
      ]);
    });

    testWidgets('a message goes to the number without the code\'s text', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLinkOpener opener = LumeRecordingLinkOpener();
      await scanRead(
        tester,
        'SMSTO:+447700900123:Reply WIN to claim',
        overrides: <Override>[linkOpenerProvider.overrideWithValue(opener)],
      );
      expect(
        find.text("The code's own message text isn't filled in"),
        findsOneWidget,
      );
      await tester.tap(find.byKey(LumeQrResultSheet.openKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opener.opened, <Uri>[Uri(scheme: 'sms', path: '+447700900123')]);
    });

    testWidgets('a scan is never added to the history', (
      WidgetTester tester,
    ) async {
      await scanRead(tester, 'https://lume.app/new');
      Navigator.of(tester.element(find.byType(LumeQrResultSheet))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widgetList<LumeRichRow>(
              inKey(LumeQrTool.historyKey, find.byType(LumeRichRow)),
            )
            .map((LumeRichRow r) => r.title),
        <String>['lume.app/tools', 'Home-WiFi'],
      );
    });

    testWidgets('the result in Urdu, right to left, at 200 %', (
      WidgetTester tester,
    ) async {
      await pumpQr(
        tester,
        surface: const Size(390, 900),
        locale: const Locale('ur'),
        textScale: 2,
        overrides: <Override>[
          scannerProvider.overrideWithValue(
            LumeRecordingScanner(
              result: const LumeScanResult(
                LumeScanOutcome.read,
                'http://example.com/a-very-long-path/that-keeps-going',
              ),
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(LumeQrTool.scanKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LumeQrResultSheet), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(LumeQrResultSheet))),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
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
