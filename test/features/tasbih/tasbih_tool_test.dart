/// Tasbih on screen: counting, the round, the ceiling, resetting, switching
/// phrase, and what is not kept.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/tasbih/application/tasbih_store.dart';
import 'package:lume/features/tasbih/domain/tasbih_count.dart';
import 'package:lume/features/tasbih/domain/tasbih_phrase.dart';
import 'package:lume/features/tasbih/presentation/tasbih_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/lifecycle.dart';
import '../../helpers/load_fonts.dart';
import 'tasbih_harness.dart';

/// The English strings, for the assertions that are about what is said.
final AppLocalizations l = AppLocalizationsEn();

/// The figure in the middle of the face.
String shown(WidgetTester tester) =>
    tester.widget<LumeNumerals>(find.byKey(LumeTasbihTool.countKey)).text;

/// One tap on the face.
Future<void> tapFace(WidgetTester tester) async {
  await tester.tap(find.byKey(LumeTasbihTool.counterKey));
  await tester.pump();
}

/// [n] taps as fast as the framework will deliver them.
Future<void> burst(WidgetTester tester, int n) async {
  for (int i = 0; i < n; i++) {
    await tester.tap(find.byKey(LumeTasbihTool.counterKey));
    await tester.pump(const Duration(milliseconds: 8));
  }
}

