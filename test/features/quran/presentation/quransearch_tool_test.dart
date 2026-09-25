/// Search the Qur'an: a real hit, a real miss, and the suggested chips that
/// re-run the search.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/quran/presentation/quransearch_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _quransearchFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeQuranSearchTool.id,
);

Future<void> pumpQuranSearch(
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
    LumeQuranSearchTool(
      request: LumeToolRequest(
        feature: _quransearchFeature,
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

void main() {
  group('the catalogue entry', () {
    test('is faith-gated', () {
      expect(_quransearchFeature.faith, isTrue);
    });
  });

  group('with nothing typed', () {
    testWidgets('shows the three ayat this build holds', (
      WidgetTester tester,
    ) async {
      await pumpQuranSearch(tester);
      expect(find.byKey(LumeQuranSearchTool.resultsKey), findsOneWidget);
      expect(
        tester.widgetList<LumeRichRow>(
          find.descendant(
            of: find.byKey(LumeQuranSearchTool.resultsKey),
            matching: find.byType(LumeRichRow),
          ),
        ),
        hasLength(3),
      );
      expect(find.byKey(LumeQuranSearchTool.scopeNoteKey), findsOneWidget);
    });
  });

  group('a real hit', () {
    testWidgets('finds an ayah by a word in its translation', (
      WidgetTester tester,
    ) async {
      await pumpQuranSearch(tester);
      await tester.enterText(
        find.byKey(LumeQuranSearchTool.searchKey),
        'hardship',
      );
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<LumeRichRow>(
          find.descendant(
            of: find.byKey(LumeQuranSearchTool.resultsKey),
            matching: find.byType(LumeRichRow),
          ),
        ),
        hasLength(1),
      );
      expect(find.text('Ash-Sharh'), findsOneWidget);
    });

    testWidgets('finds a surah by its meaning', (WidgetTester tester) async {
      await pumpQuranSearch(tester);
      await tester.enterText(find.byKey(LumeQuranSearchTool.searchKey), 'cow');
      await tester.pumpAndSettle();
      expect(find.text('Al-Baqarah'), findsOneWidget);
    });
  });

  group('a real miss', () {
    testWidgets('shows the empty state, honestly worded', (
      WidgetTester tester,
    ) async {
      await pumpQuranSearch(tester);
      await tester.enterText(
        find.byKey(LumeQuranSearchTool.searchKey),
        'zzz-nothing-matches-this',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeQuranSearchTool.emptyKey), findsOneWidget);
      final LumeToolState state = tester.widget<LumeToolState>(
        find.byKey(LumeQuranSearchTool.emptyKey),
      );
      expect(state.title, 'Nothing found');
    });
  });

  group('suggested searches', () {
    testWidgets('tapping one runs it as the query', (
      WidgetTester tester,
    ) async {
      await pumpQuranSearch(tester);
      expect(find.byKey(LumeQuranSearchTool.suggestedKey), findsOneWidget);
      // The suggested-search chips are their own horizontal scroller; at
      // 390 points wide, "ar-rahman" starts outside the initial viewport.
      await tester.ensureVisible(
        find.widgetWithText(LumeFilterChip, 'ar-rahman'),
      );
      await tester.tap(find.widgetWithText(LumeFilterChip, 'ar-rahman'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(LumeQuranSearchTool.searchKey),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'ar-rahman',
      );
      expect(find.text('Ar-Rahman'), findsOneWidget);
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never reaches the tool', (WidgetTester tester) async {
      await pumpQuranSearch(
        tester,
        user: const LumeUserContext(islamic: false),
      );
      expect(find.byKey(LumeQuranSearchTool.searchKey), findsNothing);
    });
  });
}
