/// Birthdays against the running reference — where every box is, and what
/// every box says.
///
/// The seven committed cells were measured in a browser with
/// `measure_destinations.mjs --tool birthdays`, and [ToolParity] compares each
/// recorded `getBoundingClientRect` against the finder for the same element,
/// relative to the tool bar on both sides. Only the parity build is compared:
/// the three dates are in `kLumeParityOnlySeeds`, so no development or
/// release build draws them (`birthdays_screen_test.dart`).
///
/// One structural difference runs through the whole list cell, and it is
/// measured rather than hidden. The reference's "Coming up" lists **four**
/// rows; this lists **three**. The fourth — "Ammi" — is a `context.js`
/// constant and is not a record: the reference's own record list above it
/// holds three, and its own tool bar says "3 records". One screen, two
/// counts. So everything above that fourth row compares with no allowance at
/// all, and the row the reference has and this has not is declared as a
/// number — 73 points, read out of the reference's own measurement — on the
/// card that holds the rows, on the section around it, and on everything
/// below. The subtraction itself is asserted in the second group.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/birthdays/presentation/birthdays_tool.dart';
import 'package:lume/features/records/presentation/record_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'birthdays_harness.dart';

const LumeRecordKeys keys = LumeBirthdaysTool.keys;

/// One "Coming up" row, read out of the reference's own measurement:
/// `rrow2.y - rrow1.y` in the 390 cell is 711.08 − 638.08, and the card that
/// holds four of them is 293 tall — one point of top hairline and 4 × 73.
const double kReferenceRow = 73;

/// The gap above a section, which a [LumeToolSection] carries inside its own
/// box where the reference's `<section>` carries it as a margin outside.
/// `.sect--tight` — the record list — is 16; the rest are 24.
const double kTightGap = 16;
const double kSectionGap = 24;

/// Everything below the "Coming up" list sits one row higher here.
const Map<String, double> kOneRowFewer = <String, double>{
  'srcbar': -kReferenceRow,
  'fresh': -kReferenceRow,
  'related': -kReferenceRow,
  'related.title': -kReferenceRow,
  'related.item1': -kReferenceRow,
  'related.item2': -kReferenceRow,
};

const Map<String, double> kListShifted = <String, double>{
  'sect1': -kTightGap,
  'sect2': -kSectionGap,
  'sect3': -kSectionGap,
  'related.sect': -kSectionGap - kReferenceRow,
  // The reference top-aligns the 38-point icon action inside its 44-point
  // actions row; a Flutter `Row` centres it, three points down.
  'toolbar.action2': 3,
  // The two points the line below is taller, split either side of it: the
  // centred input starts one point higher than the reference's.
  'search.input': -1,
  ...kOneRowFewer,
};

const Map<String, double> kListGrown = <String, double>{
  'sect1': kTightGap,
  'sect2': kSectionGap,
  'related.sect': kSectionGap,
  // The section keeps its 24 and loses the fourth row.
  'sect3': kSectionGap - kReferenceRow,
  // The card itself, one row shorter.
  'rows': -kReferenceRow,
  // Flutter's editable line for the field's 14-point face is 22 where
  // Chrome's `<input>` content box is 20.
  'search.input': 2,
};

/// A `Container` sized to a square tile — the disc a record row draws its
/// initial on, and the tile a rich row draws its logo on. Both are drawn at
/// 38, and neither is the 44-point target that overhangs it (D6).
Finder tile(double side) => find.byWidgetPredicate(
  (Widget w) =>
      w is Container &&
      w.constraints == BoxConstraints.tightFor(width: side, height: side),
);

/// The 38-point box a tool bar's icon control is drawn in. The control itself
/// fills the 44-point target around it, which is not the measured box.
Finder barIcon() => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is SizedBox && w.width == 38 && w.height == 38,
  ),
);

Finder inToolbar(Finder matching) =>
    find.descendant(of: find.byType(LumeToolbar), matching: matching);

Finder rrec(int at) => find.byType(LumeRecordRow).at(at);

Finder rrow(int at) =>
    inKey(LumeBirthdaysTool.upcomingKey, find.byType(LumeRichRow)).at(at);

