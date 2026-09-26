/// News, against the running reference, and used.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_art.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_lead_card.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/news/presentation/news_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kNews = LumeRoutes.tool(LumeRoutes.tools, 'news');

Future<GoRouter> pumpNews(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kNews,
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

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

List<String> rowTitles(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(find.byType(LumeRichRow))
    .map((LumeRichRow r) => r.title)
    .toList();

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('news');
  tearDownAll(parity.write);

  const String leadTitle =
      'Rupee holds steady as remittances climb for a third month';

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'ctxbar': find.byType(LumeContextBar),
    'search': find.byKey(LumeNewsTool.searchKey),
    'chips': find.byKey(LumeNewsTool.chipsKey),
    'chip1': find.byType(LumeChoiceChip).first,
    'lead': find.byKey(LumeNewsTool.leadKey),
    'lead.art': inKey(LumeNewsTool.leadKey, find.byType(LumeArt)),
    'lead.cat': inKey(LumeNewsTool.leadKey, find.text('BUSINESS')),
    'lead.title': inKey(LumeNewsTool.leadKey, find.text(leadTitle)),
    'lead.meta': inKey(
      LumeNewsTool.leadKey,
      find.text('Business Recorder · 18 min · 4 min read'),
    ),
    'rows': find.byKey(LumeNewsTool.listKey),
    'rrow1': inKey(LumeNewsTool.listKey, find.byType(LumeRichRow)).first,
    'rrow.thumb': inKey(LumeNewsTool.listKey, find.byType(LumeArt)).first,
    'rrow.sub': inKey(LumeNewsTool.listKey, find.text('Dawn')),
    'rrow.meta': inKey(LumeNewsTool.listKey, find.byType(Wrap)).first,
  };

  const Set<String> textBlocks = <String>{
    'lead.cat',
    // `.lead__title { display: block }` spans the body; the text inside it is
    // what Flutter draws, so only its position and height compare.
    'lead.title',
    'lead.meta',
    'rrow.sub',
    'rrow.meta',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_news_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_news_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_news_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpNews(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          // The pressable context item's widened target, which the reference
          // draws with negative margins and Flutter gives to LumeTargetSlop.
          drifting: <String>{'ctxbar'},
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

        // Your reading, and what follows it: the reference's geometry, moved
        // down by what the two 44-point rows add (C62).
        final Offset webOrigin = webRect('toolbar').topLeft;
        final Offset origin = tester.getTopLeft(find.byType(LumeToolbar));
        final Rect reading = tester
            .getRect(find.byKey(LumeNewsTool.readingKey))
            .shift(-origin);
        final Rect webRow = webRect('crow1').shift(-webOrigin);
        expect((reading.left + 1 - webRow.left).abs(), lessThanOrEqualTo(1));
        expect((reading.top + 1 - webRow.top).abs(), lessThanOrEqualTo(1));
        final double added = reading.height - (41 + 40 + 2);
        for (final (String k, Finder f) in <(String, Finder)>[
          ('srcbar', find.byType(LumeSourceBar)),
          ('related', find.byType(LumeRelatedTools)),
        ]) {
          final Rect w = webRect(k).shift(-webOrigin);
          final Rect g = tester.getRect(f).shift(-origin);
          expect((g.left - w.left).abs(), lessThanOrEqualTo(1), reason: k);
          expect(
            (g.top - added - w.top).abs(),
            lessThanOrEqualTo(1),
            reason: k,
          );
        }
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    Future<void> expectWords(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> news = k['news'] as Map<String, dynamic>;

      expect(
        textsUnder(tester, find.byType(LumeContextBar)),
        (news['context'] as List<dynamic>).cast<String>(),
      );
      expect(
        tester
            .widget<LumeSearchField>(find.byType(LumeSearchField))
            .placeholder,
        news['placeholder'],
      );
      expect(
        textsUnder(tester, find.byKey(LumeNewsTool.chipsKey)),
        news['chips'],
      );
      expect(
        tester
            .widget<LumeChoiceChip>(
              find.byWidgetPredicate(
                (Widget w) => w is LumeChoiceChip && w.selected,
              ),
            )
            .label,
        news['chipOn'],
      );

      final Map<String, dynamic>? lead = news['lead'] as Map<String, dynamic>?;
      if (lead == null) {
        expect(find.byType(LumeLeadCard), findsNothing);
      } else {
        final LumeLeadCard card = tester.widget<LumeLeadCard>(
          find.byType(LumeLeadCard),
        );
        expect(
          <String>[card.category, card.title, card.meta],
          <String>[
            lead['cat'] as String,
            lead['title'] as String,
            lead['meta'] as String,
          ],
        );
      }

      expect(
        <List<Object?>>[
          for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
            find.byType(LumeRichRow),
          ))
            <Object?>[r.title, r.subtitle, r.meta],
        ],
        <List<Object?>>[
          for (final dynamic r in news['rows'] as List<dynamic>)
            <Object?>[
              (r as Map<String, dynamic>)['title'],
              r['sub'],
              (r['meta'] as List<dynamic>).cast<String>(),
            ],
        ],
      );

      final Map<String, dynamic>? empty =
          news['empty'] as Map<String, dynamic>?;
      if (empty == null) {
        expect(find.byKey(LumeNewsTool.emptyKey), findsNothing);
      } else {
        final LumeToolState s = tester.widget<LumeToolState>(
          find.byKey(LumeNewsTool.emptyKey),
        );
        expect(
          <String?>[s.title, s.text],
          <String?>[empty['title'] as String?, empty['text'] as String?],
        );
      }

      expect(textsUnder(tester, find.byKey(LumeNewsTool.readingKey)), <String>[
        for (final dynamic x in news['reading'] as List<dynamic>) ...<String>[
          (x as Map<String, dynamic>)['label'] as String,
          if (x['value'] != null) x['value'] as String,
        ],
      ]);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
      expect(
        find.text(((k['header'] as Map<String, dynamic>)['sub']) as String),
        findsOneWidget,
      );
    }

    testWidgets('Pakistan', (WidgetTester tester) async {
      await pumpNews(tester);
      await expectWords(tester, 'tool_news_default_pk_390x844_light_en');
    });

    testWidgets('everywhere else — the global edition', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester, state: 'default_us');
      await expectWords(tester, 'tool_news_default_us_390x844_light_en');
    });

    for (final (String cat, String cell) in <(String, String)>[
      ('Business', 'tool_news_default_pk_cat-Business_390x844_light_en'),
      ('Lifestyle', 'tool_news_default_pk_cat-Lifestyle_390x844_light_en'),
    ]) {
      testWidgets('$cat chosen', (WidgetTester tester) async {
        await pumpNews(tester);
        final Finder chip = inKey(LumeNewsTool.chipsKey, find.text(cat));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await expectWords(tester, cell);
      });
    }

    testWidgets('a search that finds nothing', (WidgetTester tester) async {
      await pumpNews(tester);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      await expectWords(tester, 'tool_news_default_pk_q-zzz_390x844_light_en');
    });
  });

  group('used', () {
    testWidgets('Top is every story, not the stories filed under Top (C70)', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester);
      expect(find.byType(LumeLeadCard), findsOneWidget);
      expect(rowTitles(tester), hasLength(5));
      final Finder top = inKey(LumeNewsTool.chipsKey, find.text('Top'));
      await tester.tap(inKey(LumeNewsTool.chipsKey, find.text('World')));
      await tester.pumpAndSettle();
      expect(find.byType(LumeRichRow), findsNothing);
      await tester.tap(top);
      await tester.pumpAndSettle();
      expect(rowTitles(tester), hasLength(5));
    });

    testWidgets('the country opens Personalise', (WidgetTester tester) async {
      await pumpNews(tester);
      await tester.tap(inKey(LumeNewsTool.chipsKey, find.text('Top')));
      await tester.tap(
        find.descendant(
          of: find.byType(LumeContextBar),
          matching: find.text('Pakistan'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LumeSheet), findsOneWidget);
    });

    testWidgets('the tool bar’s Search puts the cursor in the field', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester);
      await tester.tap(toolbarAction('Search this tool'));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('the lead and the reading rows speak', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester);
      await tester.tap(find.byKey(LumeNewsTool.leadKey));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text(leadTitle),
        ),
        findsOneWidget,
      );
      final Finder sources = inKey(
        LumeNewsTool.readingKey,
        find.text('Sources'),
      );
      await tester.ensureVisible(sources);
      await tester.tap(sources);
      await tester.pump();
      expect(find.text('Choose your sources'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('leaving keeps the category and the query', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpNews(tester);
      await tester.tap(inKey(LumeNewsTool.chipsKey, find.text('Sport')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'squad');
      await tester.pumpAndSettle();
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      router.go(kNews);
      await tester.pumpAndSettle();
      expect(
        tester.widget<LumeLeadCard>(find.byType(LumeLeadCard)).title,
        'Pakistan name a 16-player squad for the home Test series',
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'squad',
      );
    });

    testWidgets('the share card is the top story, with where and when', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester, surface: const Size(390, 900));
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, leadTitle);
      expect(card.source, 'Business Recorder · 18 min');
    });

    testWidgets('with no top story there is nothing to share', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester);
      final Finder lifestyle = inKey(
        LumeNewsTool.chipsKey,
        find.text('Lifestyle'),
      );
      await tester.ensureVisible(lifestyle);
      await tester.tap(lifestyle);
      await tester.pumpAndSettle();
      await tester.tap(toolbarAction('Share'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(LumeShareCardArt), findsNothing);
    });

    testWidgets('an Urdu reader searches in Urdu or English', (
      WidgetTester tester,
    ) async {
      await pumpNews(tester, locale: const Locale('ur'));
      final AppLocalizations ur = lookupAppLocalizations(const Locale('ur'));
      await tester.enterText(find.byType(EditableText), 'dengue');
      await tester.pumpAndSettle();
      expect(
        tester.widget<LumeLeadCard>(find.byType(LumeLeadCard)).title,
        ur.newsHeadlinePkDengue,
      );
      await tester.enterText(find.byType(EditableText), 'Geo Super');
      await tester.pumpAndSettle();
      expect(
        tester.widget<LumeLeadCard>(find.byType(LumeLeadCard)).title,
        ur.newsHeadlinePkSquad,
      );
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpNews(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
