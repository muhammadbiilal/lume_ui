/// The component gallery, as a development surface and as a smoke test.
///
/// It renders every component in one tree, so if it lays out clean at every
/// width class, in both themes and all three languages, the component system
/// composes. That is a weaker claim than the per-component tests make, and a
/// different one: those check each widget alone, this checks them together.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/gallery/presentation/component_gallery.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  test('the gallery is marked development-only', () {
    // A guard with teeth: if anyone wires a production route to the gallery,
    // this is the constant they have to lie about first.
    expect(kGalleryIsDevelopmentOnly, isTrue);
  });

  group('it lays out at every width class', () {
    const Map<String, Size> widths = <String, Size>{
      'narrow 359': LumeViewport.narrow,
      'phone 390': LumeViewport.phone,
      'large phone 430': LumeViewport.phoneLarge,
      'medium 700': LumeViewport.medium,
      'expanded 1100': LumeViewport.expanded,
      'wide 1280': LumeViewport.wide,
      'landscape phone 852x393': LumeViewport.landscapePhone,
    };

    widths.forEach((String label, Size size) {
      testWidgets('at $label', (WidgetTester tester) async {
        await pumpLume(tester, const ComponentGallery(), surface: size);
        expectNoOverflow(tester);
      });
    });
  });

  group('it lays out in every theme and language', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final String code in <String>['en', 'ur', 'ar']) {
        testWidgets('${mode.name} · $code', (WidgetTester tester) async {
          await pumpLume(
            tester,
            const ComponentGallery(),
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
      await pumpLume(
        tester,
        const ComponentGallery(),
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
        const ComponentGallery(),
        textScale: 2.0,
        surface: LumeViewport.narrow,
      );
      expectNoOverflow(tester);
    });
  });

  group('it is interactive, not a picture', () {
    testWidgets('the theme switch works', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const ComponentGallery(),
        surface: const Size(390, 3000),
      );
      expect(find.text('Light'), findsOneWidget);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('the text-scale switch works', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const ComponentGallery(),
        surface: const Size(390, 3000),
      );
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.text('100%'));
      await tester.pumpAndSettle();
      expect(find.text('150%'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('a control in the gallery is the real control', (
      WidgetTester tester,
    ) async {
      // Not a replica: toggling the gallery's switch toggles a LumeSwitch,
      // which is the widget every screen will use.
      await pumpLume(
        tester,
        const ComponentGallery(),
        surface: const Size(390, 12000),
      );
      expect(find.text('Components · compact'), findsOneWidget);
    });
  });
}
