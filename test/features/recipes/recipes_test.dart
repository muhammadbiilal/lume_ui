/// Recipes, against the running reference, and used.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_art.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/recipes/presentation/recipes_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kRecipes = LumeRoutes.tool(LumeRoutes.tools, 'recipes');

Future<GoRouter> pumpRecipes(
  WidgetTester tester, {
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kRecipes,
    profile: taxProfile('default_pk'),
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

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('recipes');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'search': find.byKey(LumeRecipesTool.searchKey),
    'chips': find.byKey(LumeRecipesTool.chipsKey),
    'chip1': find.byType(LumeChoiceChip).first,
    'sect3.title': find.text('Your favourites'),
    'imgcard1': inKey(
      LumeRecipesTool.favouritesKey,
      find.byType(LumeImageCard),
    ).first,
    'imgcard2': inKey(
      LumeRecipesTool.favouritesKey,
      find.byType(LumeImageCard),
    ).at(1),
    'imgcard.art': inKey(
      LumeRecipesTool.favouritesKey,
      find.byType(LumeArt),
    ).first,
    'imgcard.kicker': inKey(
      LumeRecipesTool.favouritesKey,
      find.text('PAKISTANI'),
    ).first,
    'imgcard.title': inKey(
      LumeRecipesTool.favouritesKey,
      find.text('Chicken Karahi'),
    ),
    'imgcard.meta': inKey(
      LumeRecipesTool.favouritesKey,
      find.text('50 min · serves 4'),
    ).first,
    'rows': find.byKey(LumeRecipesTool.listKey),
    'rrow1': inKey(LumeRecipesTool.listKey, find.byType(LumeRichRow)).first,
    'rrow2': inKey(LumeRecipesTool.listKey, find.byType(LumeRichRow)).at(1),
    'rrow.thumb': inKey(LumeRecipesTool.listKey, find.byType(LumeArt)).first,
    'rrow.title': inKey(LumeRecipesTool.listKey, find.text('Chicken Karahi')),
    'rrow.sub': inKey(LumeRecipesTool.listKey, find.text('Pakistani')).first,
    'rrow.meta': inKey(LumeRecipesTool.listKey, find.byType(Wrap)).first,
    'badge': inKey(LumeRecipesTool.listKey, find.byType(LumeBadge)).first,
  };

  const Set<String> textBlocks = <String>{
    'sect3.title',
    'imgcard.kicker',
    'imgcard.title',
    'imgcard.meta',
    'rrow.title',
    'rrow.sub',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_recipes_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_recipes_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_recipes_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpRecipes(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          // The badge's ✓ is drawn in the platform's fallback face — Plus
          // Jakarta Sans has no check mark — so its width is the platform's,
          // not the design's.
          noWidth: <String>{...textBlocks, 'rrow.meta', 'badge'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));

        // Under the list: the links and everything after them, held to the
        // reference shifted by what the two 44-point rows add (C62).
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
        final Rect links = tester
            .getRect(find.byKey(LumeRecipesTool.linksKey))
            .shift(-origin);
        // The web's `rows` target is the first `.rows` — the recipe list —
        // so the links card is measured by its first row instead.
        final Rect webLink = webRect('crow1').shift(-webOrigin);
        expect((links.left + 1 - webLink.left).abs(), lessThanOrEqualTo(1));
        expect((links.top + 1 - webLink.top).abs(), lessThanOrEqualTo(1));
        final double added = links.height - (41 + 40 + 2);
        for (final (String k, Finder f) in <(String, Finder)>[
          ('srcbar', find.byType(LumeSourceBar)),
          ('related', find.byType(LumeRelatedTools)),
        ]) {
          final Rect w = webRect(k).shift(-webOrigin);
          final Rect r = tester.getRect(f).shift(-origin);
          expect((r.left - w.left).abs(), lessThanOrEqualTo(1), reason: k);
          expect(
            (r.top - added - w.top).abs(),
            lessThanOrEqualTo(1),
            reason: k,
          );
        }
      });
    }

    testWidgets('no match — the tool state, where the list would be', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(tester);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      final List<String> misses = parity.bounds(
        tester,
        'tool_recipes_default_pk_q-zzz_390x844_light_en',
        <String, Finder>{
          'toolbar': find.byType(LumeToolbar),
          'state': find.byKey(LumeRecipesTool.emptyKey),
          'state.title': find.text('No recipes match'),
          'state.text': find.text('Try a cuisine, an ingredient or a tag.'),
        },
        noWidth: <String>{'state.title', 'state.text'},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });
  });

  group('what it says, in each state the reference was captured in', () {
    Future<void> expectWords(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> lib = k['library'] as Map<String, dynamic>;

      expect(
        tester
            .widget<LumeSearchField>(find.byType(LumeSearchField))
            .placeholder,
        lib['placeholder'],
      );
      expect(
        textsUnder(tester, find.byKey(LumeRecipesTool.chipsKey)),
        lib['chips'],
      );
      final LumeChoiceChip on = tester.widget<LumeChoiceChip>(
        find.byWidgetPredicate((Widget w) => w is LumeChoiceChip && w.selected),
      );
      expect(on.label, lib['chipOn']);

      final List<LumeImageCard> cards = tester
          .widgetList<LumeImageCard>(
            inKey(LumeRecipesTool.favouritesKey, find.byType(LumeImageCard)),
          )
          .toList();
      expect(
        <List<String?>>[
          for (final LumeImageCard c in cards)
            <String?>[c.kicker, c.title, c.meta],
        ],
        <List<String?>>[
          for (final dynamic c in lib['cards'] as List<dynamic>)
            <String?>[
              (c as Map<String, dynamic>)['kicker'] as String?,
              c['title'] as String?,
              c['meta'] as String?,
            ],
        ],
      );

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(find.byType(LumeRichRow))
          .toList();
      expect(
        <List<Object?>>[
          for (final LumeRichRow r in rows)
            <Object?>[r.title, r.subtitle, r.badge?.label, r.meta],
        ],
        <List<Object?>>[
          for (final dynamic r in lib['rows'] as List<dynamic>)
            <Object?>[
              (r as Map<String, dynamic>)['title'],
              r['sub'],
              (r['badge'] as String?)?.replaceFirst('✓', ''),
              (r['meta'] as List<dynamic>).cast<String>(),
            ],
        ],
      );

      final Map<String, dynamic>? empty = lib['empty'] as Map<String, dynamic>?;
      if (empty == null) {
        expect(find.byKey(LumeRecipesTool.emptyKey), findsNothing);
      } else {
        final LumeToolState s = tester.widget<LumeToolState>(
          find.byKey(LumeRecipesTool.emptyKey),
        );
        expect(
          <String?>[s.title, s.text],
          <String?>[empty['title'] as String?, empty['text'] as String?],
        );
      }

      expect(textsUnder(tester, find.byKey(LumeRecipesTool.linksKey)), <String>[
        for (final dynamic x in lib['links'] as List<dynamic>)
          (x as Map<String, dynamic>)['label'] as String,
      ]);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
      final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
      expect(find.text(src['fresh'] as String), findsOneWidget);
      expect(
        (k['header'] as Map<String, dynamic>)['actions'],
        hasLength(
          tester
              .widgetList(
                find.descendant(
                  of: find.byType(LumeToolbar),
                  matching: find.byType(LumeIconButton),
                ),
              )
              .length,
        ),
      );
    }

    testWidgets('opened', (WidgetTester tester) async {
      await pumpRecipes(tester);
      await expectWords(tester, 'tool_recipes_default_pk_390x844_light_en');
    });

    testWidgets('Pakistani chosen', (WidgetTester tester) async {
      await pumpRecipes(tester);
      await tester.tap(inKey(LumeRecipesTool.chipsKey, find.text('Pakistani')));
      await tester.pumpAndSettle();
      await expectWords(
        tester,
        'tool_recipes_default_pk_cuisine-Pakistani_390x844_light_en',
      );
    });

    testWidgets('searching for oats', (WidgetTester tester) async {
      await pumpRecipes(tester);
      await tester.enterText(find.byType(EditableText), 'oats');
      await tester.pumpAndSettle();
      await expectWords(
        tester,
        'tool_recipes_default_pk_q-oats_390x844_light_en',
      );
    });

    testWidgets('searching for what is not there', (WidgetTester tester) async {
      await pumpRecipes(tester);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      await expectWords(
        tester,
        'tool_recipes_default_pk_q-zzz_390x844_light_en',
      );
    });
  });

  group('used', () {
    testWidgets('the chosen cuisine is drawn and announced as chosen (C69)', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(tester);
      await tester.tap(inKey(LumeRecipesTool.chipsKey, find.text('Levantine')));
      await tester.pumpAndSettle();
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        tester.getSemantics(
          find.byWidgetPredicate(
            (Widget w) => w is LumeChoiceChip && w.label == 'Levantine',
          ),
        ),
        isSemantics(label: 'Levantine', isSelected: true, isButton: true),
      );
      h.dispose();
      expect(
        tester
            .widgetList<LumeRichRow>(find.byType(LumeRichRow))
            .map((LumeRichRow r) => r.title),
        <String>['Shakshuka'],
      );
    });

    testWidgets('the tool bar’s Search puts the cursor in the field', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToolbar),
          matching: find.byWidgetPredicate(
            (Widget w) => w is LumeIconButton && w.label == 'Search this tool',
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('a card says its method is not in Lume yet', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(tester);
      await tester.tap(
        inKey(LumeRecipesTool.favouritesKey, find.byType(LumeImageCard)).at(1),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text("The method for Daal Chawal isn't in Lume yet."),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Meal Planner opens from the links', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(tester);
      final Finder link = inKey(
        LumeRecipesTool.linksKey,
        find.text('Meal Planner'),
      );
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(LumeToolbar),
          matching: find.text('Meal Planner'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('leaving keeps the cuisine and the query', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpRecipes(tester);
      await tester.tap(inKey(LumeRecipesTool.chipsKey, find.text('Pakistani')));
      await tester.enterText(find.byType(EditableText), 'pulao');
      await tester.pumpAndSettle();
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      router.go(kRecipes);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<LumeRichRow>(find.byType(LumeRichRow))
            .map((LumeRichRow r) => r.title),
        <String>['Beef Pulao'],
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'pulao',
      );
    });

    testWidgets('an Urdu reader finds a recipe in Urdu or in English', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(tester, locale: const Locale('ur'));
      final AppLocalizations ur = lookupAppLocalizations(const Locale('ur'));
      await tester.enterText(find.byType(EditableText), 'oats');
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<LumeRichRow>(find.byType(LumeRichRow))
            .map((LumeRichRow r) => r.title),
        <String>[ur.recipeNameOvernightOats],
      );
      await tester.enterText(find.byType(EditableText), 'دال');
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<LumeRichRow>(find.byType(LumeRichRow))
            .map((LumeRichRow r) => r.title),
        <String>[ur.recipeNameDaalChawal],
      );
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
    });

    testWidgets('the share card says what the library holds', (
      WidgetTester tester,
    ) async {
      await pumpRecipes(
        tester,
        surface: const Size(390, 900),
        overrides: <Override>[
          sharerProvider.overrideWithValue(LumeRecordingSharer()),
        ],
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToolbar),
          matching: find.byWidgetPredicate(
            (Widget w) => w is LumeIconButton && w.label == 'Share',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(
        card.text,
        '6 recipes · Your favourites: Chicken Karahi, Daal Chawal',
      );
      expect(card.source, 'Recipe library');
      expect(card.kind, LumeShareKind.quote);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpRecipes(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
