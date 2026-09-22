/// Reaching the counter without a fingertip, and hearing where it has got
/// to without hearing every tap on the way.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/features/tasbih/application/tasbih_store.dart';
import 'package:lume/features/tasbih/domain/tasbih_count.dart';
import 'package:lume/features/tasbih/domain/tasbih_phrase.dart';
import 'package:lume/features/tasbih/presentation/tasbih_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'tasbih_harness.dart';

final AppLocalizations en = AppLocalizationsEn();

String face(WidgetTester tester) =>
    tester.widget<LumeNumerals>(find.byKey(LumeTasbihTool.countKey)).text;

LumeToolSession holding(LumeTasbihCount count) {
  final LumeToolSession session = LumeToolSession();
  LumeTasbihStore(session).write(count);
  return session;
}

/// Tab until the focus is inside the tap target. Returns false if it never
/// gets there, which is the failure worth naming.
Future<bool> focusFace(WidgetTester tester) async {
  for (int i = 0; i < 40; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final BuildContext? focused =
        tester.binding.focusManager.primaryFocus?.context;
    if (focused == null) continue;
    bool inside = false;
    focused.visitAncestorElements((Element e) {
      if (e.widget.key == LumeTasbihTool.counterKey) {
        inside = true;
        return false;
      }
      return true;
    });
    if (inside) return true;
  }
  return false;
}

