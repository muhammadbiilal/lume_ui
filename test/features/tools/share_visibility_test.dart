/// A control that cannot do what it says is never drawn as though it could.
///
/// Expenses and Goals declare Share in the reference's supports and have no
/// typed card, privacy filter or share adapter behind it (Goals is not
/// converted yet, so only Expenses draws a tool bar here). The parity flavor
/// reproduces the reference's control for evidence — disabled, announced as
/// unavailable, with no handler for a tap, a key or an assistive action.
/// Development and release leave it out. A tool with a real card keeps its
/// Share in every flavor.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';

import '../../helpers/load_fonts.dart';
import '../wave1/wave1_tools_test.dart' show pumpTool, toolbarAction;

void main() {
  setUpAll(loadLumeFonts);

  List<Override> flavor(LumeBuildProfile p) => <Override>[
    buildProfileProvider.overrideWithValue(p),
  ];

  Finder share() => toolbarAction('Share');

  test('Expenses and Goals declare Share and cannot share', () {
    for (final String id in <String>['expenses', 'goals']) {
      final LumeFeature f = kLumeFeatures.firstWhere(
        (LumeFeature x) => x.id == id,
      );
      expect(f.supports, contains(LumeToolSupport.sharing), reason: id);
      expect(f.shareable, isFalse, reason: id);
    }
  });

  for (final String id in <String>['expenses']) {
    testWidgets('$id · parity: the reference\'s Share, truly disabled', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await pumpTool(t, id, overrides: flavor(LumeBuildProfile.parity));
      expect(share(), findsOneWidget);
      expect(t.widget<LumeIconButton>(share()).onPressed, isNull);

      // Announced as a button that is not available.
      final SemanticsData s = t.getSemantics(share()).getSemanticsData();
      expect(s.label, 'Share');
      expect(s.flagsCollection.isButton, isTrue);
      expect(s.flagsCollection.isEnabled, Tristate.isFalse);
      expect(s.hasAction(SemanticsAction.tap), isFalse);

      // No key reaches it: nothing on it can take focus.
      expect(
        find.descendant(
          of: share(),
          matching: find.byType(FocusableActionDetector),
        ),
        findsNothing,
      );

      // A tap does nothing — no sheet, no sentence.
      await t.tap(share(), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.byType(LumeSheet), findsNothing);
      h.dispose();
    });

    for (final LumeBuildProfile p in <LumeBuildProfile>[
      LumeBuildProfile.development,
      LumeBuildProfile.release,
    ]) {
      testWidgets('$id · ${p.name}: no Share at all', (WidgetTester t) async {
        await pumpTool(t, id, overrides: flavor(p));
        expect(share(), findsNothing);
        expect(find.bySemanticsLabel('Share'), findsNothing);
        // Tab through the whole screen: nothing named Share takes focus.
        for (int i = 0; i < 40; i++) {
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.pump();
          final BuildContext? c = FocusManager.instance.primaryFocus?.context;
          if (c == null) continue;
          expect(
            c.findAncestorWidgetOfExactType<LumeIconButton>()?.label,
            isNot('Share'),
          );
        }
      });
    }
  }

  for (final LumeBuildProfile p in LumeBuildProfile.values) {
    testWidgets('Age · ${p.name}: a real card keeps its Share, live', (
      WidgetTester t,
    ) async {
      await pumpTool(t, 'age', overrides: flavor(p));
      expect(share(), findsOneWidget);
      expect(t.widget<LumeIconButton>(share()).onPressed, isNotNull);
    });
  }

  // Every tool that declares Share: in development and release its Share is
  // live or not there at all.
  final List<String> sharing = <String>[
    for (final LumeFeature f in kLumeFeatures)
      if (f.supports.contains(LumeToolSupport.sharing)) f.id,
  ];
  for (final LumeBuildProfile p in <LumeBuildProfile>[
    LumeBuildProfile.development,
    LumeBuildProfile.release,
  ]) {
    testWidgets('${p.name}: no tool draws a Share it cannot use', (
      WidgetTester t,
    ) async {
      for (final String id in sharing) {
        await pumpTool(t, id, overrides: flavor(p));
        for (final LumeIconButton b in t.widgetList<LumeIconButton>(share())) {
          expect(b.onPressed, isNotNull, reason: id);
        }
      }
    });
  }

  // Every tool that declares search: in development and release its Search
  // works or is not there; in parity it may stay only disabled — no
  // handler, no focus, announced as unavailable. Never inert.
  final List<String> searching = <String>[
    for (final LumeFeature f in kLumeFeatures)
      if (f.supports.contains(LumeToolSupport.search)) f.id,
  ];
  for (final LumeBuildProfile p in LumeBuildProfile.values) {
    testWidgets('${p.name}: no tool draws a Search that does nothing', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      int disabled = 0;
      for (final String id in searching) {
        await pumpTool(t, id, overrides: flavor(p));
        final Finder search = toolbarAction('Search this tool');
        for (final Element e in search.evaluate()) {
          final LumeIconButton b = e.widget as LumeIconButton;
          if (b.onPressed != null) continue;
          expect(p, LumeBuildProfile.parity, reason: '$id: a dead Search');
          disabled++;
          final Finder one = find.byElementPredicate((Element x) => x == e);
          expect(
            find.descendant(
              of: one,
              matching: find.byType(FocusableActionDetector),
            ),
            findsNothing,
            reason: id,
          );
          final SemanticsData s = t.getSemantics(one).getSemanticsData();
          expect(s.flagsCollection.isEnabled, Tristate.isFalse, reason: id);
          expect(s.hasAction(SemanticsAction.tap), isFalse, reason: id);
        }
      }
      if (p != LumeBuildProfile.parity) expect(disabled, 0);
      h.dispose();
    });
  }
}
