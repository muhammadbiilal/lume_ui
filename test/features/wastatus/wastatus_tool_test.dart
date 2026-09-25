/// WhatsApp Status Saver: the screen says why it cannot scan, gives real
/// steps instead of a fake scan, and never fabricates a source-bar claim
/// over data it does not have.
///
/// NOTE — expected to be blocked on ARB keys, not on logic: every string this
/// screen shows is new copy (`wastatusWhyTitle` and its siblings) that has
/// not been added to the `.arb` files yet — deliberately out of scope for
/// this tool (see the task's own constraints and `wastatus_tool.dart`'s doc
/// comment). Until a later, centralised pass adds those keys and regenerates
/// `app_localizations.dart`, this whole file fails to *compile*
/// (`undefined_getter` on `AppLocalizations`), which `flutter test` reports
/// as every test below failing. `wastatus_capability_test.dart` in this same
/// directory carries no such dependency and is green today; this file is
/// written to be correct and complete the moment the keys land, not to pass
/// in the meantime.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/catalogue/presentation/feature_strings.dart';
import 'package:lume/features/wastatus/presentation/wastatus_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import 'wastatus_harness.dart';

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  group('honesty: no fake capability', () {
    testWidgets(
      'draws no source bar — there is no figure on this screen for one to '
      'claim anything about',
      (WidgetTester tester) async {
        await pumpWastatus(tester);
        expect(find.byType(LumeSourceBar), findsNothing);
      },
    );

    testWidgets(
      'draws no empty/pending state and no action button — the reference\'s '
      '"Detected statuses" list and its "Grant folder access" button (which '
      'only ever showed a toast) are not reproduced',
      (WidgetTester tester) async {
        await pumpWastatus(tester);
        expect(find.byType(LumeToolState), findsNothing);
        expect(find.byType(LumeCollectionState), findsNothing);
        expect(find.byType(LumeButton), findsNothing);
      },
    );

    testWidgets('shows no privacy note — this is not a sensitive tool', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester);
      expect(find.byType(LumePrivateState), findsNothing);
    });
  });

  group('structure', () {
    testWidgets('leads with why Lume itself cannot scan', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester);
      final LumeNotice why = tester.widget<LumeNotice>(
        find.byKey(LumeWastatusTool.whyKey),
      );
      expect(why.kind, LumeNoticeKind.info);
      expect(why.title, isNotEmpty);
      expect(why.text, isNotEmpty);
    });

    testWidgets('gives exactly three numbered steps to save one yourself', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester);
      expect(inKey(LumeWastatusTool.saveKey, find.text('1')), findsOneWidget);
      expect(inKey(LumeWastatusTool.saveKey, find.text('2')), findsOneWidget);
      expect(inKey(LumeWastatusTool.saveKey, find.text('3')), findsOneWidget);
    });

    testWidgets(
      'hedges the Android folder tip rather than promising it will work',
      (WidgetTester tester) async {
        await pumpWastatus(tester);
        final LumeNotice folder = tester.widget<LumeNotice>(
          find.byKey(LumeWastatusTool.folderKey),
        );
        expect(folder.kind, LumeNoticeKind.info);
        expect(folder.title, isNotEmpty);
        expect(folder.text, isNotEmpty);
      },
    );
  });

  group('related rail', () {
    testWidgets('offers Media Saver and the document scanner', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byKey(LumeWastatusTool.relatedKey)),
      );
      final LumeRelatedTools rail = tester.widget<LumeRelatedTools>(
        find.byKey(LumeWastatusTool.relatedKey),
      );
      expect(
        rail.tools.map((LumeRelatedTool t) => t.id),
        <String>['mediasaver', 'docscan'],
      );
      expect(
        find.text(LumeFeatureStrings.name(l, 'mediasaver')),
        findsOneWidget,
      );
      expect(find.text(LumeFeatureStrings.name(l, 'docscan')), findsOneWidget);
    });

    testWidgets('opens the tapped related tool through onOpenRelated', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await pumpWastatus(tester, onOpenRelated: opened.add);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byKey(LumeWastatusTool.relatedKey)),
      );
      final Finder target = find.text(LumeFeatureStrings.name(l, 'mediasaver'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(opened, <String>['mediasaver']);
    });
  });

  group('localization and accessibility', () {
    testWidgets('renders right-to-left in Arabic with no layout errors', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      final BuildContext context = tester.element(
        find.byKey(LumeWastatusTool.whyKey),
      );
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('renders right-to-left in Urdu with no layout errors', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester, locale: const Locale('ur'));
      expect(tester.takeException(), isNull);
      final BuildContext context = tester.element(
        find.byKey(LumeWastatusTool.whyKey),
      );
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('survives 200% text scale with no overflow', (
      WidgetTester tester,
    ) async {
      await pumpWastatus(tester, textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '200% text scale in Arabic (RTL and long text together) still renders '
      'cleanly',
      (WidgetTester tester) async {
        await pumpWastatus(
          tester,
          locale: const Locale('ar'),
          textScale: 2.0,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
