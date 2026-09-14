/// Emergency, against the running reference, and used.
///
/// Every press goes to a [LumeRecordingDialer]: the test proves the number
/// handed over is the number drawn and announced, and that nothing reaches the
/// platform (D6).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_dialer.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/emergency/presentation/emergency_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kEmergency = LumeRoutes.tool(LumeRoutes.tools, 'emergency');

Future<LumeRecordingDialer> pumpEmergency(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  LumeDialOutcome outcome = LumeDialOutcome.opened,
}) async {
  final LumeRecordingDialer dialer = LumeRecordingDialer(outcome: outcome);
  await pumpLumeRouter(
    tester,
    initialLocation: kEmergency,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: <Override>[dialerProvider.overrideWithValue(dialer)],
  );
  await tester.pumpAndSettle();
  return dialer;
}

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('emergency');
  tearDownAll(parity.write);

  Finder callTile(int i) => find
      .descendant(
        of: find.byKey(LumeEmergencyTool.callsKey),
        matching: find.byType(LumeCallTile),
      )
      .at(i);

  Finder inside(Finder of, Finder matching) =>
      find.descendant(of: of, matching: matching).first;

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'ctxbar': find.byType(LumeContextBar),
    'sos': find.byKey(LumeEmergencyTool.sosKey),
    'sos.name': find.text('Rescue 1122'),
    'sos.kind': find.text('Ambulance & rescue'),
    'sos.num': inside(find.byKey(LumeEmergencyTool.sosKey), find.text('1122')),
    'sect3.title': find.text('Other services'),
    'calls': find.byKey(LumeEmergencyTool.callsKey),
    'call1': callTile(0),
    'call2': callTile(1),
    'call3': callTile(2),
    'call.name': find.text('Police'),
    'call.num': inside(callTile(0), find.text('15')),
    'call.kind': find.text('Police emergency'),
    'rows': find.byKey(LumeEmergencyTool.infoKey),
    'crow1': find.byType(LumeCompactRow).first,
    'crow.label': find.text('Medical details'),
    'crow.value': find.text('Set up'),
  };

  /// Under the rows: held to the reference shifted by what the rows add.
  Map<String, Finder> below() => <String, Finder>{
    'notecard': find.byKey(LumeEmergencyTool.noteKey),
    'notecard.title': find.text('Numbers work without signal'),
    'notecard.text': find.textContaining('Emergency numbers can usually'),
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> textBlocks = <String>{
    'sos.name',
    'sos.kind',
    'call.name',
    'call.num',
    'call.kind',
    'crow.label',
    'crow.value',
    'notecard.title',
    'sect3.title',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_emergency_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_emergency_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_emergency_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpEmergency(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          // C62 — a pressable row keeps its 44-point target, taller than
          // `button.crow`; its words stay centred within it.
          noHeight: <String>{'rows', 'crow1'},
          drifting: <String>{'crow.label', 'crow.value'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));

        final Map<String, dynamic> web =
            webToolCell(cell)!['bounds'] as Map<String, dynamic>;
        Rect webRect(String k) {
          final Map<String, dynamic> b = web[k] as Map<String, dynamic>;
          return Rect.fromLTWH(
            (b['x'] as num).toDouble(),
            (b['y'] as num).toDouble(),
            (b['width'] as num).toDouble(),
            (b['height'] as num).toDouble(),
          );
        }

        final Offset webOrigin = webRect('toolbar').topLeft;
        final Offset origin = tester.getTopLeft(find.byType(LumeToolbar));
        final double added =
            tester.getSize(find.byKey(LumeEmergencyTool.infoKey)).height -
            webRect('rows').height;
        expect(
          added,
          12,
          reason: 'three 44-point rows where the reference has 124',
        );
        for (final MapEntry<String, Finder> e in below().entries) {
          final Rect w = webRect(e.key).shift(-webOrigin);
          final Rect f = tester.getRect(e.value).shift(-origin);
          expect(
            (f.left - w.left).abs(),
            lessThanOrEqualTo(1),
            reason: '${e.key}.x',
          );
          expect(
            (f.top - added - w.top).abs(),
            lessThanOrEqualTo(1),
            reason: '${e.key}.y',
          );
          expect(
            (f.height - w.height).abs(),
            lessThanOrEqualTo(1),
            reason: '${e.key}.height',
          );
        }
      });
    }
  });

  group('what it says, for each reader the reference was captured for', () {
    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
      'default_ae',
      'default_jp',
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpEmergency(tester, state: state);
        final Map<String, dynamic> k =
            webToolCell(
                  'tool_emergency_${state}_390x844_light_en',
                )!['composition']
                as Map<String, dynamic>;
        final Map<String, dynamic> e = k['emergency'] as Map<String, dynamic>;

        expect(
          find.text((k['header'] as Map<String, dynamic>)['sub'] as String),
          findsOneWidget,
        );
        expect(
          textsUnder(tester, find.byType(LumeContextBar)),
          (k['context'] as List<dynamic>).cast<String>(),
        );
        expect(
          textsUnder(tester, find.byKey(LumeEmergencyTool.sosKey)),
          <String>[
            e['name'] as String,
            e['kind'] as String,
            e['num'] as String,
          ],
        );
        expect(
          textsUnder(tester, find.byKey(LumeEmergencyTool.callsKey)),
          <String>[
            for (final dynamic c in e['calls'] as List<dynamic>) ...<String>[
              (c as Map<String, dynamic>)['name'] as String,
              c['num'] as String,
              c['kind'] as String,
            ],
          ],
        );
        expect(
          textsUnder(tester, find.byKey(LumeEmergencyTool.infoKey)),
          <String>[
            for (final dynamic c in e['info'] as List<dynamic>) ...<String>[
              (c as Map<String, dynamic>)['label'] as String,
              c['value'] as String,
            ],
          ],
        );
        // The composition reads `.note`, which the stylesheet calls
        // `.notecard`; the note's words are in the measured bounds.
        final Map<String, dynamic> b =
            webToolCell('tool_emergency_${state}_390x844_light_en')!['bounds']
                as Map<String, dynamic>;
        expect(
          textsUnder(tester, find.byKey(LumeEmergencyTool.noteKey)),
          <String>[
            (b['notecard.title'] as Map<String, dynamic>)['text'] as String,
            (b['notecard.text'] as Map<String, dynamic>)['text'] as String,
          ],
        );
        final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
        expect(find.text(src['fresh'] as String), findsOneWidget);
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
      });
    }
  });

  group('every number opens the dialer with that number, and never calls', () {
    testWidgets('the primary number and each other one', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDialer dialer = await pumpEmergency(
        tester,
        state: 'muslim_gb',
      );
      await tester.tap(find.byKey(LumeEmergencyTool.sosKey));
      await tester.pump();
      for (int i = 0; i < 3; i++) {
        await tester.ensureVisible(callTile(i));
        await tester.tap(callTile(i));
        await tester.pump();
      }
      expect(dialer.requested, <String>['999', '111', '101', '0800 111 999']);
      // What was handed over is what is drawn on the tile.
      expect(textsUnder(tester, callTile(2)), contains(dialer.requested.last));
      expect(dialer.dialled.last.uri.toString(), 'tel:0800111999');
      // An opened dialer says nothing, as the reference says nothing.
      expect(find.byType(LumeToolFrame), findsOneWidget);
      expect(find.textContaining('phone app'), findsNothing);
    });

    testWidgets('each one is announced as the call it makes', (
      WidgetTester tester,
    ) async {
      await pumpEmergency(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(LumeEmergencyTool.sosKey)),
        // `<a href="tel:…">` — a link, as the reference writes it.
        isSemantics(
          label: 'Call Rescue 1122 at \u20661122\u2069',
          isLink: true,
          hasTapAction: true,
        ),
      );
      final SemanticsNode police = tester.getSemantics(callTile(0));
      expect(police.label, 'Call Police at \u206615\u2069');
      expect(police.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      h.dispose();
    });

    testWidgets('a dialer that fails is said out loud', (
      WidgetTester tester,
    ) async {
      await pumpEmergency(tester, outcome: LumeDialOutcome.failed);
      await tester.tap(find.byKey(LumeEmergencyTool.sosKey));
      await tester.pump();
      expect(
        find.text('Couldn’t open the phone app. Dial 1122 yourself.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a device that cannot dial says so', (
      WidgetTester tester,
    ) async {
      await pumpEmergency(tester, outcome: LumeDialOutcome.unavailable);
      await tester.tap(callTile(0));
      await tester.pump();
      expect(
        find.text('This device can’t make calls. Dial 15 from a phone.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a dismissed hand-off says nothing', (
      WidgetTester tester,
    ) async {
      final LumeRecordingDialer dialer = await pumpEmergency(
        tester,
        outcome: LumeDialOutcome.cancelled,
      );
      await tester.tap(callTile(1));
      await tester.pump();
      expect(dialer.requested, <String>['16']);
      expect(find.textContaining('phone app'), findsNothing);
      expect(find.textContaining('make calls'), findsNothing);
    });
  });

  group('your information', () {
    testWidgets('sharing the location copies city and country, then says so', (
      WidgetTester tester,
    ) async {
      final List<String> copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
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
      await pumpEmergency(tester);
      await tester.tap(find.text('Share my location'));
      await tester.pump();
      expect(copied, <String>['Islamabad, Pakistan']);
      expect(find.text('Location copied to share'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    for (final (String row, String title) in <(String, String)>[
      ('Medical details', 'Health Records'),
      ('Identity documents', 'Documents'),
    ]) {
      testWidgets('$row opens $title', (WidgetTester tester) async {
        await pumpEmergency(tester);
        await tester.tap(find.text(row));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(LumeToolbar),
            matching: find.text(title),
          ),
          findsOneWidget,
        );
      });
    }
  });

  group('everywhere', () {
    testWidgets('right to left, numbers still read left to right', (
      WidgetTester tester,
    ) async {
      await pumpEmergency(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      final Finder num = inside(
        find.byKey(LumeEmergencyTool.sosKey),
        find.text('1122'),
      );
      expect(Directionality.of(tester.element(num)), TextDirection.ltr);
      // The number sits at the start of the reading order's end: the left.
      expect(
        tester.getCenter(num).dx,
        lessThan(
          tester
              .getCenter(
                inside(
                  find.byKey(LumeEmergencyTool.sosKey),
                  find.text('ریسکیو 1122'),
                ),
              )
              .dx,
        ),
      );
      // The first call tile leads from the right.
      expect(
        tester.getCenter(callTile(0)).dx,
        greaterThan(tester.getCenter(callTile(1)).dx),
      );
      expect(find.text('پولیس'), findsOneWidget);
      expect(find.text('Police'), findsNothing);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpEmergency(tester, textScale: 2);
      expectNoOverflow(tester);
    });

    testWidgets('the note is a plain note, not an action', (
      WidgetTester tester,
    ) async {
      await pumpEmergency(tester);
      expect(
        find.descendant(
          of: find.byKey(LumeEmergencyTool.noteKey),
          matching: find.byType(LumeNoteCard),
        ),
        findsNothing,
        reason: 'the key is on the note itself',
      );
      expect(find.byType(LumeNoteCard), findsOneWidget);
    });
  });
}