Finder inRrec(Finder matching) =>
    find.descendant(of: rrec(0), matching: matching);

Finder inRrow(Finder matching) =>
    find.descendant(of: rrow(0), matching: matching);

/// `.summary__stats` — the strip under the lead figure, which the card draws
/// as the one box with a hairline over it and 14 points of padding.
Finder statStrip() => inKey(
  LumeBirthdaysTool.summaryKey,
  find.byWidgetPredicate(
    (Widget w) => w is Container && w.padding == const EdgeInsets.only(top: 14),
  ),
);

/// `.summary__stat` — one of the three equal columns inside it.
Finder inStats(int at) =>
    find.descendant(of: statStrip(), matching: find.byType(Column)).at(at);

/// The list cell's elements.
///
/// Three measured names are left out rather than pointed at something that is
/// not the same box:
///
/// * `srcline` — Lume's own "Sample data" mark leads the line here (C85) and
///   the reference has no such part, so its box is wider and, being placed by
///   the trailing edge, starts further back. What the line says, and that the
///   mark is what the difference is, is asserted in the second group.
/// * `fab` — the reference places its floating action 96 above the bottom of
///   its *scrolled content* (983.58 on a screen whose content ends at
///   1129.58, below its own viewport); Flutter places it 96 above the bottom
///   of the *viewport*, which on the tall surface these cells are pumped at —
///   tall so that nothing is clipped — is 4736. Two measurements from
///   different edges, and no shift of one produces the other. Its size and
///   its `x`, which both builds do measure the same way, are asserted against
///   the same cell in the second group instead.
/// * `cfact.value` — the reference's is an inline box shrink-wrapped at the
///   trailing edge; Flutter's is an end-aligned `Expanded`, which is the
///   whole remaining column. Same words, different box.
Map<String, Finder> listElements() => <String, Finder>{
  'toolbar': find.byType(LumeToolbar),
  'toolbar.back': barIcon().first,
  'toolbar.title': inToolbar(find.byType(Text)).first,
  'toolbar.sub': inToolbar(find.byType(Text)).at(1),
  // `.toolbar__actions` — the one shrink-wrapped row in the bar, and an
  // ancestor of the text button's own, so it is the first in tree order.
  'toolbar.actions': inToolbar(
    find.byWidgetPredicate(
      (Widget w) => w is Row && w.mainAxisSize == MainAxisSize.min,
    ),
  ).first,
  'toolbar.textbtn': find.byKey(keys.add),
  'toolbar.action2': barIcon().last,
  'search': find.byKey(keys.search),
  'search.input': find.descendant(
    of: find.byKey(keys.search),
    matching: find.byType(EditableText),
  ),
  'recs': find.byKey(keys.records),
  'rrec1': rrec(0),
  'rrec2': rrec(1),
  'rrec.disc': inRrec(tile(38)),
  'rrec.title': inRrec(find.byType(Text)).at(1),
  'rrec.sub': inRrec(find.byType(Text)).at(2),
  'rrec.value': inRrec(find.byType(LumeNumerals)),
  'rrec.chev': inRrec(find.byType(LumeIcon)).last,
  'sect1': find.byType(LumeToolSection).at(0),
  'sect2': find.byType(LumeToolSection).at(1),
  'sect3': find.byType(LumeToolSection).at(2),
  'sect3.title': find.text('Coming up'),
  'summary': find.byKey(LumeBirthdaysTool.summaryKey),
  'summary.kicker': inKey(
    LumeBirthdaysTool.summaryKey,
    find.byType(Text),
  ).first,
  'summary.value': inKey(
    LumeBirthdaysTool.summaryKey,
    find.byType(LumeNumerals),
  ).first,
  'summary.caption': inKey(
    LumeBirthdaysTool.summaryKey,
    find.byType(Text),
  ).at(2),
  'summary.stats': statStrip(),
  'summary.stat1': inStats(0),
  'summary.stat2': inStats(1),
  'summary.stat3': inStats(2),
  'rows': find.byKey(LumeBirthdaysTool.upcomingKey),
  'rrow1': rrow(0),
  'rrow2': rrow(1),
  'rrow.logo': inRrow(tile(38)),
  'rrow.title': inRrow(find.byType(Text)).at(1),
  'rrow.sub': inRrow(find.byType(Text)).at(2),
  'rrow.meta': inRrow(find.byType(Wrap)),
  'rrow.value': inRrow(find.byType(LumeNumerals)),
  'rrow.chev': inRrow(find.byType(LumeIcon)).last,
  'srcbar': find.byType(LumeSourceBar),
  'fresh': find.byType(LumeFreshness),
  'related': find.byType(LumeRelatedTools),
  'related.sect': find.byType(LumeToolSection).at(4),
  'related.title': find.text('Related tools'),
  'related.item1': relatedItem(0),
  'related.item2': relatedItem(1),
};

