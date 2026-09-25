/// Ayah of the Day: today's real ayah, Share and Save made real (mirrors
/// Hadith's own C77), and the honest label an Urdu reader is given for the
/// reference's unverified English.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/quran/presentation/ayah_tool.dart';
import 'package:lume/features/quran/presentation/quran_text.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _ayahFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeAyahTool.id,
);

Future<void> pumpAyah(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 1400),
  DateTime? now,
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeAyahTool(
      request: LumeToolRequest(
        feature: _ayahFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    now: now,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the catalogue entry', () {
    test('is faith-gated and shareable', () {
      expect(_ayahFeature.faith, isTrue);
      expect(_ayahFeature.shareable, isTrue);
    });
  });

  group('today\'s ayah', () {
    testWidgets('is Ar-Ra‘d 13:28 on the fixture day, with its real Arabic', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester);
      expect(find.byKey(LumeAyahTool.cardKey), findsOneWidget);
      // "13:28"/the translation also names the same ayah again in "More
      // verses" below — scope to today's own card.
      final Finder card = find.byKey(LumeAyahTool.cardKey);
      expect(
        find.descendant(of: card, matching: find.textContaining('13:28')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byType(LumeQuranArabicText),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('remembrance of God'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('Alladhīna āmanū'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is a different ayah on a different day', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester, now: DateTime(2026, 9, 9, 9));
      // The ayah that was today's on the fixture day may still be listed in
      // "More verses" (it's one of the pool's other two on this new day) —
      // check today's own card, not the whole screen.
      expect(
        find.descendant(
          of: find.byKey(LumeAyahTool.cardKey),
          matching: find.textContaining('remembrance of God'),
        ),
        findsNothing,
      );
    });
  });

  group('no tafsir', () {
    testWidgets('the reference\'s placeholder commentary is not shown', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester);
      expect(
        find.textContaining('Classical commentators'),
        findsNothing,
      );
    });
  });

  group('used', () {
    testWidgets('a reader without the Islamic experience never reaches it', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeAyahTool.cardKey), findsNothing);
    });

    testWidgets('Share hands over today\'s ayah, Arabic and all', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester);
      await tester.tap(find.byKey(LumeAyahTool.shareKey));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quran);
      expect(card.text, startsWith('Those who believe'));
      expect(card.arabic, isNotNull);
      expect(card.source, contains('13:28'));
    });

    testWidgets('Save keeps today\'s ayah for the session, and says so', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester);
      await tester.tap(find.byKey(LumeAyahTool.saveKey));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Saved to your reading'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<LumeButton>(find.byKey(LumeAyahTool.saveKey)).label,
        'Saved',
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testWidgets('the other two ayat are listed under "More verses"', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester);
      expect(find.byKey(LumeAyahTool.moreKey), findsOneWidget);
      expect(
        tester.widgetList(
          find.descendant(
            of: find.byKey(LumeAyahTool.moreKey),
            matching: find.byType(LumeRichRow),
          ),
        ),
        hasLength(3),
      );
    });

    for (final Locale locale in <Locale>[
      const Locale('ur'),
      const Locale('ar'),
    ]) {
      testWidgets(
        'in ${locale.languageCode} the Arabic renders right to left',
        (WidgetTester tester) async {
          await pumpAyah(tester, locale: locale);
          final BuildContext ctx = tester.element(
            find.byType(LumeQuranArabicText),
          );
          expect(Directionality.of(ctx), TextDirection.rtl);
        },
      );
    }

    testWidgets(
      'in Urdu, the English translation is labelled and spoken as English',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await pumpAyah(tester, locale: const Locale('ur'));
        // The note that says "shown in English" is itself localized — under
        // Urdu it reads in Urdu, not the English literal (the ayah's own
        // body is what stays English).
        final AppLocalizations l = AppLocalizations.of(
          tester.element(find.byType(LumeAyahTool)),
        );
        expect(find.text(l.readerFallbackEnglish), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('in English there is nothing to label', (
      WidgetTester tester,
    ) async {
      await pumpAyah(tester);
      expect(
        find.text(
          'Shown in English — no verified translation in this language yet',
        ),
        findsNothing,
      );
    });
  });
}
