/// Al-Qur'an: the twelve surahs, searched exactly as the reference searches
/// them, and a real ayah revealed for the two surahs this build holds one
/// for.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/quran/presentation/quran_text.dart';
import 'package:lume/features/quran/presentation/quran_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _quranFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeQuranTool.id,
);

Future<void> pumpQuran(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeQuranTool(
      request: LumeToolRequest(
        feature: _quranFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

Finder _shareButton() => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == 'Share',
  ),
);

List<String> _surahTitles(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(
      find.descendant(
        of: find.byKey(LumeQuranTool.browseKey),
        matching: find.byType(LumeRichRow),
      ),
    )
    .map((LumeRichRow r) => r.title)
    .toList();

void main() {
  group('the catalogue entry', () {
    test('is faith-gated and shareable', () {
      expect(_quranFeature.faith, isTrue);
      expect(_quranFeature.shareable, isTrue);
    });
  });

  group('browsing', () {
    testWidgets('lists the twelve surahs, with their Arabic names', (
      WidgetTester tester,
    ) async {
      await pumpQuran(tester);
      expect(find.byKey(LumeQuranTool.browseKey), findsOneWidget);
      expect(_surahTitles(tester), hasLength(12));
      expect(_surahTitles(tester), contains('Al-Fatihah'));
      expect(find.byType(LumeQuranArabicText), findsWidgets);
    });

    testWidgets('a search narrows the list, and a miss shows the empty state', (
      WidgetTester tester,
    ) async {
      await pumpQuran(tester);
      await tester.enterText(find.byKey(LumeQuranTool.searchKey), 'cave');
      await tester.pumpAndSettle();
      expect(_surahTitles(tester), <String>['Al-Kahf']);

      await tester.enterText(
        find.byKey(LumeQuranTool.searchKey),
        'not a surah at all',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeQuranTool.emptyKey), findsOneWidget);
      final LumeToolState state = tester.widget<LumeToolState>(
        find.byKey(LumeQuranTool.emptyKey),
      );
      expect(state.title, 'No surahs found');
    });

    testWidgets(
      'a surah with a real ayah reveals it on tap, sharing it honestly',
      (WidgetTester tester) async {
        await pumpQuran(tester);
        await tester.enterText(find.byKey(LumeQuranTool.searchKey), 'thunder');
        await tester.pumpAndSettle();
        expect(find.byKey(LumeQuranTool.readerKey), findsNothing);

        await tester.tap(find.text('Ar-Ra‘d'));
        await tester.pumpAndSettle();
        expect(find.byKey(LumeQuranTool.readerKey), findsOneWidget);
        expect(find.textContaining('remembrance of God'), findsOneWidget);

        await tester.tap(_shareButton());
        await tester.pumpAndSettle();
        final LumeShareCard card = tester
            .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
            .card;
        expect(card.kind, LumeShareKind.quran);
        expect(card.arabic, isNotNull);
        expect(card.source, contains('13:28'));
      },
    );

    testWidgets('a surah with no ayah in this fixture just names itself', (
      WidgetTester tester,
    ) async {
      await pumpQuran(tester);
      await tester.enterText(find.byKey(LumeQuranTool.searchKey), 'opening');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Al-Fatihah'));
      await tester.pump();
      expect(find.byKey(LumeQuranTool.readerKey), findsNothing);
      expect(find.text('Al-Fatihah'), findsWidgets);
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never reaches the tool', (WidgetTester tester) async {
      await pumpQuran(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeQuranTool.browseKey), findsNothing);
      expect(find.byKey(LumeQuranTool.searchKey), findsNothing);
    });
  });

  group('Arabic', () {
    testWidgets('the surah names render right to left', (
      WidgetTester tester,
    ) async {
      await pumpQuran(tester);
      // `LumeQuranArabicText` wraps its own child in a `Directionality`, so
      // that sits *below* the widget's own element, not above it — look up
      // directionality from a descendant, not the widget's own context.
      final BuildContext ctx = tester.element(
        find
            .descendant(
              of: find.byType(LumeQuranArabicText).first,
              matching: find.byType(Text),
            )
            .first,
      );
      expect(Directionality.of(ctx), TextDirection.rtl);
    });

    testWidgets('in Urdu, the Arabic still reads right to left', (
      WidgetTester tester,
    ) async {
      await pumpQuran(tester, locale: const Locale('ur'));
      expect(find.byKey(LumeQuranTool.browseKey), findsOneWidget);
      final BuildContext ctx = tester.element(
        find.byType(LumeQuranArabicText).first,
      );
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
  });
}
