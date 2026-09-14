/// Documents, against the running reference, and used — the record family
/// that deletes for good.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/documents/presentation/documents_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kDocuments = LumeRoutes.tool(LumeRoutes.tools, 'documents');

Future<GoRouter> pumpDocuments(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kDocuments,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
  return router;
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

/// The box a chip or option draws, inside its larger target.
Finder drawn(Type parent, double height) => find.descendant(
  of: find.byType(parent),
  matching: find.byWidgetPredicate(
    (Widget w) => w is Container && w.constraints?.minHeight == height,
  ),
);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        (w is LumeIconButton && w.label == label) ||
        (w is LumeTextButton && w.label == label),
  ),
);

List<String> recordTitles(WidgetTester tester) => tester
    .widgetList<LumeRecordRow>(find.byType(LumeRecordRow))
    .map((LumeRecordRow r) => r.title)
    .toList();

String badgeText(LumeBadge? b) =>
    b == null ? '' : '${LumeBadge.glyphFor(b.tone) ?? ''}${b.label}';

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> openFirstRecord(WidgetTester tester) =>
    tapVisible(tester, find.byType(LumeRecordRow).first);

Future<void> openForm(WidgetTester tester) =>
    tapVisible(tester, find.byKey(LumeDocumentsTool.addKey));