/// Choose the phrase whose chip reads [label], scrolling the strip to it —
/// five chips do not fit across a phone.
Future<void> choose(WidgetTester tester, String label) async {
  final Finder chip = find.text(label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// A session already holding [count].
LumeToolSession seeded(LumeTasbihCount count) {
  final LumeToolSession session = LumeToolSession();
  LumeTasbihStore(session).write(count);
  return session;
}

void main() {
  setUpAll(loadLumeFonts);

  group('what it draws', () {
    testWidgets('the phrase, the face, the rounds and Reset', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(find.byKey(LumeTasbihTool.phrasesKey), findsOneWidget);
      expect(find.byKey(LumeTasbihTool.phraseKey), findsOneWidget);
      expect(find.byKey(LumeTasbihTool.counterKey), findsOneWidget);
      expect(find.byKey(LumeTasbihTool.ringKey), findsOneWidget);
      expect(find.byKey(LumeTasbihTool.roundsKey), findsOneWidget);
      expect(find.byKey(LumeTasbihTool.resetKey), findsOneWidget);
    });

    testWidgets('the five phrases, as the reference names them', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(
        tester
            .widgetList<LumeFilterChip>(
              inTasbih(LumeTasbihTool.phrasesKey, find.byType(LumeFilterChip)),
            )
            .map((LumeFilterChip c) => c.label)
            .toList(),
        LumeTasbihPhrases.all
            .map((LumeTasbihPhrase p) => p.transliteration)
            .toList(),
      );
    });

    testWidgets('the Arabic and the gloss of the chosen phrase', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(find.text(LumeTasbihPhrases.all.first.arabic), findsOneWidget);
      expect(find.text(LumeTasbihPhrases.all.first.meaning), findsOneWidget);
    });

    testWidgets('the round is stated as a fact about the round', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(find.text(l.tasbihTargetLabel('33')), findsOneWidget);
    });

    testWidgets('it starts at nothing counted', (WidgetTester tester) async {
      await pumpTasbih(tester);
      expect(shown(tester), '0');
      expect(find.text(l.tasbihSets(0)), findsOneWidget);
    });

    testWidgets('"Recent sessions" is not drawn — nothing backs it', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      // The reference's two fixture rows, by their own words.
      expect(find.text('Recent sessions'), findsNothing);
      expect(find.text(l.commonYesterday), findsNothing);
      expect(find.byType(LumeCompactRow), findsNothing);
    });

    testWidgets('what is not kept is said instead', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(find.byKey(LumeTasbihTool.notKeptKey), findsOneWidget);
      expect(
        tester
            .widget<LumeNoteCard>(
              inTasbih(LumeTasbihTool.notKeptKey, find.byType(LumeNoteCard)),
            )
            .title,
        l.tasbihNotKept,
      );
    });

    testWidgets('the rounds read-out is a read-out, not a button', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      // `tasbih.tool.js:41` draws it with `UI.button` and gives it no action.
      expect(
        inTasbih(LumeTasbihTool.roundsKey, find.byType(LumeButton)),
        findsNothing,
      );
      final SemanticsNode node = tester.getSemantics(
        find.byKey(LumeTasbihTool.roundsKey),
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });
  });

  group('counting', () {
    testWidgets('a tap counts one', (WidgetTester tester) async {
      await pumpTasbih(tester);
      await tapFace(tester);
      expect(shown(tester), '1');
    });

    testWidgets('the ring fills with the round', (WidgetTester tester) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 0)),
      );
      expect(
        tester
            .widget<LumeProgressRing>(find.byKey(LumeTasbihTool.ringKey))
            .value,
        0,
      );
      await burst(tester, 11);
      expect(
        tester
            .widget<LumeProgressRing>(find.byKey(LumeTasbihTool.ringKey))
            .value,
        closeTo(1 / 3, 1e-9),
      );
    });

    testWidgets('a burst of taps loses none and doubles none', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      await burst(tester, 25);
      expect(shown(tester), '25');
    });

    testWidgets('a burst across a round boundary still counts every tap', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = await pumpTasbih(tester);
      await burst(tester, 40);
      await tester.pumpAndSettle();
      final LumeTasbihCount after = LumeTasbihStore(session).read();
      expect(after.rounds, 1);
      expect(after.count, 7);
    });

    testWidgets('the round finishes, says so, and starts again', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 32)),
      );
      await tapFace(tester);
      expect(shown(tester), '0');
      expect(find.text(l.tasbihSets(1)), findsOneWidget);
      expect(find.text(l.tasbihComplete), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('the ceiling', () {
    testWidgets('a tap at 9,999 rounds counts nothing and says why', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = await pumpTasbih(
        tester,
        session: seeded(
          const LumeTasbihCount(count: 12, rounds: LumeTasbihCount.maxRounds),
        ),
      );
      await tapFace(tester);
      expect(shown(tester), '12');
      expect(find.text(l.tasbihMax), findsOneWidget);
      expect(LumeTasbihStore(session).read().rounds, LumeTasbihCount.maxRounds);
      await tester.pumpAndSettle();
    });

    testWidgets('the last round before it still completes', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 32, rounds: 9998)),
      );
      await tapFace(tester);
      expect(find.text(l.tasbihSets(9999)), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('reset', () {
    testWidgets('is offered only once there is something to reset', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      expect(
        tester
            .widget<LumeButton>(find.byKey(LumeTasbihTool.resetKey))
            .onPressed,
        isNull,
      );
      await tapFace(tester);
      expect(
        tester
            .widget<LumeButton>(find.byKey(LumeTasbihTool.resetKey))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('asks before it clears, and says what goes', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
      );
      await tester.tap(find.byKey(LumeTasbihTool.resetKey));
      await tester.pumpAndSettle();
      expect(find.byKey(LumeTasbihTool.confirmKey), findsOneWidget);
      expect(find.text(l.tasbihResetAsk), findsOneWidget);
      expect(find.text(l.tasbihResetText), findsOneWidget);
      expect(find.text(l.tasbihResetGo), findsOneWidget);
      expect(find.text(l.tasbihKeepCount), findsOneWidget);
    });

    testWidgets('keeping the count changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
      );
      await tester.tap(find.byKey(LumeTasbihTool.resetKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.tasbihKeepCount));
      await tester.pumpAndSettle();
      expect(shown(tester), '12');
      expect(find.text(l.tasbihSets(2)), findsOneWidget);
    });

    testWidgets('confirming clears the count and the rounds', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
      );
      await tester.tap(find.byKey(LumeTasbihTool.resetKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.tasbihResetGo));
      await tester.pumpAndSettle();
      expect(shown(tester), '0');
      expect(find.text(l.tasbihSets(0)), findsOneWidget);
      expect(LumeTasbihStore(session).read(), const LumeTasbihCount());
    });
  });

  group('changing phrase', () {
    testWidgets('a fresh counter switches without asking', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester);
      await choose(tester, 'Astaghfirullah');
      expect(find.byKey(LumeTasbihTool.confirmKey), findsNothing);
      expect(find.text(LumeTasbihPhrases.all[4].arabic), findsOneWidget);
      expect(find.text(l.tasbihTargetLabel('100')), findsOneWidget);
    });

    testWidgets('a part-finished round is not thrown away silently', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
      );
      await choose(tester, 'Alhamdulillah');
      expect(find.text(l.tasbihSwitchAsk), findsOneWidget);
      expect(find.text(l.tasbihSwitchText), findsOneWidget);
      expect(find.text(l.tasbihSwitchGo), findsOneWidget);
      // Still on the first phrase while the question stands.
      expect(find.text(LumeTasbihPhrases.all.first.arabic), findsOneWidget);
    });

    testWidgets('keeping the count stays on the phrase', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
      );
      await choose(tester, 'Alhamdulillah');
      await tester.tap(find.text(l.tasbihKeepCount));
      await tester.pumpAndSettle();
      expect(shown(tester), '12');
      expect(find.text(LumeTasbihPhrases.all.first.arabic), findsOneWidget);
    });

    testWidgets('changing it zeroes the count and keeps the rounds', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
      );
      await choose(tester, 'Alhamdulillah');
      await tester.tap(find.text(l.tasbihSwitchGo));
      await tester.pumpAndSettle();
      expect(shown(tester), '0');
      expect(find.text(l.tasbihSets(2)), findsOneWidget);
      expect(LumeTasbihStore(session).read().phrase, 1);
    });

    testWidgets('choosing the phrase already chosen asks nothing', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 12)),
      );
      await choose(tester, 'SubhanAllah');
      expect(find.byType(LumeSheet), findsNothing);
      expect(shown(tester), '12');
    });
  });

  group('how long the count lasts', () {
    testWidgets('it is there when the tool is opened again', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = await pumpTasbih(tester);
      await burst(tester, 5);
      await tester.pumpAndSettle();
      await pumpTasbih(tester, session: session);
      expect(shown(tester), '5');
    });

    testWidgets('a new run of the app starts at nothing', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(
        tester,
        session: seeded(const LumeTasbihCount(count: 9)),
      );
      expect(shown(tester), '9');
      // A fresh session is what a fresh launch has: nothing was written down.
      await pumpTasbih(tester);
      expect(shown(tester), '0');
    });

    testWidgets('backgrounding the app neither loses nor writes the count', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = await pumpTasbih(tester);
      await burst(tester, 4);
      await lumeGoAway(tester);
      await tester.pumpAndSettle();
      await lumeComeBack(tester);
      await tester.pumpAndSettle();
      expect(shown(tester), '4');
      expect(LumeTasbihStore(session).read().count, 4);
    });
  });

  group('where a hidden tool must not appear', () {
    testWidgets('a reader without the Islamic experience is refused', (
      WidgetTester tester,
    ) async {
      await pumpTasbihRoute(tester, state: 'default_pk');
      // Whether or not the id is in the registry, the route refuses it: the
      // catalogue's gate answers before anything is built (§64).
      expect(find.byKey(LumeTasbihTool.counterKey), findsNothing);
      expect(find.text(LumeTasbihPhrases.all.first.arabic), findsNothing);
    });

    testWidgets('a Muslim reader outside Pakistan gets the same tool', (
      WidgetTester tester,
    ) async {
      await pumpTasbih(tester, state: 'muslim_gb');
      expect(find.byKey(LumeTasbihTool.counterKey), findsOneWidget);
      expect(find.text(l.tasbihTargetLabel('33')), findsOneWidget);
    });
  });
}