void main() {
  setUpAll(loadLumeFonts);

  group('reaching it', () {
    testWidgets('the tap target takes keyboard focus and Enter counts', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(
        await focusFace(tester),
        isTrue,
        reason: 'the face never took focus',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(face(tester), '1');
    });

    testWidgets('Space counts too', (WidgetTester tester) async {
      await pumpTasbih(tester);
      expect(await focusFace(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(face(tester), '1');
    });

    testWidgets('an assistive activation counts — switch access, and a '
        'screen reader\'s double tap', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(tester);
      final SemanticsNode node = tester.getSemantics(
        find.byKey(LumeTasbihTool.counterKey),
      );
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the face is not activatable without a pointer',
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(face(tester), '1');
      handle.dispose();
    });

    testWidgets('every phrase can be chosen from the keyboard', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      final Set<String> reached = <String>{};
      for (int i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext? focused =
            tester.binding.focusManager.primaryFocus?.context;
        if (focused == null) continue;
        final Iterable<Text> words = tester.widgetList<Text>(
          find.descendant(
            of: find.byElementPredicate((Element e) => e == focused),
            matching: find.byType(Text),
          ),
        );
        reached.addAll(words.map((Text t) => t.data ?? ''));
      }
      for (final LumeTasbihPhrase p in LumeTasbihPhrases.all) {
        expect(
          reached,
          contains(p.transliteration),
          reason: '${p.transliteration} cannot be reached by keyboard',
        );
      }
    });
  });

  group('what a screen reader hears', () {
    testWidgets('the face is a button that says what it does', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(tester);
      final SemanticsData data = tester
          .getSemantics(find.byKey(LumeTasbihTool.counterKey))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, en.tasbihTap);
      expect(data.value, en.tasbihOf('0', '33'));
      handle.dispose();
    });

    testWidgets('the ring reports itself as progress towards the round', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(
        tester,
        session: holding(const LumeTasbihCount(count: 11)),
      );
      final SemanticsData data = tester
          .getSemantics(find.byKey(LumeTasbihTool.ringKey))
          .getSemanticsData();
      // `tasbih.tool.js:36-37` draws the ring `aria-hidden`; the shared
      // component names it and gives it a value.
      expect(data.label, en.tasbihCounter);
      expect(data.value, en.tasbihOf('11', '33'));
      handle.dispose();
    });

    testWidgets('a burst is not announced tap by tap', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(tester);
      final List<String> announced = <String>[];
      for (int i = 0; i < 20; i++) {
        await tester.tap(find.byKey(LumeTasbihTool.counterKey));
        await tester.pump(const Duration(milliseconds: 8));
        announced.add(
          tester
              .getSemantics(find.byKey(LumeTasbihTool.counterKey))
              .getSemanticsData()
              .value,
        );
      }
      // Twenty taps inside the settling window; the spoken value has not
      // moved, so a screen reader has nothing new to interrupt with.
      expect(announced.toSet(), <String>{en.tasbihOf('0', '33')});
      expect(face(tester), '20');

      await tester.pump(LumeTasbihTool.announceAfter);
      expect(
        tester
            .getSemantics(find.byKey(LumeTasbihTool.counterKey))
            .getSemanticsData()
            .value,
        en.tasbihOf('20', '33'),
      );
      handle.dispose();
    });

    testWidgets('the value is a live region, so the settled figure is said', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(tester);
      expect(
        tester
            .getSemantics(find.byKey(LumeTasbihTool.counterKey))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('finishing a round is said at once, not after the wait', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(
        tester,
        session: holding(const LumeTasbihCount(count: 32)),
      );
      await tester.tap(find.byKey(LumeTasbihTool.counterKey));
      await tester.pump();
      expect(
        tester
            .getSemantics(find.byKey(LumeTasbihTool.counterKey))
            .getSemanticsData()
            .value,
        en.tasbihOf('0', '33'),
      );
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('the gloss is labelled as a meaning', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTasbih(tester);
      final SemanticsData data = tester
          .getSemantics(
            find
                .ancestor(
                  of: find.text(LumeTasbihPhrases.all.first.meaning),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .getSemanticsData();
      expect(data.label, en.tasbihMeaning);
      expect(data.value, LumeTasbihPhrases.all.first.meaning);
      handle.dispose();
    });
  });

  group('haptics are optional', () {
    testWidgets('a device with no haptics still counts', (
      WidgetTester tester,
    ) async {
      // No handler is registered for the platform channel, so every call
      // raises MissingPluginException — which is exactly a build with no
      // haptic support.
      await pumpTasbih(tester);
      await tester.tap(find.byKey(LumeTasbihTool.counterKey));
      await tester.pump();
      expect(face(tester), '1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a platform that refuses to vibrate still counts', (
      WidgetTester tester,
    ) async {
      final List<String> asked = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            asked.add('${call.arguments}');
            throw PlatformException(code: 'no_vibrator');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpTasbih(
        tester,
        session: holding(const LumeTasbihCount(count: 32)),
      );
      await tester.tap(find.byKey(LumeTasbihTool.counterKey));
      await tester.pump();
      expect(face(tester), '0');
      expect(find.text(en.tasbihSets(1)), findsOneWidget);
      expect(asked, isNotEmpty, reason: 'haptics were never offered');
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });

  group('the shapes the interface can be asked to take', () {
    for (final String language in <String>['ar', 'ur']) {
      testWidgets('$language reads right to left and still counts', (
        WidgetTester tester,
      ) async {
        await pumpTasbih(tester, locale: Locale(language));
        expect(
          Directionality.of(
            tester.element(find.byKey(LumeTasbihTool.counterKey)),
          ),
          TextDirection.rtl,
        );
        await tester.tap(find.byKey(LumeTasbihTool.counterKey));
        await tester.pump();
        // The figure is a numeral run, which stays left to right inside an
        // RTL page (`shared.css:647`).
        expect(find.byKey(LumeTasbihTool.countKey), findsOneWidget);
        expect(find.byKey(LumeTasbihTool.ringKey), findsOneWidget);
      });
    }

    testWidgets('the Arabic is drawn in its own direction in an English '
        'interface', (WidgetTester tester) async {
      await pumpTasbih(tester);
      expect(
        Directionality.of(
          tester.element(find.text(LumeTasbihPhrases.all.first.arabic)),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('at 200 % text nothing overflows and it still counts', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        textScale: 2,
        session: holding(const LumeTasbihCount(count: 9, rounds: 3)),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(LumeTasbihTool.counterKey));
      await tester.pump();
      expect(face(tester), '10');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ceiling still fits the face at 200 % text', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        textScale: 2,
        session: holding(
          const LumeTasbihCount(count: 32, rounds: LumeTasbihCount.maxRounds),
        ),
      );
      expect(
        find.text(en.tasbihSets(LumeTasbihCount.maxRounds)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with motion turned down it counts and settles', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      await tester.tap(find.byKey(LumeTasbihTool.counterKey));
      // Nothing here runs forever, so the pump can settle: a ring that
      // animated indefinitely would hang here.
      await tester.pumpAndSettle();
      expect(face(tester), '1');
    });

    testWidgets('in the dark it draws the same tool', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester, theme: ThemeMode.dark);
      expect(find.byKey(LumeTasbihTool.counterKey), findsOneWidget);
      expect(find.text(en.tasbihTargetLabel('33')), findsOneWidget);
    });

    for (final Size surface in <Size>[
      LumeViewport.narrow,
      LumeViewport.medium,
      LumeViewport.expanded,
    ]) {
      testWidgets('it draws at ${surface.width.toInt()}', (
        WidgetTester tester,
      ) async {
        await pumpTasbih(tester, surface: Size(surface.width, 5000));
        expect(find.byKey(LumeTasbihTool.counterKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