Future<void> dismissToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('documents');
  tearDownAll(parity.write);

  Map<String, Finder> listElements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'toolbar.textbtn': find.byKey(LumeDocumentsTool.addKey),
    'search': find.byKey(LumeDocumentsTool.searchKey),
    'recs': find.byKey(LumeDocumentsTool.recordsKey),
    'rrec1': find.byType(LumeRecordRow).first,
    'rrec2': find.byType(LumeRecordRow).at(1),
    'summary': find.byKey(LumeDocumentsTool.summaryKey),
    'notecard': find.byKey(LumeDocumentsTool.renewKey),
    'fchip1': drawn(LumeFilterChip, LumeFilterChip.height).first,
    'fchip2': drawn(LumeFilterChip, LumeFilterChip.height).at(1),
    'sortopt1': drawn(LumeSortBar, LumeSortBar.optionHeight).first,
    'sortopt2': drawn(LumeSortBar, LumeSortBar.optionHeight).at(1),
    'rows': find.byKey(LumeDocumentsTool.attentionKey),
    'rrow1': inKey(
      LumeDocumentsTool.attentionKey,
      find.byType(LumeRichRow),
    ).first,
    'rrow2': inKey(
      LumeDocumentsTool.attentionKey,
      find.byType(LumeRichRow),
    ).at(1),
    'btnrow': find.byKey(LumeDocumentsTool.actionsKey),
    'btn1': inKey(LumeDocumentsTool.actionsKey, find.byType(LumeButton)).first,
    'btn2': inKey(LumeDocumentsTool.actionsKey, find.byType(LumeButton)).last,
    'srcbar': find.byType(LumeSourceBar),
    'privacy': find.byType(LumePrivateState),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> below = <String>{
    'fchip1',
    'fchip2',
    'sortopt1',
    'sortopt2',
    'rows',
    'rrow1',
    'rrow2',
    'btnrow',
    'btn1',
    'btn2',
    'srcbar',
    'privacy',
    'related',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_documents_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_documents_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_documents_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpDocuments(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{...listElements()}..removeWhere(
            // The note is text: at 650 and 1050 against 700 and 1100 it wraps
            // differently, and what follows it moves by that line.
            (String k, _) => size.width > 390 && k == 'related',
          ),
          noHeight: <String>{if (size.width > 390) 'privacy'},
          drifting: below,
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    testWidgets('tool_documents_default_pk_detail_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester);
      await openFirstRecord(tester);
      final List<String> misses = parity.bounds(
        tester,
        'tool_documents_default_pk_detail_390x844_light_en',
        <String, Finder>{
          'toolbar': find.byType(LumeToolbar),
          'chero': find.byKey(LumeDocumentsTool.heroKey),
          'cfacts': find.byKey(LumeDocumentsTool.factsKey),
          'cacts': find.byKey(LumeDocumentsTool.detailActionsKey),
          'crud.id': find.byKey(LumeDocumentsTool.recordIdKey),
        },
        noWidth: const <String>{'crud.id'},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });

    testWidgets('tool_documents_default_pk_new_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester);
      await openForm(tester);
      final List<String> misses = parity.bounds(
        tester,
        'tool_documents_default_pk_new_390x844_light_en',
        <String, Finder>{
          'toolbar': find.byType(LumeToolbar),
          'cform': find.byKey(LumeDocumentsTool.formKey),
          'cfield1': find.byKey(LumeDocumentsTool.fieldKey('name')),
          'cfield2': find.byKey(LumeDocumentsTool.fieldKey('cat')),
          'csubmit': find.byKey(LumeDocumentsTool.submitKey),
        },
        noHeight: const <String>{'cform'},
        drifting: const <String>{'csubmit'},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });
  });

  group('what it says, in each state the reference was captured in', () {
    Map<String, dynamic> composition(String cell) =>
        webToolCell(cell)!['composition'] as Map<String, dynamic>;

    List<String> strings(Object? v) => (v as List<dynamic>).cast<String>();

    // The reference writes "1 files"; it is plural here (C75).
    List<String> files(List<String> meta) => <String>[
      for (final String m in meta) m.replaceAll(RegExp(r'^1 files$'), '1 file'),
    ];

    void expectHeader(WidgetTester tester, Map<String, dynamic> k) {
      final Map<String, dynamic> h = k['header'] as Map<String, dynamic>;
      final LumeToolbar bar = tester.widget<LumeToolbar>(
        find.byType(LumeToolbar),
      );
      expect(
        <String?>[bar.title, bar.subtitle],
        <String?>[h['title'] as String?, h['sub'] as String?],
      );
      for (final dynamic a in h['actions'] as List<dynamic>) {
        final Map<String, dynamic> m = a as Map<String, dynamic>;
        final String label = (m['text'] ?? m['label']) as String;
        expect(toolbarAction(label), findsOneWidget, reason: label);
      }
    }

    void expectList(WidgetTester tester, String cell) {
      final Map<String, dynamic> k = composition(cell);
      final Map<String, dynamic> r = k['records'] as Map<String, dynamic>;
      expectHeader(tester, k);

      expect(
        tester
            .widget<LumeSearchField>(find.byKey(LumeDocumentsTool.searchKey))
            .placeholder,
        r['placeholder'],
      );
      expect(find.byType(LumeRecordChip), findsNothing);
      final List<dynamic> states = r['states'] as List<dynamic>;
      if (states.isEmpty) {
        expect(
          <List<String?>>[
            for (final LumeRecordRow row in tester.widgetList<LumeRecordRow>(
              find.byType(LumeRecordRow),
            ))
              <String?>[
                row.initial,
                row.title,
                row.subtitle,
                badgeText(row.badge),
              ],
          ],
          <List<String?>>[
            for (final dynamic w in r['rows'] as List<dynamic>)
              <String?>[
                (w as Map<String, dynamic>)['initial'] as String?,
                w['title'] as String?,
                w['sub'] as String?,
                w['badge'] as String?,
              ],
          ],
        );
      } else {
        final Map<String, dynamic> s = states.single as Map<String, dynamic>;
        final LumeCollectionState st = tester.widget<LumeCollectionState>(
          find.byKey(LumeDocumentsTool.recordStateKey),
        );
        expect(
          <Object?>[st.title, st.text, (st.primaryAction! as LumeButton).label],
          <Object?>[s['title'], s['text'], strings(s['ctas']).single],
        );
      }

      final Map<String, dynamic> sm = k['summary'] as Map<String, dynamic>;
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeDocumentsTool.summaryKey),
      );
      expect(
        <Object?>[
          card.kicker,
          card.value,
          card.caption,
          <List<String>>[
            for (final LumeStat s in card.stats) <String>[s.value, s.label],
          ],
        ],
        <Object?>[
          sm['kicker'],
          sm['value'],
          sm['caption'],
          <List<String>>[
            for (final dynamic s in sm['stats'] as List<dynamic>)
              <String>[
                (s as Map<String, dynamic>)['value'] as String,
                s['label'] as String,
              ],
          ],
        ],
      );

      // The reference writes "2 document needs renewing"; plural here (C75).
      final Map<String, dynamic> note = k['note'] as Map<String, dynamic>;
      final LumeNoteCard renew = tester.widget<LumeNoteCard>(
        find.byKey(LumeDocumentsTool.renewKey),
      );
      expect(
        <String?>[renew.title, renew.text],
        <String?>[
          (note['title'] as String).replaceAll(
            '2 document needs',
            '2 documents need',
          ),
          note['text'] as String?,
        ],
      );

      final Map<String, dynamic> lib = k['library'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> want = (lib['rows'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final Map<String, dynamic>? empty = k['state'] as Map<String, dynamic>?;
      if (want.isEmpty) {
        final LumeToolState st = tester.widget<LumeToolState>(
          find.byKey(LumeDocumentsTool.emptyKey),
        );
        expect(
          <Object?>[st.title, st.text, (st.action! as LumeButton).label],
          <Object?>[empty!['title'], empty['text'], empty['action']],
        );
      } else {
        expect(
          <List<Object?>>[
            for (final LumeRichRow row in tester.widgetList<LumeRichRow>(
              find.descendant(
                of: find.byType(LumeRows),
                matching: find.byType(LumeRichRow),
              ),
            ))
              <Object?>[
                row.title,
                row.subtitle,
                badgeText(row.badge),
                row.meta,
              ],
          ],
          <List<Object?>>[
            for (final Map<String, dynamic> w in want)
              <Object?>[
                w['title'],
                w['sub'],
                w['badge'],
                files(strings(w['meta'])),
              ],
          ],
        );
      }
      final List<String> titled = <String>[
        for (final dynamic s in k['sections'] as List<dynamic>)
          if ((s as Map<String, dynamic>)['title'] != null)
            s['title'] as String,
      ];
      // "Valid" is a group and a badge: the groups are asked for by section.
      expect(<String>[
        for (final LumeToolSection s in tester.widgetList<LumeToolSection>(
          find.byType(LumeToolSection),
        ))
          if (s.title != null) s.title!,
      ], titled);
      expect(
        tester
            .widgetList<LumeButton>(
              inKey(LumeDocumentsTool.actionsKey, find.byType(LumeButton)),
            )
            .map((LumeButton b) => b.label)
            .toList(),
        strings(k['buttons']),
      );
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    }

    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpDocuments(tester, state: state);
        expectList(tester, 'tool_documents_${state}_390x844_light_en');
      });
    }

    testWidgets('a search that finds nothing', (WidgetTester tester) async {
      await pumpDocuments(tester);
      await tester.enterText(find.byKey(LumeDocumentsTool.searchKey), 'zzz');
      await tester.pumpAndSettle();
      expectList(tester, 'tool_documents_default_pk_q-zzz_390x844_light_en');
    });

    testWidgets('the Vehicle category', (WidgetTester tester) async {
      await pumpDocuments(tester);
      await tapVisible(
        tester,
        inKey(LumeDocumentsTool.filterKey, find.text('Vehicle')),
      );
      expectList(
        tester,
        'tool_documents_default_pk_cat-Vehicle_390x844_light_en',
      );
    });

    void expectDetail(WidgetTester tester, String cell) {
      final Map<String, dynamic> k = composition(cell);
      final Map<String, dynamic> r = k['records'] as Map<String, dynamic>;
      if (!cell.contains('1100')) expectHeader(tester, k);
      final Map<String, dynamic> h = r['hero'] as Map<String, dynamic>;
      final LumeRecordHero hero = tester.widget<LumeRecordHero>(
        find.byKey(LumeDocumentsTool.heroKey),
      );
      expect(
        <String?>[hero.kicker, hero.value, hero.title, hero.caption],
        <String?>[
          h['kicker'] as String?,
          h['value'] as String?,
          h['title'] as String?,
          h['caption'] as String?,
        ],
      );
      expect(
        <List<String>>[
          for (final LumeFact f
              in tester
                  .widget<LumeFactCard>(
                    inKey(
                      LumeDocumentsTool.factsKey,
                      find.byType(LumeFactCard),
                    ),
                  )
                  .facts)
            <String>[f.label, f.value],
        ],
        <List<String>>[
          for (final dynamic f in r['facts'] as List<dynamic>)
            <String>[(f as List<dynamic>)[0] as String, f[1] as String],
        ],
      );
      final LumeDetailActions acts = tester.widget<LumeDetailActions>(
        find.byKey(LumeDocumentsTool.detailActionsKey),
      );
      expect(<String?>[
        acts.editLabel,
        acts.deleteLabel,
      ], strings(r['actions']));
      expect(
        tester
            .widget<LumeRecordId>(find.byKey(LumeDocumentsTool.recordIdKey))
            .label,
        startsWith('Record ID DOC-'),
      );
    }

    testWidgets('a record opened', (WidgetTester tester) async {
      await pumpDocuments(tester);
      await openFirstRecord(tester);
      expectDetail(tester, 'tool_documents_default_pk_detail_390x844_light_en');
    });

    testWidgets('a record opened beside the list', (WidgetTester tester) async {
      await pumpDocuments(tester, surface: const Size(1050, 5000));
      await openFirstRecord(tester);
      expectDetail(
        tester,
        'tool_documents_default_pk_detail_1100x900_light_en',
      );
      expect(
        tester.widget<LumeRecordRow>(find.byType(LumeRecordRow).first).selected,
        isTrue,
      );
    });

    void expectForm(WidgetTester tester, String cell) {
      final Map<String, dynamic> k = composition(cell);
      final Map<String, dynamic> r = k['records'] as Map<String, dynamic>;
      expectHeader(tester, k);
      const List<String> names = <String>[
        'name',
        'cat',
        'num',
        'expires',
        'holder',
        'notes',
      ];
      final List<Map<String, dynamic>> fields = (r['fields'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(fields, hasLength(names.length));
      for (int i = 0; i < names.length; i++) {
        final Map<String, dynamic> want = fields[i];
        final Widget w = tester.widget(
          find.byKey(LumeDocumentsTool.fieldKey(names[i])),
        );
        switch (w) {
          case LumeFormField():
            expect(
              <Object?>[
                w.label,
                w.optionalLabel,
                w.placeholder,
                w.controller!.text,
                w.error == null ? null : '!${w.error}',
              ],
              <Object?>[
                want['label'],
                want['optional'],
                want['placeholder'],
                want['value'],
                want['error'],
              ],
              reason: names[i],
            );
          case LumeFormPicker():
            const Map<String, String> shown = <String, String>{
              'identity': 'Identity',
              '2026-09-07': 'Mon, 7 Sept',
            };
            expect(
              <Object?>[w.label, w.optionalLabel, w.value],
              <Object?>[want['label'], want['optional'], shown[want['value']]],
              reason: names[i],
            );
          default:
            fail('${names[i]} is a ${w.runtimeType}');
        }
      }
      expect(find.text(strings(r['submit']).single), findsOneWidget);
      expect(find.text(r['submitNote'] as String), findsOneWidget);
    }

    testWidgets('a new document', (WidgetTester tester) async {
      await pumpDocuments(tester);
      await openForm(tester);
      expectForm(tester, 'tool_documents_default_pk_new_390x844_light_en');
    });

    testWidgets('saved with no name', (WidgetTester tester) async {
      await pumpDocuments(tester);
      await openForm(tester);
      await tester.tap(toolbarAction('Save'));
      await tester.pumpAndSettle();
      expectForm(tester, 'tool_documents_default_pk_invalid_390x844_light_en');
      await dismissToast(tester);
    });
  });

  group('used', () {
    testWidgets('a delete says it is for good, and offers no Undo', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester, surface: const Size(390, 900));
      await openFirstRecord(tester);
      await tapVisible(
        tester,
        inKey(LumeDocumentsTool.detailActionsKey, find.text('Delete document')),
      );
      final LumeDeleteConfirmation sheet = tester.widget(
        find.byType(LumeDeleteConfirmation),
      );
      expect(
        <Object?>[
          sheet.title,
          sheet.consequence,
          sheet.confirmLabel,
          sheet.cancelLabel,
          sheet.kind,
          sheet.warn,
        ],
        <Object?>[
          'Delete this document?',
          'Passport will be removed. This action cannot be undone.',
          'Delete document',
          'Cancel',
          LumeDeleteKind.irreversible,
          false,
        ],
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeDeleteConfirmation),
          matching: find.text('Delete document'),
        ),
      );
      await tester.pumpAndSettle();
      expect(recordTitles(tester), isNot(contains('Passport')));
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Document deleted permanently'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Undo'),
        ),
        findsNothing,
      );
      await dismissToast(tester);
    });

    testWidgets('a saved document can be undone, and reads its standing', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester, surface: const Size(390, 900));
      await openForm(tester);
      await tester.enterText(
        find.byKey(LumeDocumentsTool.fieldKey('name')),
        'Visa',
      );
      await tester.tap(toolbarAction('Save'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(LumeDocumentsTool.heroKey), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Undo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(recordTitles(tester), isNot(contains('Visa')));
      await dismissToast(tester);
    });

    testWidgets('Add a document opens the Document Scanner', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester);
      await tapVisible(
        tester,
        inKey(LumeDocumentsTool.actionsKey, find.text('Add a document')),
      );
      expect(find.byType(LumeDocumentsTool), findsNothing);
      expect(find.text('Document Scanner'), findsWidgets);
    });

    testWidgets('a vault row asks for an unlock it cannot give (C75)', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester, surface: const Size(390, 1400));
      await tapVisible(
        tester,
        inKey(LumeDocumentsTool.attentionKey, find.byType(LumeRichRow)).first,
      );
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Unlock with device authentication to view'),
        ),
        findsOneWidget,
      );
      await dismissToast(tester);
    });

    testWidgets('sorting by expiry puts the soonest first', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester);
      expect(
        tester
            .widget<LumeRichRow>(
              inKey(
                LumeDocumentsTool.attentionKey,
                find.byType(LumeRichRow),
              ).first,
            )
            .title,
        'Car Registration',
      );
      await tapVisible(
        tester,
        inKey(LumeDocumentsTool.sortKey, find.text('Expiry')),
      );
      expect(
        tester
            .widget<LumeRichRow>(
              inKey(
                LumeDocumentsTool.attentionKey,
                find.byType(LumeRichRow),
              ).first,
            )
            .title,
        'Driving Licence',
      );
    });

    testWidgets('Export writes the vault, and Share is not offered', (
      WidgetTester tester,
    ) async {
      final LumeRecordingExporter exporter = LumeRecordingExporter();
      await pumpDocuments(
        tester,
        surface: const Size(390, 900),
        overrides: <Override>[exporterProvider.overrideWithValue(exporter)],
      );
      expect(toolbarAction('Share'), findsNothing);
      await tester.tap(toolbarAction('Export'));
      await tester.pump();
      final LumeExportFile file = exporter.exported.single;
      expect(file.fileName, 'lume-documents-2026-09-07.csv');
      final List<String> lines = file.text.trim().split(RegExp(r'\r?\n'));
      expect(lines, hasLength(8));
      expect(lines.first, 'Name,Category,Reference,Expiry,Holder,Files');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('in Urdu the records read right to left', (
      WidgetTester tester,
    ) async {
      await pumpDocuments(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expect(find.text('Documents'), findsNothing);
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic, the form', (WidgetTester tester) async {
      await pumpDocuments(tester, locale: const Locale('ar'));
      await openForm(tester);
      expectNoOverflow(tester);
    });

    for (final String where in <String>['list', 'detail', 'form']) {
      testWidgets('at 200 %, the $where', (WidgetTester tester) async {
        await pumpDocuments(tester, textScale: 2);
        if (where == 'detail') await openFirstRecord(tester);
        if (where == 'form') await openForm(tester);
        expectNoOverflow(tester);
      });
    }
  });
}
