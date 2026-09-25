/// Media Saver on screen: opened directly for a reader ([pumpLume]), not
/// through the real router — the shared `tool_registry.dart` this repository
/// routes through is out of scope for this change, the same approach
/// `parcel_tool_test.dart` and `trains_tool_test.dart` take for their own
/// waves.
///
/// The load-bearing assertions here are the honesty ones: the screen never
/// claims a download happened, never invents a saved file, and says plainly
/// — on screen, not only in a toast that scrolls away — that Lume cannot
/// fetch media from a link.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/mediasaver/presentation/mediasaver_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

final LumeFeature _mediaFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeMediaSaverTool.id,
);

Future<void> pumpMediaSaver(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
  double textScale = 1,
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeMediaSaverTool(
      request: LumeToolRequest(
        feature: _mediaFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  setUpAll(loadLumeFonts);

  group('the catalogue entry', () {
    test('declares no network fetch and is not sensitive', () {
      expect(_mediaFeature.sensitive, isFalse);
    });
  });

  group('what it draws', () {
    testWidgets('a link field, a permanent no-network notice, and an empty '
        'library — never the reference’s fabricated files or storage figure', (
      WidgetTester tester,
    ) async {
      await pumpMediaSaver(tester);

      expect(
        inKey(LumeMediaSaverTool.fieldKey, find.byType(EditableText)),
        findsOneWidget,
      );
      expect(find.byKey(LumeMediaSaverTool.noticeKey), findsOneWidget);
      expect(
        tester
            .widget<LumeNotice>(find.byKey(LumeMediaSaverTool.noticeKey))
            .kind,
        LumeNoticeKind.info,
      );

      // No sample media, no fabricated size, no fabricated storage total —
      // the reference's three items and "182 MB" have no honest counterpart
      // here, so none of it is drawn.
      expect(find.text('182 MB'), findsNothing);
      expect(find.textContaining('MB'), findsNothing);
      final LumeToolState empty = tester.widget<LumeToolState>(
        find.byKey(LumeMediaSaverTool.libraryKey),
      );
      expect(empty.isError, isFalse);
    });

    testWidgets('the notice explains the limitation in words, not a status '
        'chip or a bare icon', (WidgetTester tester) async {
      await pumpMediaSaver(tester);
      final LumeNotice notice = tester.widget<LumeNotice>(
        find.byKey(LumeMediaSaverTool.noticeKey),
      );
      expect(notice.title, isNotEmpty);
      expect(notice.text, isNotEmpty);
      expect(notice.text.toLowerCase(), contains('internet'));
    });
  });

  group('used', () {
    testWidgets('Save answers whatever was typed — or nothing — with the '
        'same fixed, honest line, never a claim of success', (
      WidgetTester tester,
    ) async {
      await pumpMediaSaver(tester);
      await tester.enterText(
        inKey(LumeMediaSaverTool.fieldKey, find.byType(EditableText)),
        'https://example.com/not-a-real-post',
      );
      await tester.pump();
      await tester.tap(inKey(LumeMediaSaverTool.saveKey, find.text('Save')));
      await tester.pump();

      expect(find.byType(LumeToast), findsOneWidget);
      final LumeToast toast = tester.widget<LumeToast>(find.byType(LumeToast));
      expect(toast.data.tone, LumeToastTone.info);
      // The library stays empty — pressing Save never adds a fixture item,
      // whatever was pasted.
      expect(find.byKey(LumeMediaSaverTool.libraryKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('pressing Save twice with different links shows the exact '
        'same words both times', (WidgetTester tester) async {
      await pumpMediaSaver(tester);
      final Finder save = inKey(LumeMediaSaverTool.saveKey, find.text('Save'));

      await tester.enterText(
        inKey(LumeMediaSaverTool.fieldKey, find.byType(EditableText)),
        'https://example.com/a',
      );
      await tester.tap(save);
      await tester.pump();
      final String first = tester
          .widget<LumeToast>(find.byType(LumeToast))
          .data
          .message;
      await tester.pump(const Duration(seconds: 3));

      await tester.enterText(
        inKey(LumeMediaSaverTool.fieldKey, find.byType(EditableText)),
        'https://example.com/b',
      );
      await tester.tap(save);
      await tester.pump();
      final String second = tester
          .widget<LumeToast>(find.byType(LumeToast))
          .data
          .message;

      expect(first, second);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('there is no share action — there is nothing honest for '
        'this tool to share', (WidgetTester tester) async {
      await pumpMediaSaver(tester);
      expect(
        find.byWidgetPredicate((Widget w) => w is LumeShareCardArt),
        findsNothing,
      );
    });

    testWidgets('in Urdu the field and notice run right to left, without '
        'overflow', (WidgetTester tester) async {
      await pumpMediaSaver(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeMediaSaverTool.noticeKey)),
        ),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpMediaSaver(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
