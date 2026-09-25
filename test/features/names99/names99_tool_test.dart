/// 99 Names on screen — the twelve names it actually holds, honestly counted
/// against the ninety-nine it is named for, and never reached by a reader
/// without the Islamic experience.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/names99/data/names99_fixtures.dart';
import 'package:lume/features/names99/domain/names99_model.dart';
import 'package:lume/features/names99/presentation/names99_tool.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/load_fonts.dart';
import 'names99_harness.dart';

final AppLocalizations en = AppLocalizationsEn();

void main() {
  setUpAll(loadLumeFonts);

  group('the catalogue entry', () {
    test('is faith-gated', () {
      expect(names99Feature.faith, isTrue);
    });
  });

  group('the gallery', () {
    testWidgets('draws all twelve names, with their real Arabic and meaning', (
      WidgetTester tester,
    ) async {
      await pumpNames99(tester);
      expect(find.byKey(LumeNames99Tool.gridKey), findsOneWidget);
      for (final LumeName n in LumeNames99Fixtures.all) {
        expect(
          find.text(n.arabic),
          findsOneWidget,
          reason: '${n.transliteration}\'s Arabic is missing',
        );
        expect(find.text(n.transliteration), findsOneWidget);
        expect(find.text(n.meaning.text), findsOneWidget);
      }
    });

    testWidgets('says how many of the ninety-nine this build holds — never '
        'silently as though twelve were the whole set', (
      WidgetTester tester,
    ) async {
      await pumpNames99(tester);
      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeNames99Tool.summaryKey),
      );
      expect(summary.value, '12');
      // The intended English for `names99Total`/`names99Caption`/
      // `names99Reading` — literal here rather than `en.names99…` because
      // these keys are proposed by this tool and not yet in the ARBs (see
      // this wave's report); a later pass adds them and this pins the words
      // it should add.
      expect(summary.valueSmall, '/ 99');
      expect(summary.caption, 'The remaining 87 need a verified source.');

      final LumeProgressRing ring = tester.widget(
        find.descendant(
          of: find.byKey(LumeNames99Tool.summaryKey),
          matching: find.byType(LumeProgressRing),
        ),
      );
      expect(ring.valueText, '12 of 99');
    });

    testWidgets('a search narrows the grid, by transliteration or meaning', (
      WidgetTester tester,
    ) async {
      await pumpNames99(tester);
      await tester.enterText(
        find.byKey(LumeNames99Tool.searchKey),
        'sovereign',
      );
      await tester.pumpAndSettle();
      expect(find.text('Al-Malik'), findsOneWidget);
      expect(find.text('Ar-Rahman'), findsNothing);
    });

    testWidgets('a search with no match says so plainly, and Clear reopens '
        'the whole list', (WidgetTester tester) async {
      await pumpNames99(tester);
      await tester.enterText(find.byKey(LumeNames99Tool.searchKey), 'wadud');
      await tester.pumpAndSettle();
      final LumeToolState state = tester.widget(
        find.byKey(LumeNames99Tool.emptyKey),
      );
      expect(state.title, 'No name matches');
      expect(state.text, 'Try the transliteration or the meaning.');

      await tester.tap(find.text(en.actionClear));
      await tester.pumpAndSettle();
      expect(find.byKey(LumeNames99Tool.gridKey), findsOneWidget);
      expect(find.text('Ar-Rahman'), findsOneWidget);
    });

    testWidgets('tapping a name says its transliteration and meaning, and '
        'offers to share it', (WidgetTester tester) async {
      await pumpNames99(tester);
      await tester.tap(find.text('Al-Quddus'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Al-Quddus — The Most Holy'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(en.commonShare).last);
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, 'The Most Holy');
      expect(card.arabic, 'الْقُدُّوس');
      expect(card.source, 'Al-Quddus — Asma ul Husna');
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never sees the gallery — the shared tool frame refuses a '
        'faith-gated body whether or not a route ever reaches it (§64)', (
      WidgetTester tester,
    ) async {
      await pumpNames99(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeNames99Tool.summaryKey), findsNothing);
      expect(find.byKey(LumeNames99Tool.gridKey), findsNothing);
      expect(find.byKey(LumeNames99Tool.searchKey), findsNothing);
    });
  });

  group('right to left', () {
    testWidgets('the Arabic is drawn right to left in an English interface', (
      WidgetTester tester,
    ) async {
      await pumpNames99(tester);
      expect(
        Directionality.of(
          tester.element(find.text(LumeNames99Fixtures.all.first.arabic)),
        ),
        TextDirection.rtl,
      );
    });

    for (final String language in <String>['ur', 'ar']) {
      testWidgets(
        'in $language the interface turns, the Arabic stays right to left, '
        'and the meaning stays the reference\'s own English',
        (WidgetTester tester) async {
          await pumpNames99(tester, locale: Locale(language));
          expect(find.byKey(LumeNames99Tool.gridKey), findsOneWidget);
          expect(
            Directionality.of(
              tester.element(find.text(LumeNames99Fixtures.all.first.arabic)),
            ),
            TextDirection.rtl,
          );
          // No invented Urdu or Arabic rendering of the meaning: the same
          // English the fixture holds is on screen regardless of interface
          // language (C82).
          for (final LumeName n in LumeNames99Fixtures.all) {
            expect(find.text(n.meaning.text), findsOneWidget);
          }
        },
      );
    }
  });

  testWidgets('at 200% text nothing overflows', (WidgetTester tester) async {
    await pumpNames99(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
