/// Hadith, against the running reference, and used — the scripture reader
/// (F6A-D5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_reader.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/hadith/presentation/hadith_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kHadith = LumeRoutes.tool(LumeRoutes.tools, 'hadith');

Future<void> pumpHadith(
  WidgetTester tester, {
  String state = 'muslim_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kHadith,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder drawn(Type parent, double height) => find.descendant(
  of: find.byType(parent),
  matching: find.byWidgetPredicate(
    (Widget w) => w is Container && w.constraints?.minHeight == height,
  ),
);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

List<String> browseTitles(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(
      inKey(LumeHadithTool.browseKey, find.byType(LumeRichRow)),
    )
    .map((LumeRichRow r) => r.title)
    .toList();

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('hadith');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'kard': find.byKey(LumeHadithTool.readerKey),
    'reader.ref': find.byKey(LumeReaderCard.referenceKey),
    'reader.body': find.byKey(LumeReaderCard.bodyKey),
    'reader.meta': find.byKey(LumeReaderCard.metaKey),
    'reader.badge': inKey(LumeReaderCard.metaKey, find.byType(LumeBadge)),
    'reader.acts': find.byKey(LumeReaderCard.actionsKey),
    'reader.btn1': find.byKey(LumeHadithTool.shareKey),
    'reader.btn2': find.byKey(LumeHadithTool.saveKey),
    'search': find.byKey(LumeHadithTool.searchKey),
    'fchip1': drawn(LumeFilterChip, LumeFilterChip.height).first,
    'fchip2': drawn(LumeFilterChip, LumeFilterChip.height).at(1),
    'rows': find.byKey(LumeHadithTool.browseKey),
    'rrow1': inKey(LumeHadithTool.browseKey, find.byType(LumeRichRow)).first,
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> text = <String>{'reader.body', 'reader.meta'};

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_hadith_muslim_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_hadith_muslim_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_hadith_muslim_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpHadith(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: const <String>{'reader.ref'},
          // The body is 15 on a 25.5 line there and 25 here: three lines are a
          // point and a half apart, and the card with them.
          noHeight: text,
          drifting: const <String>{
            'kard',
            'reader.meta',
            'reader.badge',
            'reader.acts',
            'reader.btn1',
            'reader.btn2',
            'search',
            'fchip1',
            'fchip2',
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
    Future<void> expectWords(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> x = k['reader'] as Map<String, dynamic>;

      final LumeReaderCard card = tester.widget<LumeReaderCard>(
        find.byKey(LumeHadithTool.readerKey),
      );
      final LumeBadge badge = card.badge! as LumeBadge;
      expect(
        <Object?>[
          card.reference,
          card.body,
          <String>[
            card.byline!,
            '${LumeBadge.glyphFor(badge.tone) ?? ''}${badge.label}',
          ],
          <String>[
            for (final Widget b in card.actions) (b as LumeButton).label,
          ],
        ],
        <Object?>[
          x['ref'],
          x['body'],
          (x['meta'] as List<dynamic>).cast<String>(),
          <String>[
            for (final dynamic b in x['buttons'] as List<dynamic>)
              (b as List<dynamic>)[0] as String,
          ],
        ],
      );

      expect(
        tester
            .widget<LumeSearchField>(find.byKey(LumeHadithTool.searchKey))
            .placeholder,
        (k['library'] as Map<String, dynamic>)['placeholder'],
      );
      expect(
        <List<Object?>>[
          for (final LumeFilterChip c in tester.widgetList<LumeFilterChip>(
            find.byType(LumeFilterChip),
          ))
            <Object?>[c.label, c.count?.toString(), c.selected],
        ],
        <List<Object?>>[
          for (final dynamic c in x['filters'] as List<dynamic>)
            (c as List<dynamic>).cast<Object?>(),
        ],
      );

      final List<dynamic> rows =
          (k['library'] as Map<String, dynamic>)['rows'] as List<dynamic>;
      expect(
        <List<Object?>>[
          for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
            inKey(LumeHadithTool.browseKey, find.byType(LumeRichRow)),
          ))
            <Object?>[
              r.title,
              r.subtitle,
              '${LumeBadge.glyphFor(r.badge!.tone) ?? ''}${r.badge!.label}',
              r.meta,
            ],
        ],
        <List<Object?>>[
          for (final dynamic w in rows)
            <Object?>[
              (w as Map<String, dynamic>)['title'],
              w['sub'],
              w['badge'],
              (w['meta'] as List<dynamic>).cast<String>(),
            ],
        ],
      );
      expect(find.text('Browse'), findsOneWidget);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    }

    for (final String state in <String>['muslim_pk', 'muslim_gb']) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpHadith(tester, state: state);
        await expectWords(tester, 'tool_hadith_${state}_390x844_light_en');
      });
    }
  });

  group('used', () {
    testWidgets('a reader without the Islamic experience never reaches it', (
      WidgetTester tester,
    ) async {
      await pumpHadith(tester, state: 'default_pk');
      expect(find.byType(LumeHadithTool), findsNothing);
    });

    testWidgets('Share hands over the hadith being read (C77)', (
      WidgetTester tester,
    ) async {
      await pumpHadith(tester, surface: const Size(390, 900));
      await tester.tap(find.byKey(LumeHadithTool.shareKey));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.hadith);
      expect(card.text, startsWith('The strong is not the one'));
      expect(card.source, 'Sahih Muslim 2609');
    });

    testWidgets('Save keeps the day\'s hadith, and says so (C77)', (
      WidgetTester tester,
    ) async {
      await pumpHadith(tester, surface: const Size(390, 900));
      await tester.tap(find.byKey(LumeHadithTool.saveKey));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Saved to your reading'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<LumeButton>(find.byKey(LumeHadithTool.saveKey)).label,
        'Saved',
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testWidgets('a collection narrows the list', (WidgetTester tester) async {
      await pumpHadith(tester);
      await tester.tap(inKey(LumeHadithTool.filterKey, find.text('Muslim')));
      await tester.pumpAndSettle();
      expect(browseTitles(tester), hasLength(1));
    });

    testWidgets('a search finds by the words, and nothing says so', (
      WidgetTester tester,
    ) async {
      await pumpHadith(tester);
      await tester.enterText(find.byKey(LumeHadithTool.searchKey), 'anger');
      await tester.pumpAndSettle();
      expect(browseTitles(tester), hasLength(1));
      await tester.enterText(find.byKey(LumeHadithTool.searchKey), 'zzz');
      await tester.pumpAndSettle();
      final LumeToolState st = tester.widget<LumeToolState>(
        find.byKey(LumeHadithTool.emptyKey),
      );
      expect(
        <String?>[st.title, st.text],
        <String?>[
          'Nothing found',
          'Try another collection or a shorter search.',
        ],
      );
    });

    testWidgets(
      'in Urdu the interface turns, and the hadith stays as written',
      (WidgetTester tester) async {
        await pumpHadith(tester, locale: const Locale('ur'));
        expect(
          Directionality.of(tester.element(find.byType(LumeToolFrame))),
          TextDirection.rtl,
        );
        expect(
          Directionality.of(tester.element(find.byKey(LumeReaderCard.bodyKey))),
          TextDirection.ltr,
        );
        expectNoOverflow(tester);
      },
    );

    testWidgets('in Arabic', (WidgetTester tester) async {
      await pumpHadith(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpHadith(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