/// `.related__item` — the 78-point tile, not the target around it.
Finder relatedItem(int at) => find
    .byWidgetPredicate(
      (Widget w) =>
          w is Container &&
          w.constraints == const BoxConstraints.tightFor(width: 78),
    )
    .at(at);

/// Widths the words set rather than the layout: the reference stretches these
/// boxes to their column and Flutter shrink-wraps them to the text, so where
/// they start and how tall their line is are compared and the column is not.
const Set<String> kTextWidth = <String>{
  'toolbar.title',
  'toolbar.sub',
  'rrec.sub',
  'rrow.sub',
  'rrow.meta',
  'summary.kicker',
  'summary.value',
  'summary.caption',
};

Map<String, Finder> detailElements() => <String, Finder>{
  'toolbar': find.byType(LumeToolbar),
  'chero': find.byKey(keys.hero),
  'chero.kicker': inKey(keys.hero, find.byType(Text)).first,
  'chero.value': inKey(keys.hero, find.byType(LumeNumerals)),
  'chero.caption': inKey(keys.hero, find.byType(Text)).at(2),
  'cfacts': find.byKey(keys.facts),
  'cfact1': inKey(
    keys.facts,
    find.byWidgetPredicate(
      (Widget w) =>
          w is Padding && w.padding == const EdgeInsets.symmetric(vertical: 15),
    ),
  ).first,
  'cfact.label': inKey(keys.facts, find.byType(Text)).first,
  'cacts': find.byKey(keys.detailActions),
  'cact.edit': find.byType(LumeDetailAction).first,
  'cact.danger': find.byType(LumeDetailAction).last,
  'crud.id': find.byKey(keys.recordId),
};

/// The hero's three lines are shrink-wrapped here and stretched there.
const Set<String> kHeroText = <String>{
  'chero.kicker',
  'chero.value',
  'chero.caption',
};

