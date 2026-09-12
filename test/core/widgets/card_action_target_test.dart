/// A card foot's actions — an accessibility correction with unchanged visible
/// geometry.
///
/// `.ghostbtn` is 35 × 30, under §9's 44 × 44 floor on both axes, and it sits
/// in a card foot that is exactly its own height: growing the control makes
/// every card carrying one fourteen points taller and moves every section
/// below it down the page. So the painted box and the target are separated,
/// as D6 separated the stepper's.
///
/// Every clause of that is asserted here, because "the target is bigger now"
/// is easy to claim and easy to get subtly wrong: targets that overlap,
/// targets that spill outside the card and get clipped out of the hit test, a
/// target that moved the glyph it belongs to, or two nested buttons where a
/// screen reader should find one.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/widgets/lume/lume_explore.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  int bookmarks = 0;
  int shares = 0;

  setUp(() {
    bookmarks = 0;
    shares = 0;
  });

  /// The reference's card: an ayah, an attribution, bookmark and share.
  Widget card() => LumeQuoteCard(
    arabic: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
    text: 'Truly, it is in the remembrance of God that hearts find rest.',
    attribution: 'Ar-Ra’d 13:28',
    actions: <LumeCardAction>[
      LumeCardAction(
        icon: LumeIcons.bookmark,
        semanticLabel: 'Bookmark',
        onPressed: () => bookmarks++,
      ),
      LumeCardAction(
        icon: LumeIcons.share,
        semanticLabel: 'Share',
        onPressed: () => shares++,
      ),
    ],
  );

  Future<void> show(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Size surface = LumeViewport.phone,
  }) => pumpLume(
    tester,
    Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 350, child: card()),
    ),
    locale: locale,
    textScale: textScale,
    surface: surface,
  );

  /// The two targets, bookmark first.
  List<Rect> targets(WidgetTester tester) => <Rect>[
    tester.getRect(find.bySemanticsLabel('Bookmark')),
    tester.getRect(find.bySemanticsLabel('Share')),
  ];

  /// The two painted glyphs, bookmark first.
  List<Rect> glyphs(WidgetTester tester) => <Rect>[
    for (final String icon in <String>[LumeIcons.bookmark, LumeIcons.share])
      tester.getRect(
        find.descendant(
          of: find.byType(LumeQuoteCard),
          matching: find.byWidgetPredicate(
            (Widget w) => w is LumeIcon && w.name == icon,
          ),
        ),
      ),
  ];

  group('what is drawn is the reference’s', () {
    testWidgets('the glyph box is 35 × 30 and the glyph 15 × 15', (
      WidgetTester tester,
    ) async {
      await show(tester);
      for (final Rect g in glyphs(tester)) {
        expect(g.size, const Size(15, 15));
      }
      // The box the glyph is centred in, which is what `.ghostbtn` measures.
      final List<Rect> t = targets(tester);
      for (int i = 0; i < 2; i++) {
        final Rect box = Rect.fromCenter(
          center: glyphs(tester)[i].center,
          width: LumeCardAction.boxWidth,
          height: LumeCardAction.boxHeight,
        );
        expect(t[i].contains(box.topLeft), isTrue, reason: 'box $i top-left');
        expect(
          t[i].contains(box.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: 'box $i bottom-right',
        );
      }
    });

    testWidgets('and the card is still the height the prototype renders', (
      WidgetTester tester,
    ) async {
      // Measured: `.quote` is 350 × 193.5 at the reference cell. A target that
      // changed this would be a target that changed the page.
      await show(tester);
      final Rect r = tester.getRect(find.byType(LumeQuoteCard));
      expect(r.width, 350);
      expect(r.height, closeTo(193.5, 1.0));
    });

    testWidgets('and the two glyphs are 39 apart, as the stylesheet puts '
        'them', (WidgetTester tester) async {
      // 35 of box plus 4 of gap. This is the number that makes two centred
      // 44-point targets impossible and the outward extension necessary.
      await show(tester);
      final List<Rect> g = glyphs(tester);
      expect(
        g[1].center.dx - g[0].center.dx,
        closeTo(LumeCardAction.boxWidth + LumeCardAction.gap, 0.01),
      );
    });
  });

  group('what can be touched is §9’s', () {
    testWidgets('each target is at least 44 × 44', (WidgetTester tester) async {
      await show(tester);
      for (final Rect t in targets(tester)) {
        expect(t.width, greaterThanOrEqualTo(LumeSpace.tap));
        expect(t.height, greaterThanOrEqualTo(LumeSpace.tap));
      }
    });

    testWidgets('and they do not overlap', (WidgetTester tester) async {
      await show(tester);
      final List<Rect> t = targets(tester);
      expect(t[0].overlaps(t[1]), isFalse);
      // They touch: the four points between the painted boxes is exactly the
      // room left over once each has taken its nine outward.
      expect(t[1].left - t[0].right, closeTo(LumeCardAction.gap, 0.01));
    });

    testWidgets('and neither reaches outside the card', (
      WidgetTester tester,
    ) async {
      // A target that spilled past the card would be clipped out of the hit
      // test by the ancestor that draws the card, and the extra points would
      // be a claim rather than a target.
      await show(tester);
      final Rect card = tester.getRect(find.byType(LumeQuoteCard));
      for (final Rect t in targets(tester)) {
        expect(card.contains(t.topLeft), isTrue);
        expect(card.contains(t.bottomRight - const Offset(0.01, 0.01)), isTrue);
      }
    });

    testWidgets('and a tap at each of the four edges activates the control', (
      WidgetTester tester,
    ) async {
      await show(tester);
      final Rect t = targets(tester)[0];
      const double inside = 0.5;
      for (final (String where, Offset at) corner in <(String, Offset)>[
        ('leading', Offset(t.left + inside, t.center.dy)),
        ('trailing', Offset(t.right - inside, t.center.dy)),
        ('top', Offset(t.center.dx, t.top + inside)),
        ('bottom', Offset(t.center.dx, t.bottom - inside)),
      ]) {
        bookmarks = 0;
        await tester.tapAt(corner.$2);
        await tester.pump();
        expect(bookmarks, 1, reason: corner.$1);
        expect(shares, 0, reason: corner.$1);
      }
    });

    testWidgets('and a tap just outside one does not', (
      WidgetTester tester,
    ) async {
      await show(tester);
      final Rect t = targets(tester)[0];
      // Above the target is the foot's padding; below it the card's. Neither
      // belongs to the control.
      await tester.tapAt(Offset(t.center.dx, t.top - 2));
      await tester.tapAt(Offset(t.center.dx, t.bottom + 2));
      await tester.pump();
      expect(bookmarks, 0);
      expect(shares, 0);
    });

    testWidgets('and the run between them belongs to neither', (
      WidgetTester tester,
    ) async {
      await show(tester);
      final List<Rect> t = targets(tester);
      await tester.tapAt(Offset((t[0].right + t[1].left) / 2, t[0].center.dy));
      await tester.pump();
      expect(bookmarks, 0);
      expect(shares, 0);
    });

    testWidgets('and the attribution beside them is not a control', (
      WidgetTester tester,
    ) async {
      await show(tester);
      await tester.tap(find.text('Ar-Ra’d 13:28'));
      await tester.pump();
      expect(bookmarks, 0);
      expect(shares, 0);
    });
  });

  group('what is announced is one control, not two', () {
    testWidgets('each action is a single button with its own name', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await show(tester);
      for (final String name in <String>['Bookmark', 'Share']) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(name))
              .flagsCollection
              .isButton,
          isTrue,
          reason: name,
        );
      }
      handle.dispose();
    });

    testWidgets('and the glyph under it says nothing of its own', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await show(tester);
      // One node per action. A nested pair would give a screen reader
      // "Bookmark, Bookmark" and two things to activate.
      expect(find.bySemanticsLabel('Bookmark'), findsOneWidget);
      expect(
        find.descendant(
          of: find.bySemanticsLabel('Bookmark'),
          matching: find.bySemanticsLabel('Bookmark'),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('and a selected action says so', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpLume(
        tester,
        LumeQuoteCard(
          text: 'Small steps, taken daily, are still a road.',
          attribution: 'Lume',
          actions: <LumeCardAction>[
            LumeCardAction(
              icon: LumeIcons.bookmark,
              semanticLabel: 'Bookmark',
              selected: true,
              onPressed: () => bookmarks++,
            ),
          ],
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Bookmark'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });
  });

  group('what a keyboard can do', () {
    testWidgets('tab reaches each action and Enter presses it', (
      WidgetTester tester,
    ) async {
      await show(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(bookmarks + shares, 1);
    });

    testWidgets('and Space does too', (WidgetTester tester) async {
      await show(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(bookmarks + shares, 1);
    });

    testWidgets('and the focus ring is drawn without moving anything', (
      WidgetTester tester,
    ) async {
      await show(tester);
      final Rect before = tester.getRect(find.byType(LumeQuoteCard));
      final List<Rect> targetsBefore = targets(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(LumeQuoteCard)), before);
      expect(targets(tester), targetsBefore);
    });
  });

  group('and all of it again', () {
    testWidgets('right to left', (WidgetTester tester) async {
      await show(tester, locale: const Locale('ur'));
      final List<Rect> t = targets(tester);
      final List<Rect> g = glyphs(tester);

      // Mirrored: bookmark is now the trailing-most, so it is the one whose
      // spare points go into the card's padding.
      expect(g[0].center.dx - g[1].center.dx, closeTo(39, 0.01));
      expect(t[0].overlaps(t[1]), isFalse);
      for (final Rect r in t) {
        expect(r.width, greaterThanOrEqualTo(LumeSpace.tap));
        expect(r.height, greaterThanOrEqualTo(LumeSpace.tap));
      }

      final Rect card = tester.getRect(find.byType(LumeQuoteCard));
      for (final Rect r in t) {
        expect(card.contains(r.topLeft), isTrue);
        expect(card.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue);
      }

      await tester.tapAt(Offset(t[0].left + 0.5, t[0].center.dy));
      await tester.pump();
      expect(bookmarks, 1);
    });

    testWidgets('at 200 per cent text', (WidgetTester tester) async {
      await show(tester, textScale: 2.0, surface: const Size(390, 1200));
      final List<Rect> t = targets(tester);
      expect(t[0].overlaps(t[1]), isFalse);
      for (final Rect r in t) {
        expect(r.width, greaterThanOrEqualTo(LumeSpace.tap));
        expect(r.height, greaterThanOrEqualTo(LumeSpace.tap));
      }
      // The glyph does not scale with the text, so the geometry is the same
      // one — the card is only taller.
      for (final Rect g in glyphs(tester)) {
        expect(g.size, const Size(15, 15));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('and on a phone lying down', (WidgetTester tester) async {
      await show(tester, surface: LumeViewport.landscapePhone);
      final List<Rect> t = targets(tester);
      expect(t[0].overlaps(t[1]), isFalse);
      for (final Rect r in t) {
        expect(r.width, greaterThanOrEqualTo(LumeSpace.tap));
        expect(r.height, greaterThanOrEqualTo(LumeSpace.tap));
      }
      await tester.tapAt(t[1].center);
      await tester.pump();
      expect(shares, 1);
    });
  });
}
