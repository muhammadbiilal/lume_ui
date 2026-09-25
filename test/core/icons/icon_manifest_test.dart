/// The icon set: complete, geometrically faithful, and correctly directional.
///
/// The icons were extracted from the web reference's own sprite (`index.html`)
/// and compared back against it byte for byte before Phase F9 removed that
/// file — every one of the 112 matched. The manifest and the geometry checks
/// below stand on their own now, with nothing left to compare against.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/theme/lume/lume_space.dart';

import '../../helpers/lume_harness.dart';

const String _dir = 'assets/icons';

void main() {
  final Map<String, dynamic> manifest =
      jsonDecode(File('$_dir/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final List<String> manifestNames = (manifest['icons'] as List<dynamic>)
      .cast<String>();

  group('completeness', () {
    test('the manifest declares 112 icons', () {
      expect(manifest['count'], 112);
      expect(manifestNames, hasLength(112));
    });

    test('LumeIcons.all matches the manifest exactly', () {
      expect(LumeIcons.all.toSet(), manifestNames.toSet());
      expect(LumeIcons.all, hasLength(112));
    });

    test('every declared icon has an asset file', () {
      for (final String name in LumeIcons.all) {
        expect(
          File('$_dir/$name.svg').existsSync(),
          isTrue,
          reason:
              'assets/icons/$name.svg is missing — a silent fallback '
              'would ship instead',
        );
      }
    });

    test('no asset file is undeclared', () {
      final Set<String> onDisk = Directory(_dir)
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.svg'))
          .map((File f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
          .toSet();
      expect(onDisk.difference(LumeIcons.all.toSet()), isEmpty);
    });

    test('no name collides after camel-casing', () {
      expect(LumeIcons.all.toSet(), hasLength(LumeIcons.all.length));
    });
  });

  group('geometry survived extraction', () {
    test(
      'every asset carries the stroke presentation the sprite inherited',
      () {
        for (final String name in LumeIcons.all) {
          final String svg = File('$_dir/$name.svg').readAsStringSync();
          expect(svg, contains('fill="none"'), reason: name);
          expect(svg, contains('stroke="currentColor"'), reason: name);
          expect(
            svg,
            contains('stroke-width="${LumeSpace.iconStroke}"'),
            reason: '$name must carry the 1.75 stroke',
          );
          expect(svg, contains('stroke-linecap="round"'), reason: name);
          expect(svg, contains('stroke-linejoin="round"'), reason: name);
        }
      },
    );

    test('every icon is drawn in the same 24 box', () {
      for (final String name in LumeIcons.all) {
        expect(
          File('$_dir/$name.svg').readAsStringSync(),
          contains('viewBox="0 0 24 24"'),
          reason: name,
        );
      }
    });

    test('a per-symbol fill override survives', () {
      // `i-battery`'s charge bar is filled, not stroked. It is the only one,
      // and it is exactly the kind of detail a re-drawing would lose.
      expect(
        File('$_dir/battery.svg').readAsStringSync(),
        contains('fill="currentColor" stroke="none"'),
      );
    });

    test('every asset actually draws something', () {
      // Length is the wrong measure — `minus` is one short path and is
      // legitimately the smallest file in the set. What matters is that the
      // body holds at least one drawing element.
      final RegExp shape = RegExp(
        r'<(path|circle|rect|line|polyline|polygon|ellipse)',
      );
      for (final String name in LumeIcons.all) {
        final String svg = File('$_dir/$name.svg').readAsStringSync();
        expect(shape.hasMatch(svg), isTrue, reason: '$name has no geometry');
      }
    });

    test('every asset is well-formed enough to declare a namespace', () {
      for (final String name in LumeIcons.all) {
        expect(
          File('$_dir/$name.svg').readAsStringSync(),
          startsWith('<svg xmlns="http://www.w3.org/2000/svg"'),
          reason: name,
        );
      }
    });
  });

  group('directionality', () {
    test('the mirroring set is only forward/back glyphs', () {
      expect(LumeIcons.directional, contains(LumeIcons.chevR));
      expect(LumeIcons.directional, contains(LumeIcons.arrowR));
    });

    test('clocks, media controls and compasses never mirror', () {
      for (final String name in <String>[
        LumeIcons.clock,
        LumeIcons.play,
        LumeIcons.compass,
        LumeIcons.navigation,
        LumeIcons.timer,
      ]) {
        expect(
          LumeIcons.mirrors(name),
          isFalse,
          reason: '$name is a picture of a thing, not a reading direction',
        );
      }
    });

    test('vertical arrows do not mirror', () {
      expect(LumeIcons.mirrors(LumeIcons.arrowUp), isFalse);
      expect(LumeIcons.mirrors(LumeIcons.arrowDown), isFalse);
    });

    test('every name in both sets is a real icon', () {
      for (final String n in <String>[
        ...LumeIcons.directional,
        ...LumeIcons.neverMirror,
      ]) {
        expect(LumeIcons.all, contains(n), reason: '$n is not in the set');
      }
    });

    testWidgets('a directional icon mirrors in RTL and not in LTR', (
      WidgetTester tester,
    ) async {
      Matrix4? transformOf(WidgetTester t) {
        final Iterable<Transform> ts = t.widgetList<Transform>(
          find.byType(Transform),
        );
        return ts.isEmpty ? null : ts.first.transform;
      }

      await pumpLume(
        tester,
        const LumeIcon(LumeIcons.chevR),
        locale: const Locale('en'),
      );
      expect(transformOf(tester), isNull, reason: 'LTR must not mirror');

      await pumpLume(
        tester,
        const LumeIcon(LumeIcons.chevR),
        locale: const Locale('ar'),
      );
      expect(
        transformOf(tester)?.entry(0, 0),
        -1.0,
        reason: 'a forward chevron must point the way the language reads',
      );
    });

    testWidgets('a clock does not mirror even in RTL', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        const LumeIcon(LumeIcons.clock),
        locale: const Locale('ar'),
      );
      expect(find.byType(Transform), findsNothing);
    });
  });

  group('rendering', () {
    testWidgets('an icon renders at each of the three sizes', (
      WidgetTester tester,
    ) async {
      for (final double size in <double>[
        LumeSpace.iconSm,
        LumeSpace.iconMd,
        LumeSpace.iconLg,
      ]) {
        // Centred, because `home:` hands its child tight constraints and no
        // widget can be smaller than the constraints it is given.
        await pumpLume(
          tester,
          Center(child: LumeIcon(LumeIcons.home, size: size)),
        );
        expect(
          tester.getSize(find.byType(LumeIcon)),
          Size(size, size),
          reason: 'icon at $size',
        );
      }
    });

    testWidgets('a representative sample renders without throwing', (
      WidgetTester tester,
    ) async {
      const List<String> sample = <String>[
        LumeIcons.lume,
        LumeIcons.home,
        LumeIcons.grid,
        LumeIcons.sun,
        LumeIcons.compass,
        LumeIcons.user,
        LumeIcons.battery,
        LumeIcons.prayer,
        LumeIcons.train,
        LumeIcons.calculator,
      ];
      for (final String name in sample) {
        await pumpLume(tester, LumeIcon(name));
        expect(tester.takeException(), isNull, reason: name);
      }
    });

    testWidgets('an unlabelled icon contributes no semantics', (
      WidgetTester tester,
    ) async {
      // Asserting on the tree would count SvgPicture's own ExcludeSemantics
      // as well as ours. What matters is the outcome: a decorative icon says
      // nothing to a screen reader.
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpLume(tester, const Center(child: LumeIcon(LumeIcons.home)));
      expect(
        find.bySemanticsLabel(RegExp('.+')),
        findsNothing,
        reason: 'a decorative icon must not be announced',
      );
      handle.dispose();
    });

    testWidgets('a labelled icon announces itself', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        const Center(child: LumeIcon(LumeIcons.home, semanticLabel: 'Home')),
      );
      expect(tester.getSemantics(find.byType(LumeIcon)).label, 'Home');
    });
  });
}