Map<String, Finder> formElements() => <String, Finder>{
  'toolbar': find.byType(LumeToolbar),
  'cform': find.byKey(keys.form),
  'cfield1': find.byKey(keys.field('name')),
  'cfield2': find.byKey(keys.field('kind')),
  'cfield.label': find
      .descendant(
        of: find.byKey(keys.field('name')),
        matching: find.byType(Row),
      )
      .first,
  'cfield.box': find.descendant(
    of: find.byKey(keys.field('name')),
    matching: find.byType(AnimatedContainer),
  ),
  'csubmit': find.byKey(keys.submit),
  'csubmit.btn': inKey(keys.submit, find.byType(LumeButton)),
  'csubmit.note': inKey(keys.submit, find.byType(Text)).last,
};

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('birthdays');
  tearDownAll(parity.write);

  void check(
    WidgetTester tester,
    String cell,
    Map<String, Finder> elements, {
    Set<String> noWidth = const <String>{},
    Set<String> noHeight = const <String>{},
    Map<String, double> shifted = const <String, double>{},
    Map<String, double> grown = const <String, double>{},
  }) {
    final List<String> misses = parity.bounds(
      tester,
      cell,
      elements,
      noWidth: noWidth,
      noHeight: noHeight,
      shifted: shifted,
      grown: grown,
    );
    expect(misses, isEmpty, reason: misses.join('\n'));
  }

  // Only the English cells are compared point for point. The Urdu and Arabic
  // cells were measured in Chrome with its own Noto faces; Flutter loads
  // different ones, so their line boxes differ by a few points everywhere and
  // a bounds comparison would be measuring the font, not the layout. What
  // those cells are for — the words, the direction and the numerals — is
  // asserted in `birthdays_screen_test.dart`.
  group('where everything is', () {
    for (final String theme in <String>['light', 'dark']) {
      final String cell = 'tool_birthdays_default_pk_390x844_${theme}_en';
      testWidgets(cell, (WidgetTester tester) async {
        await pumpBirthdays(
          tester,
          surface: const Size(390, 5000),
          theme: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
        );
        check(
          tester,
          cell,
          listElements(),
          noWidth: kTextWidth,
          shifted: kListShifted,
          grown: kListGrown,
        );
      });
    }

    // The two width classes above the phone. The shell takes its rail (84 at
    // medium) or its sidebar (244 at expanded) out of the surface, and the
    // reference's stage takes 25 points of margin either side out of its
    // window on top of that — so the surface is reduced by the stage's 50 and
    // the shell's own rail then lands the column exactly where the reference
    // measured it: 650 − 84 = 566, 1050 − 244 = 806. The same subtraction
    // `worldclock_parity_test.dart` and the wave-2 cells make.
    //
    // 852x393 is left out: it is the height-constrained landscape cell, and
    // its column comes from the rail against a 393-point height, which a tall
    // surface cannot reproduce.
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_birthdays_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_birthdays_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpBirthdays(tester, surface: size);
        check(
          tester,
          cell,
          listElements(),
          noWidth: kTextWidth,
          shifted: kListShifted,
          grown: kListGrown,
        );
      });
    }
  });

  group('where everything is, on one date', () {
    testWidgets('tool_birthdays_default_pk_detail_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpBirthdays(tester);
      await tapVisible(tester, rrec(0));
      check(
        tester,
        'tool_birthdays_default_pk_detail_390x844_light_en',
        detailElements(),
        noWidth: kHeroText,
      );
    });

    testWidgets('tool_birthdays_default_pk_detail_1100x900_light_en', (
      WidgetTester tester,
    ) async {
      // The same 1050 as the wide list cell: the stage's 50 points of
      // margin off the reference's window, and the shell's sidebar off that.
      await pumpBirthdays(tester, surface: const Size(1050, 5000));
      await tapVisible(tester, rrec(0));
      check(
        tester,
        'tool_birthdays_default_pk_detail_1100x900_light_en',
        detailElements(),
        noWidth: kHeroText,
      );
    });

    testWidgets('tool_birthdays_default_pk_new_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpBirthdays(tester);
      await tapVisible(tester, find.byKey(keys.add));
      check(
        tester,
        'tool_birthdays_default_pk_new_390x844_light_en',
        formElements(),
        // The reference's `.cform` is the fields; the key here is on the whole
        // form, the submit bar included.
        noHeight: const <String>{'cform'},
        grown: const <String, double>{
          // Lume sets the note 12 under the button where the reference sets
          // 10, and the note's own line is 0.65 taller.
          'csubmit': 2,
        },
        shifted: const <String, double>{
          // The same 12 against 10, less the 0.65 the accent button's line is
          // shorter than the reference's 46.
          'csubmit.note': 1.35,
        },
      );
    });
  });

  group('what it says, in the state the reference was captured in', () {
    const String listCell = 'tool_birthdays_default_pk_390x844_light_en';
    const String detailCell =
        'tool_birthdays_default_pk_detail_390x844_light_en';
    const String formCell = 'tool_birthdays_default_pk_new_390x844_light_en';

    Map<String, dynamic> composition(String cell) =>
        webToolCell(cell)!['composition'] as Map<String, dynamic>;

    testWidgets('the bar, the search and the three records', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpBirthdays(tester);
      final Map<String, dynamic> k = composition(listCell);

      final Map<String, dynamic> header = k['header'] as Map<String, dynamic>;
      expect(find.text(header['title'] as String), findsOneWidget);
      expect(find.text(header['sub'] as String), findsOneWidget);
      for (final dynamic a in header['actions'] as List<dynamic>) {
        final Map<String, dynamic> action = a as Map<String, dynamic>;
        expect(find.bySemanticsLabel(action['label'] as String), findsWidgets);
        if (action['text'] != null) {
          expect(find.text(action['text'] as String), findsOneWidget);
        }
      }

      final Map<String, dynamic> records = k['records'] as Map<String, dynamic>;
      expect(
        tester.widget<LumeSearchField>(find.byKey(keys.search)).placeholder,
        records['placeholder'],
      );

      final List<dynamic> rows = records['rows'] as List<dynamic>;
      final List<LumeRecordRow> drawn = tester
          .widgetList<LumeRecordRow>(find.byType(LumeRecordRow))
          .toList();
      expect(drawn, hasLength(rows.length));
      for (int i = 0; i < rows.length; i++) {
        final Map<String, dynamic> r = rows[i] as Map<String, dynamic>;
        expect(drawn[i].initial, r['initial']);
        expect(drawn[i].title, r['title']);
        expect(drawn[i].subtitle, r['sub']);
        expect(drawn[i].value, r['value']);
      }
      handle.dispose();
    });

    testWidgets('the summary — and the one figure it does not agree with', (
      WidgetTester tester,
    ) async {
      await pumpBirthdays(tester);
      final Map<String, dynamic> k = composition(listCell);
      final Map<String, dynamic> s = k['summary'] as Map<String, dynamic>;
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeBirthdaysTool.summaryKey),
      );
      expect(card.kicker, s['kicker']);
      expect(card.value, s['value']);
      expect(card.caption, s['caption']);

      final List<dynamic> stats = s['stats'] as List<dynamic>;
      expect(card.stats, hasLength(stats.length));
      for (int i = 0; i < stats.length; i++) {
        final Map<String, dynamic> stat = stats[i] as Map<String, dynamic>;
        expect(card.stats[i].label, stat['label']);
        if (i > 0) expect(card.stats[i].value, stat['value']);
      }

      // Tracked is the one figure that differs, and the reference contradicts
      // itself about it on this very screen: its card says four are tracked,
      // its record list holds three, and its own tool bar says "3 records".
      // Three is what there is.
      expect((stats.first as Map<String, dynamic>)['value'], '4');
      expect(
        card.stats.first.value,
        '3',
        reason:
            'the reference counts a fourth date its own list does not hold, '
            'on a screen whose bar says "3 records"',
      );
    });

    testWidgets('Coming up — the fourth row the reference lists is not a '
        'record', (WidgetTester tester) async {
      await pumpBirthdays(tester);
      final Map<String, dynamic> k = composition(listCell);

      final List<dynamic> listed = k['rows'] as List<dynamic>;
      expect(listed, hasLength(4));
      final Set<String> held = <String>{
        for (final dynamic r
            in (k['records'] as Map<String, dynamic>)['rows'] as List<dynamic>)
          (r as Map<String, dynamic>)['title'] as String,
      };
      expect(held, hasLength(3));
      expect(
        held,
        isNot(contains((listed.last as Map<String, dynamic>)['title'])),
        reason: 'the reference\'s fourth row is a constant, not a record',
      );

      // Which is the whole of the 73 points declared above.
      expect(
        inKey(LumeBirthdaysTool.upcomingKey, find.byType(LumeRichRow)),
        findsNWidgets(3),
      );
    });

    testWidgets('the source bar, the related rail and the floating action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpBirthdays(tester);
      final Map<String, dynamic> k = composition(listCell);

      final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
      expect(find.text(src['fresh'] as String), findsOneWidget);
      expect(referenceSourceLine(tester), src['line']);
      // C85: a parity build marks the reproduced data in its own source line,
      // which is the part the reference's `.srcline` has no equivalent of and
      // the reason that box is not compared.
      expect(find.byKey(LumeSourceLine.sampleKey), findsOneWidget);
      expect(find.text('Sample data'), findsOneWidget);

      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);

      final Map<String, dynamic> fab = k['fab'] as Map<String, dynamic>;
      expect(
        tester.widget<LumeFab>(find.byKey(LumeBirthdaysTool.fabKey)).label,
        fab['label'],
      );
      expect(find.bySemanticsLabel(fab['label'] as String), findsOneWidget);
      // Everything about its box that both builds measure the same way: the
      // drawn size, and where the trailing edge puts it. Only `y` differs,
      // and only because the two builds measure it from different edges.
      final Map<String, dynamic> bounds =
          webToolCell(listCell)!['bounds'] as Map<String, dynamic>;
      final Map<String, dynamic> box = bounds['fab'] as Map<String, dynamic>;
      final Rect drawn = tester.getRect(find.byKey(LumeBirthdaysTool.fabKey));
      expect(drawn.width, box['width']);
      expect(drawn.height, box['height']);
      expect(
        drawn.left - tester.getRect(find.byType(LumeToolbar)).left,
        (box['x'] as num) -
            ((bounds['toolbar'] as Map<String, dynamic>)['x'] as num),
      );
      handle.dispose();
    });

    testWidgets('the detail — and the year the reference drops', (
      WidgetTester tester,
    ) async {
      await pumpBirthdays(tester);
      await tapVisible(tester, rrec(0));
      final Map<String, dynamic> records =
          composition(detailCell)['records'] as Map<String, dynamic>;

      final Map<String, dynamic> hero = records['hero'] as Map<String, dynamic>;
      final LumeRecordHero drawn = tester.widget<LumeRecordHero>(
        find.byKey(keys.hero),
      );
      expect(drawn.kicker, hero['kicker']);
      expect(drawn.value, hero['value']);
      expect(drawn.caption, hero['caption']);

      final List<dynamic> facts = records['facts'] as List<dynamic>;
      final List<String> said = textsIn(tester, find.byKey(keys.facts));
      expect(said, hasLength(facts.length * 2));
      for (int i = 0; i < facts.length; i++) {
        final List<dynamic> fact = facts[i] as List<dynamic>;
        expect(said[i * 2], fact[0]);
        // The Date fact is the exception, below.
        if (i != 1) expect(said[i * 2 + 1], fact[1]);
      }

      // The reference prints a 1997 birthday as "Thu, 11 Sept": the weekday
      // of a year it does not name, beside a "Next one" that is the same day
      // and month. Here the stored day is printed with its year, which is the
      // only part of it the reader cannot work out from the row above.
      expect((facts[1] as List<dynamic>)[1], 'Thu, 11 Sept');
      expect(
        said[3],
        '11 Sept 1997',
        reason: 'the date a record stores, with the year the reference drops',
      );
    });

    testWidgets('the form: every field, the button and its note', (
      WidgetTester tester,
    ) async {
      await pumpBirthdays(tester);
      await tapVisible(tester, find.byKey(keys.add));
      final Map<String, dynamic> records =
          composition(formCell)['records'] as Map<String, dynamic>;
      final List<dynamic> fields = records['fields'] as List<dynamic>;

      const List<String> names = <String>['name', 'kind', 'date', 'notes'];
      for (int i = 0; i < fields.length; i++) {
        final Map<String, dynamic> f = fields[i] as Map<String, dynamic>;
        expect(find.text(f['label'] as String), findsOneWidget);
        final Widget control = tester.widget(find.byKey(keys.field(names[i])));
        switch (f['control'] as String) {
          case 'input:text':
            expect(control, isA<LumeFormField>());
            expect((control as LumeFormField).placeholder, f['placeholder']);
          case 'textarea':
            expect(control, isA<LumeFormField>());
            expect((control as LumeFormField).kind, LumeFieldKind.multiline);
            expect(control.optionalLabel, f['optional']);
          // A native `<select>` and a native date input are both a picker
          // here: the options are chosen in a sheet rather than in place.
          case 'select':
          case 'input:date':
            expect(control, isA<LumeFormPicker>());
        }
      }

      // The select's own options, which the reference draws inside its
      // `<select>` and this draws when the picker is opened.
      final Map<String, dynamic> occasion = fields[1] as Map<String, dynamic>;
      final List<dynamic> options = occasion['options'] as List<dynamic>;
      expect(
        tester.widget<LumeFormPicker>(find.byKey(keys.field('kind'))).value,
        options.first,
      );
      await tapVisible(tester, find.byKey(keys.field('kind')));
      for (final dynamic option in options) {
        expect(find.text(option as String), findsWidgets);
      }

      expect(
        find.text((records['submit'] as List<dynamic>).single as String),
        findsWidgets,
      );
      expect(find.text(records['submitNote'] as String), findsOneWidget);
    });
  });
}
