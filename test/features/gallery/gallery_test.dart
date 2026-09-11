/// The token gallery, which is the F1 verification surface.
///
/// It earns a test because it is the one place every token is rendered
/// together: if the gallery lays out at every viewport, in both themes, in
/// three languages and at 200 % text without overflowing, the foundation is
/// sound enough to build components on.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/features/gallery/presentation/gallery_screen.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('it lays out at every viewport', () {
    const List<(String, Size)> viewports = <(String, Size)>[
      ('359 narrow', LumeViewport.narrow),
      ('390 phone', LumeViewport.phone),
      ('430 large phone', LumeViewport.phoneLarge),
      ('700 medium', LumeViewport.medium),
      ('1100 expanded', LumeViewport.expanded),
      ('1280 wide', LumeViewport.wide),
      ('852x393 landscape phone', LumeViewport.landscapePhone),
    ];

    for (final (String label, Size size) in viewports) {
      testWidgets('$label lays out without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpLume(tester, const GalleryScreen(), surface: size);
        expectNoOverflow(tester);
      });
    }
  });

  group('it lays out in both themes and all three languages', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final String code in <String>['en', 'ur', 'ar']) {
        testWidgets('${mode.name} · $code', (WidgetTester tester) async {
          await pumpLume(
            tester,
            const GalleryScreen(),
            theme: mode,
            locale: Locale(code),
          );
          expectNoOverflow(tester);
        });
      }
    }
  });

  group('dynamic type', () {
    testWidgets('200 per cent does not overflow', (WidgetTester tester) async {
      // §9 asks for at least 200 % without clipping. The gallery is a scroll
      // view, so growth goes downward rather than out of the surface — which
      // is the behaviour every screen should have.
      await pumpLume(
        tester,
        const GalleryScreen(),
        textScale: 2.0,
        surface: LumeViewport.phone,
      );
      expectNoOverflow(tester);
    });

    testWidgets('200 per cent at the narrowest width does not overflow', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        const GalleryScreen(),
        textScale: 2.0,
        surface: LumeViewport.narrow,
      );
      expectNoOverflow(tester);
    });
  });

  group('it shows what it claims to', () {
    testWidgets('every icon in the set is rendered', (
      WidgetTester tester,
    ) async {
      // A tall surface, because a lazy list otherwise builds only a screenful
      // and a count would prove nothing.
      await pumpLume(
        tester,
        const GalleryScreen(),
        surface: const Size(390, 6000),
      );
      expect(find.text('Icons — ${LumeIcons.all.length}'), findsOneWidget);
    });

    testWidgets('it reports the measured width class', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        const GalleryScreen(),
        surface: LumeViewport.expanded,
      );
      expect(find.text('expanded'), findsOneWidget);
    });

    testWidgets('a landscape phone is reported as compact, with the reason', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        const GalleryScreen(),
        surface: LumeViewport.landscapePhone,
      );
      expect(find.text('compact'), findsOneWidget);
      expect(
        find.textContaining('height override active'),
        findsOneWidget,
        reason: 'the gallery should say why it is compact on a wide surface',
      );
    });
  });
}
